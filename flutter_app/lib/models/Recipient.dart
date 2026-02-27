// // class Recipient {
// //   final String name;
// //   final String contact;

// //   Recipient({required this.name, required this.contact});

// //   @override
// //   bool operator ==(Object other) =>
// //       identical(this, other) ||
// //       other is Recipient &&
// //           runtimeType == other.runtimeType &&
// //           name == other.name &&
// //           contact == other.contact;

// //   @override
// //   int get hashCode => name.hashCode ^ contact.hashCode;
// // }
class Recipient {
  final String name;
  final String phoneNumber;
  final String emailAddress;

  Recipient(
      {required this.name,
      required this.phoneNumber,
      required this.emailAddress});
}

// // class Contact {
// //   final String name;
// //   final String phoneNumber;
// //   final String emailAddress;
// //   final String? address; // Optional
// //   final String? ageRange; // Optional
// //   final String? sex; // Optional

// //   Contact({
// //     required this.name,
// //     required this.phoneNumber,
// //     required this.emailAddress,
// //     this.address,
// //     this.ageRange,
// //     this.sex,
// //   });
// // }
