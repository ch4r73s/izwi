import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_event.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/main.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';

class AccountManagementTile extends StatelessWidget {
  const AccountManagementTile({
    super.key,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  Future<void> _logout(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoaderScreen()),
      (route) => false,
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final apiClient = ApiClient(SecureStorageService());
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? loadError;

    // Pre-fill from API
    try {
      final response = await apiClient.get(AppConstants.profilePath);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        nameCtrl.text = (body['displayName'] as String?) ?? '';
        emailCtrl.text = (body['email'] as String?) ?? '';
      } else {
        loadError = 'Could not load profile.';
      }
    } catch (_) {
      loadError = 'Could not reach the server.';
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: loadError != null
            ? Text(loadError, style: const TextStyle(color: Colors.red))
            : Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Display name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (loadError == null)
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _submitEditProfile(
                  context,
                  displayName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  Future<void> _submitEditProfile(
    BuildContext context, {
    required String displayName,
    required String email,
  }) async {
    final apiClient = ApiClient(SecureStorageService());
    try {
      final response = await apiClient.put(
        AppConstants.profilePath,
        {'displayName': displayName, 'email': email},
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final msg = body?['message'] as String? ?? 'Failed to update profile.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      v != newCtrl.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _submitChangePassword(
                  context,
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _submitChangePassword(
    BuildContext context, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final apiClient = ApiClient(SecureStorageService());
    try {
      final response = await apiClient.post(
        AppConstants.changePasswordPath,
        {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current password is incorrect.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to change password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Account Management',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      leading: const Icon(Icons.account_circle),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Edit Profile'),
          onTap: () => _showEditProfileDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Change Password'),
          onTap: () => _showChangePasswordDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}
