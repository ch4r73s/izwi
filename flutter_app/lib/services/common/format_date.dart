import 'package:intl/intl.dart';

/// Formats a date string into a more readable format with an ordinal suffix.
///
/// The [dateString] should be in the format 'yyyy-MM-dd HH:mm a'.
/// This function returns a formatted string with the date in "Month daySuffix, year" format.
String formatDate(String dateString) {
  try {
    DateFormat format = DateFormat('yyyy-MM-dd HH:mm a');
    DateTime dateTime = format.parse(dateString);

    int day = dateTime.day;
    String suffix;

    // Determine the ordinal suffix
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }

    // Format the date
    return '${DateFormat('MMMM').format(dateTime)} ${day}$suffix, ${DateFormat('yyyy').format(dateTime)}';
  } catch (e) {
    // Handle any parsing or formatting errors
    return 'Invalid date format';
  }
}
