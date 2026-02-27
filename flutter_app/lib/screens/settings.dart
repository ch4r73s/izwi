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
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5C3CB0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Text(
                'Control account security, notification behavior, privacy, and theme.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  AccountManagementTile(
                    initiallyExpanded: _isAccountManagementExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isAccountManagementExpanded = expanded;
                      });
                    },
                  ),
                  const Divider(height: 10),
                  NotificationsTile(
                    initiallyExpanded: _isNotificationsExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isNotificationsExpanded = expanded;
                      });
                    },
                  ),
                  const Divider(height: 10),
                  PrivacySettingsTile(
                    initiallyExpanded: _isPrivacySettingsExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isPrivacySettingsExpanded = expanded;
                      });
                    },
                  ),
                  const Divider(height: 10),
                  LanguageAndRegionTile(
                    selectedLanguage: 'English',
                    selectedRegion: 'Zimbabwe',
                  ),
                  const Divider(height: 10),
                  DataManagementTile(
                    initiallyExpanded: _isDataManagementExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isDataManagementExpanded = expanded;
                      });
                    },
                  ),
                  const Divider(height: 10),
                  HelpAndSupportTile(
                    initiallyExpanded: _isHelpAndSupportExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isHelpAndSupportExpanded = expanded;
                      });
                    },
                  ),
                  const Divider(height: 10),
                  ThemeAndAppearanceTile(),
                  const Divider(height: 10),
                  LegalTile(
                    initiallyExpanded: _isLegalExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isLegalExpanded = expanded;
                      });
                    },
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
