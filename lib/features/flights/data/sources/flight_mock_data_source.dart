import '../../domain/entities/airport.dart';
import '../../domain/entities/flight.dart';

class FlightMockDataSource {
  static const airports = [
    Airport(code: 'DAL', city: 'Dallas', name: 'Dallas Love Field'),
    Airport(code: 'BUR', city: 'Los Angeles', name: 'Burbank Bob Hope'),
    Airport(code: 'LAS', city: 'Las Vegas', name: 'Harry Reid Intl'),
    Airport(code: 'OAK', city: 'Oakland', name: 'Oakland Metro Intl'),
    Airport(code: 'PHX', city: 'Phoenix', name: 'Phoenix Deer Valley'),
    Airport(code: 'SJC', city: 'San Jose', name: 'Norman Y. Mineta'),
    Airport(code: 'BNA', city: 'Nashville', name: 'Nashville Intl'),
    Airport(code: 'AUS', city: 'Austin', name: 'Austin-Bergstrom Intl'),
  ];

  Future<List<Airport>> getAirports() async => airports;

  Future<List<Flight>> searchFlights({
    Airport? from,
    Airport? to,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final base = DateTime(d.year, d.month, d.day);

    final all = [
      Flight(
        id: 'JSX-1021',
        origin: airports[0],
        destination: airports[1],
        departureTime: base.add(const Duration(hours: 7, minutes: 30)),
        arrivalTime: base.add(const Duration(hours: 9, minutes: 45)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 12,
        price: 299,
        status: FlightStatus.onTime,
      ),
      Flight(
        id: 'JSX-1022',
        origin: airports[0],
        destination: airports[1],
        departureTime: base.add(const Duration(hours: 11, minutes: 0)),
        arrivalTime: base.add(const Duration(hours: 13, minutes: 15)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 4,
        price: 329,
        status: FlightStatus.onTime,
      ),
      Flight(
        id: 'JSX-1023',
        origin: airports[0],
        destination: airports[1],
        departureTime: base.add(const Duration(hours: 15, minutes: 45)),
        arrivalTime: base.add(const Duration(hours: 18, minutes: 0)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 18,
        price: 279,
        status: FlightStatus.onTime,
      ),
      Flight(
        id: 'JSX-2010',
        origin: airports[1],
        destination: airports[0],
        departureTime: base.add(const Duration(hours: 8, minutes: 0)),
        arrivalTime: base.add(const Duration(hours: 10, minutes: 15)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 9,
        price: 299,
        status: FlightStatus.onTime,
      ),
      Flight(
        id: 'JSX-3050',
        origin: airports[0],
        destination: airports[2],
        departureTime: base.add(const Duration(hours: 9, minutes: 15)),
        arrivalTime: base.add(const Duration(hours: 11, minutes: 0)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 22,
        price: 199,
        status: FlightStatus.onTime,
      ),
      Flight(
        id: 'JSX-4010',
        origin: airports[0],
        destination: airports[3],
        departureTime: base.add(const Duration(hours: 6, minutes: 45)),
        arrivalTime: base.add(const Duration(hours: 9, minutes: 30)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 3,
        price: 349,
        status: FlightStatus.boarding,
      ),
      Flight(
        id: 'JSX-5020',
        origin: airports[1],
        destination: airports[2],
        departureTime: base.add(const Duration(hours: 14, minutes: 30)),
        arrivalTime: base.add(const Duration(hours: 15, minutes: 45)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 16,
        price: 179,
        status: FlightStatus.onTime,
      ),
      Flight(
        id: 'JSX-6030',
        origin: airports[7],
        destination: airports[0],
        departureTime: base.add(const Duration(hours: 10, minutes: 20)),
        arrivalTime: base.add(const Duration(hours: 11, minutes: 15)),
        aircraft: 'Embraer E135',
        totalSeats: 30,
        availableSeats: 8,
        price: 149,
        status: FlightStatus.delayed,
      ),
    ];

    return all.where((f) {
      if (from != null && f.origin.code != from.code) return false;
      if (to != null && f.destination.code != to.code) return false;
      return true;
    }).toList();
  }
}
