// Deprecated — use JsxBadge.flightStatus() from core/widgets/widgets.dart.
export '../../../../core/widgets/jsx_badge.dart' show JsxBadge;

import 'package:flutter/material.dart';
import '../../../../core/widgets/jsx_badge.dart';
import '../../domain/entities/flight.dart';

@Deprecated('Use JsxBadge.flightStatus(status) instead')
class StatusBadge extends StatelessWidget {
  final FlightStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) => JsxBadge.flightStatus(status);
}
