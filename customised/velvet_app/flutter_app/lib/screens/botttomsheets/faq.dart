import 'package:flutter/material.dart';
import 'common_sheet.dart';

void showFaqBottomSheet(BuildContext context) {
  showCommonInfoBottomSheet(
    context: context,
    title: 'FAQs and Help',
    content: const [
      _FaqItem(
        q: '1. How do I reset my password?',
        a: 'Use the login screen password reset flow and follow the email steps.',
      ),
      SizedBox(height: 12),
      _FaqItem(
        q: '2. How do I update profile information?',
        a: 'Open Settings, choose account/profile options, edit, then save.',
      ),
      SizedBox(height: 12),
      _FaqItem(
        q: '3. How do I contact support?',
        a: 'Use the Help and Support section and select contact support.',
      ),
    ],
  );
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;

  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(a),
      ],
    );
  }
}
