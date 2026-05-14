import 'package:flutter/material.dart';
import 'package:outgoing_notifications/services/theme_notifier.dart';
import 'package:provider/provider.dart';

class ThemeAndAppearanceTile extends StatelessWidget {
  const ThemeAndAppearanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return ExpansionTile(
          title: const Text(
            'Theme and Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          leading: const Icon(Icons.palette),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App theme',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.defaultTheme,
                        label: Text('Default'),
                        icon: Icon(Icons.auto_awesome),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeNotifier.mode},
                    onSelectionChanged: (selection) =>
                        themeNotifier.setTheme(selection.first),
                    style: ButtonStyle(
                      iconColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? Theme.of(context).colorScheme.primary
                              : null),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
