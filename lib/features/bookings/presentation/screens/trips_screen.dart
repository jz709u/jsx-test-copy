import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';
import '../../../flights/presentation/widgets/flight_route_display.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.gold,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
        data: (bookings) {
          final upcoming = bookings.where((b) => b.isUpcoming).toList();
          final past = bookings.where((b) => b.isPast).toList();
          return TabBarView(
            controller: _tab,
            children: [
              _TripList(bookings: upcoming, empty: const _EmptyState(icon: Icons.flight_takeoff, title: 'No upcoming trips', subtitle: 'Book your next adventure with JSX')),
              _TripList(bookings: past, empty: const _EmptyState(icon: Icons.history, title: 'No past trips', subtitle: 'Your completed flights will appear here')),
            ],
          );
        },
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<Booking> bookings;
  final Widget empty;
  const _TripList({required this.bookings, required this.empty});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return empty;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(booking: booking))),
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('EEE, MMM d, yyyy').format(booking.flight.departureTime), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        _BookingStatusBadge(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FlightRouteDisplay(flight: booking.flight, compact: true),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(booking.confirmationCode, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${booking.passengers.length} pax', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 16),
                        Text('\$${booking.totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _BookingStatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case BookingStatus.confirmed: return AppColors.success;
      case BookingStatus.checkedIn: return AppColors.gold;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.completed: return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (status) {
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.checkedIn: return 'Checked In';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.completed: return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(_label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      );
}
