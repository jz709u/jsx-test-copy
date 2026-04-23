/// Requires local Supabase: supabase start
/// Run: flutter test test/integration/supabase_booking_repository_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jsx_app_copy/features/bookings/data/repositories/supabase_booking_repository.dart';
import 'package:jsx_app_copy/features/flights/data/repositories/supabase_flight_repository.dart';
import 'local_supabase.dart';

void main() {
  late SupabaseClient client;
  late SupabaseClient serviceClient;
  late SupabaseBookingRepository repo;

  setUpAll(() {
    client        = makeClient();
    serviceClient = makeServiceClient();
  });
  tearDownAll(() async {
    await client.dispose();
    await serviceClient.dispose();
  });
  setUp(() => repo = SupabaseBookingRepository(client));

  group('SupabaseBookingRepository', () {
    group('getBookings', () {
      test('returns existing bookings for the dev user', () async {
        expect(await repo.getBookings(), isNotEmpty);
      });

      test('each booking has a confirmation code and flight id', () async {
        for (final b in await repo.getBookings()) {
          expect(b.confirmationCode, isNotEmpty);
          expect(b.flight.id, isNotEmpty);
        }
      });

      test('each booking has at least one passenger', () async {
        for (final b in await repo.getBookings()) {
          expect(b.passengers, isNotEmpty);
        }
      });

      test('each booking flight has departure before arrival', () async {
        for (final b in await repo.getBookings()) {
          expect(
            b.flight.departureTime.isBefore(b.flight.arrivalTime),
            isTrue,
            reason: '${b.confirmationCode} departure is not before arrival',
          );
        }
      });

      test('each booking has a positive total paid', () async {
        for (final b in await repo.getBookings()) {
          expect(b.totalPaid, greaterThan(0));
        }
      });
    });

    group('createBooking', () {
      String? createdCode;

      tearDown(() async {
        if (createdCode == null) return;
        await serviceClient
            .from('bookings')
            .delete()
            .eq('confirmation_code', createdCode!);
        createdCode = null;
      });

      test('returns a 7-character JSX confirmation code', () async {
        final flight = (await SupabaseFlightRepository(client).searchFlights()).first;
        createdCode = await repo.createBooking(flight, 1);
        expect(createdCode, startsWith('JSX'));
        expect(createdCode!.length, 7);
      });

      test('created booking appears in getBookings', () async {
        final flight = (await SupabaseFlightRepository(client).searchFlights()).first;
        createdCode = await repo.createBooking(flight, 1);
        final bookings = await repo.getBookings();
        expect(bookings.any((b) => b.confirmationCode == createdCode), isTrue);
      });

      test('creates the correct number of passengers', () async {
        final flight = (await SupabaseFlightRepository(client).searchFlights()).first;
        createdCode = await repo.createBooking(flight, 2);
        final bookings = await repo.getBookings();
        final created = bookings.firstWhere((b) => b.confirmationCode == createdCode);
        expect(created.passengers, hasLength(2));
      });
    });
  });
}
