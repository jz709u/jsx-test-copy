import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/flights/domain/entities/flight.dart';
import '../../features/bookings/domain/entities/booking.dart';

/// Generic colored badge with dot indicator and label.
///
/// Prefer the typed constructors [JsxBadge.flightStatus] and
/// [JsxBadge.bookingStatus] which handle color/label mapping automatically.
///
/// Use [JsxBadge.pill] for a label-only badge without a dot or border —
/// suited for membership and status labels inside cards.
class JsxBadge extends StatelessWidget {
  const JsxBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  /// Label-only pill badge: no dot indicator, no border, wider padding.
  /// Defaults to [AppColors.gold].
  factory JsxBadge.pill(String label, {Color color = AppColors.gold, Key? key}) =>
      JsxBadge(key: key, label: label, color: color, showDot: false);

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

  /// When false (pill mode) the dot indicator, border, and extra horizontal
  /// padding are omitted.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showDot ? AppSpacing.sm : 10,
        vertical: showDot ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: showDot
            ? Border.all(color: color.withValues(alpha: 0.4), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
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
