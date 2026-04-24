import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/flights/domain/entities/flight.dart';
import '../../features/bookings/domain/entities/booking.dart';

/// Generic colored badge with dot indicator and label.
///
/// Prefer the typed constructors [JsxBadge.flightStatus] and
/// [JsxBadge.bookingStatus] which handle color/label mapping automatically.
class JsxBadge extends StatelessWidget {
  const JsxBadge({
    super.key,
    required this.label,
    required this.color,
  });

  /// Badge for a [FlightStatus] value.
  factory JsxBadge.flightStatus(FlightStatus status, {Key? key}) {
    return JsxBadge(
      key: key,
      label: status.label,
      color: _flightStatusColor(status),
    );
  }

  /// Badge for a [BookingStatus] value.
  factory JsxBadge.bookingStatus(BookingStatus status, {Key? key}) {
    return JsxBadge(
      key: key,
      label: _bookingStatusLabel(status),
      color: _bookingStatusColor(status),
    );
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Color/label mappings ───────────────────────────────────────────────────

  static Color _flightStatusColor(FlightStatus s) => switch (s) {
        FlightStatus.onTime    => AppColors.success,
        FlightStatus.boarding  => AppColors.gold,
        FlightStatus.delayed   => AppColors.warning,
        FlightStatus.cancelled => AppColors.error,
        FlightStatus.departed  => AppColors.textSecondary,
        FlightStatus.landed    => AppColors.textSecondary,
      };

  static Color _bookingStatusColor(BookingStatus s) => switch (s) {
        BookingStatus.confirmed  => AppColors.success,
        BookingStatus.checkedIn  => AppColors.gold,
        BookingStatus.cancelled  => AppColors.error,
        BookingStatus.completed  => AppColors.textSecondary,
      };

  static String _bookingStatusLabel(BookingStatus s) => switch (s) {
        BookingStatus.confirmed  => 'Confirmed',
        BookingStatus.checkedIn  => 'Checked In',
        BookingStatus.cancelled  => 'Cancelled',
        BookingStatus.completed  => 'Completed',
      };
}
