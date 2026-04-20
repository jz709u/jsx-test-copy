import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetBookings {
  final BookingRepository _repository;
  const GetBookings(this._repository);

  Future<List<Booking>> execute() => _repository.getBookings();
}
