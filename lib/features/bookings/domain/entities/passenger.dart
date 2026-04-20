class Passenger {
  final String firstName;
  final String lastName;
  final String? knownTravelerNumber;

  const Passenger({
    required this.firstName,
    required this.lastName,
    this.knownTravelerNumber,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';
}
