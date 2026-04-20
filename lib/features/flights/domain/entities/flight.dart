import 'airport.dart';

class Flight {
  final String id;
  final Airport origin;
  final Airport destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String aircraft;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final FlightStatus status;

  const Flight({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.aircraft,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    required this.status,
  });

  Duration get duration => arrivalTime.difference(departureTime);

  String get durationString {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  bool get isAlmostFull => availableSeats <= 5;
}

enum FlightStatus { onTime, delayed, boarding, departed, landed, cancelled }

extension FlightStatusLabel on FlightStatus {
  String get label {
    switch (this) {
      case FlightStatus.onTime: return 'On Time';
      case FlightStatus.delayed: return 'Delayed';
      case FlightStatus.boarding: return 'Boarding';
      case FlightStatus.departed: return 'Departed';
      case FlightStatus.landed: return 'Landed';
      case FlightStatus.cancelled: return 'Cancelled';
    }
  }
}
