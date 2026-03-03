import 'package:flutter/material.dart';
import 'package:outgoing_notifications/models/Notification.dart';
import 'background/wavy_scaffold.dart';
import 'package:outgoing_notifications/services/common/format_date.dart';
import 'package:outgoing_notifications/services/common/format_time.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final date = formatDate(notification.toMap()['date']);
    final time = formatTime(notification.toMap()['date']);
    final failed = notification.failedRecipients;
    final status = notification.deliveryStatus;

    return WavyScaffold(
      theme: Theme.of(context),
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
                    'Notification Detail',
                    style: TextStyle(
                      color: Color(0xFF5C3CB0),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 15.5, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(date),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(time),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DeliverySection(
              status: status,
              allRecipients: notification.allRecipients,
              failedRecipients: failed,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status.toLowerCase()) {
      'sent' => (Icons.check_circle_rounded, Colors.green, 'Sent'),
      'failed' => (Icons.cancel_rounded, Colors.red, 'Failed'),
      _ => (Icons.warning_amber_rounded, Colors.orange, 'Partial'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverySection extends StatelessWidget {
  final String status;
  final List<Map<String, dynamic>> allRecipients;
  final Map<String, String> failedRecipients;

  const _DeliverySection({
    required this.status,
    required this.allRecipients,
    required this.failedRecipients,
  });

  @override
  Widget build(BuildContext context) {
    final sentCount = allRecipients.where((r) => r['sent'] == true).length;
    final failedCount = allRecipients.where((r) => r['sent'] != true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                '$sentCount sent',
                style: const TextStyle(fontSize: 13, color: Colors.green),
              ),
              if (failedCount > 0) ...[
                const SizedBox(width: 12),
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$failedCount failed',
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ],
            ],
          ),
          if (allRecipients.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recipients',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            ...allRecipients.map((r) {
              final name = r['name'] as String? ?? '';
              final phone = r['phone'] as String? ?? '';
              final sent = r['sent'] == true;
              final failReason = failedRecipients[phone];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      sent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: sent ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : phone,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (name.isNotEmpty)
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.black54,
                              ),
                            ),
                          if (!sent && failReason != null)
                            Text(
                              failReason,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
