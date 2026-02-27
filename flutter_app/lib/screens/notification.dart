import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:outgoing_notifications/models/Notification.dart';
import 'package:outgoing_notifications/services/database/app_notification_dao.dart';
import 'package:outgoing_notifications/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'background/wavy_scaffold.dart';
import 'create_notification.dart';
import 'notification_detail.dart';
import 'recipients_list.dart';
import 'settings.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AppNotificationDao _notificationDao = AppNotificationDao();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final fetchedNotifications = await _notificationDao.queryAll();
    fetchedNotifications.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _notifications = fetchedNotifications;
      _isLoading = false;
    });
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

  Future<void> _createRecipient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipientsListScreen(
          selectedRecipients: [],
          isSelectMode: false,
        ),
      ),
    );
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
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
          heroTag: 'notification_add_person',
          onPressed: _createRecipient,
          tooltip: 'Add recipient',
          child: const Icon(Icons.person_add_alt_1_rounded),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
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

    return Material(
      color: const Color(0xFFF2F6FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dateText,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: Colors.black45)),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: Colors.black54,
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

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 40),
            SizedBox(height: 10),
            Text(
              'No notifications yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              'Tap + to create your first notification.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
