import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_bloc.dart';
import 'package:outgoing_notifications/enums/user_role.dart';
import '../../config/routes.dart';
import '../background/wavy_scaffold.dart';
import 'clients.dart';
import '../notification.dart';
import '../recipients_list.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  void _openRecipients() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RecipientsListScreen(
              selectedRecipients: [],
              isSelectMode: false,
            ),
      ),
    );
  }

  void _openUsersManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientsScreen()),
    );
  }

  void _openSettings() {
    Navigator.pushNamed(context, Routes.adminSettings);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  void _openCreateNotification() {
    Navigator.pushNamed(context, Routes.createNotification);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRole = context.select<AuthBloc, UserRole?>(
      (bloc) => bloc.state.role,
    );
    final isAdmin = authRole == UserRole.admin;
    final manageTitle = isAdmin ? 'Add or Manage Clients' : 'Add Recipients';
    final manageSubtitle =
        isAdmin
            ? 'Create users who can log in to the app.'
            : 'Open recipient management and update your contact base.';
    final accessValue = switch (authRole) {
      UserRole.admin => 'Admin mode active',
      UserRole.user => 'User mode active',
      UserRole.guest => 'Guest mode active',
      null => 'Unauthenticated',
    };
    const dashboardTitle = 'Velvet';
    final dashboardSubtitle =
        isAdmin
            ? 'Create users, send notifications, and monitor delivery.'
            : 'Manage recipients, send notifications, and track delivery.';

    return WavyScaffold(
      theme: theme,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: const AssetImage('assets/app_icon.png'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dashboardTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Menu',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dashboardSubtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _StatsRow(),
            const SizedBox(height: 18),
            _ActionTile(
              icon: Icons.group_add_rounded,
              title: manageTitle,
              subtitle: manageSubtitle,
              onTap: isAdmin ? _openUsersManagement : _openRecipients,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.send_rounded,
              title: 'Create Notification',
              subtitle: 'Draft and schedule outbound notifications.',
              onTap: _openCreateNotification,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.notifications_active_rounded,
              title: 'View Notifications',
              subtitle: 'Review current and previous notification activity.',
              onTap: _openNotifications,
            ),
            const SizedBox(height: 22),
            Text(
              'Quick Notes',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              title: 'Access',
              value: accessValue,
              icon: Icons.verified_user_rounded,
            ),
          ],
        ),
      ),
      floatingActionButtons: [
        FloatingActionButton.extended(
          heroTag: 'add_client_cta',
          onPressed: isAdmin ? _openUsersManagement : _openRecipients,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(isAdmin ? 'Add Client' : 'Add Recipient'),
          tooltip: isAdmin ? 'Add client' : 'Add recipient',
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Active Lists',
            value: '1',
            icon: Icons.view_list_rounded,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Channels',
            value: 'SMS + WhatsApp',
            icon: Icons.multiple_stop_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
