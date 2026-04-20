import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/flight.dart';

class FlightRouteDisplay extends StatelessWidget {
  final Flight flight;
  final bool compact;

  const FlightRouteDisplay({super.key, required this.flight, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('h:mm a');
    return Row(
      children: [
        _AirportCol(
          code: flight.origin.code,
          city: flight.origin.city,
          time: timeFmt.format(flight.departureTime),
          compact: compact,
          align: CrossAxisAlignment.start,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                flight.durationString,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                  Expanded(child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.4))),
                  const Icon(Icons.flight, color: AppColors.gold, size: 14),
                  Expanded(child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.4))),
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Nonstop',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: compact ? 9 : 10,
                ),
              ),
            ],
          ),
        ),
        _AirportCol(
          code: flight.destination.code,
          city: flight.destination.city,
          time: timeFmt.format(flight.arrivalTime),
          compact: compact,
          align: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

class _AirportCol extends StatelessWidget {
  final String code;
  final String city;
  final String time;
  final bool compact;
  final CrossAxisAlignment align;

  const _AirportCol({required this.code, required this.city, required this.time, required this.compact, required this.align});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          time,
          style: TextStyle(color: AppColors.white, fontSize: compact ? 14 : 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        const SizedBox(height: 2),
        Text(
          code,
          style: TextStyle(color: AppColors.gold, fontSize: compact ? 18 : 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        Text(city, style: TextStyle(color: AppColors.textSecondary, fontSize: compact ? 10 : 12)),
      ],
    );
  }
}
