import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:outgoing_notifications/models/Contact.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
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
      final ByteData data = await rootBundle.load('assets/contacts.xlsx');
      final bytes = data.buffer.asUint8List();
      final excel = Excel.decodeBytes(bytes);

      final loadedContacts = <Contact>[];
      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        for (final row in sheet.rows) {
          final name = row.isNotEmpty ? row[0]?.value.toString() ?? '' : '';
          final phone = row.length > 1 ? row[1]?.value.toString() ?? '' : '';
          final email = row.length > 2 ? row[2]?.value.toString() ?? '' : '';

          if (name.isEmpty) continue;
          loadedContacts.add(
            Contact(
              name: name,
              phoneNumber: phone,
              emailAddress: email,
              isPaused: false,
            ),
          );
        }
      }

      if (!mounted) return;
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
    showAddContactDialog(context, (newContact) {
      setState(() {
        _contacts.add(newContact);
      });
      _filterContacts();
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
                        color: Colors.white,
                        fontSize: 24,
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
