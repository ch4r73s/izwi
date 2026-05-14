import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/config/navigation_key.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
import 'package:outgoing_notifications/services/common/capitalize_each_word_formatter.dart';
import 'package:outgoing_notifications/services/common/send_bulk_sms.dart';
import 'package:outgoing_notifications/services/common/template_resolver.dart';
import 'package:outgoing_notifications/services/storage/failed_notification_log.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'package:outgoing_notifications/models/notification_template.dart';
import 'background/wavy_scaffold.dart';
import 'botttomsheets/template_picker_sheet.dart';
import 'recipients_list.dart';
import 'package:outgoing_notifications/main.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiClient = ApiClient(SecureStorageService());
  final _maxMessageLength = 320;
  final List<Recipient> _selectedRecipients = [];
  bool _isSubmitting = false;
  bool _scheduleForLater = false;

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty &&
      _selectedRecipients.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<({String provider, String smsEndpoint, String smsUsername, String smsPassword, String apiKey, String senderId})?>
  _loadGatewayCredentials() async {
    final response = await _apiClient.get(AppConstants.messageGatewayCredentialsPath);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final provider    = (body['provider']    as String?)?.trim() ?? '';
    final smsEndpoint = (body['smsEndpoint'] as String?)?.trim() ?? '';
    final smsUsername = (body['smsUsername'] as String?)?.trim() ?? '';
    final smsPassword = (body['smsPassword'] as String?)?.trim() ?? '';
    final apiKey      = (body['apiKey']      as String?)?.trim() ?? '';
    final senderId    = (body['senderId']    as String?)?.trim() ?? '';

    if (smsEndpoint.isEmpty) return null;

    return (provider: provider, smsEndpoint: smsEndpoint, smsUsername: smsUsername, smsPassword: smsPassword, apiKey: apiKey, senderId: senderId);
  }

  Future<void> _selectRecipients() async {
    final selectedRecipients = await Navigator.push<List<Recipient>>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipientsListScreen(
          selectedRecipients: _selectedRecipients,
          isSelectMode: true,
        ),
      ),
    );

    if (selectedRecipients == null) return;
    setState(() {
      _selectedRecipients
        ..clear()
        ..addAll(selectedRecipients);
    });
  }

  Future<void> _saveAndSendNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final recipientsCopy = List<Recipient>.from(_selectedRecipients);

    setState(() => _isSubmitting = true);

    final gatewayCredentials = await _loadGatewayCredentials();
    if (!mounted) return;

    if (gatewayCredentials == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load SMS gateway credentials from API')),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoaderScreen()),
      (route) => false,
    );

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Sending to ${recipientsCopy.length} recipient${recipientsCopy.length == 1 ? '' : 's'}...',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    unawaited(_runSendInBackground(
      title: title,
      message: message,
      recipients: recipientsCopy,
      gatewayCredentials: gatewayCredentials,
    ));
  }

  Future<void> _runSendInBackground({
    required String title,
    required String message,
    required List<Recipient> recipients,
    required ({
      String provider,
      String smsEndpoint,
      String smsUsername,
      String smsPassword,
      String apiKey,
      String senderId,
    }) gatewayCredentials,
  }) async {
    // ── Step 1: Save-first ─ create a Pending record before sending ──────────
    String? notificationId;
    try {
      final pendingPayload = recipients.map((r) => {
        'name': r.name,
        'phoneNumber': r.phoneNumber.trim(),
        'status': 'Pending',
      }).toList();

      final saveResp = await _apiClient.post(AppConstants.notificationsPath, {
        'title': title,
        'message': message,
        'type': 'Sms',
        'deliveryStatus': 'Pending',
        'recipients': pendingPayload,
      });

      if (saveResp.statusCode >= 200 && saveResp.statusCode < 300) {
        final body = jsonDecode(saveResp.body) as Map<String, dynamic>;
        notificationId = body['id'] as String?;
      }
    } catch (_) {
      // Pre-send save failed — continue sending, will fall back to post-send save.
    }

    // ── Step 2: Send ──────────────────────────────────────────────────────────
    try {
      final messages = {
        for (final r in recipients)
          if (r.phoneNumber.trim().isNotEmpty)
            r.phoneNumber.trim(): resolveTemplate(message, r),
      };

      final smsResult = await sendBulkSms(
        provider: gatewayCredentials.provider,
        smsEndpoint: gatewayCredentials.smsEndpoint,
        smsUsername: gatewayCredentials.smsUsername,
        smsPassword: gatewayCredentials.smsPassword,
        apiKey: gatewayCredentials.apiKey,
        senderId: gatewayCredentials.senderId,
        messages: messages,
      );

      final deliveryStatus = smsResult.failedCount == 0
          ? 'Sent'
          : smsResult.sentCount == 0
              ? 'Failed'
              : 'Partial';
      final errorDetails = smsResult.failedReasons.isEmpty
          ? null
          : smsResult.failedReasons.entries.map((e) => '${e.key}: ${e.value}').join(' | ');

      final recipientPayload = recipients.map((r) {
        final phone = r.phoneNumber.trim();
        final sent = !smsResult.failedMsisdns.contains(phone);
        return {
          'name': r.name,
          'phoneNumber': phone,
          'status': sent ? 'Sent' : 'Failed',
          if (!sent && smsResult.failedReasons.containsKey(phone))
            'errorReason': smsResult.failedReasons[phone],
          if (sent && smsResult.gatewayMessageIds.containsKey(phone))
            'gatewayMessageId': smsResult.gatewayMessageIds[phone],
          if (sent && smsResult.gatewayPayloads.containsKey(phone))
            'gatewayPayload': smsResult.gatewayPayloads[phone],
        };
      }).toList();

      // ── Step 3: Update the pre-saved record, or fall back to a fresh POST ──
      if (notificationId != null) {
        try {
          await _apiClient.patch(
            AppConstants.notificationDeliveryPath(notificationId),
            {
              'deliveryStatus': deliveryStatus,
              if (errorDetails != null) 'errorDetails': errorDetails,
              'recipients': recipientPayload,
            },
          );
        } catch (e) {
          // PATCH failed — log result locally so it appears in the UI.
          final recipientsSummary = jsonEncode(
            recipients.map((r) {
              final sent = !smsResult.failedMsisdns.contains(r.phoneNumber.trim());
              return {'name': r.name, 'phone': r.phoneNumber.trim(), 'sent': sent};
            }).toList(),
          );
          await FailedNotificationLog.write(
            title: title,
            message: message,
            deliveryStatus: deliveryStatus,
            recipientsSummary: recipientsSummary,
            errorDetails: errorDetails,
            error: e,
          );
        }
      } else {
        // Pre-send save never succeeded — try a full POST now with final results.
        final recipientsSummary = jsonEncode(
          recipients.map((r) {
            final sent = !smsResult.failedMsisdns.contains(r.phoneNumber.trim());
            return {'name': r.name, 'phone': r.phoneNumber.trim(), 'sent': sent};
          }).toList(),
        );
        await _saveNotificationToApi(
          title: title,
          message: message,
          deliveryStatus: deliveryStatus,
          errorDetails: errorDetails,
          recipientsSummary: recipientsSummary,
          recipients: recipientPayload,
        );
      }

      if (smsResult.sentCount > 0) {
        // Billing: each 160-char block counts as 1 SMS unit (ceil). Sum across
        // sent recipients because name substitution can shift message length.
        final smsUnitsConsumed = messages.entries
            .where((e) => !smsResult.failedMsisdns.contains(e.key))
            .fold(0, (sum, e) => sum + (e.value.length / 160).ceil());
        await _apiClient.post(AppConstants.recordSmsPath, {'count': smsUnitsConsumed});
      }

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Sent: ${smsResult.sentCount}, Failed: ${smsResult.failedCount}'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Send failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _saveNotificationToApi({
    required String title,
    required String message,
    required String deliveryStatus,
    String? errorDetails,
    String? recipientsSummary,
    List<Map<String, dynamic>>? recipients,
  }) async {
    try {
      await _apiClient.post(
        AppConstants.notificationsPath,
        <String, dynamic>{
          'title': title,
          'message': message,
          'type': 'Sms',
          'deliveryStatus': deliveryStatus,
          if (errorDetails != null && errorDetails.isNotEmpty) 'errorDetails': errorDetails,
          if (recipientsSummary != null) 'recipientsSummary': recipientsSummary,
          if (recipients != null && recipients.isNotEmpty) 'recipients': recipients,
        },
      );
    } catch (e) {
      await FailedNotificationLog.write(
        title: title,
        message: message,
        deliveryStatus: deliveryStatus,
        recipientsSummary: recipientsSummary,
        errorDetails: errorDetails,
        error: e,
      );
    }
  }

  Future<void> _openTemplatePicker() async {
    final template = await showModalBottomSheet<NotificationTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TemplatePickerSheet(),
    );
    if (template == null) return;
    _titleController.text = template.title;
    _messageController.text = template.body;
  }

  Future<void> _saveAsTemplate() async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template name',
            hintText: 'e.g. Weekly Update',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;

    final response = await _apiClient.post(
      AppConstants.templatesPath,
      {
        'name': nameController.text.trim(),
        'title': _titleController.text.trim(),
        'body': _messageController.text.trim(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.statusCode == 201 ? 'Template saved.' : 'Failed to save template.'),
        ),
      );
    }
  }

  void _showPreview() {
    final cs = Theme.of(context).colorScheme;
    final title = _titleController.text.trim().isEmpty
        ? 'Notification Title'
        : _titleController.text.trim();
    final message = _messageController.text.trim().isEmpty
        ? 'Your notification message will appear here.'
        : _messageController.text.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preview'),
        content: Container(
          decoration: BoxDecoration(
            color: cs.inverseSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_rounded, color: cs.onInverseSurface, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: cs.onInverseSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: cs.onInverseSurface.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRecipientsField(ColorScheme cs) {
    const chipLimit = 2;
    final visible = _selectedRecipients.take(chipLimit).toList();
    final overflow = _selectedRecipients.length - chipLimit;

    return GestureDetector(
      onTap: _selectRecipients,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'To:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _selectedRecipients.isEmpty
                  ? Text('Who is this for?', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...visible.map(
                          (r) => Chip(
                            label: Text(r.name, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _selectedRecipients.remove(r)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        if (overflow > 0)
                          Chip(
                            label: Text('+$overflow more', style: const TextStyle(fontSize: 12)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
            ),
            Icon(Icons.person_add_alt_1_rounded, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Color _countColor(ColorScheme cs) {
    final remaining = _maxMessageLength - _messageController.text.length;
    if (remaining <= 20) return Colors.red;
    if (remaining <= 50) return Colors.orange;
    return cs.onPrimary.withValues(alpha: 0.75);
  }

  InputDecoration _fieldDecoration(String hint, ColorScheme cs) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final charCount = _messageController.text.length;
    final hasMessage = _messageController.text.trim().isNotEmpty;

    return WavyScaffold(
      theme: theme,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Create Notification',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _showPreview,
                    icon: const Icon(Icons.preview_rounded),
                    tooltip: 'Preview',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecipientsField(cs),
                      const SizedBox(height: 16),

                      Text(
                        'NOTIFICATION TITLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        inputFormatters: [CapitalizeEachWordFormatter()],
                        decoration: _fieldDecoration('Enter subject line...', cs),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Text(
                            'MESSAGE BODY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _openTemplatePicker,
                            child: Row(
                              children: [
                                Icon(Icons.folder_open_rounded, size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Use Template',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _messageController,
                        maxLength: _maxMessageLength,
                        minLines: 8,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: _fieldDecoration('What do you want to say?', cs),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: hasMessage ? _saveAsTemplate : null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark_add_outlined,
                                  size: 14,
                                  color: hasMessage ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Save as Template',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasMessage ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$charCount / $_maxMessageLength',
                              style: TextStyle(fontSize: 11, color: _countColor(cs)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.schedule_rounded, size: 20, color: cs.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Schedule for later',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Switch(
                              value: _scheduleForLater,
                              activeThumbColor: cs.primary,
                              activeTrackColor: cs.primary.withValues(alpha: 0.4),
                              onChanged: (val) => setState(() => _scheduleForLater = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isValid && !_isSubmitting ? _saveAndSendNotification : null,
                          icon: _isSubmitting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text('Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
