import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                Expanded(
                  child: Text(
                    'Notification Detail',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.surface,
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
                      _StatusBadge(
                        status: status,
                        isLocalFailed: notification.isLocalFailed,
                      ),
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
  final bool isLocalFailed;

  const _StatusBadge({required this.status, this.isLocalFailed = false});

  @override
  Widget build(BuildContext context) {
    if (isLocalFailed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 14),
            SizedBox(width: 4),
            Text(
              'Not Saved',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (status.toLowerCase() == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 5),
            Text(
              'Sending...',
              style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    final (icon, color, label) = switch (status.toLowerCase()) {
      'sent'      => (Icons.check_circle_rounded, Colors.green, 'Sent'),
      'delivered' => (Icons.done_all_rounded, Colors.teal, 'Delivered'),
      'failed'    => (Icons.cancel_rounded, Colors.red, 'Failed'),
      _           => (Icons.warning_amber_rounded, Colors.orange, 'Partial'),
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
    final pendingCount  = allRecipients.where((r) => (r['status'] as String? ?? '').toLowerCase() == 'pending').length;
    final sentCount     = allRecipients.where((r) {
      final s = (r['status'] as String? ?? '').toLowerCase();
      return s == 'sent' || s == 'delivered' || r['sent'] == true && s != 'pending' && s != 'failed';
    }).length;
    final failedCount   = allRecipients.where((r) {
      final s = (r['status'] as String? ?? '').toLowerCase();
      return s == 'failed' || (r['sent'] != true && s != 'pending' && s != 'sent' && s != 'delivered');
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              if (pendingCount > 0) ...[
                const SizedBox(width: 2, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                const SizedBox(width: 6),
                Text(
                  '$pendingCount pending',
                  style: const TextStyle(fontSize: 13, color: Colors.amber),
                ),
                const SizedBox(width: 12),
              ],
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
            Text(
              'Recipients',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            ...allRecipients.map((r) {
              final name = r['name'] as String? ?? '';
              final phone = r['phone'] as String? ?? '';
              final recipientStatus = (r['status'] as String? ?? (r['sent'] == true ? 'Sent' : 'Failed')).toLowerCase();
              final isPending   = recipientStatus == 'pending';
              final isDelivered = recipientStatus == 'delivered';
              final isSent      = recipientStatus == 'sent';
              final failReason  = failedRecipients[phone];

              String? deliveredAtLabel;
              if (r['deliveredAt'] != null) {
                final parsed = DateTime.tryParse(r['deliveredAt'] as String);
                if (parsed != null) {
                  deliveredAtLabel = DateFormat('MMdd-HHmmss').format(parsed);
                }
              }

              final Widget statusIcon = isPending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                  : Icon(
                      isDelivered ? Icons.done_all_rounded : isSent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isDelivered ? Colors.teal : isSent ? Colors.green : Colors.red,
                      size: 16,
                    );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusIcon,
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
                              deliveredAtLabel != null ? '$phone ($deliveredAtLabel)' : phone,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (!isSent && !isPending && !isDelivered && failReason != null)
                            Text(
                              failReason,
                              style: const TextStyle(fontSize: 11, color: Colors.red),
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
