import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendBulkWhatsAppMessages(
  List<String> phoneNumbers,
  String message,
) async {
  const String whatsappAccessToken =
      'EAANFwCX7VcwBO0TkR8Mv7VaGOnqM10UewPXcGiezfpsr9D2DoPUlONH8ZCm6oaE0of61vSlAz04636pUN2BYqlndA2Ws5shNzOZBohgiwhWrCxdYljKZCdysAzBfLZBhfC4dUHZBiDdPQZAEn5kAYKTenyapAhOC1uQ1PBpI7PpQHmtK3xojL2GZAvNKO6Gu4Gm1U6eBxinMY7XLKvuHT1Jy8BpzmAZD'; //'YOUR_FACEBOOK_ACCESS_TOKEN';
  const String phoneNumberId = '426397357229947'; //'YOUR_PHONE_NUMBER_ID'; // e.g., 1234567890

  final Uri apiUrl = Uri.parse(
    'https://graph.facebook.com/v21.0/$phoneNumberId/messages',
  );

  for (String phoneNumber in phoneNumbers) {
    final response = await http.post(
      apiUrl,
      headers: <String, String>{
        'Authorization': 'Bearer $whatsappAccessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': phoneNumber, // phone number in international format without +
        'type': 'text',
        'text': {'body': message},
      }),
    );

    if (response.statusCode == 200) {
      print('WhatsApp message sent to $phoneNumber: ${response.body}');
    } else {
      print(
        'Failed to send WhatsApp message to $phoneNumber: ${response.body}',
      );
    }
  }
}
