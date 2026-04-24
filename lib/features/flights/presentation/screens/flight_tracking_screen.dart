import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_track.dart';
import '../../services/live_activity_service.dart';
import '../providers/flight_track_provider.dart';

class FlightTrackingScreen extends ConsumerStatefulWidget {
  final Flight flight;
  final String confirmationCode;
  const FlightTrackingScreen({super.key, required this.flight, this.confirmationCode = ''});

  @override
  ConsumerState<FlightTrackingScreen> createState() => _FlightTrackingScreenState();
}

class _FlightTrackingScreenState extends ConsumerState<FlightTrackingScreen> {
  bool _liveActivityActive = false;
  FlightTrack? _lastTrack;

  @override
  void dispose() {
    // Don't end the Live Activity on navigation — let it persist on lock screen
    // until the user explicitly stops it or the flight ends.
    super.dispose();
  }

  Future<void> _toggleLiveActivity() async {
    if (_liveActivityActive) {
      await LiveActivityService.end(widget.flight.id);
      if (mounted) setState(() => _liveActivityActive = false);
    } else {
      final track = _lastTrack;
      if (track == null) return;
      await LiveActivityService.start(
        flight: widget.flight,
        track: track,
        confirmationCode: widget.confirmationCode,
      );
      if (mounted) setState(() => _liveActivityActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackAsync = ref.watch(flightTrackProvider(widget.flight));

    // Push updates to live activity whenever track changes
    trackAsync.whenData((track) {
      _lastTrack = track;
      if (_liveActivityActive) {
        LiveActivityService.update(
          flight: widget.flight,
          track: track,
          confirmationCode: widget.confirmationCode,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.flight.origin.code} → ${widget.flight.destination.code}'),
        actions: [
          // Live Activity toggle
          GestureDetector(
            onTap: _toggleLiveActivity,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (_liveActivityActive ? AppColors.gold : AppColors.surface).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_liveActivityActive ? AppColors.gold : AppColors.divider).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _liveActivityActive ? Icons.dynamic_feed_rounded : Icons.add_to_home_screen,
                    size: 13,
                    color: _liveActivityActive ? AppColors.gold : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _liveActivityActive ? 'Live' : 'Add to Lock Screen',
                    style: TextStyle(
                      color: _liveActivityActive ? AppColors.gold : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Live pulse badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle))
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 800.ms)
                    .then()
                    .fadeOut(duration: 800.ms),
                const SizedBox(width: 6),
                const JsxText('Live', JsxTextVariant.labelMedium, color: AppColors.success),
              ],
            ),
          ),
        ],
      ),
      body: AsyncBuilder(
        value: trackAsync,
        data: (track) => _TrackingBody(flight: widget.flight, track: track),
      ),
    );
  }
}


class _TrackingBody extends StatelessWidget {
  final Flight flight;
  final FlightTrack track;

  const _TrackingBody({required this.flight, required this.track});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _FlightPathCard(flight: flight, track: track),
          const SizedBox(height: 20),
          _PhaseCard(track: track),
          const SizedBox(height: 20),
          _StatsGrid(track: track),
          const SizedBox(height: 20),
          _EtaCard(flight: flight, track: track),
          const SizedBox(height: 20),
          _FlightInfoCard(flight: flight),
        ],
      ),
    );
  }
}

class _FlightPathCard extends StatelessWidget {
  final Flight flight;
  final FlightTrack track;

  const _FlightPathCard({required this.flight, required this.track});

