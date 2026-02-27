class Contact {
  final String name;
  final String phoneNumber;
  final String emailAddress;
  final String? address; // Optional
  final String? ageRange; // Optional
  final String? sex; // Optional
  bool isPaused;

  Contact({
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
    this.address,
    this.ageRange,
    this.sex,
    this.isPaused = false,
  });
}
