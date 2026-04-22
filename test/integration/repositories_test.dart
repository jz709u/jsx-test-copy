/// Integration tests for the Supabase repository implementations.
///
/// Requires local Supabase to be running:
///   supabase start
///
/// Run with:
///   flutter test test/integration/repositories_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jsx_app_copy/features/flights/data/repositories/supabase_flight_repository.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/bookings/data/repositories/supabase_booking_repository.dart';
import 'package:jsx_app_copy/features/user/data/repositories/supabase_user_repository.dart';

// ── Local Supabase credentials (supabase start) ───────────────────────────────

const _localUrl            = 'http://127.0.0.1:54321';
const _localAnonKey        = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
const _localServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

late SupabaseClient _client;
late SupabaseClient _serviceClient; // bypasses RLS for cleanup

void main() {
  setUpAll(() {
    _client        = SupabaseClient(_localUrl, _localAnonKey);
    _serviceClient = SupabaseClient(_localUrl, _localServiceRoleKey);
  });

  tearDownAll(() async {
    await _client.dispose();
    await _serviceClient.dispose();
  });

  // ── SupabaseUserRepository ──────────────────────────────────────────────────

  group('SupabaseUserRepository', () {
    late SupabaseUserRepository repo;
    setUp(() => repo = SupabaseUserRepository(_client));

    test('getCurrentUser returns the dev user', () async {
      final user = await repo.getCurrentUser();
      expect(user.id, 'a0000000-0000-0000-0000-000000000001');
      expect(user.firstName, isNotEmpty);
      expect(user.lastName, isNotEmpty);
      expect(user.email, isNotEmpty);
    });

    test('getCurrentUser maps loyalty points and credit balance', () async {
      final user = await repo.getCurrentUser();
      expect(user.loyaltyPoints, isNonNegative);
      expect(user.creditBalance, isNonNegative);
    });

    test('getCurrentUser derives correct initials', () async {
      final user = await repo.getCurrentUser();
      expect(user.initials, '${user.firstName[0]}${user.lastName[0]}');
    });
  });

  // ── SupabaseFlightRepository ────────────────────────────────────────────────

  group('SupabaseFlightRepository', () {
    late SupabaseFlightRepository repo;
    setUp(() => repo = SupabaseFlightRepository(_client));

    group('getAirports', () {
      test('returns all seeded airports', () async {
        final airports = await repo.getAirports();
        expect(airports, isNotEmpty);
      });

      test('airports are returned in a consistent sort order', () async {
        final airports = await repo.getAirports();
        final codes = airports.map((a) => a.code).toList();
        final ascending  = codes.toList()..sort();
        final descending = ascending.reversed.toList();
        expect(codes, anyOf(equals(ascending), equals(descending)));
      });

      test('each airport has a non-empty code, city and name', () async {
        final airports = await repo.getAirports();
        for (final a in airports) {
          expect(a.code, isNotEmpty);
          expect(a.city, isNotEmpty);
          expect(a.name, isNotEmpty);
        }
      });

      test('includes DAL and BUR', () async {
        final codes = (await repo.getAirports()).map((a) => a.code).toSet();
        expect(codes, containsAll(['DAL', 'BUR']));
      });
    });

    group('searchFlights', () {
      const dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
      const bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

      test('returns flights without filters', () async {
        final flights = await repo.searchFlights();
        expect(flights, isNotEmpty);
      });

      test('filters by origin', () async {
        final flights = await repo.searchFlights(from: dal);
        expect(flights, isNotEmpty);
        expect(flights.every((f) => f.origin.code == 'DAL'), isTrue);
      });

      test('filters by destination', () async {
        final flights = await repo.searchFlights(to: bur);
        expect(flights, isNotEmpty);
        expect(flights.every((f) => f.destination.code == 'BUR'), isTrue);
      });

      test('filters by origin and destination', () async {
        final flights = await repo.searchFlights(from: dal, to: bur);
        expect(flights, isNotEmpty);
        expect(
          flights.every((f) => f.origin.code == 'DAL' && f.destination.code == 'BUR'),
          isTrue,
        );
      });

      test('departure times fall on the requested date', () async {
        final date = DateTime(2030, 6, 15);
        final flights = await repo.searchFlights(date: date);
        for (final f in flights) {
          expect(f.departureTime.year, 2030);
          expect(f.departureTime.month, 6);
          expect(f.departureTime.day, 15);
        }
      });

      test('each flight has departure before arrival', () async {
        final flights = await repo.searchFlights();
        for (final f in flights) {
          expect(
            f.departureTime.isBefore(f.arrivalTime),
            isTrue,
            reason: '${f.id} departure is not before arrival',
          );
        }
      });

      test('each flight has a positive price and seat counts', () async {
        final flights = await repo.searchFlights();
        for (final f in flights) {
          expect(f.price, greaterThan(0));
          expect(f.totalSeats, greaterThan(0));
        }
      });
    });
  });

  // ── SupabaseBookingRepository ───────────────────────────────────────────────

  group('SupabaseBookingRepository', () {
    late SupabaseBookingRepository repo;
    setUp(() => repo = SupabaseBookingRepository(_client));

    group('getBookings', () {
      test('returns existing bookings for the dev user', () async {
        final bookings = await repo.getBookings();
        expect(bookings, isNotEmpty);
      });

      test('all bookings belong to the dev user flight schedules', () async {
        final bookings = await repo.getBookings();
        for (final b in bookings) {
          expect(b.confirmationCode, isNotEmpty);
          expect(b.flight.id, isNotEmpty);
        }
      });

      test('each booking has at least one passenger', () async {
        final bookings = await repo.getBookings();
        for (final b in bookings) {
          expect(b.passengers, isNotEmpty);
        }
      });

      test('each booking has departure before arrival', () async {
        final bookings = await repo.getBookings();
        for (final b in bookings) {
          expect(
            b.flight.departureTime.isBefore(b.flight.arrivalTime),
            isTrue,
            reason: '${b.confirmationCode} departure is not before arrival',
          );
        }
      });

      test('each booking has a positive total paid', () async {
        final bookings = await repo.getBookings();
        for (final b in bookings) {
          expect(b.totalPaid, greaterThan(0));
        }
      });
    });

    group('createBooking', () {
      String? _createdCode;

      tearDown(() async {
        if (_createdCode == null) return;
        // Clean up via service role to bypass RLS
        await _serviceClient
            .from('bookings')
            .delete()
            .eq('confirmation_code', _createdCode!);
        _createdCode = null;
      });

      test('creates a booking and returns a JSX confirmation code', () async {
        final flights = await SupabaseFlightRepository(_client).searchFlights();
        final flight = flights.first;

        final code = await repo.createBooking(flight, 1);
        _createdCode = code;

        expect(code, startsWith('JSX'));
        expect(code.length, 7);
      });

      test('created booking appears in getBookings', () async {
        final flights = await SupabaseFlightRepository(_client).searchFlights();
        final flight = flights.first;

        final code = await repo.createBooking(flight, 1);
        _createdCode = code;

        final bookings = await repo.getBookings();
        expect(bookings.any((b) => b.confirmationCode == code), isTrue);
      });

      test('creates correct number of passengers', () async {
        final flights = await SupabaseFlightRepository(_client).searchFlights();
        final flight = flights.first;

        final code = await repo.createBooking(flight, 2);
        _createdCode = code;

        final bookings = await repo.getBookings();
        final created = bookings.firstWhere((b) => b.confirmationCode == code);
        expect(created.passengers, hasLength(2));
      });
    });
  });
}
