import 'package:flutter/material.dart';
import 'common_sheet.dart';

void showPrivacyPolicyBottomSheet(BuildContext context) {
  showCommonInfoBottomSheet(
    context: context,
    title: 'Privacy Policy',
    content: const [
      Text(
        'Your privacy is important to us. This policy explains how we collect, use, and protect your personal information.',
      ),
    ],
  );
}
