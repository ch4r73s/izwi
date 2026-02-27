import 'package:intl/intl.dart';

class AppNotification {
  String title;
  String message;
  DateTime date;

  AppNotification({
    required this.title,
    required this.message,
    required this.date,
  });

  // Factory method to create a AppNotification object from a map
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      title: map['title'] as String,
      message: map['message'] as String,
      date: DateFormat('yyyy-MM-dd hh:mm a').parse(map['date']!),
    );
  }

  // Method to convert AppNotification object to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(date),
    };
  }
}
