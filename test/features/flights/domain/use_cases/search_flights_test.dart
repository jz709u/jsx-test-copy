import 'package:flutter_test/flutter_test.dart';
import 'package:jsx_app_copy/features/flights/data/repositories/mock_flight_repository.dart';
import 'package:jsx_app_copy/features/flights/domain/entities/airport.dart';
import 'package:jsx_app_copy/features/flights/domain/use_cases/search_flights.dart';

void main() {
  late SearchFlights useCase;

  setUp(() => useCase = SearchFlights(MockFlightRepository()));

  const dal = Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field');
  const bur = Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope');

  group('SearchFlights', () {
    test('returns results when no filters applied', () async {
      final result = await useCase.execute();
      expect(result, isNotEmpty);
    });

    test('delegates origin filter to repository', () async {
      final result = await useCase.execute(from: dal);
      expect(result.every((f) => f.origin.code == 'DAL'), isTrue);
    });

    test('delegates destination filter to repository', () async {
      final result = await useCase.execute(to: bur);
      expect(result.every((f) => f.destination.code == 'BUR'), isTrue);
    });

    test('delegates combined origin + destination filter', () async {
      final result = await useCase.execute(from: dal, to: bur);
      expect(result, isNotEmpty);
      expect(result.every((f) => f.origin.code == 'DAL' && f.destination.code == 'BUR'), isTrue);
    });

    test('returns empty list for route with no flights', () async {
      const sjc = Airport(code: 'SJC', city: 'San Jose', name: 'Norman Y. Mineta');
      const bna = Airport(code: 'BNA', city: 'Nashville', name: 'Nashville Intl');
      final result = await useCase.execute(from: sjc, to: bna);
      expect(result, isEmpty);
    });

    test('delegates date to repository', () async {
      final date = DateTime(2030, 12, 25);
      final result = await useCase.execute(date: date);
      expect(result.every((f) => f.departureTime.year == 2030), isTrue);
    });
  });
}
