import '../../../flights/domain/entities/flight.dart';
import '../repositories/booking_repository.dart';

class CreateBooking {
  final BookingRepository _repository;
  const CreateBooking(this._repository);

  Future<String> execute(Flight flight, int passengers) =>
      _repository.createBooking(flight, passengers);
}
