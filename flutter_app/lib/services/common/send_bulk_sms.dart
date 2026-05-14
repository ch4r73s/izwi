import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/models/ebs_response.dart';

// Number of SMS requests sent concurrently per batch.
const _concurrency = 10;

class SmsSendResult {
  final int sentCount;
  final int failedCount;
  final List<String> failedMsisdns;
  final Map<String, String> failedReasons;

  const SmsSendResult({
    required this.sentCount,
    required this.failedCount,
    required this.failedMsisdns,
    this.failedReasons = const {},
  });
}

/// Sends personalised bulk SMS.
///
/// [messages] maps each phone number to its resolved message body.
Future<SmsSendResult> sendBulkSms({
  required String provider,
  required String smsEndpoint,
  required Map<String, String> messages,
  String smsUsername = '',
  String smsPassword = '',
  String apiKey = '',
  String senderId = '',
}) async {
  return switch (provider.toLowerCase()) {
    'tumirai' => _sendViaTumirai(
        endpoint: smsEndpoint,
        apiKey: apiKey,
        senderId: senderId,
        messages: messages,
      ),
    _ => _sendViaEbs(
        endpoint: smsEndpoint,
        smsUsername: smsUsername,
        smsPassword: smsPassword,
        messages: messages,
      ),
  };
}

Future<SmsSendResult> _sendViaEbs({
  required String endpoint,
  required String smsUsername,
  required String smsPassword,
  required Map<String, String> messages,
}) async {
  final failedMsisdns = <String>[];
  final failedReasons = <String, String>{};
  var sentCount = 0;

  final baseUri = Uri.parse(endpoint);
  final entries = messages.entries.toList();

  for (var i = 0; i < entries.length; i += _concurrency) {
    final batch = entries.sublist(i, (i + _concurrency).clamp(0, entries.length));
    final results = await Future.wait(batch.map((entry) async {
      final uri = baseUri.replace(queryParameters: {
        'user': smsUsername,
        'password': smsPassword,
        'msisdn': entry.key,
        'message': entry.value,
      });
      try {
        final response = await http.get(uri);
        final ebsResponse = EbsResponse.fromXml(response.body);
        return (msisdn: entry.key, success: ebsResponse.isSuccess, reason: ebsResponse.toString());
      } catch (e) {
        return (msisdn: entry.key, success: false, reason: e.toString());
      }
    }));

    for (final r in results) {
      if (r.success) {
        sentCount++;
      } else {
        failedMsisdns.add(r.msisdn);
        failedReasons[r.msisdn] = r.reason;
      }
    }
  }

  return SmsSendResult(
    sentCount: sentCount,
    failedCount: failedMsisdns.length,
    failedMsisdns: failedMsisdns,
    failedReasons: failedReasons,
  );
}

Future<SmsSendResult> _sendViaTumirai({
  required String endpoint,
  required String apiKey,
  required String senderId,
  required Map<String, String> messages,
}) async {
  final failedMsisdns = <String>[];
  final failedReasons = <String, String>{};
  var sentCount = 0;

  final entries = messages.entries.toList();

  for (var i = 0; i < entries.length; i += _concurrency) {
    final batch = entries.sublist(i, (i + _concurrency).clamp(0, entries.length));
    final results = await Future.wait(batch.map((entry) async {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'Idempotency-Key': '${entry.key.replaceAll('+', '')}-${DateTime.now().millisecondsSinceEpoch}',
          },
          body: jsonEncode({
            'to': entry.key,
            'sender_id': senderId,
            'text': entry.value,
          }),
        );
        final success = response.statusCode >= 200 && response.statusCode < 300;
        return (msisdn: entry.key, success: success, reason: success ? '' : response.body);
      } catch (e) {
        return (msisdn: entry.key, success: false, reason: e.toString());
      }
    }));

    for (final r in results) {
      if (r.success) {
        sentCount++;
      } else {
        failedMsisdns.add(r.msisdn);
        failedReasons[r.msisdn] = r.reason;
      }
    }
  }

  return SmsSendResult(
    sentCount: sentCount,
    failedCount: failedMsisdns.length,
    failedMsisdns: failedMsisdns,
    failedReasons: failedReasons,
  );
}
