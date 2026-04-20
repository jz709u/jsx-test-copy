import '../entities/airport.dart';
import '../entities/flight.dart';
import '../repositories/flight_repository.dart';

class SearchFlights {
  final FlightRepository _repository;
  const SearchFlights(this._repository);

  Future<List<Flight>> execute({Airport? from, Airport? to, DateTime? date}) =>
      _repository.searchFlights(from: from, to: to, date: date);
}
