import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/models/Contact.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'background/wavy_scaffold.dart';
import 'dialogs/edit_contact.dart';
import 'dialogs/pause.dart';

class ContactDetailsScreen extends StatefulWidget {
  final Contact contact;
  final Function(Contact) onPause;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
    required this.onPause,
  });

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _apiClient = ApiClient(SecureStorageService());
  late Contact _contact;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future<void> _pauseContact() async {
    final confirmPause = await showDialog<bool>(
      context: context,
      builder: (context) => WavyPauseDialog(
        contact: _contact,
        onPause: widget.onPause,
      ),
    );

    if (confirmPause == true && mounted) {
      widget.onPause(_contact);
      Navigator.pop(context);
    }
  }

  Future<List<String>> _fetchDistrictSuggestions() async {
    try {
      final response = await _apiClient.get(
        '${AppConstants.recipientsPath}/districts',
      );
      if (response.statusCode != 200) return const [];
      final list = jsonDecode(response.body) as List;
      return list.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _editContact() async {
    final districtSuggestions = await _fetchDistrictSuggestions();
    if (!mounted) return;
    final updated = await showEditContactDialog(
      context,
      _contact,
      districtSuggestions: districtSuggestions,
    );
    if (updated == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final response = await _apiClient.put(
        '${AppConstants.recipientsPath}/${_contact.id}',
        {
          'name': updated.name,
          'phoneNumber': updated.phoneNumber,
          'email': updated.emailAddress,
          if (updated.address?.isNotEmpty == true) 'address': updated.address,
          if (updated.ageRange?.isNotEmpty == true) 'ageRange': updated.ageRange,
          if (updated.sex?.isNotEmpty == true) 'gender': updated.sex,
          if (updated.district?.isNotEmpty == true) 'district': updated.district,
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _contact = _contact.copyWith(
            name: data['name'] as String? ?? updated.name,
            phoneNumber: data['phoneNumber'] as String? ?? updated.phoneNumber,
            emailAddress: data['email'] as String? ?? updated.emailAddress,
            address: data['address'] as String?,
            ageRange: data['ageRange'] as String?,
            sex: data['gender'] as String?,
            district: data['district'] as String?,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update contact')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update contact')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                    _contact.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _isSaving ? null : _editContact,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _pauseContact,
                  icon: const Icon(Icons.pause_circle_outline_rounded),
                  tooltip: 'Pause',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Phone', value: _contact.phoneNumber),
                  _DetailRow(label: 'Email', value: _contact.emailAddress),
                  _DetailRow(label: 'Address', value: _contact.address?.isNotEmpty == true ? _contact.address! : '—'),
                  _DetailRow(label: 'Age Range', value: _contact.ageRange?.isNotEmpty == true ? _contact.ageRange! : '—'),
                  _DetailRow(label: 'Gender', value: _contact.sex?.isNotEmpty == true ? _contact.sex! : '—'),
                  _DetailRow(label: 'District', value: _contact.district?.isNotEmpty == true ? _contact.district! : '—'),
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
