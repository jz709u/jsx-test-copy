import '../../domain/entities/airport.dart';
import '../../domain/entities/flight.dart';
import '../../domain/repositories/flight_repository.dart';
import '../sources/flight_mock_data_source.dart';

class MockFlightRepository implements FlightRepository {
  final FlightMockDataSource _source;
  const MockFlightRepository(this._source);

  @override
  Future<List<Airport>> getAirports() => _source.getAirports();

  @override
  Future<List<Flight>> searchFlights({Airport? from, Airport? to, DateTime? date}) =>
      _source.searchFlights(from: from, to: to, date: date);
}
