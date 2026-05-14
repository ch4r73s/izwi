import 'package:flutter/material.dart';
import 'common_sheet.dart';

void showTermsOfServiceBottomSheet(BuildContext context) {
  showCommonInfoBottomSheet(
    context: context,
    title: 'Terms of Service',
    content: const [
      Text(
        'By using this application, you agree to the service terms and conditions outlined by the platform.',
      ),
    ],
  );
}
