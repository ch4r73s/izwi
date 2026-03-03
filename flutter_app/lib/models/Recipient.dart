class Recipient {
  final String id;
  final String name;
  final String phoneNumber;
  final String emailAddress;

  const Recipient({
    this.id = '',
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      emailAddress: json['email'] as String? ?? '',
    );
  }
}
