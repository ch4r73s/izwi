import 'package:http/http.dart' as http;
import 'package:outgoing_notifications/models/ebs_response.dart';

class SmsSendResult {
  final int sentCount;
  final int failedCount;
  final List<String> failedMsisdns;
  /// Raw EBS response bodies for failed numbers, keyed by msisdn.
  final Map<String, String> failedReasons;

  const SmsSendResult({
    required this.sentCount,
    required this.failedCount,
    required this.failedMsisdns,
    this.failedReasons = const {},
  });
}

Future<SmsSendResult> sendBulkSms({
  required String smsUsername,
  required String smsPassword,
  required List<String> msisdnList,
  required String message,
}) async {
  final failedMsisdns = <String>[];
  final failedReasons = <String, String>{};
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
      final ebsResponse = EbsResponse.fromXml(response.body);
      if (ebsResponse.isSuccess) {
        sentCount++;
      } else {
        failedMsisdns.add(msisdn);
        failedReasons[msisdn] = ebsResponse.toString();
      }
    } catch (e) {
      failedMsisdns.add(msisdn);
      failedReasons[msisdn] = e.toString();
    }
  }

  return SmsSendResult(
    sentCount: sentCount,
    failedCount: failedMsisdns.length,
    failedMsisdns: failedMsisdns,
    failedReasons: failedReasons,
  );
}
