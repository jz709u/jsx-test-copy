import '../entities/airport.dart';
import '../entities/flight.dart';

abstract class FlightRepository {
  Future<List<Airport>> getAirports();
  Future<List<Flight>> searchFlights({Airport? from, Airport? to, DateTime? date});
}
