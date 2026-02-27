import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/models/Notification.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
import 'package:outgoing_notifications/services/common/capitalize_each_word_formatter.dart';
import 'package:outgoing_notifications/services/common/send_bulk_sms.dart';
import 'package:outgoing_notifications/services/database/app_notification_dao.dart';
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
  final _notificationDao = AppNotificationDao();
  final _secureStorage = SecureStorageService();
  final _maxMessageLength = 320;
  final List<Recipient> _selectedRecipients = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
    final token = await _secureStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.messageGatewayCredentialsPath}',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final smsUsername = (body['smsUsername'] as String?)?.trim() ?? '';
    final smsPassword = (body['smsPassword'] as String?) ?? '';

    if (smsUsername.isEmpty || smsPassword.isEmpty) {
      return null;
    }

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

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

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

      final notification = AppNotification(
        title: title,
        message: message,
        date: DateTime.now(),
      );
      await _notificationDao.insert(notification);

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
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoaderScreen()),
      (route) => false,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.94),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _maxMessageLength - _messageController.text.length;

    return WavyScaffold(
      theme: theme,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    inputFormatters: [CapitalizeEachWordFormatter()],
                    decoration: _inputDecoration(
                      label: 'Title',
                      icon: Icons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLength: _maxMessageLength,
                    minLines: 4,
                    maxLines: 6,
                    decoration: _inputDecoration(
                      label: 'Message',
                      icon: Icons.message_outlined,
                      helperText: '$remaining characters remaining',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedRecipients.isEmpty
                          ? 'No recipients selected'
                          : _selectedRecipients.map((r) => r.name).join(', '),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _selectRecipients,
                        icon: const Icon(Icons.group_add_rounded),
                        label: Text(
                          'Recipients (${_selectedRecipients.length})',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSubmitting ? null : _saveAndSendNotification,
                          icon:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.send_rounded),
                          label: const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
