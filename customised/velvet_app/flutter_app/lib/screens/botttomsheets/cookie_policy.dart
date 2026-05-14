import 'package:flutter/material.dart';
import 'common_sheet.dart';

void showCookiePolicyBottomSheet(BuildContext context) {
  showCommonInfoBottomSheet(
    context: context,
    title: 'Cookie Policy',
    content: const [
      Text(
        'We use cookies to improve your app and website experience, remember preferences, and understand usage patterns.',
      ),
      SizedBox(height: 10),
      Text(
        'You can manage cookie behavior through your browser or device settings.',
      ),
    ],
  );
}
