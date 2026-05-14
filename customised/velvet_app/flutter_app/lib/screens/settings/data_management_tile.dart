import 'package:flutter/material.dart';

class DataManagementTile extends StatelessWidget {
  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  const DataManagementTile({
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Data Management',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.storage),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        ListTile(
          leading: Icon(Icons.storage),
          title: Text('Manage Storage'),
          onTap: () {
            // Add navigation or functionality for managing storage
          },
        ),
        ListTile(
          leading: Icon(Icons.backup),
          title: Text('Backup and Restore'),
          onTap: () {
            // Add navigation or functionality for backup and restore
          },
        ),
      ],
    );
  }
}
