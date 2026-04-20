class Airport {
  final String code;
  final String city;
  final String name;

  const Airport({required this.code, required this.city, required this.name});

  @override
  bool operator ==(Object other) => other is Airport && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
