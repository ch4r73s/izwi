import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailedNotificationLog {
  static const _key = 'failed_notification_logs';

  static Future<void> write({
    required String title,
    required String message,
    required String deliveryStatus,
    String? recipientsSummary,
    String? errorDetails,
    required Object error,
  }) async {
    debugPrint('[FailedNotification] DB save failed for "$title": $error');
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_key) ?? [];
      existing.add(jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'title': title,
        'message': message,
        'deliveryStatus': deliveryStatus,
        if (recipientsSummary != null) 'recipientsSummary': recipientsSummary,
        if (errorDetails != null && errorDetails.isNotEmpty) 'errorDetails': errorDetails,
        'error': error.toString(),
      }));
      await prefs.setStringList(_key, existing);
    } catch (logError) {
      debugPrint('[FailedNotification] Could not persist log entry: $logError');
    }
  }

  static Future<List<Map<String, dynamic>>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> replaceAll(List<Map<String, dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setStringList(_key, entries.map(jsonEncode).toList());
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
