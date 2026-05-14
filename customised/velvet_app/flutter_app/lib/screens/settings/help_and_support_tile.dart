import 'package:flutter/material.dart';
import 'package:outgoing_notifications/screens/botttomsheets/faq.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportTile extends StatelessWidget {
  final bool initiallyExpanded;
  final Function(bool) onExpansionChanged;

  const HelpAndSupportTile({
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  // Method to contact support via WhatsApp or SMS
  void _contactSupport() async {
    final whatsappUrl = 'whatsapp://send?phone=+263777435334';
    final smsUrl = 'sms:+263777435334';

    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else if (await canLaunch(smsUrl)) {
        await launch(smsUrl);
      } else {
        print('No suitable app found to handle the request');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Help and Support',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.help),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: [
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('FAQs and Help Articles'),
          onTap: () {
            showFaqBottomSheet(context); // Show the FAQ bottom sheet
          },
        ),
        ListTile(
          leading: const Icon(Icons.support),
          title: const Text('Contact Support'),
          onTap: _contactSupport, // Call _contactSupport on tap
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class HelpAndSupportTile extends StatelessWidget {
//   final bool initiallyExpanded;
//   final Function(bool) onExpansionChanged;

//   HelpAndSupportTile({
//     required this.initiallyExpanded,
//     required this.onExpansionChanged,
//   });

//   // Method to contact support via WhatsApp or SMS
//   void _contactSupport() async {
//     final whatsappUrl = 'whatsapp://send?phone=+263777435334';
//     final smsUrl = 'sms:+263777435334';

//     try {
//       if (await canLaunch(whatsappUrl)) {
//         await launch(whatsappUrl);
//       } else if (await canLaunch(smsUrl)) {
//         await launch(smsUrl);
//       } else {
//         print('No suitable app found to handle the request');
//       }
//     } catch (e) {
//       print('Error launching URL: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ExpansionTile(
//       title: Text(
//         'Help and Support',
//         style: TextStyle(
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       leading: Icon(Icons.help),
//       initiallyExpanded: initiallyExpanded,
//       onExpansionChanged: onExpansionChanged,
//       children: [
//         ListTile(
//           leading: Icon(Icons.help),
//           title: Text('FAQs and Help Articles'),
//           onTap: () {
//             // Add navigation or functionality for FAQs
//           },
//         ),
//         ListTile(
//           leading: Icon(Icons.support),
//           title: Text('Contact Support'),
//           onTap: _contactSupport, // Call _contactSupport on tap
//         ),
//       ],
//     );
//   }
// }
