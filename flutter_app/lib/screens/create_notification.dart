import 'package:flutter/material.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
import 'package:outgoing_notifications/services/common/capitalize_each_word_formatter.dart';
import 'package:outgoing_notifications/services/common/send_bulk_sms.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'background/wavy_scaffold.dart';
import 'recipients_list.dart';
import 'package:outgoing_notifications/main.dart';
import 'dart:convert';

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

  Future<({String smsUsername, String smsPassword})?>
  _loadGatewayCredentials() async {
    final response = await _apiClient.get(
      AppConstants.messageGatewayCredentialsPath,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final smsUsername = (body['smsUsername'] as String?)?.trim() ?? '';
    final smsPassword = (body['smsPassword'] as String?) ?? '';

    if (smsUsername.isEmpty || smsPassword.isEmpty) return null;

    return (smsUsername: smsUsername, smsPassword: smsPassword);
  }

  Future<void> _selectRecipients() async {
    final selectedRecipients = await Navigator.push<List<Recipient>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => RecipientsListScreen(
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

    setState(() => _isSubmitting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            title: Text('Sending Notification'),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Please wait...'),
              ],
            ),
          ),
    );

    try {
      final gatewayCredentials = await _loadGatewayCredentials();
      if (gatewayCredentials == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load SMS gateway credentials from API'),
            ),
          );
        }
        return;
      }

      final phoneNumbers =
          _selectedRecipients
              .map((r) => r.phoneNumber.trim())
              .where((n) => n.isNotEmpty)
              .toList();

      final smsResult = await sendBulkSms(
        smsUsername: gatewayCredentials.smsUsername,
        smsPassword: gatewayCredentials.smsPassword,
        msisdnList: phoneNumbers,
        message: message,
      );

      final deliveryStatus =
          smsResult.failedCount == 0
              ? 'Sent'
              : smsResult.sentCount == 0
              ? 'Failed'
              : 'Partial';
      final errorDetails =
          smsResult.failedReasons.isEmpty
              ? null
              : smsResult.failedReasons.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' | ');

      final recipientsSummary = jsonEncode(
        _selectedRecipients.map((r) {
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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent: ${smsResult.sentCount}, Failed: ${smsResult.failedCount}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoaderScreen()),
      (route) => false,
    );
  }

  Future<void> _saveNotificationToApi({
    required String title,
    required String message,
    required String deliveryStatus,
    String? errorDetails,
    String? recipientsSummary,
  }) async {
    try {
      await _apiClient.post(
        AppConstants.notificationsPath,
        <String, dynamic>{
          'title': title,
          'message': message,
          'type': 'Sms',
          'deliveryStatus': deliveryStatus,
          if (errorDetails != null && errorDetails.isNotEmpty)
            'errorDetails': errorDetails,
          if (recipientsSummary != null) 'recipientsSummary': recipientsSummary,
        },
      );
    } catch (_) {}
  }

  void _showPreview() {
    final title = _titleController.text.trim().isEmpty
        ? 'Notification Title'
        : _titleController.text.trim();
    final message = _messageController.text.trim().isEmpty
        ? 'Your notification message will appear here.'
        : _messageController.text.trim();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notification Preview'),
            content: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white70,
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildRecipientsField() {
    const chipLimit = 2;
    final visible = _selectedRecipients.take(chipLimit).toList();
    final overflow = _selectedRecipients.length - chipLimit;

    return GestureDetector(
      onTap: _selectRecipients,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'To:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF5C3CB0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
                  _selectedRecipients.isEmpty
                      ? const Text(
                        'Who is this for?',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      )
                      : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ...visible.map(
                            (r) => Chip(
                              label: Text(
                                r.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted:
                                  () => setState(
                                    () => _selectedRecipients.remove(r),
                                  ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          if (overflow > 0)
                            Chip(
                              label: Text(
                                '+$overflow more',
                                style: const TextStyle(fontSize: 12),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
            ),
            const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF5C3CB0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Color get _countColor {
    final remaining = _maxMessageLength - _messageController.text.length;
    if (remaining <= 20) return Colors.red;
    if (remaining <= 50) return Colors.orange;
    return Colors.grey;
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF5C3CB0), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charCount = _messageController.text.length;

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
                  const Expanded(
                    child: Text(
                      'Create Notification',
                      style: TextStyle(
                        color: Color(0xFF5C3CB0),
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
                      _buildRecipientsField(),
                      const SizedBox(height: 16),

                      const Text(
                        'NOTIFICATION TITLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5C3CB0),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        inputFormatters: [CapitalizeEachWordFormatter()],
                        decoration: _fieldDecoration('Enter subject line...'),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'MESSAGE BODY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5C3CB0),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _messageController,
                        maxLength: _maxMessageLength,
                        minLines: 8,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: _fieldDecoration('What do you want to say?'),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C3CB0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$charCount / $_maxMessageLength',
                            style: TextStyle(
                              fontSize: 11,
                              color: _countColor == Colors.grey ? Colors.white70 : _countColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF5C3CB0)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Schedule for later',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            Switch(
                              value: _scheduleForLater,
                              activeThumbColor: const Color(0xFF5C3CB0),
                              activeTrackColor: const Color(0xFF5C3CB0).withValues(alpha: 0.4),
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
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text(
                            'Send',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
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
