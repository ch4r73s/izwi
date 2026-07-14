import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/models/Contact.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
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
  static const int _pageSize = 10;

  final _apiClient = ApiClient(SecureStorageService());
  final List<Contact> _contacts = [];
  final Set<Contact> _selectedContacts = {};
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _selectAll = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  Timer? _debounce;

  List<String> _districts = [];
  final Set<String> _checkedDistricts = {};
  bool _isSelectingByDistrict = false;

  @override
  void initState() {
    super.initState();
    _loadContacts(reset: true);
    _fetchDistricts();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadContacts();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadContacts(reset: true);
    });
  }

  Future<void> _loadContacts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _contacts.clear();
        _selectedContacts.clear();
        _selectAll = false;
        _isLoading = true;
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    final search = _searchController.text.trim();
    final params = StringBuffer('page=$_currentPage&pageSize=$_pageSize');
    if (search.isNotEmpty) params.write('&search=${Uri.encodeComponent(search)}');

    try {
      final response = await _apiClient.get(
        '${AppConstants.recipientsPath}/my?$params',
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final loaded = list.map((e) {
          final m = e as Map<String, dynamic>;
          return Contact(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            phoneNumber: m['phoneNumber'] as String? ?? '',
            emailAddress: m['email'] as String? ?? '',
            address: m['address'] as String?,
            ageRange: m['ageRange'] as String?,
            sex: m['gender'] as String?,
            district: m['district'] as String?,
            isPaused: !(m['isActive'] as bool? ?? true),
          );
        }).toList();

        setState(() {
          _contacts.addAll(loaded);
          _hasMore = loaded.length == _pageSize;
          _currentPage++;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchDistricts() async {
    try {
      final response = await _apiClient.get(
        '${AppConstants.recipientsPath}/districts',
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        setState(() => _districts = list.whereType<String>().toList());
      }
    } catch (_) {
      // Non-critical — autocomplete/quick-select just falls back to empty.
    }
  }

  void _toggleDistrictChecked(String district) {
    setState(() {
      if (_checkedDistricts.contains(district)) {
        _checkedDistricts.remove(district);
      } else {
        _checkedDistricts.add(district);
      }
    });
  }

  /// Pages through every recipient in [district] via the server-side filter.
  Future<List<Contact>> _fetchContactsByDistrict(String district) async {
    var page = 1;
    const pageSize = 100;
    final matched = <Contact>[];

    while (true) {
      final response = await _apiClient.get(
        '${AppConstants.recipientsPath}/my?page=$page&pageSize=$pageSize'
        '&district=${Uri.encodeComponent(district)}',
      );
      if (response.statusCode != 200) break;

      final list = jsonDecode(response.body) as List<dynamic>;
      matched.addAll(
        list.map((e) {
          final m = e as Map<String, dynamic>;
          return Contact(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            phoneNumber: m['phoneNumber'] as String? ?? '',
            emailAddress: m['email'] as String? ?? '',
            address: m['address'] as String?,
            ageRange: m['ageRange'] as String?,
            sex: m['gender'] as String?,
            district: m['district'] as String?,
            isPaused: !(m['isActive'] as bool? ?? true),
          );
        }),
      );

      if (list.length < pageSize) break;
      page++;
    }

    return matched;
  }

  /// Fetches every recipient across all checked districts and adds them to
  /// the current selection without clearing it. Reuses existing `Contact`
  /// instances already in `_contacts` where possible (the Set relies on
  /// identity equality), and appends any not-yet-loaded ones to `_contacts`
  /// too so their checkboxes render as checked in the visible list.
  Future<void> _addCheckedDistricts() async {
    if (_checkedDistricts.isEmpty) return;

    setState(() => _isSelectingByDistrict = true);
    try {
      final results = await Future.wait(
        _checkedDistricts.map(_fetchContactsByDistrict),
      );
      final matched = results.expand((r) => r).toList();

      if (!mounted) return;
      setState(() {
        for (final contact in matched) {
          final existingIndex = _contacts.indexWhere((c) => c.id == contact.id);
          if (existingIndex == -1) {
            _contacts.add(contact);
            _selectedContacts.add(contact);
          } else {
            _selectedContacts.add(_contacts[existingIndex]);
          }
        }
        _checkedDistricts.clear();
      });
    } finally {
      if (mounted) setState(() => _isSelectingByDistrict = false);
    }
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

  Future<void> _toggleSelectAll() async {
    if (_selectAll) {
      setState(() {
        _selectedContacts.clear();
        _selectAll = false;
      });
      return;
    }

    // Wait for any in-progress load to settle before proceeding
    while ((_isLoading || _isLoadingMore) && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    // Load all remaining pages
    while (_hasMore && mounted) {
      await _loadContacts();
    }

    if (!mounted) return;
    setState(() {
      _selectedContacts
        ..clear()
        ..addAll(_contacts);
      _selectAll = true;
    });
  }

  void _confirmSelection() {
    final recipients = _selectedContacts
        .map(
          (contact) => Recipient(
            name: contact.name,
            phoneNumber: contact.phoneNumber,
            emailAddress: contact.emailAddress,
            sex: contact.sex,
            district: contact.district,
          ),
        )
        .toList();
    Navigator.pop(context, recipients);
  }

  void _handlePause(Contact contact) {
    setState(() {
      _contacts.remove(contact);
      _selectedContacts.remove(contact);
    });
  }

  void _addContact() {
    showAddContactDialog(context, (newContact) async {
      final response = await _apiClient.post(
        AppConstants.recipientsPath,
        {
          'name': newContact.name,
          'phoneNumber': newContact.phoneNumber,
          'email': newContact.emailAddress,
          if (newContact.address?.isNotEmpty == true) 'address': newContact.address,
          if (newContact.ageRange?.isNotEmpty == true) 'ageRange': newContact.ageRange,
          if (newContact.sex?.isNotEmpty == true) 'gender': newContact.sex,
          if (newContact.district?.isNotEmpty == true) 'district': newContact.district,
        },
      );

      if (response.statusCode == 200) {
        await _loadContacts(reset: true);
      } else if (response.statusCode == 409) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A recipient with this phone number already exists.'),
            ),
          );
        }
      }
    }, districtSuggestions: _districts);
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                  fillColor: Theme.of(context).colorScheme.surface,
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CheckboxListTile(
                    value: _selectAll,
                    onChanged: (_) => _toggleSelectAll(),
                    title: Text(
                      (_isLoading || _isLoadingMore) && !_selectAll
                          ? 'Loading contacts...'
                          : 'Select all contacts',
                    ),
                  ),
                ),
              ),
            if (widget.isSelectMode && _districts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select all in district(s)',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _districts
                            .map(
                              (d) => FilterChip(
                                label: Text(d),
                                selected: _checkedDistricts.contains(d),
                                onSelected: _isSelectingByDistrict
                                    ? null
                                    : (_) => _toggleDistrictChecked(d),
                              ),
                            )
                            .toList(),
                      ),
                      if (_checkedDistricts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: _isSelectingByDistrict
                                ? null
                                : _addCheckedDistricts,
                            child: Text(
                              _isSelectingByDistrict
                                  ? 'Adding…'
                                  : 'Add ${_checkedDistricts.length} district'
                                        '${_checkedDistricts.length == 1 ? '' : 's'}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _contacts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _contacts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final contact = _contacts[index];
                        return Card(
                          color: Theme.of(context).colorScheme.surface,
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
