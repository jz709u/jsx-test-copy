import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/domain/entities/booking.dart';
import 'package:jsx_app_copy/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';
import 'package:jsx_app_copy/features/home/presentation/screens/home_screen.dart';
import 'package:jsx_app_copy/features/user/domain/entities/user.dart';
import 'package:jsx_app_copy/features/user/presentation/providers/user_provider.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Airport');

final _now = DateTime.now();

Flight _flight({DateTime? departure, DateTime? arrival}) => Flight(
      id: 'JSX-1021',
      origin: _dal,
      destination: _bur,
      departureTime: departure ?? _now.add(const Duration(hours: 3)),
      arrivalTime: arrival ?? _now.add(const Duration(hours: 5)),
      aircraft: 'E135',
      totalSeats: 30,
      availableSeats: 10,
      price: 299,
      status: FlightStatus.onTime,
    );

Booking _booking({int? seatNumber, DateTime? departure}) => Booking(
      confirmationCode: 'JSX4K8P',
      flight: _flight(departure: departure),
      passengers: const [],
      totalPaid: 299,
      bookedAt: _now.subtract(const Duration(days: 7)),
      status: BookingStatus.confirmed,
      seatNumber: seatNumber,
    );

const _user = User(
  id: 'u1',
  firstName: 'Alex',
  lastName: 'Smith',
  email: 'alex@jsx.com',
  phone: '5551234567',
  loyaltyPoints: 1350,
  creditBalance: 75,
  memberSince: '2023',
  preferredSeat: 'window',
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap({
  required Widget child,
  List<Override> overrides = const [],
}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );

List<Override> _overrides({
  AsyncValue<User> user = const AsyncValue.loading(),
  AsyncValue<List<Booking>> bookings = const AsyncValue.loading(),
}) =>
    [
      currentUserProvider.overrideWith((ref) async {
        if (user is AsyncLoading) return Completer<User>().future;
        if (user is AsyncError) throw (user as AsyncError).error;
        return (user as AsyncData<User>).value;
      }),
      bookingsProvider.overrideWith((ref) async {
        if (bookings is AsyncLoading) return Completer<List<Booking>>().future;
        if (bookings is AsyncError) throw (bookings as AsyncError).error;
        return (bookings as AsyncData<List<Booking>>).value;
      }),
    ];

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen', () {
    testWidgets('shows spinner while user is loading', (tester) async {
      await tester.pumpWidget(_wrap(
        child: const HomeScreen(),
        overrides: _overrides(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows spinner while bookings are loading', (tester) async {
      await tester.pumpWidget(_wrap(
        child: const HomeScreen(),
        overrides: _overrides(user: AsyncValue.data(_user)),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text when user provider errors', (tester) async {
      await tester.pumpWidget(_wrap(
        child: const HomeScreen(),
        overrides: _overrides(
          user: AsyncValue.error('user fetch failed', StackTrace.empty),
        ),
      ));
      await tester.pump();

      expect(find.textContaining('user fetch failed'), findsOneWidget);
    });

    testWidgets('shows error text when bookings provider errors', (tester) async {
      await tester.pumpWidget(_wrap(
        child: const HomeScreen(),
        overrides: _overrides(
          user: AsyncValue.data(_user),
          bookings: AsyncValue.error('bookings failed', StackTrace.empty),
        ),
      ));
      await tester.pump();

      expect(find.textContaining('bookings failed'), findsOneWidget);
    });

    group('with data', () {
      Future<void> pump(
        WidgetTester tester, {
        List<Booking> bookings = const [],
      }) async {
        await tester.pumpWidget(_wrap(
          child: const HomeScreen(),
          overrides: _overrides(
            user: AsyncValue.data(_user),
            bookings: AsyncValue.data(bookings),
          ),
        ));
        // Resolve FutureProviders, then drain all flutter_animate timers.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
      }

      testWidgets('shows greeting with user first name', (tester) async {
        await pump(tester);
        expect(find.textContaining('Alex'), findsOneWidget);
      });

      testWidgets('shows user initials in app bar', (tester) async {
        await pump(tester);
        expect(find.text('AS'), findsOneWidget);
      });

      testWidgets('shows loyalty credit balance', (tester) async {
        await pump(tester);
        expect(find.text('\$75'), findsOneWidget);
      });

      testWidgets('shows loyalty points', (tester) async {
        await pump(tester);
        expect(find.text('1350'), findsOneWidget);
      });

      testWidgets('shows points to next reward', (tester) async {
        await pump(tester); // 1350 points → 650 to next 1000-pt tier
        expect(find.text('650 points to next reward'), findsOneWidget);
      });

      testWidgets('shows popular routes section', (tester) async {
        await pump(tester);
        expect(find.text('Popular Routes'), findsOneWidget);
        expect(find.text('Dallas → LA'), findsOneWidget);
      });

      testWidgets('shows next flight card when upcoming booking exists',
          (tester) async {
        await pump(tester, bookings: [_booking()]);
        expect(find.text('NEXT FLIGHT'), findsOneWidget);
        expect(find.text('JSX4K8P'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows seat number on next flight card when set',
          (tester) async {
        await pump(tester, bookings: [_booking(seatNumber: 12)]);
        expect(find.text('Seat 12'), findsOneWidget);
      });

      testWidgets('hides seat chip on next flight card when not set',
          (tester) async {
        await pump(tester, bookings: [_booking()]);
        expect(find.text('Seat'), findsNothing);
      });

      testWidgets('hides next flight card when no upcoming bookings',
          (tester) async {
        final past = _booking(
          departure: _now.subtract(const Duration(hours: 2)),
        );
        await pump(tester, bookings: [past]);
        expect(find.text('NEXT FLIGHT'), findsNothing);
      });

      testWidgets('shows upcoming trips count badge', (tester) async {
        await pump(tester, bookings: [_booking(), _booking()]);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('shows confirmation codes for each upcoming booking',
          (tester) async {
        await pump(tester, bookings: [_booking(), _booking()]);
        // confirmation code appears in next flight card + each upcoming card
        expect(find.text('JSX4K8P'), findsAtLeastNWidgets(2));
      });
    });
  });
}
