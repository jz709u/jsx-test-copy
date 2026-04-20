import '../../../flights/data/sources/flight_mock_data_source.dart';
import '../../../flights/domain/entities/flight.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/passenger.dart';

class BookingMockDataSource {
  Future<List<Booking>> getBookings() async {
    final now = DateTime.now();
    final airports = FlightMockDataSource.airports;

    return [
      Booking(
        confirmationCode: 'JSX4K8P',
        flight: Flight(
          id: 'JSX-1021',
          origin: airports[0],
          destination: airports[1],
          departureTime: now.add(const Duration(days: 3, hours: 2)),
          arrivalTime: now.add(const Duration(days: 3, hours: 4, minutes: 15)),
          aircraft: 'Embraer E135',
          totalSeats: 30,
          availableSeats: 12,
          price: 299,
          status: FlightStatus.onTime,
        ),
        passengers: [const Passenger(firstName: 'Alex', lastName: 'Rivera')],
        totalPaid: 299,
        bookedAt: now.subtract(const Duration(days: 10)),
        status: BookingStatus.confirmed,
        seatNumber: 7,
      ),
      Booking(
        confirmationCode: 'JSX9M2R',
        flight: Flight(
          id: 'JSX-3050',
          origin: airports[0],
          destination: airports[2],
          departureTime: now.add(const Duration(days: 14, hours: 3, minutes: 15)),
          arrivalTime: now.add(const Duration(days: 14, hours: 5)),
          aircraft: 'Embraer E135',
          totalSeats: 30,
          availableSeats: 22,
          price: 199,
          status: FlightStatus.onTime,
        ),
        passengers: [
          const Passenger(firstName: 'Alex', lastName: 'Rivera'),
          const Passenger(firstName: 'Jordan', lastName: 'Rivera'),
        ],
        totalPaid: 398,
        bookedAt: now.subtract(const Duration(days: 2)),
        status: BookingStatus.confirmed,
      ),
      Booking(
        confirmationCode: 'JSXLT7Q',
        flight: Flight(
          id: 'JSX-2010',
          origin: airports[1],
          destination: airports[0],
          departureTime: now.subtract(const Duration(days: 7, hours: 2)),
          arrivalTime: now.subtract(const Duration(days: 6, hours: 23, minutes: 45)),
          aircraft: 'Embraer E135',
          totalSeats: 30,
          availableSeats: 0,
          price: 299,
          status: FlightStatus.landed,
        ),
        passengers: [const Passenger(firstName: 'Alex', lastName: 'Rivera')],
        totalPaid: 299,
        bookedAt: now.subtract(const Duration(days: 20)),
        status: BookingStatus.completed,
        seatNumber: 12,
      ),
      Booking(
        confirmationCode: 'JSX8WXN',
        flight: Flight(
          id: 'JSX-4010',
          origin: airports[0],
          destination: airports[3],
          departureTime: now.subtract(const Duration(days: 30, hours: 1)),
          arrivalTime: now.subtract(const Duration(days: 29, hours: 22, minutes: 15)),
          aircraft: 'Embraer E135',
          totalSeats: 30,
          availableSeats: 0,
          price: 349,
          status: FlightStatus.landed,
        ),
        passengers: [const Passenger(firstName: 'Alex', lastName: 'Rivera')],
        totalPaid: 349,
        bookedAt: now.subtract(const Duration(days: 45)),
        status: BookingStatus.completed,
        seatNumber: 4,
      ),
    ];
  }

  Future<String> createBooking(Flight flight, int passengers) async {
    await Future.delayed(const Duration(seconds: 2));
    const codes = ['JSX7R2K', 'JSXPQ4M', 'JSX9WX3', 'JSXLT5N', 'JSX2BM8'];
    return codes[DateTime.now().second % codes.length];
  }
}
