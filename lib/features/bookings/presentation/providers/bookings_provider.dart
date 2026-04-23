import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/debug/backend_mode.dart';
import '../../../flights/services/spotlight_service.dart';
import '../../../flights/services/widget_update_service.dart';
import '../../data/repositories/mock_booking_repository.dart';
import '../../data/repositories/supabase_booking_repository.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/use_cases/get_bookings.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return MockBookingRepository();
  return SupabaseBookingRepository(client);
});

final getBookingsUseCaseProvider = Provider<GetBookings>(
  (ref) => GetBookings(ref.watch(bookingRepositoryProvider)),
);

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookings = await ref.watch(getBookingsUseCaseProvider).execute();
  WidgetUpdateService.update(bookings);
  SpotlightService.indexBookings(bookings);
  return bookings;
});
