import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/data/repositories/mock_booking_repository.dart';
import 'package:jsx_app_copy/features/bookings/domain/entities/booking.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

Flight _flight() => Flight(
      id: 'JSX-TEST',
      origin: _dal,
      destination: _bur,
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      arrivalTime: DateTime.now().add(const Duration(hours: 5)),
      aircraft: 'Embraer E135',
      totalSeats: 30,
      availableSeats: 10,
      price: 299,
      status: FlightStatus.onTime,
    );

void main() {
  late MockBookingRepository repo;

  setUp(() => repo = MockBookingRepository());

  group('MockBookingRepository.getBookings', () {
    test('returns 4 bookings', () async {
      final bookings = await repo.getBookings();
      expect(bookings, hasLength(4));
    });

    test('returns 2 upcoming and 2 past bookings', () async {
      final bookings = await repo.getBookings();
      final upcoming = bookings.where((b) => b.isUpcoming).toList();
      final past = bookings.where((b) => b.isPast).toList();
      expect(upcoming, hasLength(2));
      expect(past, hasLength(2));
    });

    test('upcoming bookings have confirmed status', () async {
      final bookings = await repo.getBookings();
      for (final b in bookings.where((b) => b.isUpcoming)) {
        expect(b.status, BookingStatus.confirmed);
      }
    });

    test('past bookings have completed status', () async {
      final bookings = await repo.getBookings();
      for (final b in bookings.where((b) => b.isPast)) {
        expect(b.status, BookingStatus.completed);
      }
    });

    test('all confirmation codes start with JSX', () async {
      final bookings = await repo.getBookings();
      expect(bookings.every((b) => b.confirmationCode.startsWith('JSX')), isTrue);
    });

    test('all bookings have at least one passenger', () async {
      final bookings = await repo.getBookings();
      expect(bookings.every((b) => b.passengers.isNotEmpty), isTrue);
    });

    test('each booking has a positive total paid', () async {
      final bookings = await repo.getBookings();
      expect(bookings.every((b) => b.totalPaid > 0), isTrue);
    });

    test('each booking flight has departure before arrival', () async {
      final bookings = await repo.getBookings();
      for (final b in bookings) {
        expect(
          b.flight.departureTime.isBefore(b.flight.arrivalTime),
          isTrue,
          reason: '${b.confirmationCode} departure is not before arrival',
        );
      }
    });
  });

  group('MockBookingRepository.createBooking', () {
    test('returns a confirmation code starting with JSX', () async {
      final code = await repo.createBooking(_flight(), 1);
      expect(code, startsWith('JSX'));
    });

    test('confirmation code has expected length (7 chars)', () async {
      final code = await repo.createBooking(_flight(), 1);
      expect(code.length, 7);
    });

    test('returns a non-empty string', () async {
      final code = await repo.createBooking(_flight(), 1);
      expect(code, isNotEmpty);
    });
  });
}
