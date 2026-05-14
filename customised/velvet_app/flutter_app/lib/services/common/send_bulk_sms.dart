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
  // phone → gateway message ID (populated by providers that return one, e.g. Tumirai)
  final Map<String, String> gatewayMessageIds;
  // phone → raw JSON payload from the gateway send response
  final Map<String, String> gatewayPayloads;

  const SmsSendResult({
    required this.sentCount,
    required this.failedCount,
    required this.failedMsisdns,
    this.failedReasons = const {},
    this.gatewayMessageIds = const {},
    this.gatewayPayloads = const {},
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

  final gatewayMessageIds = <String, String>{};
  final gatewayPayloads   = <String, String>{};
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
        String? gatewayId;
        String? gatewayPayload;
        if (success) {
          try {
            final decoded = jsonDecode(response.body);
            // ignore: avoid_print
            print('[Tumirai] ${entry.key} → status=${response.statusCode} body=$decoded');
            if (decoded is Map<String, dynamic>) {
              final data = decoded['data'];
              if (data is Map<String, dynamic>) {
                gatewayId = data['id'] as String?;
                gatewayPayload = jsonEncode(data);
              } else {
                gatewayId = (decoded['id'] ?? decoded['message_id'] ?? decoded['messageId']) as String?;
              }
            }
          } catch (e) {
            // ignore: avoid_print
            print('[Tumirai] parse error for ${entry.key}: $e  raw=${response.body}');
          }
        } else {
          // ignore: avoid_print
          print('[Tumirai] ${entry.key} → FAILED status=${response.statusCode} body=${response.body}');
        }
        return (msisdn: entry.key, success: success, reason: success ? '' : response.body, gatewayId: gatewayId, gatewayPayload: gatewayPayload);
      } catch (e) {
        return (msisdn: entry.key, success: false, reason: e.toString(), gatewayId: null, gatewayPayload: null);
      }
    }));

    for (final r in results) {
      if (r.success) {
        sentCount++;
        if (r.gatewayId != null) gatewayMessageIds[r.msisdn] = r.gatewayId!;
        if (r.gatewayPayload != null) gatewayPayloads[r.msisdn] = r.gatewayPayload!;
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
    gatewayMessageIds: gatewayMessageIds,
    gatewayPayloads: gatewayPayloads,
  );
}