  @override
  Widget build(BuildContext context) {
    return JsxGradientCard(
      colors: const [Color(0xFF0D1530), Color(0xFF1A2040)],
      borderAlpha: 0.2,
      radius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AirportLabel(code: flight.origin.code, city: flight.origin.city, align: CrossAxisAlignment.start),
              JsxText(flight.durationString, JsxTextVariant.labelMedium),
              _AirportLabel(code: flight.destination.code, city: flight.destination.city, align: CrossAxisAlignment.end),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _FlightPathPainter(progress: track.progress),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: track.progress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              JsxText('${(track.progress * 100).toStringAsFixed(0)}% complete',
                  JsxTextVariant.labelSmall),
              if (track.phase != FlightTrackPhase.landed && track.phase != FlightTrackPhase.preDeparture)
                JsxText('${track.minutesRemaining}m remaining',
                    JsxTextVariant.labelSmall, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlightPathPainter extends CustomPainter {
  final double progress;
  _FlightPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dashed arc path
    final pathPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, h * 0.8);
    path.quadraticBezierTo(w * 0.5, h * 0.05, w, h * 0.8);

    // Draw dashed path
    _drawDashedPath(canvas, path, pathPaint, dashLen: 6, gapLen: 4);

    // Completed portion (gold)
    final donePaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final donePath = Path();
    donePath.moveTo(0, h * 0.8);
    final ctrlX = w * 0.5;
    final ctrlY = h * 0.05;
    final endX = w * progress;
    final endY = _bezierY(progress, h * 0.8, ctrlY, h * 0.8);
    donePath.quadraticBezierTo(
      ctrlX * math.min(progress * 2, 1),
      ctrlY + (h * 0.8 - ctrlY) * math.max(0, progress * 2 - 1),
      endX,
      endY,
    );
    _drawDashedPath(canvas, donePath, donePaint, dashLen: 6, gapLen: 4);

    // Plane icon at current position
    if (progress > 0 && progress < 1) {
      final planeX = w * progress;
      final planeY = _bezierY(progress, h * 0.8, h * 0.05, h * 0.8);
      final angle = _bezierAngle(progress, h * 0.8, h * 0.05, h * 0.8, w);

      canvas.save();
      canvas.translate(planeX, planeY);
      canvas.rotate(angle);

      final planePaint = Paint()..color = AppColors.gold;
      // Simple triangle as plane
      final planePath = Path()
        ..moveTo(0, -10)
        ..lineTo(6, 8)
        ..lineTo(0, 4)
        ..lineTo(-6, 8)
        ..close();
      canvas.drawPath(planePath, planePaint);
      canvas.restore();
    }

    // Dot endpoints
    final dotPaint = Paint()..color = AppColors.gold;
    canvas.drawCircle(Offset(0, h * 0.8), 4, dotPaint);
    canvas.drawCircle(Offset(w, h * 0.8), 4, dotPaint);
  }

  double _bezierY(double t, double y0, double y1, double y2) {
    return (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * y1 + t * t * y2;
  }

  double _bezierAngle(double t, double y0, double ctrlY, double y2, double w) {
    final dx = w; // approximate horizontal velocity
    final dy = 2 * (1 - t) * (ctrlY - y0) + 2 * t * (y2 - ctrlY);
    return math.atan2(dy, dx);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dashLen, required double gapLen}) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = math.min(dist + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_FlightPathPainter old) => old.progress != progress;
}

class _AirportLabel extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment align;

  const _AirportLabel({required this.code, required this.city, required this.align});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: align,
        children: [
          JsxText(code, JsxTextVariant.headlineLarge, color: AppColors.gold, letterSpacing: -0.5),
          JsxText(city, JsxTextVariant.labelSmall, color: AppColors.textSecondary),
        ],
      );
}

class _PhaseCard extends StatelessWidget {
  final FlightTrack track;
  const _PhaseCard({required this.track});

