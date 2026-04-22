import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/domain/entities/booking.dart';
import 'package:jsx_app_copy/features/bookings/domain/entities/passenger.dart';
import 'package:jsx_app_copy/features/bookings/presentation/screens/trip_detail_screen.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

final _now = DateTime.now();

Flight get _flight {
  final dep = _now.add(const Duration(days: 3));
  return Flight(
    id: 'JSX-1021',
    origin: _dal,
    destination: _bur,
    departureTime: dep,
    arrivalTime: dep.add(const Duration(hours: 2)),
    aircraft: 'Embraer E135',
    totalSeats: 30,
    availableSeats: 10,
    price: 299,
    status: FlightStatus.onTime,
  );
}

Booking _booking({List<Passenger> passengers = const [], int? seatNumber}) => Booking(
      confirmationCode: 'JSX4K8P',
      flight: _flight,
      passengers: passengers,
      totalPaid: 299,
      bookedAt: _now.subtract(const Duration(days: 7)),
      status: BookingStatus.confirmed,
      seatNumber: seatNumber,
    );

Widget _wrap(Booking booking) => ProviderScope(
      child: MaterialApp(home: TripDetailScreen(booking: booking)),
    );

void main() {
  group('TripDetailScreen', () {
    testWidgets('shows route in app bar', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.text('DAL → BUR'), findsOneWidget);
    });

    testWidgets('shows confirmation code', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.text('JSX4K8P'), findsOneWidget);
    });

    testWidgets('shows flight id in flight details', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.text('JSX-1021'), findsOneWidget);
    });

    testWidgets('shows aircraft in flight details', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.text('Embraer E135'), findsOneWidget);
    });

    testWidgets('shows seat number when provided', (tester) async {
      await tester.pumpWidget(_wrap(_booking(seatNumber: 12)));
      await tester.pump();
      expect(find.text('Seat'), findsOneWidget);
    });

    testWidgets('shows Flight Details and Passengers section headers', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.text('Flight Details'), findsOneWidget);
      expect(find.text('Passengers'), findsOneWidget);
    });

    testWidgets('shows passenger names when present', (tester) async {
      final pax = [
        const Passenger(firstName: 'Alice', lastName: 'Jones'),
        const Passenger(firstName: 'Bob', lastName: 'Lee'),
      ];
      await tester.pumpWidget(_wrap(_booking(passengers: pax)));
      await tester.pump();
      expect(find.text('Alice Jones'), findsOneWidget);
      expect(find.text('Bob Lee'), findsOneWidget);
    });

    testWidgets('shows Track Flight button for upcoming booking', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.text('Track Flight'), findsOneWidget);
    });

    testWidgets('shows Check-in banner for upcoming booking', (tester) async {
      await tester.pumpWidget(_wrap(_booking()));
      await tester.pump();
      expect(find.textContaining('Check-in'), findsWidgets);
    });
  });
}
