import 'package:flutter/material.dart';
import '../botttomsheets/cookie_policy.dart';
import '../botttomsheets/privacy_policy.dart';
import '../botttomsheets/terms_of_service.dart';

class LegalTile extends StatelessWidget {
  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  const LegalTile({
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Legal',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.gavel),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Terms of Service'),
          onTap: () {
            showTermsOfServiceBottomSheet(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Privacy Policy'),
          onTap: () {
            showPrivacyPolicyBottomSheet(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Cookie Policy'),
          onTap: () {
            showCookiePolicyBottomSheet(context);
          },
        ),
      ],
    );
  }
}