  IconData get _icon {
    switch (track.phase) {
      case FlightTrackPhase.preDeparture: return Icons.schedule;
      case FlightTrackPhase.climbing: return Icons.flight_takeoff;
      case FlightTrackPhase.cruising: return Icons.flight;
      case FlightTrackPhase.descending: return Icons.flight_land;
      case FlightTrackPhase.landed: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return JsxCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderColor: AppColors.gold.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const JsxText('Current Phase', JsxTextVariant.labelSmall),
              const SizedBox(height: 2),
              JsxText(track.phase.label, JsxTextVariant.headlineMedium),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _StatsGrid extends StatelessWidget {
  final FlightTrack track;
  const _StatsGrid({required this.track});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _StatCard(
          icon: Icons.height,
          label: 'Altitude',
          value: track.altitudeFt > 0 ? '${(track.altitudeFt / 1000).toStringAsFixed(0)}k ft' : '—',
          sub: track.altitudeFt > 0 ? '${(track.altitudeFt * 0.3048 / 1000).toStringAsFixed(1)} km' : '',
        ),
        _StatCard(
          icon: Icons.speed,
          label: 'Speed',
          value: track.speedMph > 0 ? '${track.speedMph.toStringAsFixed(0)} mph' : '—',
          sub: track.speedMph > 0 ? '${(track.speedMph * 1.609).toStringAsFixed(0)} km/h' : '',
        ),
        _StatCard(
          icon: Icons.route,
          label: 'Distance Left',
          value: track.distanceRemainingMi > 0 ? '${track.distanceRemainingMi.toStringAsFixed(0)} mi' : '0 mi',
          sub: '${(track.distanceRemainingMi * 1.609).toStringAsFixed(0)} km',
        ),
        _StatCard(
          icon: Icons.flight_class,
          label: 'Flight',
          value: track.flightId,
          sub: 'Embraer E135',
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  const _StatCard({required this.icon, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return JsxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              JsxText(label, JsxTextVariant.labelSmall),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JsxText(value, JsxTextVariant.headlineSmall),
              if (sub.isNotEmpty)
                JsxText(sub, JsxTextVariant.caption, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _EtaCard extends StatelessWidget {
  final Flight flight;
  final FlightTrack track;

  const _EtaCard({required this.flight, required this.track});

  @override
  Widget build(BuildContext context) {
    final isLanded = track.phase == FlightTrackPhase.landed;
    final isPre = track.phase == FlightTrackPhase.preDeparture;

    return JsxGradientCard(
      colors: isLanded
          ? [const Color(0xFF0D2518), const Color(0xFF1A1B25)]
          : [const Color(0xFF2A1F00), const Color(0xFF1A1B25)],
      borderColor: isLanded ? AppColors.success : AppColors.gold,
      borderAlpha: 0.25,
      radius: 16,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            isLanded ? Icons.check_circle : (isPre ? Icons.schedule : Icons.access_time_rounded),
            color: isLanded ? AppColors.success : AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JsxText(
                  isLanded ? 'Arrived' : (isPre ? 'Departing in' : 'Estimated Arrival'),
                  JsxTextVariant.labelMedium,
                ),
                const SizedBox(height: 4),
                JsxText(
                  isLanded
                      ? flight.destination.city
                      : isPre
                          ? '${track.minutesRemaining} minutes'
                          : '${track.minutesRemaining} min · ${flight.destination.city}',
                  JsxTextVariant.headlineMedium,
                  color: isLanded ? AppColors.success : AppColors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }
}

class _FlightInfoCard extends StatelessWidget {
  final Flight flight;
  const _FlightInfoCard({required this.flight});

  @override
  Widget build(BuildContext context) {
    return JsxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const JsxText('FLIGHT INFO', JsxTextVariant.caption, letterSpacing: 1.2),
          const SizedBox(height: 12),
          JsxDetailRow('Aircraft', flight.aircraft, labelVariant: JsxTextVariant.titleSmall, labelColor: AppColors.textSecondary, valueFlexible: true),
          JsxDetailRow('Origin', '${flight.origin.name} (${flight.origin.code})', labelVariant: JsxTextVariant.titleSmall, labelColor: AppColors.textSecondary, valueFlexible: true),
          JsxDetailRow('Destination', '${flight.destination.name} (${flight.destination.code})', labelVariant: JsxTextVariant.titleSmall, labelColor: AppColors.textSecondary, valueFlexible: true),
          JsxDetailRow('Seats', '${flight.availableSeats} of ${flight.totalSeats} available', labelVariant: JsxTextVariant.titleSmall, labelColor: AppColors.textSecondary, valueFlexible: true),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }
}

