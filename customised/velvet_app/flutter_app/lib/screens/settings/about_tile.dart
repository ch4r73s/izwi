// lib/settings/about_tile.dart
import 'package:flutter/material.dart';

class AboutTile extends StatelessWidget {
  final String expandedTile;
  final Function(String) onExpansionChanged;
  final VoidCallback contactSupport;

  const AboutTile({
    super.key,
    required this.expandedTile,
    required this.onExpansionChanged,
    required this.contactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'About',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.info),
      initiallyExpanded: expandedTile == 'About',
      onExpansionChanged: (expanded) {
        onExpansionChanged(expanded ? 'About' : '');
      },
      children: [
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('App Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.contact_mail),
          title: const Text('Contact Support'),
          onTap: contactSupport,
        ),
      ],
    );
  }
}
