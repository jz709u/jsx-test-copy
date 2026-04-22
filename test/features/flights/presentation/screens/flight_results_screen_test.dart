import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';
import 'package:jsx_app_copy/features/flights/presentation/providers/flight_results_provider.dart';
import 'package:jsx_app_copy/features/flights/presentation/screens/flight_results_screen.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

final _params = FlightSearchParams(
  fromCode: 'DAL',
  toCode: 'BUR',
  date: DateTime(2030, 6, 15),
);

Flight _flight({String id = 'JSX-1021'}) {
  final dep = DateTime(2030, 6, 15, 8);
  return Flight(
    id: id,
    origin: _dal,
    destination: _bur,
    departureTime: dep,
    arrivalTime: dep.add(const Duration(hours: 2)),
    aircraft: 'E135',
    totalSeats: 30,
    availableSeats: 10,
    price: 299,
    status: FlightStatus.onTime,
  );
}

Widget _wrap({required AsyncValue<List<Flight>> results}) => ProviderScope(
      overrides: [
        flightResultsProvider(_params).overrideWith((_) async {
          if (results is AsyncLoading) return Completer<List<Flight>>().future;
          if (results is AsyncError) throw (results as AsyncError).error;
          return (results as AsyncData<List<Flight>>).value;
        }),
      ],
      child: MaterialApp(
        home: FlightResultsScreen(params: _params, passengers: 1),
      ),
    );

void main() {
  group('FlightResultsScreen', () {
    testWidgets('shows route in app bar title', (tester) async {
      await tester.pumpWidget(_wrap(results: const AsyncValue.loading()));
      await tester.pump();
      expect(find.text('DAL → BUR'), findsOneWidget);
    });

    group('loading', () {
      testWidgets('shows spinner', (tester) async {
        await tester.pumpWidget(_wrap(results: const AsyncValue.loading()));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error', () {
      testWidgets('shows error message', (tester) async {
        await tester.pumpWidget(_wrap(
          results: AsyncValue.error(Exception('timeout'), StackTrace.empty),
        ));
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('timeout'), findsOneWidget);
      });
    });

    group('data', () {
      testWidgets('shows flight cards when results are non-empty', (tester) async {
        await tester.pumpWidget(_wrap(results: AsyncData([_flight()])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('JSX-1021'), findsOneWidget);
      });

      testWidgets('shows multiple flight cards', (tester) async {
        final flights = [_flight(id: 'JSX-1021'), _flight(id: 'JSX-1022')];
        await tester.pumpWidget(_wrap(results: AsyncData(flights)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('JSX-1021'), findsOneWidget);
        expect(find.text('JSX-1022'), findsOneWidget);
      });

      testWidgets('shows empty state when no flights match', (tester) async {
        await tester.pumpWidget(_wrap(results: const AsyncData([])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('JSX-1021'), findsNothing);
        expect(find.byType(ListView), findsNothing);
      });
    });
  });
}
