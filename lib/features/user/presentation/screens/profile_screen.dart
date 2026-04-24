import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/ref_ext.dart';
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
  Future<void> _refresh() => ref.invalidateAndAwait(currentUserProvider);

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      body: AsyncBuilder(
        value: userAsync,
        data: (user) => _ProfileBody(user: user, onRefresh: _refresh),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final User user;
  final Future<void> Function() onRefresh;
  const _ProfileBody({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) => RefreshIndicator(
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
                  JsxListGroup(items: [
                    JsxListItem(icon: Icons.airline_seat_recline_normal, label: 'Preferred Seat', value: user.preferredSeat, onTap: () {}),
                    JsxListItem(icon: Icons.badge_outlined, label: 'Known Traveler Number', value: user.knownTravelerNumber ?? 'Not set', onTap: () {}),
                    JsxListItem(icon: Icons.notifications_outlined, label: 'Flight Alerts', value: 'Push & Email', onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('Account'),
                  const SizedBox(height: 10),
                  JsxListGroup(items: [
                    JsxListItem(icon: Icons.person_outline, label: 'Personal Info', value: user.email, onTap: () {}),
                    JsxListItem(icon: Icons.credit_card_outlined, label: 'Payment Methods', value: 'Visa •••• 4821', onTap: () {}),
                    JsxListItem(icon: Icons.lock_outline, label: 'Security', onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  const _SectionLabel('Support'),
                  const SizedBox(height: 10),
                  JsxListGroup(items: [
                    JsxListItem(icon: Icons.help_outline, label: 'Help Center', onTap: () {}),
                    JsxListItem(icon: Icons.chat_bubble_outline, label: 'Contact JSX', onTap: () {}),
                    JsxListItem(icon: Icons.star_outline, label: 'Rate the App', onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  JsxListGroup(items: [
                    JsxListItem(icon: Icons.logout, label: 'Sign Out', labelColor: AppColors.error, onTap: () {}, showChevron: false),
                  ]),
                  const SizedBox(height: 32),
                  const Center(child: JsxText('JSX: How I Fly v1.0.0', JsxTextVariant.bodySmall)),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
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
                JsxAvatar(
                  label: user.initials,
                  size: 72,
                  variant: JsxTextVariant.headlineLarge,
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 3),
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
                Expanded(child: JsxStatDisplay(value: '\$${user.creditBalance.toStringAsFixed(0)}', label: 'Available Credit', valueColor: AppColors.gold)),
                Container(width: 1, height: 48, color: AppColors.divider),
                Expanded(child: JsxStatDisplay(value: user.loyaltyPoints.toString(), label: 'Total Points')),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => JsxText(
        label.toUpperCase(), JsxTextVariant.labelSmall,
        color: AppColors.textSecondary, letterSpacing: 1.2,
      );
}

