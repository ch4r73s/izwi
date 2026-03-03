import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/models/Contact.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'background/wavy_scaffold.dart';
import 'contact_details.dart';
import 'dialogs/add_contact.dart';

class RecipientsListScreen extends StatefulWidget {
  final List<Recipient> selectedRecipients;
  final bool isSelectMode;

  const RecipientsListScreen({
    super.key,
    required this.selectedRecipients,
    this.isSelectMode = false,
  });

  @override
  State<RecipientsListScreen> createState() => _RecipientsListScreenState();
}

class _RecipientsListScreenState extends State<RecipientsListScreen> {
  final _secureStorage = SecureStorageService();
  final List<Contact> _contacts = [];
  final Set<Contact> _selectedContacts = {};
  final _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final token = await _secureStorage.readAccessToken();
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse(
          '${AppConstants.apiBaseUrl}${AppConstants.recipientsPath}/my',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 || !mounted) return;

      final list = jsonDecode(response.body) as List<dynamic>;
      final loadedContacts =
          list.map((e) {
            final m = e as Map<String, dynamic>;
            return Contact(
              name: m['name'] as String? ?? '',
              phoneNumber: m['phoneNumber'] as String? ?? '',
              emailAddress: m['email'] as String? ?? '',
              isPaused: !(m['isActive'] as bool? ?? true),
            );
          }).toList();

      setState(() {
        _contacts
          ..clear()
          ..addAll(loadedContacts);
        _filteredContacts = List<Contact>.from(_contacts);
      });
    } catch (_) {}
  }

  void _filterContacts() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return !contact.isPaused &&
            (contact.name.toLowerCase().contains(q) ||
                contact.emailAddress.toLowerCase().contains(q) ||
                contact.phoneNumber.toLowerCase().contains(q));
      }).toList();
    });
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedContacts.clear();
      } else {
        _selectedContacts
          ..clear()
          ..addAll(_filteredContacts);
      }
      _selectAll = !_selectAll;
    });
  }

  void _confirmSelection() {
    final recipients = _selectedContacts
        .map(
          (contact) => Recipient(
            name: contact.name,
            phoneNumber: contact.phoneNumber,
            emailAddress: contact.emailAddress,
          ),
        )
        .toList();
    Navigator.pop(context, recipients);
  }

  void _handlePause(Contact contact) {
    setState(() {
      contact.isPaused = true;
    });
    _filterContacts();
  }

  void _addContact() {
    showAddContactDialog(context, (newContact) async {
      final token = await _secureStorage.readAccessToken();
      if (token == null || token.isEmpty) return;

      final response = await http.post(
        Uri.parse(
          '${AppConstants.apiBaseUrl}${AppConstants.recipientsPath}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': newContact.name,
          'phoneNumber': newContact.phoneNumber,
          'email': newContact.emailAddress,
        }),
      );

      if (response.statusCode == 200) {
        await _loadContacts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WavyScaffold(
      theme: Theme.of(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isSelectMode ? 'Select Recipients' : 'Recipients',
                      style: const TextStyle(
                        color: Color(0xFF5C3CB0),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!widget.isSelectMode)
                    IconButton.filledTonal(
                      onPressed: _addContact,
                      icon: const Icon(Icons.person_add_rounded),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search name, email, phone',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.95),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.isSelectMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CheckboxListTile(
                    value: _selectAll,
                    onChanged: (_) => _toggleSelectAll(),
                    title: const Text('Select all visible contacts'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return Card(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${contact.phoneNumber}\n${contact.emailAddress}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: widget.isSelectMode
                          ? Checkbox(
                              value: _selectedContacts.contains(contact),
                              onChanged: (_) => _toggleSelection(contact),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        if (!widget.isSelectMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactDetailsScreen(
                                contact: contact,
                                onPause: _handlePause,
                              ),
                            ),
                          );
                        } else {
                          _toggleSelection(contact);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            if (widget.isSelectMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Confirm (${_selectedContacts.length})'),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtons: [
        if (!widget.isSelectMode)
          FloatingActionButton(
            heroTag: 'add_contact',
            onPressed: _addContact,
            tooltip: 'Add contact',
            child: const Icon(Icons.add_rounded),
          ),
      ],
    );
  }
}
