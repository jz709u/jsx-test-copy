import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/booking.dart';
import '../providers/bookings_provider.dart';
import '../../../flights/presentation/widgets/flight_route_display.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with SingleTickerProviderStateMixin {
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

  Future<void> _refresh() async {
    ref.invalidate(bookingsProvider);
    await ref.read(bookingsProvider.future);
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
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: JsxText('$e', JsxTextVariant.bodyMedium, color: AppColors.error)),
        data: (bookings) {
          final sortedBookings = bookings
            ..sort((a, b) =>
                a.flight.departureTime.compareTo(b.flight.departureTime));
          final upcoming = sortedBookings.where((b) => b.isUpcoming).toList();
          final past = sortedBookings.where((b) => b.isPast).toList();
          return TabBarView(
            controller: _tab,
            children: [
              _TripList(
                  bookings: upcoming,
                  onRefresh: _refresh,
                  empty: const _EmptyState(
                      icon: Icons.flight_takeoff,
                      title: 'No upcoming trips',
                      subtitle: 'Book your next adventure with JSX')),
              _TripList(
                  bookings: past,
                  onRefresh: _refresh,
                  empty: const _EmptyState(
                      icon: Icons.history,
                      title: 'No past trips',
                      subtitle: 'Your completed flights will appear here')),
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
  final Future<void> Function() onRefresh;
  const _TripList(
      {required this.bookings, required this.empty, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [SliverFillRemaining(child: empty)],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) => JsxCard(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TripDetailScreen(booking: booking))),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      JsxText(
                          DateFormat('EEE, MMM d, yyyy')
                              .format(booking.flight.departureTime),
                          JsxTextVariant.bodySmall),
                      JsxBadge.bookingStatus(booking.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FlightRouteDisplay(flight: booking.flight, compact: true),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: AppSpacing.itemGap),
              decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(AppRadius.card))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      JsxText(booking.confirmationCode, JsxTextVariant.labelMedium,
                          color: AppColors.gold, letterSpacing: 1),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      JsxText('${booking.passengers.length} pax',
                          JsxTextVariant.bodySmall),
                      const SizedBox(width: AppSpacing.lg),
                      JsxText('\$${booking.totalPaid.toStringAsFixed(0)}',
                          JsxTextVariant.titleSmall),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.arrow_forward_ios,
                          size: 11, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => JsxEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
      );
}
