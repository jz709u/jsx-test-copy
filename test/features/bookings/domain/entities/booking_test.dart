import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/domain/entities/booking.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Airport');

Booking _booking(DateTime departure) => Booking(
      confirmationCode: 'JSX4K8P',
      flight: Flight(
        id: 'JSX-1021',
        origin: _dal,
        destination: _bur,
        departureTime: departure,
        arrivalTime: departure.add(const Duration(hours: 2)),
        aircraft: 'E135',
        totalSeats: 30,
        availableSeats: 10,
        price: 299,
        status: FlightStatus.onTime,
      ),
      passengers: const [],
      totalPaid: 299,
      bookedAt: DateTime(2025, 1, 1),
      status: BookingStatus.confirmed,
    );

void main() {
  final now = DateTime.now();

  group('Booking.isUpcoming', () {
    test('true when departure is in the future', () {
      expect(_booking(now.add(const Duration(hours: 1))).isUpcoming, isTrue);
    });

    test('false when departure is in the past', () {
      expect(_booking(now.subtract(const Duration(hours: 1))).isUpcoming, isFalse);
    });
  });

  group('Booking.isPast', () {
    test('true when departure is in the past', () {
      expect(_booking(now.subtract(const Duration(hours: 1))).isPast, isTrue);
    });

    test('false when departure is in the future', () {
      expect(_booking(now.add(const Duration(hours: 1))).isPast, isFalse);
    });
  });
}
