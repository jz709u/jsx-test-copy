import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/flight.dart';
import '../../../bookings/presentation/providers/booking_creation_provider.dart';
import '../widgets/flight_route_display.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final Flight flight;
  final int passengers;

  const BookingConfirmationScreen({super.key, required this.flight, required this.passengers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingCreationProvider);

    if (bookingState.status == BookingCreationStatus.success) {
      return _SuccessScreen(flight: flight, confirmationCode: bookingState.confirmationCode!);
    }

    final total = flight.price * passengers;
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flight Details', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _InfoCard(children: [
              FlightRouteDisplay(flight: flight),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              _Row('Flight', flight.id),
              _Row('Aircraft', flight.aircraft),
              _Row('Date', DateFormat('EEEE, MMMM d, yyyy').format(flight.departureTime)),
              _Row('Departure', DateFormat('h:mm a').format(flight.departureTime)),
              _Row('Arrival', DateFormat('h:mm a').format(flight.arrivalTime)),
              _Row('Duration', flight.durationString),
            ]),
            const SizedBox(height: 24),
            Text('Passengers', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _InfoCard(
              children: List.generate(
                passengers,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 12),
                      Text(i == 0 ? 'Alex Rivera (You)' : 'Passenger ${i + 1}', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Price Summary', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _Row('Base fare × $passengers', '\$${(flight.price * passengers).toStringAsFixed(0)}'),
              _Row('Taxes & fees', '\$0'),
              const Divider(color: AppColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Text("You'll earn \$${(total * 0.05).toStringAsFixed(2)} Club JSX credit", style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 32),
            if (bookingState.status == BookingCreationStatus.failure) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(bookingState.errorMessage ?? 'Something went wrong', style: const TextStyle(color: AppColors.error)),
              ),
            ],
            ElevatedButton(
              onPressed: bookingState.status == BookingCreationStatus.loading
                  ? null
                  : () => ref.read(bookingCreationProvider.notifier).confirm(flight, passengers),
              child: bookingState.status == BookingCreationStatus.loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                  : const Text('Confirm Booking'),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No change fees · Free cancellation 24h before flight',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(value, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _SuccessScreen extends StatelessWidget {
  final Flight flight;
  final String confirmationCode;
  const _SuccessScreen({required this.flight, required this.confirmationCode});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 24),
                const Text("You're booked!", style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${flight.origin.city} to ${flight.destination.city}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('CONFIRMATION', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(confirmationCode, style: const TextStyle(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 3)),
                      const SizedBox(height: 12),
                      Text(DateFormat('EEE, MMM d · h:mm a').format(flight.departureTime), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Back to Home'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('View My Trips', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      );
}
