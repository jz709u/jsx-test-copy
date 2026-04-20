import '../../../flights/domain/entities/flight.dart';
import '../entities/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings();
  Future<String> createBooking(Flight flight, int passengers);
}
