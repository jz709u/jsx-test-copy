/// Requires local Supabase: supabase start
/// Run: flutter test test/integration/supabase_flight_repository_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jsx_app_copy/features/flights/data/repositories/supabase_flight_repository.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'local_supabase.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

void main() {
  late SupabaseClient client;
  late SupabaseFlightRepository repo;

  setUpAll(() => client = makeClient());
  tearDownAll(() => client.dispose());
  setUp(() => repo = SupabaseFlightRepository(client));

  group('SupabaseFlightRepository', () {
    group('getAirports', () {
      test('returns all seeded airports', () async {
        final airports = await repo.getAirports();
        expect(airports, isNotEmpty);
      });

      test('airports are returned in a consistent sort order', () async {
        final codes = (await repo.getAirports()).map((a) => a.code).toList();
        final ascending  = codes.toList()..sort();
        final descending = ascending.reversed.toList();
        expect(codes, anyOf(equals(ascending), equals(descending)));
      });

      test('each airport has non-empty code, city and name', () async {
        for (final a in await repo.getAirports()) {
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
      test('returns flights without filters', () async {
        expect(await repo.searchFlights(), isNotEmpty);
      });

      test('filters by origin', () async {
        final flights = await repo.searchFlights(from: _dal);
        expect(flights, isNotEmpty);
        expect(flights.every((f) => f.origin.code == 'DAL'), isTrue);
      });

      test('filters by destination', () async {
        final flights = await repo.searchFlights(to: _bur);
        expect(flights, isNotEmpty);
        expect(flights.every((f) => f.destination.code == 'BUR'), isTrue);
      });

      test('filters by origin and destination', () async {
        final flights = await repo.searchFlights(from: _dal, to: _bur);
        expect(flights, isNotEmpty);
        expect(
          flights.every((f) => f.origin.code == 'DAL' && f.destination.code == 'BUR'),
          isTrue,
        );
      });

      test('departure times fall on the requested date', () async {
        final date    = DateTime(2030, 6, 15);
        final flights = await repo.searchFlights(date: date);
        for (final f in flights) {
          expect(f.departureTime.year,  2030);
          expect(f.departureTime.month, 6);
          expect(f.departureTime.day,   15);
        }
      });

      test('each flight has departure before arrival', () async {
        for (final f in await repo.searchFlights()) {
          expect(
            f.departureTime.isBefore(f.arrivalTime),
            isTrue,
            reason: '${f.id} departure is not before arrival',
          );
        }
      });

      test('each flight has positive price and total seats', () async {
        for (final f in await repo.searchFlights()) {
          expect(f.price, greaterThan(0));
          expect(f.totalSeats, greaterThan(0));
        }
      });
    });
  });
}
