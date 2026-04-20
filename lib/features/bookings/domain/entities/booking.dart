import '../../../flights/domain/entities/flight.dart';
import 'passenger.dart';

class Booking {
  final String confirmationCode;
  final Flight flight;
  final List<Passenger> passengers;
  final double totalPaid;
  final DateTime bookedAt;
  final BookingStatus status;
  final int? seatNumber;

  const Booking({
    required this.confirmationCode,
    required this.flight,
    required this.passengers,
    required this.totalPaid,
    required this.bookedAt,
    required this.status,
    this.seatNumber,
  });

  bool get isUpcoming => flight.departureTime.isAfter(DateTime.now());
  bool get isPast => flight.departureTime.isBefore(DateTime.now());
}

enum BookingStatus { confirmed, checkedIn, cancelled, completed }
