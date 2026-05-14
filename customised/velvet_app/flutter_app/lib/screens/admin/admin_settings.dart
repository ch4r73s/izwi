import 'package:flutter/material.dart';
import '../background/wavy_scaffold.dart';
import '../billing.dart';
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
    final cs = theme.colorScheme;

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
              'Admin controls for account, language, and app theme.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Theme(
              data: theme.copyWith(
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
                    LanguageAndRegionTile(
                      selectedLanguage: 'English',
                      selectedRegion: 'Zimbabwe',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Changes are applied immediately for this session.',
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
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
