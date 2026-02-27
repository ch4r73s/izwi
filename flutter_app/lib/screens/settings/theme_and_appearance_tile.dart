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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: const Icon(Icons.palette),
          initiallyExpanded: false,
          children: [
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Choose Theme'),
              onTap: () {
                themeNotifier.toggleTheme();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Light/Dark Mode'),
              trailing: Switch(
                value: themeNotifier.isDarkMode,
                onChanged: (value) {
                  themeNotifier.toggleTheme();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
