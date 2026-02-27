import 'package:flutter/material.dart';
import '../background/wavy_scaffold.dart';
import '../settings/account_management.dart';
import '../settings/language_and_region_tile.dart';
import '../settings/theme_and_appearance_tile.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isAccountManagementExpanded = false;

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WavyScaffold(
      theme: theme,
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
              ),
              child: Text(
                'Admin controls for account, language, and app theme.',
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
                  LanguageAndRegionTile(
                    selectedLanguage: 'English',
                    selectedRegion: 'Zimbabwe',
                  ),
                  const Divider(height: 10),
                  ThemeAndAppearanceTile(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.admin_panel_settings_rounded),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Changes are applied immediately for this session.',
                      style: TextStyle(fontSize: 13),
                    ),
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
