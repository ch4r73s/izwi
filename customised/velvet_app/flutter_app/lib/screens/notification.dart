import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/models/Notification.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
import 'package:outgoing_notifications/services/storage/failed_notification_log.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'package:outgoing_notifications/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'background/wavy_scaffold.dart';
import 'create_notification.dart';
import 'notification_detail.dart';
import 'settings.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _apiClient = ApiClient(SecureStorageService());
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    // 1. Fetch saved notifications from API.
    final apiNotifications = <AppNotification>[];
    try {
      final response = await _apiClient.get(AppConstants.notificationsSentPath);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        apiNotifications.addAll(
          list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (_) {}

    // 2. Load locally-stored failed entries and attempt to retry each one.
    final failedLogs = await FailedNotificationLog.readAll();
    final stillFailed = <Map<String, dynamic>>[];

    for (final log in failedLogs) {
      try {
        final smsErrorDetails = log['errorDetails'] as String?;
        final dbSaveError = log['error'] as String?;
        final combinedError = [
          if (smsErrorDetails != null && smsErrorDetails.isNotEmpty) smsErrorDetails,
          if (dbSaveError != null && dbSaveError.isNotEmpty) 'DB save error: $dbSaveError',
        ].join(' | ');

        await _apiClient.post(
          AppConstants.notificationsPath,
          <String, dynamic>{
            'title': log['title'],
            'message': log['message'],
            'type': 'Sms',
            'deliveryStatus': log['deliveryStatus'],
            if (combinedError.isNotEmpty) 'errorDetails': combinedError,
            if (log['recipientsSummary'] != null) 'recipientsSummary': log['recipientsSummary'],
          },
        );
        // Retry succeeded — entry (with full error details) will appear via API on next fetch.
      } catch (_) {
        stillFailed.add(log);
      }
    }

    // 3. Persist only the ones that still failed.
    await FailedNotificationLog.replaceAll(stillFailed);

    // 4. Merge API results with still-failing local entries and sort by date.
    final all = [
      ...apiNotifications,
      ...stillFailed.map(AppNotification.fromFailedLog),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _notifications = all;
        _isLoading = false;
      });
    }
  }

  List<_NotificationGroup> _groupedNotifications() {
    final DateFormat groupFormat = DateFormat('MMMM yyyy');
    final Map<String, List<AppNotification>> groups = {};

    for (final notification in _notifications) {
      final key = groupFormat.format(notification.date);
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(notification);
    }

    return groups.entries
        .map((entry) => _NotificationGroup(entry.key, entry.value))
        .toList();
  }

  Future<void> _createNotification() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateNotificationScreen()),
    );
    _fetchNotifications();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  void _viewNotificationDetail(AppNotification notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final groupedNotifications = _groupedNotifications();

    return WavyScaffold(
      theme: themeNotifier.currentTheme,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _MetricPill(
                    label: 'Total',
                    value: '${_notifications.length}',
                  ),
                  const SizedBox(width: 8),
                  _MetricPill(
                    label: 'Months',
                    value: '${groupedNotifications.length}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : groupedNotifications.isEmpty
                        ? const _EmptyNotificationsView()
                        : RefreshIndicator(
                            onRefresh: _fetchNotifications,
                            child: ListView.separated(
                              itemCount: groupedNotifications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final group = groupedNotifications[index];
                                return _MonthGroupCard(
                                  month: group.month,
                                  notifications: group.notifications,
                                  onTap: _viewNotificationDetail,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtons: [
        FloatingActionButton(
          heroTag: 'notification_add_message',
          onPressed: _createNotification,
          tooltip: 'Create notification',
          child: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _NotificationGroup {
  final String month;
  final List<AppNotification> notifications;

  _NotificationGroup(this.month, this.notifications);
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: cs.onSurface),
          children: [
            TextSpan(
              text: '$value ',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            TextSpan(text: label, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _MonthGroupCard extends StatelessWidget {
  final String month;
  final List<AppNotification> notifications;
  final ValueChanged<AppNotification> onTap;

  const _MonthGroupCard({
    required this.month,
    required this.notifications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationTile(
                notification: notification,
                onTap: () => onTap(notification),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy').format(notification.date);
    final timeText = DateFormat('hh:mm a').format(notification.date);

    final cs = Theme.of(context).colorScheme;
    final tileColor = notification.isLocalFailed
        ? Colors.orange.withValues(alpha: 0.12)
        : notification.deliveryStatus.toLowerCase() == 'pending'
            ? Colors.amber.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DeliveryStatusIcon(
                    status: notification.deliveryStatus,
                    isLocalFailed: notification.isLocalFailed,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.2, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dateText,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryStatusIcon extends StatelessWidget {
  final String status;
  final bool isLocalFailed;

  const _DeliveryStatusIcon({required this.status, this.isLocalFailed = false});

  @override
  Widget build(BuildContext context) {
    if (isLocalFailed) {
      return const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 18);
    }
    if (status.toLowerCase() == 'pending') {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
      );
    }
    final (icon, color) = switch (status.toLowerCase()) {
      'sent'      => (Icons.check_circle_rounded, Colors.green),
      'delivered' => (Icons.done_all_rounded, Colors.teal),
      'failed'    => (Icons.cancel_rounded, Colors.red),
      _           => (Icons.warning_amber_rounded, Colors.orange),
    };
    return Icon(icon, color: color, size: 18);
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tap + to create your first notification.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
