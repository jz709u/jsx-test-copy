import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/flights/data/repositories/mock_flight_repository.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';

void main() {
  late MockFlightRepository repo;

  setUp(() => repo = MockFlightRepository());

  // Known airports from the mock data
  const dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
  const bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');
  const las = Airport(code: 'LAS', city: 'Las Vegas', name: 'Harry Reid Intl');

  group('MockFlightRepository.getAirports', () {
    test('returns all 8 airports', () async {
      final airports = await repo.getAirports();
      expect(airports, hasLength(8));
    });

    test('includes DAL, BUR and LAS', () async {
      final codes = (await repo.getAirports()).map((a) => a.code).toSet();
      expect(codes, containsAll(['DAL', 'BUR', 'LAS', 'OAK', 'PHX', 'SJC', 'BNA', 'AUS']));
    });
  });

  group('MockFlightRepository.searchFlights', () {
    test('returns all flights when no filters applied', () async {
      final flights = await repo.searchFlights();
      expect(flights, hasLength(8));
    });

    test('filters by origin airport', () async {
      final flights = await repo.searchFlights(from: dal);
      expect(flights.every((f) => f.origin.code == 'DAL'), isTrue);
    });

    test('filters by destination airport', () async {
      final flights = await repo.searchFlights(to: bur);
      expect(flights.every((f) => f.destination.code == 'BUR'), isTrue);
    });

    test('filters by both origin and destination', () async {
      final flights = await repo.searchFlights(from: dal, to: bur);
      expect(flights, hasLength(3)); // JSX-1021, JSX-1022, JSX-1023
      expect(flights.every((f) => f.origin.code == 'DAL' && f.destination.code == 'BUR'), isTrue);
    });

    test('returns empty list when no flights match', () async {
      // PHX and SJC exist as airports but have no scheduled flights
      const phx = Airport(code: 'PHX', city: 'Phoenix', name: 'Phoenix Deer Valley');
      const sjc = Airport(code: 'SJC', city: 'San Jose', name: 'Norman Y. Mineta');
      final flights = await repo.searchFlights(from: phx, to: sjc);
      expect(flights, isEmpty);
    });

    test('flight departure and arrival times are on the given date', () async {
      final date = DateTime(2030, 8, 15);
      final flights = await repo.searchFlights(date: date);
      for (final f in flights) {
        expect(f.departureTime.year, 2030);
        expect(f.departureTime.month, 8);
        expect(f.departureTime.day, 15);
      }
    });

    test('all returned flights have a positive price', () async {
      final flights = await repo.searchFlights();
      expect(flights.every((f) => f.price > 0), isTrue);
    });

    test('all returned flights have departure before arrival', () async {
      final flights = await repo.searchFlights();
      expect(flights.every((f) => f.departureTime.isBefore(f.arrivalTime)), isTrue);
    });

    test('DAL→OAK flight is flagged as boarding', () async {
      final flights = await repo.searchFlights(from: dal);
      final boarding = flights.where((f) => f.id == 'JSX-4010').single;
      expect(boarding.status.name, 'boarding');
    });

    test('AUS→DAL flight is flagged as delayed', () async {
      final flights = await repo.searchFlights();
      final delayed = flights.where((f) => f.id == 'JSX-6030').single;
      expect(delayed.status.name, 'delayed');
    });
  });
}
