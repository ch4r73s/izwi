import 'package:flutter/material.dart';

class PrivacySettingsTile extends StatelessWidget {
  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  const PrivacySettingsTile({
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Privacy Settings',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.privacy_tip),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        ListTile(
          leading: Icon(Icons.visibility),
          title: Text('Profile Visibility'),
          onTap: () {
            // Add navigation or functionality for profile visibility settings
          },
        ),
        ListTile(
          leading: Icon(Icons.data_usage),
          title: Text('Data Usage'),
          onTap: () {
            // Add navigation or functionality for data usage settings
          },
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Security Settings'),
          onTap: () {
            // Add navigation or functionality for security settings
          },
        ),
      ],
    );
  }
}
