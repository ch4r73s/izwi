import 'package:outgoing_notifications/models/Recipient.dart';

/// Resolves template variables in a message for a specific recipient.
///
/// Supported variables:
///   {name} or [name] — expands to the recipient's name, prefixed with a
///             gender salutation when gender is known:
///             • male   → "madzibaba <name>"
///             • female → "madzimai <name>"
///             • unknown → "<name>"
String resolveTemplate(String template, Recipient recipient) {
  return template.replaceAllMapped(
    RegExp(r'\{name\}|\[name\]', caseSensitive: false),
    (_) => _resolvedName(recipient),
  );
}

String _resolvedName(Recipient recipient) {
  final gender = (recipient.sex ?? '').trim().toLowerCase();
  if (gender.startsWith('m')) return 'madzibaba ${recipient.name}';
  if (gender.startsWith('f')) return 'madzimai ${recipient.name}';
  return recipient.name;
}
