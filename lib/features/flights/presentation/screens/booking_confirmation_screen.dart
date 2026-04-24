import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
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
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JsxText('Flight Details', JsxTextVariant.headlineMedium),
            const SizedBox(height: AppSpacing.itemGap),
            JsxCard(
              child: Column(
                children: [
                  FlightRouteDisplay(flight: flight),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppSpacing.itemGap),
                  JsxDetailRow('Flight', flight.id),
                  JsxDetailRow('Aircraft', flight.aircraft),
                  JsxDetailRow('Date', DateFormat('EEEE, MMMM d, yyyy').format(flight.departureTime)),
                  JsxDetailRow('Departure', DateFormat('h:mm a').format(flight.departureTime)),
                  JsxDetailRow('Arrival', DateFormat('h:mm a').format(flight.arrivalTime)),
                  JsxDetailRow('Duration', flight.durationString),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            JsxText('Passengers', JsxTextVariant.headlineMedium),
            const SizedBox(height: AppSpacing.itemGap),
            JsxCard(
              child: Column(
                children: List.generate(
                  passengers,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle),
                          child: Center(
                            child: JsxText('${i + 1}',
                                JsxTextVariant.titleSmall, color: AppColors.gold),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.itemGap),
                        JsxText(
                          i == 0 ? 'Alex Rivera (You)' : 'Passenger ${i + 1}',
                          JsxTextVariant.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            JsxText('Price Summary', JsxTextVariant.headlineMedium),
            const SizedBox(height: AppSpacing.itemGap),
            JsxCard(
              child: Column(
                children: [
                  JsxDetailRow('Base fare × $passengers', '\$${(flight.price * passengers).toStringAsFixed(0)}'),
                  JsxDetailRow('Taxes & fees', '\$0'),
                  const Divider(color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      JsxText('Total', JsxTextVariant.titleLarge),
                      JsxText('\$${total.toStringAsFixed(0)}',
                          JsxTextVariant.headlineLarge, color: AppColors.gold),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.itemGap),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.itemGap),
                    decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.chip)),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.gold, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        JsxText(
                          "You'll earn \$${(total * 0.05).toStringAsFixed(2)} Club JSX credit",
                          JsxTextVariant.labelMedium, color: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3l),
            if (bookingState.status == BookingCreationStatus.failure) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.itemGap),
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.chip)),
                child: JsxText(bookingState.errorMessage ?? 'Something went wrong',
                    JsxTextVariant.bodySmall, color: AppColors.error),
              ),
            ],
            JsxButton(
              label: 'Confirm Booking',
              loading: bookingState.status == BookingCreationStatus.loading,
              onPressed: () =>
                  ref.read(bookingCreationProvider.notifier).confirm(flight, passengers),
            ),
            const SizedBox(height: AppSpacing.itemGap),
            const Center(
              child: JsxText(
                'No change fees · Free cancellation 24h before flight',
                JsxTextVariant.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.x3l),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final Flight flight;
  final String confirmationCode;
  const _SuccessScreen({required this.flight, required this.confirmationCode});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
                const SizedBox(height: AppSpacing.xxl),
                JsxText("You're booked!", JsxTextVariant.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                JsxText('${flight.origin.city} to ${flight.destination.city}',
                    JsxTextVariant.bodyLarge),
                const SizedBox(height: AppSpacing.x3l),
                JsxCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3l, vertical: AppSpacing.xl),
                  borderColor: AppColors.gold.withValues(alpha: 0.3),
                  radius: AppRadius.sheet,
                  child: Column(
                    children: [
                      JsxText('CONFIRMATION', JsxTextVariant.labelSmall,
                          letterSpacing: 1.5, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.sm),
                      JsxText(confirmationCode, JsxTextVariant.displayMedium,
                          color: AppColors.gold, letterSpacing: 3),
                      const SizedBox(height: AppSpacing.itemGap),
                      JsxText(
                          DateFormat('EEE, MMM d · h:mm a')
                              .format(flight.departureTime),
                          JsxTextVariant.bodyMedium),
                    ],
                  ),
                ),
                const Spacer(),
                JsxButton(
                  label: 'Back to Home',
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                const SizedBox(height: AppSpacing.itemGap),
                JsxButton(
                  label: 'View My Trips',
                  variant: JsxButtonVariant.ghost,
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      );
}
