import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/data/repositories/mock_booking_repository.dart';
import 'package:jsx_app_copy/features/bookings/domain/use_cases/create_booking.dart';
import 'package:jsx_app_copy/features/bookings/presentation/providers/booking_creation_provider.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/flight.dart';
import 'package:jsx_app_copy/features/flights/presentation/screens/booking_confirmation_screen.dart';

const _dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
const _bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

Flight get _flight {
  final dep = DateTime(2030, 6, 15, 8);
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

class _StubBookingNotifier extends BookingCreationNotifier {
  _StubBookingNotifier(BookingCreationState s)
      : super(CreateBooking(MockBookingRepository())) {
    state = s;
  }

  @override
  Future<void> confirm(Flight flight, int passengers) async {}
}

Widget _wrap(BookingCreationState bookingState) => ProviderScope(
      overrides: [
        bookingCreationProvider.overrideWith((_) => _StubBookingNotifier(bookingState)),
      ],
      child: MaterialApp(
        home: BookingConfirmationScreen(flight: _flight, passengers: 1),
      ),
    );

void main() {
  group('BookingConfirmationScreen', () {
    group('idle', () {
      testWidgets('shows Review & Book in app bar', (tester) async {
        await tester.pumpWidget(_wrap(const BookingCreationState()));
        await tester.pump();
        expect(find.text('Review & Book'), findsOneWidget);
      });

      testWidgets('shows Flight Details section', (tester) async {
        await tester.pumpWidget(_wrap(const BookingCreationState()));
        await tester.pump();
        expect(find.text('Flight Details'), findsOneWidget);
      });

      testWidgets('shows Passengers section', (tester) async {
        await tester.pumpWidget(_wrap(const BookingCreationState()));
        await tester.pump();
        expect(find.text('Passengers'), findsOneWidget);
      });

      testWidgets('shows Confirm Booking button', (tester) async {
        await tester.pumpWidget(_wrap(const BookingCreationState()));
        await tester.pump();
        expect(find.text('Confirm Booking'), findsOneWidget);
      });

      testWidgets('shows flight id', (tester) async {
        await tester.pumpWidget(_wrap(const BookingCreationState()));
        await tester.pump();
        expect(find.text('JSX-1021'), findsOneWidget);
      });

      testWidgets('button is enabled', (tester) async {
        await tester.pumpWidget(_wrap(const BookingCreationState()));
        await tester.pump();
        final btn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Confirm Booking'),
        );
        expect(btn.onPressed, isNotNull);
      });
    });

    group('loading', () {
      testWidgets('shows spinner inside button', (tester) async {
        await tester.pumpWidget(_wrap(
          const BookingCreationState(status: BookingCreationStatus.loading),
        ));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Confirm Booking'), findsNothing);
      });

      testWidgets('button is disabled while loading', (tester) async {
        await tester.pumpWidget(_wrap(
          const BookingCreationState(status: BookingCreationStatus.loading),
        ));
        await tester.pump();
        final btns = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
        expect(btns.every((b) => b.onPressed == null), isTrue);
      });
    });

    group('success', () {
      testWidgets("shows You're booked! message", (tester) async {
        await tester.pumpWidget(_wrap(
          const BookingCreationState(
            status: BookingCreationStatus.success,
            confirmationCode: 'JSX4K8P',
          ),
        ));
        await tester.pump();
        expect(find.text("You're booked!"), findsOneWidget);
      });

      testWidgets('shows confirmation code', (tester) async {
        await tester.pumpWidget(_wrap(
          const BookingCreationState(
            status: BookingCreationStatus.success,
            confirmationCode: 'JSX4K8P',
          ),
        ));
        await tester.pump();
        expect(find.text('JSX4K8P'), findsOneWidget);
      });
    });

    group('failure', () {
      testWidgets('shows error message', (tester) async {
        await tester.pumpWidget(_wrap(
          const BookingCreationState(
            status: BookingCreationStatus.failure,
            errorMessage: 'Payment declined',
          ),
        ));
        await tester.pump();
        expect(find.text('Payment declined'), findsOneWidget);
      });

      testWidgets('Confirm Booking button is still enabled', (tester) async {
        await tester.pumpWidget(_wrap(
          const BookingCreationState(
            status: BookingCreationStatus.failure,
            errorMessage: 'Payment declined',
          ),
        ));
        await tester.pump();
        final btn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Confirm Booking'),
        );
        expect(btn.onPressed, isNotNull);
      });
    });
  });
}
