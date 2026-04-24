import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/date_format_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/airport.dart';
import '../providers/flight_results_provider.dart';
import '../providers/flight_search_provider.dart';
import 'flight_results_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flightSearchProvider);
    final notifier = ref.read(flightSearchProvider.notifier);
    final airportsAsync = ref.watch(airportsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Book a Flight'), pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TripTypeToggle(roundTrip: state.roundTrip, onChanged: notifier.setRoundTrip),
                const SizedBox(height: 20),
                _SearchCard(
                  state: state,
                  onFromTap: () => _pickAirport(context, ref, isFrom: true),
                  onToTap: () => _pickAirport(context, ref, isFrom: false),
                  onDateTap: () => _pickDate(context, ref),
                  onPassengersTap: () => _pickPassengers(context, ref),
                  onSwap: notifier.swap,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.canSearch
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FlightResultsScreen(
                                params: FlightSearchParams(
                                  fromCode: state.from!.code,
                                  toCode: state.to!.code,
                                  date: state.date,
                                ),
                                passengers: state.passengers,
                              ),
                            ),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppColors.surfaceElevated,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                  child: const Text('Search Flights'),
                ),
                const SizedBox(height: 32),
                const JsxText('POPULAR ROUTES', JsxTextVariant.labelSmall,
                    color: AppColors.textSecondary, letterSpacing: 1.5),
                const SizedBox(height: 12),
                AsyncBuilder(
                  value: airportsAsync,
                  data: (airports) => Column(
                    children: airports
                        .take(6)
                        .map((a) => _PopularRouteRow(airport: a, onTap: () => notifier.setTo(a)))
                        .toList(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAirport(BuildContext context, WidgetRef ref, {required bool isFrom}) async {
    final state = ref.read(flightSearchProvider);
    final airportsAsync = ref.read(airportsProvider);
    final allAirports = airportsAsync.valueOrNull ?? [];

    final result = await showModalBottomSheet<Airport>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AirportPicker(
        title: isFrom ? 'Flying From' : 'Flying To',
        airports: allAirports,
        exclude: isFrom ? state.to?.code : state.from?.code,
      ),
    );
    if (result != null) {
      final notifier = ref.read(flightSearchProvider.notifier);
      if (isFrom) {
        notifier.setFrom(result);
      } else {
        notifier.setTo(result);
      }
    }
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final state = ref.read(flightSearchProvider);
    final result = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold, onPrimary: AppColors.background, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (result != null) ref.read(flightSearchProvider.notifier).setDate(result);
  }

  void _pickPassengers(BuildContext context, WidgetRef ref) {
    final state = ref.read(flightSearchProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PassengerPicker(
        count: state.passengers,
        onChanged: ref.read(flightSearchProvider.notifier).setPassengers,
      ),
    );
  }
}

class _TripTypeToggle extends StatelessWidget {
  final bool roundTrip;
  final ValueChanged<bool> onChanged;
  const _TripTypeToggle({required this.roundTrip, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            _ToggleBtn(label: 'One Way', selected: !roundTrip, onTap: () => onChanged(false)),
            _ToggleBtn(label: 'Round Trip', selected: roundTrip, onTap: () => onChanged(true)),
          ],
        ),
      );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.background : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}

class _SearchCard extends StatelessWidget {
  final FlightSearchState state;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onDateTap;
  final VoidCallback onPassengersTap;
  final VoidCallback onSwap;

  const _SearchCard({
    required this.state,
    required this.onFromTap,
    required this.onToTap,
    required this.onDateTap,
    required this.onPassengersTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _FieldRow(
              icon: Icons.flight_takeoff,
              label: 'From',
              value: state.from != null ? '${state.from!.city} (${state.from!.code})' : 'Select city',
              hasValue: state.from != null,
              onTap: onFromTap,
              trailing: GestureDetector(
                onTap: onSwap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
                  child: const Icon(Icons.swap_vert, color: AppColors.gold, size: 16),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _FieldRow(
              icon: Icons.flight_land,
              label: 'To',
              value: state.to != null ? '${state.to!.city} (${state.to!.code})' : 'Select city',
              hasValue: state.to != null,
              onTap: onToTap,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _FieldRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: state.date.mediumDate,
              hasValue: true,
              onTap: onDateTap,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _FieldRow(
              icon: Icons.person_outline,
              label: 'Passengers',
              value: '${state.passengers} passenger${state.passengers > 1 ? 's' : ''}',
              hasValue: true,
              onTap: onPassengersTap,
            ),
          ],
        ),
      );
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FieldRow({required this.icon, required this.label, required this.value, required this.hasValue, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JsxText(label, JsxTextVariant.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: hasValue ? AppColors.white : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      );
}

class _AirportPicker extends StatelessWidget {
  final String title;
  final List<Airport> airports;
  final String? exclude;

  const _AirportPicker({required this.title, required this.airports, this.exclude});

  @override
  Widget build(BuildContext context) {
    final filtered = airports.where((a) => a.code != exclude).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              JsxText(title, JsxTextVariant.headlineMedium),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Divider(height: 1),
        ...filtered.map((a) => ListTile(
              onTap: () => Navigator.pop(context, a),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(a.code, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w800))),
              ),
              title: JsxText(a.city, JsxTextVariant.titleMedium),
              subtitle: JsxText(a.name, JsxTextVariant.bodySmall),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _PassengerPicker extends StatefulWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _PassengerPicker({required this.count, required this.onChanged});

  @override
  State<_PassengerPicker> createState() => _PassengerPickerState();
}

class _PassengerPickerState extends State<_PassengerPicker> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.count;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            JsxText('Passengers', JsxTextVariant.headlineMedium),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CountBtn(icon: Icons.remove, onTap: _count > 1 ? () { setState(() => _count--); widget.onChanged(_count); } : null),
                const SizedBox(width: 32),
                JsxText('$_count', JsxTextVariant.displayLarge),
                const SizedBox(width: 32),
                _CountBtn(icon: Icons.add, onTap: _count < 8 ? () { setState(() => _count++); widget.onChanged(_count); } : null),
              ],
            ),
            const SizedBox(height: 8),
            const JsxText('Max 8 passengers', JsxTextVariant.bodySmall),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: onTap != null ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: onTap != null ? AppColors.gold : AppColors.divider),
          ),
          child: Icon(icon, color: onTap != null ? AppColors.gold : AppColors.textMuted, size: 20),
        ),
      );
}

class _PopularRouteRow extends StatelessWidget {
  final Airport airport;
  final VoidCallback onTap;
  const _PopularRouteRow({required this.airport, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(airport.code, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800))),
          ),
          title: JsxText(airport.city, JsxTextVariant.titleMedium),
          subtitle: JsxText(airport.name, JsxTextVariant.labelSmall),
          trailing: const Icon(Icons.north_east, color: AppColors.textMuted, size: 16),
        ),
      );
}
