import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking.dart';
import '../../../flights/presentation/screens/flight_tracking_screen.dart';
import '../../../flights/presentation/widgets/flight_route_display.dart';
import '../../../flights/presentation/widgets/status_badge.dart';

class TripDetailScreen extends StatelessWidget {
  final Booking booking;
  const TripDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${booking.flight.origin.code} → ${booking.flight.destination.code}')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _BoardingPassCard(booking: booking),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking.isUpcoming) ...[
                      _CheckInBanner(booking: booking),
                      const SizedBox(height: 12),
                    ],
                    _TrackFlightButton(booking: booking),
                    const SizedBox(height: 20),
                    Text('Flight Details', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    _InfoCard(children: [
                      _Row('Flight', booking.flight.id),
                      _Row('Aircraft', booking.flight.aircraft),
                      _Row('Date', DateFormat('EEEE, MMMM d, yyyy').format(booking.flight.departureTime)),
                      _Row('Departure', DateFormat('h:mm a').format(booking.flight.departureTime)),
                      _Row('Arrival', DateFormat('h:mm a').format(booking.flight.arrivalTime)),
                      _Row('Duration', booking.flight.durationString),
                      if (booking.seatNumber != null) _Row('Seat', '${booking.seatNumber}'),
                    ]),
                    const SizedBox(height: 20),
                    Text('Passengers', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    _InfoCard(
                      children: booking.passengers
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                                      child: Center(child: Text(p.initials, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700))),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(p.fullName, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('Payment', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    _InfoCard(children: [
                      _Row('Total Paid', '\$${booking.totalPaid.toStringAsFixed(0)}'),
                      _Row('Booked On', DateFormat('MMM d, yyyy').format(booking.bookedAt)),
                    ]),
                    const SizedBox(height: 32),
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
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A2040), Color(0xFF0D1530)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('JSX', style: TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      StatusBadge(status: booking.flight.status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FlightRouteDisplay(flight: booking.flight),
                ],
              ),
            ),
            _DashedDivider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: booking.confirmationCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CONFIRMATION', style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(booking.confirmationCode, style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy, size: 12, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (booking.seatNumber != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('SEAT', style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('${booking.seatNumber}', style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
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
          Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle)),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                const dashW = 6.0;
                final count = (constraints.maxWidth / (dashW * 2)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(count, (_) => Container(width: dashW, height: 1, color: AppColors.divider)),
                );
              },
            ),
          ),
          Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _canCheckIn ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _canCheckIn ? AppColors.gold.withValues(alpha: 0.4) : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(_canCheckIn ? Icons.check_circle_outline : Icons.access_time, color: _canCheckIn ? AppColors.gold : AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _canCheckIn ? 'Check-in Available' : 'Check-in Opens Soon',
                    style: TextStyle(color: _canCheckIn ? AppColors.gold : AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _canCheckIn ? 'Check in now for a smoother boarding experience' : 'Check-in opens 24 hours before departure',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_canCheckIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                child: const Text('Check In', style: TextStyle(color: AppColors.background, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      );
}

class _TrackFlightButton extends StatelessWidget {
  final Booking booking;
  const _TrackFlightButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FlightTrackingScreen(flight: booking.flight, confirmationCode: booking.confirmationCode)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.radar, color: AppColors.gold, size: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track Flight', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Live position, altitude & speed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
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
