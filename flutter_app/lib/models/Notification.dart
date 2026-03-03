import 'dart:convert';
import 'package:intl/intl.dart';

class AppNotification {
  final String title;
  final String message;
  final DateTime date;
  final String deliveryStatus; // "Sent" | "Partial" | "Failed"
  final String? errorDetails;
  final String? recipientsSummary; // JSON: [{"name":...,"phone":...,"sent":bool}]

  AppNotification({
    required this.title,
    required this.message,
    required this.date,
    this.deliveryStatus = 'Sent',
    this.errorDetails,
    this.recipientsSummary,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      title: map['title'] as String,
      message: map['message'] as String,
      date: DateFormat('yyyy-MM-dd hh:mm a').parse(map['date']!),
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      deliveryStatus: json['deliveryStatus'] as String? ?? 'Sent',
      errorDetails: json['errorDetails'] as String?,
      recipientsSummary: json['recipientsSummary'] as String?,
    );
  }

  /// Parses recipientsSummary JSON into a list of recipient entries.
  /// Each entry: {'name': String, 'phone': String, 'sent': bool}
  List<Map<String, dynamic>> get allRecipients {
    if (recipientsSummary == null || recipientsSummary!.isEmpty) return [];
    try {
      final list = jsonDecode(recipientsSummary!) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Parses errorDetails (format: "phone: reason | phone: reason") into a map.
  Map<String, String> get failedRecipients {
    if (errorDetails == null || errorDetails!.isEmpty) return {};
    final result = <String, String>{};
    for (final entry in errorDetails!.split(' | ')) {
      final idx = entry.indexOf(': ');
      if (idx >= 0) {
        result[entry.substring(0, idx)] = entry.substring(idx + 2);
      }
    }
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'date': DateFormat('yyyy-MM-dd hh:mm a').format(date),
    };
  }
}
