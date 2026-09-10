import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';
import '../orders/order_flow_router.dart';
import '../orders/my_orders_screen.dart';
import '../home/earnings_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/app_error_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _future;
  Future<List<DeliveryOrder>>? _recentActivity;

  Timer? _poll;
  bool _popupShowing = false;
  bool? _lastKnownAvailability;

  static const _fastPoll = Duration(seconds: 2);
  static const _slowPoll = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();

    _refresh();
    _refreshRecentActivity();
    _scheduleNextPoll();

    context.read<AppState>().addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    final isAvailable =
        context.read<AppState>().partner?.isAvailable ?? false;

    if (_lastKnownAvailability == isAvailable) return;

    _lastKnownAvailability = isAvailable;

    _poll?.cancel();

    _refresh(silent: true);
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    final isAvailable =
        context.read<AppState>().partner?.isAvailable ?? false;

    _lastKnownAvailability = isAvailable;

    final interval =
        (isAvailable && !_popupShowing) ? _fastPoll : _slowPoll;

    _poll = Timer(interval, () async {
      await _refresh(silent: true);

      if (mounted) {
        _scheduleNextPoll();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    context.read<AppState>().removeListener(_onAppStateChanged);
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final future = DeliveryService.dashboard();

    if (!silent && mounted) {
      setState(() => _future = future);
    }

    try {
      final data = await future;

      _checkForPendingOrder(data.pendingOrders);

      if (silent && mounted) {
        setState(() {
          _future = Future.value(data);
        });
      }
    } catch (_) {
      // Silent polling failure intentionally ignored.
    }
  }

  Future<void> _refreshRecentActivity() async {
    final future = DeliveryService.myOrders('delivered');

    if (mounted) {
      setState(() => _recentActivity = future);
    }
  }

  void _checkForPendingOrder(List<DeliveryOrder> pending) {
    final isAvailable =
        context.read<AppState>().partner?.isAvailable ?? false;

    if (pending.isEmpty ||
        !isAvailable ||
        _popupShowing ||
        !mounted) {
      return;
    }

    _popupShowing = true;

    openOrder(
      context,
      pending.first.id,
    ).whenComplete(() {
      _popupShowing = false;
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refresh(),
      _refreshRecentActivity(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      drawer: const _AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            children: [
              _TopBar(
                partnerName: partner?.name,
                isAvailable: partner?.isAvailable ?? false,
              ),

              const SizedBox(height: 22),

              FutureBuilder<DashboardData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      snap.data == null) {
                    return const _DashboardLoader();
                  }

                  if (snap.hasError && snap.data == null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: AppErrorView(
                        error: snap.error!,
                        onRetry: _refresh,
                      ),
                    );
                  }

                  if (!snap.hasData) {
                    return const _DashboardLoader();
                  }

                  final data = snap.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EarningsCard(
                        earnings: data.earnings,
                        isOnline: partner?.isAvailable ?? false,
                      ),

                      const SizedBox(height: 22),

                      const _SectionTitle(
                        title: 'Performance',
                        subtitle: 'Your delivery overview',
                      ),

                      const SizedBox(height: 12),

                      _StatsGrid(
                        earnings: data.earnings,
                        activeCount: data.activeOrders.length,
                        rating: partner?.rating ?? 0,
                      ),

                      const SizedBox(height: 24),

                      const _QuickActions(),

                      const SizedBox(height: 24),

                      _RecentActivity(
                        future: _recentActivity,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   LOADER
============================================================ */

class _DashboardLoader extends StatelessWidget {
  const _DashboardLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading your dashboard...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   TOP BAR
============================================================ */

class _TopBar extends StatelessWidget {
  final String? partnerName;
  final bool isAvailable;

  const _TopBar({
    required this.partnerName,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = partnerName == null
        ? 'Partner'
        : partnerName!.trim().split(' ').first;

    return Row(
      children: [
        Builder(
          builder: (context) {
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF292929),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good day, $firstName 👋',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                isAvailable
                    ? 'You are ready to receive orders'
                    : 'Go online to receive orders',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        _AvailabilityPill(
          isAvailable: isAvailable,
        ),
      ],
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityPill({
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        right: 3,
        top: 3,
        bottom: 3,
      ),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFFEAF8EF)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFFC8EBD4)
              : const Color(0xFFE3E3E3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF20A653)
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Online' : 'Offline',
            style: TextStyle(
              color: isAvailable
                  ? const Color(0xFF16863F)
                  : Colors.grey.shade700,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Transform.scale(
            scale: .72,
            child: Switch(
              value: isAvailable,
              activeThumbColor: const Color(0xFF20A653),
              activeTrackColor: const Color(0xFFBCE8CA),
              onChanged: (_) async {
                try {
                  await context
                      .read<AppState>()
                      .toggleAvailability();
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('$e'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   EARNINGS CARD
============================================================ */

class _EarningsCard extends StatelessWidget {
  final EarningsSummary earnings;
  final bool isOnline;

  const _EarningsCard({
    required this.earnings,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -15,
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.07),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 25,
            bottom: -35,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      "Today's Earnings",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Color(0xFF6BE28B),
                            size: 7,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                '₹${earnings.todayEarnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${earnings.completedToday} deliveries completed today',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                height: 1,
                color: Colors.white.withOpacity(.12),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _MiniEarningStat(
                    title: 'Deliveries',
                    value: '${earnings.completedToday}',
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(.15),
                  ),
                  _MiniEarningStat(
                    title: 'Status',
                    value: isOnline ? 'Working' : 'Offline',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniEarningStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniEarningStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   SECTION TITLE
============================================================ */

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   STATS GRID
============================================================ */

class _StatsGrid extends StatelessWidget {
  final EarningsSummary earnings;
  final int activeCount;
  final double rating;

  const _StatsGrid({
    required this.earnings,
    required this.activeCount,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          value: '${earnings.completedToday}',
          label: 'Orders Delivered',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppTheme.primary,
          footer: earnings.completedToday > 0
              ? '+${earnings.completedToday} today'
              : 'No deliveries yet',
        ),
        _StatCard(
          value: '$activeCount',
          label: 'Ongoing Orders',
          icon: Icons.delivery_dining_rounded,
          iconColor: Colors.blue,
          showArrow: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyOrdersScreen(),
              ),
            );
          },
        ),
        _StatCard(
          value: rating > 0 ? rating.toStringAsFixed(1) : '—',
          label: 'Partner Rating',
          icon: Icons.star_rounded,
          iconColor: AppTheme.gold,
          showArrow: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyOrdersScreen(),
              ),
            );
          },
        ),
        _StatCard(
          value: '₹0',
          label: "Today's Incentives",
          icon: Icons.card_giftcard_rounded,
          iconColor: Colors.purple,
          showArrow: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EarningsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? footer;
  final bool showArrow;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.footer,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.black.withOpacity(.035),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  if (showArrow)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),

              const Spacer(),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (footer != null) ...[
                const SizedBox(height: 3),
                Text(
                  footer!,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   QUICK ACTIONS
============================================================ */

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.receipt_long_rounded,
        'My Orders',
        'View & manage',
        AppTheme.primary,
        () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyOrdersScreen(),
              ),
            ),
      ),
      (
        Icons.currency_rupee_rounded,
        'Earnings',
        'Track your income',
        Colors.green,
        () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EarningsScreen(),
              ),
            ),
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Wallet',
        'Manage balance',
        Colors.blue,
        () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WalletScreen(),
              ),
            ),
      ),
      (
        Icons.person_rounded,
        'Profile',
        'Update details',
        Colors.purple,
        () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                title: 'Quick Actions',
                subtitle: 'Everything you need',
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.primary,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.05,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: item.$5,
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.black.withOpacity(.035),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.$4.withOpacity(.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          item.$1,
                          color: item.$4,
                          size: 21,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$3,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/* ============================================================
   RECENT ACTIVITY
============================================================ */

class _RecentActivity extends StatelessWidget {
  final Future<List<DeliveryOrder>>? future;

  const _RecentActivity({
    required this.future,
  });

  String _timeLabel(String? iso) {
    if (iso == null) return '';

    final dt = DateTime.tryParse(iso);

    if (dt == null) return '';

    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');

    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                title: 'Recent Activity',
                subtitle: 'Your latest completed deliveries',
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyOrdersScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.primary,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        FutureBuilder<List<DeliveryOrder>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration(),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              );
            }

            if (snap.hasError) {
              return const SizedBox.shrink();
            }

            final orders =
                (snap.data ?? []).take(3).toList();

            if (orders.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: AppTheme.primary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No deliveries yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed orders will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: orders.map((o) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8EF),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.green,
                          size: 21,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${o.orderCode}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              o.restaurantName,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _timeLabel(
                                    o.deliveredAt ?? o.placedAt,
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${o.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFEAF8EF),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Delivered',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.black.withOpacity(.035),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.035),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

/* ============================================================
   DRAWER
============================================================ */

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;

    return Drawer(
      backgroundColor: const Color(0xFFFFFBF8),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryDark,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Partner',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          partner?.name ?? 'Partner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            _DrawerItem(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              selected: true,
              onTap: () => Navigator.pop(context),
            ),

            _DrawerItem(
              icon: Icons.receipt_long_rounded,
              title: 'My Orders',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyOrdersScreen(),
                  ),
                );
              },
            ),

            _DrawerItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Wallet',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WalletScreen(),
                  ),
                );
              },
            ),

            _DrawerItem(
              icon: Icons.currency_rupee_rounded,
              title: 'Earnings',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EarningsScreen(),
                  ),
                );
              },
            ),

            _DrawerItem(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                color: Colors.grey.shade200,
              ),
            ),

            _DrawerItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              danger: true,
              onTap: () async {
                await AuthService.logout();

                if (!context.mounted) return;

                context.read<AppState>().clear();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.red
        : selected
            ? AppTheme.primary
            : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? AppTheme.primary.withOpacity(.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: selected || danger
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}