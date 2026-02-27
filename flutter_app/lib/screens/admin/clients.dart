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
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _ssidnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsCostController = TextEditingController(text: '0.05');
  final _secureStorage = SecureStorageService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String _selectedRole = 'User';

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _ssidnController.dispose();
    _passwordController.dispose();
    _smsCostController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await _secureStorage.readAccessToken();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.addUserPath}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'ssidn': _ssidnController.text.trim(),
          'password': _passwordController.text,
          'smsCostPerMessage':
              double.tryParse(_smsCostController.text.trim()) ?? 0.05,
        }),
      );

      if (!mounted) return;

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      var message =
          isSuccess ? 'User added successfully' : 'Failed to add user';

      if (!isSuccess) {
        try {
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          final apiMessage = parsed['message'];
          if (apiMessage is String && apiMessage.isNotEmpty) {
            message = apiMessage;
          }
        } catch (_) {
          // keep default message
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      if (isSuccess) {
        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _ssidnController.clear();
        _passwordController.clear();
        _smsCostController.text = '0.05';
        setState(() => _selectedRole = 'User');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                const Expanded(
                  child: Text(
                    'Clients',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter a name'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter an email'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'User', child: Text('User')),
                        DropdownMenuItem(value: 'Guest', child: Text('Guest')),
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ssidnController,
                      decoration: const InputDecoration(labelText: 'SSIDN'),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter SSIDN'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Please enter password'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _smsCostController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cost per SMS',
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid SMS cost';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _addUser,
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Add User'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
