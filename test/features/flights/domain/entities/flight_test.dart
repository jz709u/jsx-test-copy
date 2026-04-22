import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Airport');

Flight _flight({required DateTime departure, required DateTime arrival}) => Flight(
      id: 'JSX-1021',
      origin: _dal,
      destination: _bur,
      departureTime: departure,
      arrivalTime: arrival,
      aircraft: 'E135',
      totalSeats: 30,
      availableSeats: 10,
      price: 299,
      status: FlightStatus.onTime,
    );

void main() {
  final base = DateTime(2025, 6, 1, 8, 0);

  group('Flight.duration', () {
    test('returns difference between arrival and departure', () {
      final f = _flight(departure: base, arrival: base.add(const Duration(hours: 2, minutes: 15)));
      expect(f.duration, const Duration(hours: 2, minutes: 15));
    });
  });

  group('Flight.durationString', () {
    test('formats hours and minutes', () {
      final f = _flight(departure: base, arrival: base.add(const Duration(hours: 2, minutes: 30)));
      expect(f.durationString, '2h 30m');
    });

    test('omits hours when duration is less than one hour', () {
      final f = _flight(departure: base, arrival: base.add(const Duration(minutes: 45)));
      expect(f.durationString, '45m');
    });

    test('shows zero minutes when duration is exact hours', () {
      final f = _flight(departure: base, arrival: base.add(const Duration(hours: 3)));
      expect(f.durationString, '3h 0m');
    });
  });

  group('Flight.isAlmostFull', () {
    test('true when 5 or fewer seats remain', () {
      final f = Flight(
        id: 'x', origin: _dal, destination: _bur,
        departureTime: base, arrivalTime: base,
        aircraft: 'E135', totalSeats: 30, availableSeats: 5,
        price: 0, status: FlightStatus.onTime,
      );
      expect(f.isAlmostFull, isTrue);
    });

    test('false when more than 5 seats remain', () {
      final f = Flight(
        id: 'x', origin: _dal, destination: _bur,
        departureTime: base, arrivalTime: base,
        aircraft: 'E135', totalSeats: 30, availableSeats: 6,
        price: 0, status: FlightStatus.onTime,
      );
      expect(f.isAlmostFull, isFalse);
    });
  });
}
