import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';

import '../background/wavy_scaffold.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ssidnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsUsernameController = TextEditingController();
  final _smsPasswordController = TextEditingController();
  final _smsCostController = TextEditingController(text: '0.05');
  final _secureStorage = SecureStorageService();

  String _selectedRole = 'User';
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureSmsPassword = true;
  bool _showAddForm = false;

  List<Map<String, dynamic>> _clients = [];
  bool _isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ssidnController.dispose();
    _passwordController.dispose();
    _smsUsernameController.dispose();
    _smsPasswordController.dispose();
    _smsCostController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoadingClients = true);
    try {
      final token = await _secureStorage.readAccessToken();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.clientsPath}'),
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _clients = list.cast<Map<String, dynamic>>();
          _isLoadingClients = false;
        });
      } else {
        setState(() => _isLoadingClients = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }

  Future<void> _addUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await _secureStorage.readAccessToken();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.addUserPath}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'ssidn': _ssidnController.text.trim(),
          'password': _passwordController.text,
          'smsUsername': _smsUsernameController.text.trim(),
          'smsPassword': _smsPasswordController.text,
          'smsCostPerMessage':
              double.tryParse(_smsCostController.text.trim()) ?? 0.05,
        }),
      );

      if (!mounted) return;

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      var message = isSuccess ? 'Client added successfully' : 'Failed to add client';

      if (!isSuccess) {
        try {
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          final apiMessage = parsed['message'];
          if (apiMessage is String && apiMessage.isNotEmpty) {
            message = apiMessage;
          }
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (isSuccess) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _ssidnController.clear();
        _passwordController.clear();
        _smsUsernameController.clear();
        _smsPasswordController.clear();
        _smsCostController.text = '0.05';
        setState(() {
          _selectedRole = 'User';
          _showAddForm = false;
        });
        await _loadClients();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WavyScaffold(
      theme: theme,
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
                    'Clients',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () =>
                      setState(() => _showAddForm = !_showAddForm),
                  icon: Icon(
                    _showAddForm ? Icons.close_rounded : Icons.person_add_rounded,
                  ),
                  tooltip: _showAddForm ? 'Cancel' : 'Add client',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Add client form (collapsible) ──────────────────────────
            if (_showAddForm) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'User', child: Text('User')),
                          DropdownMenuItem(
                              value: 'Guest', child: Text('Guest')),
                          DropdownMenuItem(
                              value: 'Admin', child: Text('Admin')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ssidnController,
                        decoration: const InputDecoration(labelText: 'SSIDN'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      Text(
                        'SMS Gateway',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _smsUsernameController,
                        decoration:
                            const InputDecoration(labelText: 'SMS Username'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _smsPasswordController,
                        obscureText: _obscureSmsPassword,
                        decoration: InputDecoration(
                          labelText: 'SMS Password',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() =>
                                _obscureSmsPassword = !_obscureSmsPassword),
                            icon: Icon(
                              _obscureSmsPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _smsCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Cost per SMS'),
                        validator: (v) {
                          final p = double.tryParse((v ?? '').trim());
                          if (p == null || p <= 0) return 'Enter a valid cost';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _addUser,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Add Client'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── Client list ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'All Clients',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _loadClients,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingClients)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_clients.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'No clients yet. Tap + to add one.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...(_clients.map((c) => _ClientCard(client: c))),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final user = client['user'] as Map<String, dynamic>?;
    final role = user?['role'] as String? ?? '—';
    final email = user?['email'] as String? ?? '—';
    final isActive = user?['isActive'] as bool? ?? false;
    final cost = (client['smsCostPerMessage'] as num?)?.toStringAsFixed(4) ?? '—';

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: Icon(
              Icons.business_rounded,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        client['name'] as String? ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _RoleChip(role: role),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  'SSIDN: ${client['ssidn'] ?? '—'}  ·  \$$cost/SMS',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: isActive ? Colors.green : Colors.red,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (role.toLowerCase()) {
      'admin' => Colors.deepPurple,
      'user' => Colors.blue,
      _ => cs.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
