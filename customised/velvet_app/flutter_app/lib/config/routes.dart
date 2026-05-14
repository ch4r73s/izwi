// routes.dart
import 'package:flutter/material.dart';
import 'package:outgoing_notifications/models/Contact.dart';
import 'package:outgoing_notifications/models/Recipient.dart';
import 'package:outgoing_notifications/screens/admin/admin_dashboard.dart';
import 'package:outgoing_notifications/screens/admin/admin_settings.dart';
import 'package:outgoing_notifications/screens/authentication.dart';
import 'package:outgoing_notifications/screens/billing.dart';
import 'package:outgoing_notifications/screens/create_notification.dart';
import 'package:outgoing_notifications/screens/settings.dart';

// Define route names
class Routes {
  static const String adminHome = '/dashboard';
  static const String userHome = '/home';
  static const String guestHome = '/guestHome';
  static const String authentication = '/authentication';
  static const String billing = '/billing';
  static const String contact = '/contact';
  static const String contacts = '/contacts';
  static const String notification = '/notification';
  static const String createNotification = '/createNotification';
  static const String settings = '/settings';
  static const String adminSettings = '/adminSettings';
}

// Create a function to return routes
Map<String, WidgetBuilder> getRoutes(BuildContext context) {
  return {
    Routes.adminHome: (context) => const AdminDashboardScreen(),
    Routes.userHome: (context) => const AdminDashboardScreen(),
    Routes.guestHome: (context) => const AdminDashboardScreen(),
    Routes.authentication: (context) => AuthenticationScreen(),
    Routes.billing: (context) => BillingScreen(),
    Routes.contact:
        (context) =>
            throw UnimplementedError('ContactDetailsScreen needs parameters'),
    Routes.contacts:
        (context) =>
            throw UnimplementedError('RecipientsListScreen needs parameters'),
    Routes.notification:
        (context) =>
            throw UnimplementedError(
              'NotificationDetailScreen needs parameters',
            ),
    Routes.createNotification: (context) => CreateNotificationScreen(),
    Routes.settings: (context) => SettingsScreen(),
    Routes.adminSettings: (context) => AdminSettingsScreen(),
  };
}

// Function to navigate to the ContactDetailsScreen with parameters
void navigateToContactDetails(
  BuildContext context,
  Contact contact,
  bool onPause,
) {
  Navigator.pushNamed(
    context,
    Routes.contact,
    arguments: {'contact': contact, 'onPause': onPause},
  );
}

// Function to navigate to the NotificationDetailScreen with parameters
void navigateToNotificationDetail(
  BuildContext context,
  Map<String, String> notification,
  bool onPause,
) {
  Navigator.pushNamed(
    context,
    Routes.notification,
    arguments: {'notification': notification},
  );
}

// Function to navigate to RecipientsListScreen with parameters
void navigateToRecipientsList(
  BuildContext context,
  List<Recipient> selectedRecipients,
  bool isSelectMode,
) {
  Navigator.pushNamed(
    context,
    Routes.contacts,
    arguments: {
      'selectedRecipients': selectedRecipients,
      'isSelectMode': isSelectMode,
    },
  );
}
