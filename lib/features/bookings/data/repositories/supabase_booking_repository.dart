import '../../../flights/domain/entities/flight.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../sources/supabase_booking_data_source.dart';

class SupabaseBookingRepository implements BookingRepository {
  final SupabaseBookingDataSource _source;
  SupabaseBookingRepository(this._source);

  @override
  Future<List<Booking>> getBookings() => _source.getBookings();

  @override
  Future<String> createBooking(Flight flight, int passengers) =>
      _source.createBooking(flight, passengers);
}
