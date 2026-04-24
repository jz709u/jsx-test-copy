import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../flights/presentation/providers/flight_realtime_provider.dart';
import '../../../flights/presentation/widgets/flight_route_display.dart';
import '../../../user/domain/entities/user.dart';
import '../../../user/presentation/providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    // Rebuild every minute so countdown labels stay accurate.
    ref.watch(minuteTickerProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: JsxText('Error: $e', JsxTextVariant.bodyMedium, color: AppColors.error)),
        data: (user) => bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => Center(child: JsxText('Error: $e', JsxTextVariant.bodyMedium, color: AppColors.error)),
          data: (bookings) => _HomeBody(
          user: user,
          bookings: bookings,
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(bookingsProvider);
            await Future.wait([
              ref.read(currentUserProvider.future),
              ref.read(bookingsProvider.future),
            ]);
          },
        ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final User user;
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;

  const _HomeBody({required this.user, required this.bookings, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final upcoming = bookings.where((b) => b.isUpcoming).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JsxText('Good ${_greeting()}, ${user.firstName}',
                    JsxTextVariant.headlineLarge),
                JsxText(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    JsxTextVariant.labelMedium),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                child: Center(
                  child: JsxText(user.initials, JsxTextVariant.titleMedium, color: AppColors.background),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (upcoming.isNotEmpty) ...[
                _NextFlightCard(booking: upcoming.first)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 28),
              ],
              JsxSectionHeader(title: 'Upcoming Trips', count: upcoming.length),
              const SizedBox(height: AppSpacing.itemGap),
              ...upcoming.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                    child: _UpcomingBookingCard(booking: b),
                  )),
              const SizedBox(height: AppSpacing.sectionGap),
              _LoyaltyCard(user: user)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.sectionGap),
              const JsxSectionHeader(title: 'Popular Routes'),
              const SizedBox(height: 12),
              const _PopularRoutesGrid(),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _NextFlightCard extends StatelessWidget {
  final Booking booking;
  const _NextFlightCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final diff = booking.flight.departureTime.difference(DateTime.now());
    final daysLeft = diff.inDays;
    final hoursLeft = diff.inHours.remainder(24);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2A1F00), Color(0xFF1A1B25)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const JsxText('NEXT FLIGHT', JsxTextVariant.labelSmall, color: AppColors.gold, letterSpacing: 1.5),
              JsxBadge.flightStatus(booking.flight.status),
            ],
          ),
          const SizedBox(height: 20),
          FlightRouteDisplay(flight: booking.flight),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              JsxChip(icon: Icons.confirmation_number_outlined, label: booking.confirmationCode),
              const SizedBox(width: AppSpacing.itemGap),
              JsxChip(
                icon: Icons.access_time_rounded,
                label: daysLeft > 0 ? '$daysLeft days, ${hoursLeft}h away' : '${diff.inHours}h ${diff.inMinutes.remainder(60)}m away',
              ),
            ],
          ),
          if (booking.seatNumber != null) ...[
            const SizedBox(height: 10),
            JsxChip(icon: Icons.airline_seat_recline_normal, label: 'Seat ${booking.seatNumber}'),
          ],
        ],
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final Booking booking;
  const _UpcomingBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) => JsxCard(
        child: Column(
          children: [
            FlightRouteDisplay(flight: booking.flight, compact: true),
            const SizedBox(height: AppSpacing.itemGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                JsxText(DateFormat('MMM d, yyyy').format(booking.flight.departureTime),
                    JsxTextVariant.bodySmall),
                JsxText(booking.confirmationCode, JsxTextVariant.labelMedium,
                    color: AppColors.gold, letterSpacing: 1),
              ],
            ),
          ],
        ),
      );
}

class _LoyaltyCard extends StatelessWidget {
  final User user;
  const _LoyaltyCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A2040), Color(0xFF0D1220)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const JsxText('CLUB JSX', JsxTextVariant.labelSmall, color: AppColors.gold, letterSpacing: 1.5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const JsxText('Member', JsxTextVariant.labelSmall, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _LoyaltyStat(value: '\$${user.creditBalance.toStringAsFixed(0)}', label: 'JSX Credit')),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(child: _LoyaltyStat(value: user.loyaltyPoints.toString(), label: 'Points Earned')),
              Container(width: 1, height: 40, color: AppColors.divider),
              const Expanded(child: _LoyaltyStat(value: '5%', label: 'Back on Flights')),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (user.loyaltyPoints % 1000) / 1000,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          JsxText('${1000 - (user.loyaltyPoints % 1000)} points to next reward', JsxTextVariant.labelSmall),
        ],
      ),
    );
  }
}

class _LoyaltyStat extends StatelessWidget {
  final String value;
  final String label;
  const _LoyaltyStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          JsxText(value, JsxTextVariant.headlineLarge),
          const SizedBox(height: 2),
          JsxText(label, JsxTextVariant.caption, textAlign: TextAlign.center),
        ],
      );
}

class _PopularRoutesGrid extends StatelessWidget {
  const _PopularRoutesGrid();

  static const _routes = [
    ('DAL', 'BUR', 'Dallas → LA'),
    ('BUR', 'DAL', 'LA → Dallas'),
    ('DAL', 'LAS', 'Dallas → Vegas'),
    ('DAL', 'OAK', 'Dallas → Oakland'),
    ('AUS', 'DAL', 'Austin → Dallas'),
    ('LAS', 'BUR', 'Vegas → LA'),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: _routes.map((r) => JsxChip.nav(label: r.$3)).toList(),
      );
}
