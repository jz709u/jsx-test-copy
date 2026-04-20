import '../../../flights/domain/entities/flight.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../sources/booking_mock_data_source.dart';

class MockBookingRepository implements BookingRepository {
  final BookingMockDataSource _source;
  const MockBookingRepository(this._source);

  @override
  Future<List<Booking>> getBookings() => _source.getBookings();

  @override
  Future<String> createBooking(Flight flight, int passengers) =>
      _source.createBooking(flight, passengers);
}
