import 'package:http/http.dart' as http;

class SmsSendResult {
  final int sentCount;
  final int failedCount;
  final List<String> failedMsisdns;

  const SmsSendResult({
    required this.sentCount,
    required this.failedCount,
    required this.failedMsisdns,
  });
}

Future<SmsSendResult> sendBulkSms({
  required String smsUsername,
  required String smsPassword,
  required List<String> msisdnList,
  required String message,
}) async {
  final failedMsisdns = <String>[];
  var sentCount = 0;

  for (final msisdn in msisdnList) {
    final uri = Uri.https(
      'bulksms.ebs-online.co.zw',
      '/vportal/cnm/vsms/plain',
      <String, String>{
        'user': smsUsername,
        'password': smsPassword,
        'msisdn': msisdn,
        'message': message,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        sentCount++;
      } else {
        failedMsisdns.add(msisdn);
      }
    } catch (_) {
      failedMsisdns.add(msisdn);
    }
  }

  return SmsSendResult(
    sentCount: sentCount,
    failedCount: failedMsisdns.length,
    failedMsisdns: failedMsisdns,
  );
}
