import 'package:flutter/material.dart';
import 'package:outgoing_notifications/config/routes.dart';
import 'package:outgoing_notifications/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'background/wavy_scaffold.dart';
import 'settings/account_management.dart';
import 'settings/data_management_tile.dart';
import 'settings/help_and_support_tile.dart';
import 'settings/language_and_region_tile.dart';
import 'settings/legal_tile.dart';
import 'settings/notifications_tile.dart';
import 'settings/privacy_settings_tile.dart';
import 'settings/theme_and_appearance_tile.dart';
import 'billing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAccountManagementExpanded = false;
  bool _isNotificationsExpanded = false;
  bool _isPrivacySettingsExpanded = false;
  bool _isDataManagementExpanded = false;
  bool _isHelpAndSupportExpanded = false;
  bool _isLegalExpanded = false;

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, Routes.userHome);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final cs = Theme.of(context).colorScheme;

    return WavyScaffold(
      theme: themeNotifier.currentTheme,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 10),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Control account security, notification behavior, privacy, and theme.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(color: cs.primary),
                listTileTheme: ListTileThemeData(iconColor: cs.primary),
                expansionTileTheme: ExpansionTileThemeData(
                  iconColor: cs.primary,
                  collapsedIconColor: cs.primary,
                  textColor: cs.primary,
                  collapsedTextColor: cs.onSurface,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    AccountManagementTile(
                      initiallyExpanded: _isAccountManagementExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _isAccountManagementExpanded = expanded),
                    ),
                    const Divider(height: 10),
                    NotificationsTile(
                      initiallyExpanded: _isNotificationsExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _isNotificationsExpanded = expanded),
                    ),
                    const Divider(height: 10),
                    PrivacySettingsTile(
                      initiallyExpanded: _isPrivacySettingsExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _isPrivacySettingsExpanded = expanded),
                    ),
                    const Divider(height: 10),
                    LanguageAndRegionTile(
                      selectedLanguage: 'English',
                      selectedRegion: 'Zimbabwe',
                    ),
                    const Divider(height: 10),
                    DataManagementTile(
                      initiallyExpanded: _isDataManagementExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _isDataManagementExpanded = expanded),
                    ),
                    const Divider(height: 10),
                    HelpAndSupportTile(
                      initiallyExpanded: _isHelpAndSupportExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _isHelpAndSupportExpanded = expanded),
                    ),
                    const Divider(height: 10),
                    ThemeAndAppearanceTile(),
                    const Divider(height: 10),
                    ListTile(
                      leading: const Icon(Icons.sim_card_outlined),
                      title: const Text(
                        'Subscription & Billing',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('View your plan, SMS balance, and payment history.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BillingScreen()),
                      ),
                    ),
                    const Divider(height: 10),
                    LegalTile(
                      initiallyExpanded: _isLegalExpanded,
                      onExpansionChanged: (expanded) =>
                          setState(() => _isLegalExpanded = expanded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
