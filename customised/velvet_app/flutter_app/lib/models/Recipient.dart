class Recipient {
  final String id;
  final String name;
  final String phoneNumber;
  final String emailAddress;
  final String? sex;

  const Recipient({
    this.id = '',
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
    this.sex,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      emailAddress: json['email'] as String? ?? '',
      sex: json['gender'] as String?,
    );
  }
}
