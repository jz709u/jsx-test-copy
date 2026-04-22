import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/domain/entities/booking.dart';
import 'package:jsx_app_copy/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:jsx_app_copy/features/bookings/presentation/screens/trips_screen.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

final _now = DateTime.now();

Flight _flight({DateTime? departure, DateTime? arrival}) => Flight(
      id: 'JSX-1021',
      origin: _dal,
      destination: _bur,
      departureTime: departure ?? _now.add(const Duration(days: 3)),
      arrivalTime: arrival ?? _now.add(const Duration(days: 3, hours: 2)),
      aircraft: 'E135',
      totalSeats: 30,
      availableSeats: 10,
      price: 299,
      status: FlightStatus.onTime,
    );

Booking _booking({
  String code = 'JSX4K8P',
  DateTime? departure,
  BookingStatus status = BookingStatus.confirmed,
}) =>
    Booking(
      confirmationCode: code,
      flight: _flight(departure: departure),
      passengers: const [],
      totalPaid: 299,
      bookedAt: _now.subtract(const Duration(days: 7)),
      status: status,
    );

Widget _wrap({AsyncValue<List<Booking>> bookings = const AsyncValue.loading()}) => ProviderScope(
      overrides: [
        bookingsProvider.overrideWith((ref) async {
          if (bookings is AsyncLoading) return Completer<List<Booking>>().future;
          if (bookings is AsyncError) throw (bookings as AsyncError).error;
          return (bookings as AsyncData<List<Booking>>).value;
        }),
      ],
      child: const MaterialApp(home: TripsScreen()),
    );

void main() {
  group('TripsScreen', () {
    testWidgets('shows My Trips in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('My Trips'), findsOneWidget);
    });

    testWidgets('shows Upcoming and Past tabs', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
    });

    group('loading', () {
      testWidgets('shows spinner', (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error', () {
      testWidgets('shows error message', (tester) async {
        await tester.pumpWidget(_wrap(
          bookings: AsyncValue.error(Exception('fetch failed'), StackTrace.empty),
        ));
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('fetch failed'), findsOneWidget);
      });
    });

    group('with data', () {
      testWidgets('shows upcoming booking confirmation code', (tester) async {
        final upcoming = _booking(code: 'JSX4K8P');
        await tester.pumpWidget(_wrap(bookings: AsyncData([upcoming])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('JSX4K8P'), findsOneWidget);
      });

      testWidgets('upcoming booking appears in Upcoming tab', (tester) async {
        final upcoming = _booking(code: 'JSX4K8P');
        await tester.pumpWidget(_wrap(bookings: AsyncData([upcoming])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('JSX4K8P'), findsOneWidget);
      });

      testWidgets('shows empty state when no upcoming bookings', (tester) async {
        final past = _booking(
          code: 'JSX9ZZZ',
          departure: _now.subtract(const Duration(days: 10)),
          status: BookingStatus.completed,
        );
        await tester.pumpWidget(_wrap(bookings: AsyncData([past])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('No upcoming trips'), findsOneWidget);
      });

      testWidgets('past booking appears in Past tab', (tester) async {
        final past = _booking(
          code: 'JSX9ZZZ',
          departure: _now.subtract(const Duration(days: 10)),
          status: BookingStatus.completed,
        );
        await tester.pumpWidget(_wrap(bookings: AsyncData([past])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
        expect(find.text('JSX9ZZZ'), findsOneWidget);
      });
    });
  });
}
