import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/bookings/presentation/providers/bookings_provider.dart';
import '../../features/bookings/presentation/screens/trip_detail_screen.dart';
import '../../features/flights/presentation/screens/flight_tracking_screen.dart';
import '../../features/flights/services/navigation_service.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/flights/presentation/screens/search_screen.dart';
import '../../features/bookings/presentation/screens/trips_screen.dart';
import '../../features/user/presentation/screens/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    TripsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for a pending route from intents on cold start
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingRoute());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPendingRoute();
  }

  Future<void> _checkPendingRoute() async {
    final route = await NavigationService.getPendingRoute();
    if (route == null || !mounted) return;

    if (route == 'search' || route.startsWith('search?')) {
      setState(() => _index = 1);
      // TODO: parse from/to params and pre-fill search when SearchScreen supports it
    } else if (route == 'boarding-pass' || route == 'track' || route.startsWith('booking/')) {
      setState(() => _index = 2); // My Trips tab
      _navigateFromTripsRoute(route);
    }
  }

  void _navigateFromTripsRoute(String route) {
    final bookingsAsync = ref.read(bookingsProvider);
    bookingsAsync.whenData((bookings) {
      final upcoming = bookings.where((b) => b.isUpcoming).toList()
        ..sort((a, b) => a.flight.departureTime.compareTo(b.flight.departureTime));
      if (upcoming.isEmpty) return;

      if (route == 'track') {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FlightTrackingScreen(
            flight: upcoming.first.flight,
            confirmationCode: upcoming.first.confirmationCode,
          ),
        ));
      } else if (route == 'boarding-pass' || route.startsWith('booking/')) {
        final code = route.startsWith('booking/')
            ? route.replaceFirst('booking/', '')
            : upcoming.first.confirmationCode;
        final booking = bookings.firstWhere(
          (b) => b.confirmationCode == code,
          orElse: () => upcoming.first,
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TripDetailScreen(booking: booking),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search_rounded), label: 'Book'),
            BottomNavigationBarItem(icon: Icon(Icons.flight_outlined), activeIcon: Icon(Icons.flight_rounded), label: 'My Trips'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
