import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight_track.dart';
import 'package:jsx_app_copy/features/flights/presentation/providers/flight_track_provider.dart';
import 'package:jsx_app_copy/features/flights/presentation/screens/flight_tracking_screen.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

Flight get _flight {
  final dep = DateTime.now().subtract(const Duration(hours: 1));
  return Flight(
    id: 'JSX-1021',
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

FlightTrack _track() => const FlightTrack(
      flightId: 'JSX-1021',
      progress: 0.5,
      altitudeFt: 37000,
      speedMph: 480,
      distanceRemainingMi: 600,
      minutesRemaining: 60,
      phase: FlightTrackPhase.cruising,
    );

enum _TrackMode { loading, data, error }

Widget _wrap(Flight flight, {_TrackMode mode = _TrackMode.data}) => ProviderScope(
      overrides: [
        flightTrackProvider(flight).overrideWith((_) {
          switch (mode) {
            case _TrackMode.loading:
              return StreamController<FlightTrack>().stream;
            case _TrackMode.error:
              return Stream.fromFuture(Future.error(Exception('no signal')));
            case _TrackMode.data:
              return Stream.fromIterable([_track()]);
          }
        }),
      ],
      child: MaterialApp(
        home: FlightTrackingScreen(flight: flight),
      ),
    );

void main() {
  group('FlightTrackingScreen', () {
    testWidgets('shows route in app bar', (tester) async {
      final f = _flight;
      await tester.pumpWidget(_wrap(f));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('DAL → BUR'), findsOneWidget);
    });

    testWidgets('shows Add to Lock Screen button initially', (tester) async {
      final f = _flight;
      await tester.pumpWidget(_wrap(f));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Add to Lock Screen'), findsOneWidget);
    });

    group('loading', () {
      testWidgets('shows spinner when no track data yet', (tester) async {
        final f = _flight;
        await tester.pumpWidget(_wrap(f, mode: _TrackMode.loading));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('with track data', () {
      testWidgets('shows phase label', (tester) async {
        final f = _flight;
        await tester.pumpWidget(_wrap(f));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('Cruising'), findsOneWidget);
      });

      testWidgets('shows altitude stat', (tester) async {
        final f = _flight;
        await tester.pumpWidget(_wrap(f));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('37k ft'), findsOneWidget);
      });

      testWidgets('shows speed stat', (tester) async {
        final f = _flight;
        await tester.pumpWidget(_wrap(f));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('480 mph'), findsOneWidget);
      });
    });
  });
}
