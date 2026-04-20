import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/flight.dart';
import '../providers/flight_results_provider.dart';
import '../widgets/flight_route_display.dart';
import '../widgets/status_badge.dart';
import 'booking_confirmation_screen.dart';

class FlightResultsScreen extends ConsumerWidget {
  final FlightSearchParams params;
  final int passengers;

  const FlightResultsScreen({super.key, required this.params, required this.passengers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(flightResultsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${params.fromCode} → ${params.toCode}'),
            Text(
              '${DateFormat('MMM d').format(params.date)} · $passengers pax',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
        data: (results) => results.isEmpty
            ? _EmptyResults(fromCode: params.fromCode, toCode: params.toCode)
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FlightResultCard(
                  flight: results[i],
                  passengers: passengers,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingConfirmationScreen(flight: results[i], passengers: passengers),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _FlightResultCard extends StatelessWidget {
  final Flight flight;
  final int passengers;
  final VoidCallback onTap;

  const _FlightResultCard({required this.flight, required this.passengers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalPrice = flight.price * passengers;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: flight.isAlmostFull ? AppColors.warning.withValues(alpha: 0.3) : AppColors.divider,
            width: flight.isAlmostFull ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(flight.id, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                StatusBadge(status: flight.status),
              ],
            ),
            const SizedBox(height: 16),
            FlightRouteDisplay(flight: flight),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flight.aircraft, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    if (flight.isAlmostFull)
                      Text('Only ${flight.availableSeats} seats left!', style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))
                    else
                      Text('${flight.availableSeats} seats available', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    if (passengers > 1)
                      Text('\$${flight.price.toStringAsFixed(0)}/person', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String fromCode;
  final String toCode;
  const _EmptyResults({required this.fromCode, required this.toCode});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_rounded, color: AppColors.textMuted, size: 64),
              const SizedBox(height: 16),
              Text('No flights found', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('$fromCode to $toCode is not currently a JSX route.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold, side: const BorderSide(color: AppColors.gold)),
                child: const Text('Try Another Route'),
              ),
            ],
          ),
        ),
      );
}
