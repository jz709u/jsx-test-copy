class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int loyaltyPoints;
  final double creditBalance;
  final String memberSince;
  final String? knownTravelerNumber;
  final String preferredSeat;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.loyaltyPoints,
    required this.creditBalance,
    required this.memberSince,
    this.knownTravelerNumber,
    required this.preferredSeat,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';
}
