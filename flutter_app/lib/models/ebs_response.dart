import 'package:xml/xml.dart';

class EbsResponse {
  final int status;
  final int? credits;
  final String? result;

  const EbsResponse({
    required this.status,
    this.credits,
    this.result,
  });

  bool get isSuccess => status == 1;

  factory EbsResponse.fromXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final response = document.findAllElements('RESPONSE').first;
    return EbsResponse(
      status: int.parse(response.findAllElements('status').first.innerText),
      credits: int.tryParse(
        response.findAllElements('credits').firstOrNull?.innerText ?? '',
      ),
      result: response.findAllElements('result').firstOrNull?.innerText,
    );
  }

  @override
  String toString() =>
      'EbsResponse(status: $status, credits: $credits, result: $result)';
}
