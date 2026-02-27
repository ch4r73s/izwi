import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_bloc.dart';
import 'package:outgoing_notifications/bloc/auth/auth_event.dart';
import 'package:outgoing_notifications/main.dart';

class AccountManagementTile extends StatelessWidget {
  const AccountManagementTile({
    super.key,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  // void _logout(BuildContext context) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool(
  //       'isUserLoggedIn', false); // Set the login status to false
  //   await prefs.setString('userRole', userRole.toString());
  //   // Navigate back to the login screen
  //   Navigator.pushReplacementNamed(context, '/authentication');
  // }
  Future<void> _logout(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthLogoutRequested());

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoaderScreen()),
      (route) => false,
    );
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
          leading: Icon(Icons.person),
          title: Text('Edit Profile'),
          onTap: () {
            // Add navigation or functionality for editing profile
          },
        ),
        ListTile(
          leading: Icon(Icons.image),
          title: Text('Change Profile Picture'),
          onTap: () {
            // Add navigation or functionality for changing profile picture
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {
            // Add navigation or functionality for logging out
            _logout(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_forever),
          title: Text('Delete Account'),
          onTap: () {
            // Add navigation or functionality for deleting account
          },
        ),
        ListTile(
          leading: Icon(Icons.lock),
          title: Text('Change Password'),
          onTap: () {
            // Add navigation or functionality for changing password
          },
        ),
        ListTile(
          leading: Icon(Icons.link),
          title: Text('Link/Unlink Social Media'),
          onTap: () {
            // Add navigation or functionality for social media accounts
          },
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Two-Factor Authentication'),
          onTap: () {
            // Add navigation or functionality for two-factor authentication
          },
        ),
      ],
    );
  }
}
