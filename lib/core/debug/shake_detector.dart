import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'debug_menu.dart';

class ShakeDetector extends StatefulWidget {
  final Widget child;

  const ShakeDetector({super.key, required this.child});

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime(0);

  static const _threshold   = 18.0; // m/s² — magnitude above which we count a shake
  static const _cooldownMs  = 1500; // ms between consecutive triggers

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(_onAccel);
  }

  void _onAccel(AccelerometerEvent e) {
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (magnitude < _threshold) return;

    final now = DateTime.now();
    if (now.difference(_lastShake).inMilliseconds < _cooldownMs) return;
    _lastShake = now;

    if (mounted) showDebugMenu(context);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
