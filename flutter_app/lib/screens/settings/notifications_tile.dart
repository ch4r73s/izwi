import 'package:flutter/material.dart';

class NotificationsTile extends StatelessWidget {
  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  const NotificationsTile({
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.notifications),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Customize Notifications'),
          onTap: () {
            // Add navigation or functionality for customizing notifications
          },
        ),
        ListTile(
          leading: Icon(Icons.volume_up),
          title: Text('Notification Tones and Vibration'),
          onTap: () {
            // Add navigation or functionality for tones and vibration settings
          },
        ),
      ],
    );
  }
}
