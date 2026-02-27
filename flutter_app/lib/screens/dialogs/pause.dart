import 'package:flutter/material.dart';
import 'package:outgoing_notifications/models/Contact.dart';

class WavyPauseDialog extends StatelessWidget {
  final Contact contact;
  final Function(Contact) onPause;

  const WavyPauseDialog({
    super.key,
    required this.contact,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pause Contact'),
      content: const Text('Do you want to pause this contact?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onPause(contact);
            Navigator.of(context).pop(true);
          },
          child: const Text('Pause'),
        ),
      ],
    );
  }
}
