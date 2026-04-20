import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/flights/services/spotlight_service.dart';
import '../../../../features/flights/services/widget_update_service.dart';
import '../../data/repositories/mock_booking_repository.dart';
import '../../data/sources/booking_mock_data_source.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/use_cases/get_bookings.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (_) => MockBookingRepository(BookingMockDataSource()),
);

final getBookingsUseCaseProvider = Provider<GetBookings>(
  (ref) => GetBookings(ref.watch(bookingRepositoryProvider)),
);

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookings = await ref.watch(getBookingsUseCaseProvider).execute();
  WidgetUpdateService.update(bookings);
  SpotlightService.indexBookings(bookings);
  return bookings;
});
