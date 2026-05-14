import 'package:intl/intl.dart';

String formatTime(String dateString) {
  try {
    // Create the DateFormat object with the input format
    DateFormat inputFormat = DateFormat('yyyy-MM-dd hh:mm a');
    DateTime dateTime = inputFormat.parse(dateString);

    // Create a new DateFormat for 24-hour time notation
    DateFormat outputFormat = DateFormat('HH:mm');
    return outputFormat.format(dateTime);
  } catch (e) {
    // Handle any parsing or formatting errors
    return 'Invalid date format';
  }
}
