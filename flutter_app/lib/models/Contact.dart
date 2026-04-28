class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String emailAddress;
  final String? address;
  final String? ageRange;
  final String? sex;
  bool isPaused;

  Contact({
    this.id = '',
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
    this.address,
    this.ageRange,
    this.sex,
    this.isPaused = false,
  });

  Contact copyWith({
    String? name,
    String? phoneNumber,
    String? emailAddress,
    String? address,
    String? ageRange,
    String? sex,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      address: address ?? this.address,
      ageRange: ageRange ?? this.ageRange,
      sex: sex ?? this.sex,
      isPaused: isPaused,
    );
  }
}
