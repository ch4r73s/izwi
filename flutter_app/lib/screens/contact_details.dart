import 'package:flutter/material.dart';
import 'package:outgoing_notifications/models/Contact.dart';
import 'background/wavy_scaffold.dart';
import 'dialogs/pause.dart';

class ContactDetailsScreen extends StatelessWidget {
  final Contact contact;
  final Function(Contact) onPause;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
    required this.onPause,
  });

  Future<void> _pauseContact(BuildContext context) async {
    final confirmPause = await showDialog<bool>(
      context: context,
      builder: (context) => WavyPauseDialog(
        contact: contact,
        onPause: onPause,
      ),
    );

    if (confirmPause == true && context.mounted) {
      onPause(contact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WavyScaffold(
      theme: Theme.of(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _pauseContact(context),
                  icon: const Icon(Icons.pause_circle_outline_rounded),
                  tooltip: 'Pause',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.blueGrey.shade200,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Phone', value: contact.phoneNumber),
                  _DetailRow(label: 'Email', value: contact.emailAddress),
                  if ((contact.address ?? '').isNotEmpty)
                    _DetailRow(label: 'Address', value: contact.address!),
                  if ((contact.ageRange ?? '').isNotEmpty)
                    _DetailRow(label: 'Age Range', value: contact.ageRange!),
                  if ((contact.sex ?? '').isNotEmpty)
                    _DetailRow(label: 'Sex', value: contact.sex!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
