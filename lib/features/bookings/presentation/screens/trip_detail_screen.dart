import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/booking.dart';
import '../../../flights/presentation/screens/flight_tracking_screen.dart';
import '../../../flights/presentation/widgets/flight_route_display.dart';

class TripDetailScreen extends StatelessWidget {
  final Booking booking;
  const TripDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                '${booking.flight.origin.code} → ${booking.flight.destination.code}')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _BoardingPassCard(booking: booking),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking.isUpcoming) ...[
                      _CheckInBanner(booking: booking),
                      const SizedBox(height: AppSpacing.itemGap),
                    ],
                    _TrackFlightButton(booking: booking),
                    const SizedBox(height: AppSpacing.xl),
                    JsxText('Flight Details', JsxTextVariant.headlineMedium),
                    const SizedBox(height: AppSpacing.itemGap),
                    JsxCard(
                      child: Column(
                        children: [
                          _Row('Flight', booking.flight.id),
                          _Row('Aircraft', booking.flight.aircraft),
                          _Row('Date',
                              DateFormat('EEEE, MMMM d, yyyy').format(booking.flight.departureTime)),
                          _Row('Departure',
                              DateFormat('h:mm a').format(booking.flight.departureTime)),
                          _Row('Arrival',
                              DateFormat('h:mm a').format(booking.flight.arrivalTime)),
                          _Row('Duration', booking.flight.durationString),
                          if (booking.seatNumber != null)
                            _Row('Seat', '${booking.seatNumber}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    JsxText('Passengers', JsxTextVariant.headlineMedium),
                    const SizedBox(height: AppSpacing.itemGap),
                    JsxCard(
                      child: Column(
                        children: booking.passengers
                            .map((p) => Padding(
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
                                          child: Text(p.initials,
                                              style: const TextStyle(
                                                  color: AppColors.gold,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.itemGap),
                                      JsxText(p.fullName, JsxTextVariant.bodyLarge),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    JsxText('Payment', JsxTextVariant.headlineMedium),
                    const SizedBox(height: AppSpacing.itemGap),
                    JsxCard(
                      child: Column(
                        children: [
                          _Row('Total Paid',
                              '\$${booking.totalPaid.toStringAsFixed(0)}'),
                          _Row('Booked On',
                              DateFormat('MMM d, yyyy').format(booking.bookedAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3l),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _BoardingPassCard extends StatelessWidget {
  final Booking booking;
  const _BoardingPassCard({required this.booking});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(AppSpacing.screenPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1A2040), Color(0xFF0D1530)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('JSX',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      JsxBadge.flightStatus(booking.flight.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FlightRouteDisplay(flight: booking.flight),
                ],
              ),
            ),
            _DashedDivider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: booking.confirmationCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 2)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        JsxText('CONFIRMATION', JsxTextVariant.labelSmall,
                            letterSpacing: 1.2),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(booking.confirmationCode,
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy,
                                size: 12, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (booking.seatNumber != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        JsxText('SEAT', JsxTextVariant.labelSmall,
                            letterSpacing: 1.2),
                        const SizedBox(height: 4),
                        Text('${booking.seatNumber}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.background, shape: BoxShape.circle)),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                const dashW = 6.0;
                final count = (constraints.maxWidth / (dashW * 2)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(count,
                      (_) => Container(width: dashW, height: 1, color: AppColors.divider)),
                );
              },
            ),
          ),
          Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.background, shape: BoxShape.circle)),
        ],
      );
}

class _CheckInBanner extends StatelessWidget {
  final Booking booking;
  const _CheckInBanner({required this.booking});

  bool get _canCheckIn {
    final diff = booking.flight.departureTime.difference(DateTime.now());
    return diff.inHours <= 24 && diff.inHours >= 1;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _canCheckIn
              ? AppColors.gold.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _canCheckIn
                  ? AppColors.gold.withValues(alpha: 0.4)
                  : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
                _canCheckIn
                    ? Icons.check_circle_outline
                    : Icons.access_time,
                color: _canCheckIn ? AppColors.gold : AppColors.textSecondary,
                size: 20),
            const SizedBox(width: AppSpacing.itemGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _canCheckIn ? 'Check-in Available' : 'Check-in Opens Soon',
                    style: TextStyle(
                        color: _canCheckIn ? AppColors.gold : AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  JsxText(
                    _canCheckIn
                        ? 'Check in now for a smoother boarding experience'
                        : 'Check-in opens 24 hours before departure',
                    JsxTextVariant.labelSmall,
                  ),
                ],
              ),
            ),
            if (_canCheckIn)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.itemGap, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Text('Check In',
                    style: TextStyle(
                        color: AppColors.background,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      );
}

class _TrackFlightButton extends StatelessWidget {
  final Booking booking;
  const _TrackFlightButton({required this.booking});

  @override
  Widget build(BuildContext context) => JsxCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FlightTrackingScreen(
                  flight: booking.flight,
                  confirmationCode: booking.confirmationCode)),
        ),
        borderColor: AppColors.gold.withValues(alpha: 0.3),
        radius: 14,
        child: Row(
          children: [
            const Icon(Icons.radar, color: AppColors.gold, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JsxText('Track Flight', JsxTextVariant.titleMedium),
                  JsxText('Live position, altitude & speed',
                      JsxTextVariant.labelSmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
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
            JsxText(label, JsxTextVariant.bodyMedium),
            JsxText(value, JsxTextVariant.titleSmall),
          ],
        ),
      );
}
