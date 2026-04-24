import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/flight.dart';
import '../providers/flight_results_provider.dart';
import '../widgets/flight_route_display.dart';
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
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
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
    return JsxCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderColor: flight.isAlmostFull
          ? AppColors.warning.withValues(alpha: 0.3)
          : AppColors.divider,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(flight.id, style: AppTextStyles.labelSmall),
              JsxBadge.flightStatus(flight.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FlightRouteDisplay(flight: flight),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppSpacing.itemGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(flight.aircraft, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 2),
                  if (flight.isAlmostFull)
                    Text('Only ${flight.availableSeats} seats left!',
                        style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))
                  else
                    Text('${flight.availableSeats} seats available',
                        style: AppTextStyles.labelSmall),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  if (passengers > 1)
                    Text('\$${flight.price.toStringAsFixed(0)}/person',
                        style: AppTextStyles.labelSmall),
                ],
              ),
            ],
          ),
        ],
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
          padding: const EdgeInsets.all(AppSpacing.x4l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_rounded, color: AppColors.textMuted, size: 64),
              const SizedBox(height: AppSpacing.lg),
              Text('No flights found', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('$fromCode to $toCode is not currently a JSX route.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xxl),
              JsxButton(
                label: 'Try Another Route',
                variant: JsxButtonVariant.secondary,
                fullWidth: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
}
