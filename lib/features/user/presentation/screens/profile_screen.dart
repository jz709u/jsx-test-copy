import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/user.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _refresh() async {
    ref.invalidate(currentUserProvider);
    await ref.read(currentUserProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold))),
      error: (e, _) => Scaffold(body: Center(child: JsxText('$e', JsxTextVariant.bodyMedium, color: AppColors.error))),
      data: (user) => _ProfileBody(user: user, onRefresh: _refresh),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final User user;
  final Future<void> Function() onRefresh;
  const _ProfileBody({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.gold,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(background: _ProfileHeader(user: user)),
              title: const Text('Profile'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ClubJsxCard(user: user),
                  const SizedBox(height: 24),
                  const _SectionLabel('Travel Preferences'),
                  const SizedBox(height: 10),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.airline_seat_recline_normal, label: 'Preferred Seat', value: user.preferredSeat, onTap: () {}),
                    _SettingsItem(icon: Icons.badge_outlined, label: 'Known Traveler Number', value: user.knownTravelerNumber ?? 'Not set', onTap: () {}),
                    _SettingsItem(icon: Icons.notifications_outlined, label: 'Flight Alerts', value: 'Push & Email', onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('Account'),
                  const SizedBox(height: 10),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.person_outline, label: 'Personal Info', value: user.email, onTap: () {}),
                    _SettingsItem(icon: Icons.credit_card_outlined, label: 'Payment Methods', value: 'Visa •••• 4821', onTap: () {}),
                    _SettingsItem(icon: Icons.lock_outline, label: 'Security', onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('Support'),
                  const SizedBox(height: 10),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.help_outline, label: 'Help Center', onTap: () {}),
                    _SettingsItem(icon: Icons.chat_bubble_outline, label: 'Contact JSX', onTap: () {}),
                    _SettingsItem(icon: Icons.star_outline, label: 'Rate the App', onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  _SettingsGroup(items: [
                    _SettingsItem(icon: Icons.logout, label: 'Sign Out', labelColor: AppColors.error, onTap: () {}, showChevron: false),
                  ]),
                  const SizedBox(height: 32),
                  const Center(child: JsxText('JSX: How I Fly v1.0.0', JsxTextVariant.bodySmall)),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
          ),
        ),
      );
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A2040), AppColors.background], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 3)),
                  child: Center(child: JsxText(user.initials, JsxTextVariant.headlineLarge, color: AppColors.background)),
                ),
                const SizedBox(height: 10),
                JsxText(user.fullName, JsxTextVariant.headlineLarge),
                JsxText(user.email, JsxTextVariant.titleSmall, color: AppColors.textSecondary),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: JsxText('Club JSX Member since ${user.memberSince}', JsxTextVariant.labelSmall, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ClubJsxCard extends StatelessWidget {
  final User user;
  const _ClubJsxCard({required this.user});

  @override
  Widget build(BuildContext context) => JsxGradientCard(
        colors: const [Color(0xFF252010), Color(0xFF1A1B25)],
        radius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                JsxText('CLUB JSX', JsxTextVariant.titleSmall, color: AppColors.gold, letterSpacing: 2),
                Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _Stat(value: '\$${user.creditBalance.toStringAsFixed(0)}', label: 'Available Credit', highlight: true)),
                Container(width: 1, height: 48, color: AppColors.divider),
                Expanded(child: _Stat(value: user.loyaltyPoints.toString(), label: 'Total Points')),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const JsxText('Earn 5% back on every flight', JsxTextVariant.labelMedium),
                const Spacer(),
                GestureDetector(child: const JsxText('Learn More', JsxTextVariant.labelMedium, color: AppColors.gold)),
              ],
            ),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  const _Stat({required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          JsxText(value, JsxTextVariant.headlineLarge, color: highlight ? AppColors.gold : AppColors.white),
          const SizedBox(height: 2),
          JsxText(label, JsxTextVariant.labelSmall, textAlign: TextAlign.center),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => JsxText(
        label.toUpperCase(), JsxTextVariant.labelSmall,
        color: AppColors.textSecondary, letterSpacing: 1.2,
      );
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(children: [e.value, if (!isLast) const Divider(height: 1, indent: 52)]);
          }).toList(),
        ),
      );
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsItem({required this.icon, required this.label, this.value, this.labelColor, required this.onTap, this.showChevron = true});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: labelColor ?? AppColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JsxText(label, JsxTextVariant.titleMedium, color: labelColor),
                    if (value != null) ...[const SizedBox(height: 1), JsxText(value!, JsxTextVariant.bodySmall)],
                  ],
                ),
              ),
              if (showChevron) const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}
