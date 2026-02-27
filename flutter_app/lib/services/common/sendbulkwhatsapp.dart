import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendBulkWhatsAppMessages(
    List<String> phoneNumbers, String message) async {
  const String accountSid =
      'YOUR_TWILIO_ACCOUNT_SID'; // Replace with your Twilio Account SID
  const String authToken =
      'YOUR_TWILIO_AUTH_TOKEN'; // Replace with your Twilio Auth Token
  const String fromWhatsAppNumber =
      'whatsapp:+YOUR_TWILIO_WHATSAPP_NUMBER'; // Replace with your Twilio WhatsApp number

  final String basicAuth =
      'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken'));

  for (String toPhoneNumber in phoneNumbers) {
    final response = await http.post(
      Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: <String, String>{
        'From': fromWhatsAppNumber,
        'To': 'whatsapp:$toPhoneNumber',
        'Body': message,
      },
    );

    if (response.statusCode == 201) {
      print(
          'WhatsApp message sent successfully to $toPhoneNumber: ${response.body}');
    } else {
      print(
          'Failed to send WhatsApp message to $toPhoneNumber: ${response.body}');
    }
  }
}



// void main() {
//   List<String> phoneNumbers = ['+1234567890', '+0987654321']; // Replace with actual phone numbers
//   String message = 'Hello from Flutter and Twilio via WhatsApp!';
  
//   sendBulkWhatsAppMessages(phoneNumbers, message);
// }
