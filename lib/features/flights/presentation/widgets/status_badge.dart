import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/flight.dart';

class StatusBadge extends StatelessWidget {
  final FlightStatus status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case FlightStatus.onTime: return AppColors.success;
      case FlightStatus.boarding: return AppColors.gold;
      case FlightStatus.delayed: return AppColors.warning;
      case FlightStatus.cancelled: return AppColors.error;
      case FlightStatus.departed:
      case FlightStatus.landed: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status.label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
