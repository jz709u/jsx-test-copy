import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/bookings/data/repositories/mock_booking_repository.dart';
import 'package:jsx_app_copy/features/bookings/domain/use_cases/get_bookings.dart';

void main() {
  late GetBookings useCase;

  setUp(() => useCase = GetBookings(MockBookingRepository()));

  group('GetBookings', () {
    test('returns a list of bookings', () async {
      final result = await useCase.execute();
      expect(result, isNotEmpty);
    });

    test('each booking has a non-empty confirmation code', () async {
      final result = await useCase.execute();
      expect(result.every((b) => b.confirmationCode.isNotEmpty), isTrue);
    });

    test('each booking has an associated flight', () async {
      final result = await useCase.execute();
      expect(result.every((b) => b.flight.id.isNotEmpty), isTrue);
    });
  });
}
