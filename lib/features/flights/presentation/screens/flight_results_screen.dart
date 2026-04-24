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
            JsxText('${DateFormat('MMM d').format(params.date)} · $passengers pax',
                JsxTextVariant.labelMedium),
          ],
        ),
      ),
      body: AsyncBuilder(
        value: resultsAsync,
        data: (results) => results.isEmpty
            ? JsxEmptyState(
                icon: Icons.flight_rounded,
                title: 'No flights found',
                subtitle: '${params.fromCode} to ${params.toCode} is not currently a JSX route.',
                actionLabel: 'Try Another Route',
                onAction: () => Navigator.pop(context),
              )
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
              JsxText(flight.id, JsxTextVariant.labelSmall),
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
                  JsxText(flight.aircraft, JsxTextVariant.bodySmall),
                  const SizedBox(height: 2),
                  if (flight.isAlmostFull)
                    JsxText('Only ${flight.availableSeats} seats left!',
                        JsxTextVariant.labelSmall, color: AppColors.warning)
                  else
                    JsxText('${flight.availableSeats} seats available',
                        JsxTextVariant.labelSmall),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  JsxText('\$${totalPrice.toStringAsFixed(0)}', JsxTextVariant.headlineLarge),
                  if (passengers > 1)
                    JsxText('\$${flight.price.toStringAsFixed(0)}/person',
                        JsxTextVariant.labelSmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

