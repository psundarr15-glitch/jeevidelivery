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

  // While online and not already showing a pending-order popup, poll
  // fast so orders surface within ~2s — both a brand new order and any
  // of a backlog of already-pending ones (see _checkForPendingOrder:
  // as long as the partner is online and nothing is on screen, whatever
  // is next in the pending list gets shown, so a partner works through
  // all of them one after another instead of only ever seeing the
  // first one until they restart the app). Falls back to a slow poll
  // while offline since there's nothing time-sensitive to catch then.
  static const _fastPoll = Duration(seconds: 2);
  static const _slowPoll = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshRecentActivity();
    _scheduleNextPoll();
    // Without this, toggling online mid-wait doesn't take effect until
    // whatever slow-poll cycle was already scheduled finishes — up to
    // 20s of a partner sitting "online" but still on the old interval,
    // which is exactly the bug: a partner going online seconds after an
    // order was placed but not seeing it for ~20s. Reacting to the
    // toggle immediately (cancel + reschedule + refresh right away)
    // closes that gap instead of waiting for the next scheduled tick.
    context.read<AppState>().addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    final isAvailable = context.read<AppState>().partner?.isAvailable ?? false;
    if (_lastKnownAvailability == isAvailable) return;
    _lastKnownAvailability = isAvailable;
    _poll?.cancel();
    _refresh(silent: true);
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    final isAvailable = context.read<AppState>().partner?.isAvailable ?? false;
    _lastKnownAvailability = isAvailable;
    final interval = (isAvailable && !_popupShowing) ? _fastPoll : _slowPoll;
    _poll = Timer(interval, () async {
      await _refresh(silent: true);
      if (mounted) _scheduleNextPoll();
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
    if (!silent) setState(() => _future = future);
    try {
      final data = await future;
      _checkForPendingOrder(data.pendingOrders);
      if (silent && mounted) setState(() => _future = Future.value(data));
    } catch (_) {
      // silent polling failures shouldn't interrupt whatever's on screen
    }
  }

  Future<void> _refreshRecentActivity() async {
    final future = DeliveryService.myOrders('delivered');
    setState(() => _recentActivity = future);
  }

  /// Shows the next pending order whenever the partner is online and
  /// nothing is currently on screen — deliberately NOT "only the first
  /// one ever seen": accepting or rejecting an order removes it from
  /// this list on the next poll (accepted → assigned to someone,
  /// rejected → excluded for this partner), so as long as more remain,
  /// the next poll shows the next one. That's what makes working
  /// through a backlog of several pending orders work without having
  /// to restart the app between each one.
  void _checkForPendingOrder(List<DeliveryOrder> pending) {
    final isAvailable = context.read<AppState>().partner?.isAvailable ?? false;
    if (pending.isEmpty || !isAvailable || _popupShowing || !mounted) return;
    _popupShowing = true;
    openOrder(context, pending.first.id).whenComplete(() => _popupShowing = false);
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refresh(), _refreshRecentActivity()]);
  }

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      drawer: _AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _TopBar(partnerName: partner?.name, isAvailable: partner?.isAvailable ?? false),
              const SizedBox(height: 18),
              FutureBuilder<DashboardData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
                    return const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()));
                  }
                  if (snap.hasError && snap.data == null) {
                    return Padding(padding: const EdgeInsets.only(top: 40), child: AppErrorView(error: snap.error!, onRetry: _refresh));
                  }
                  final data = snap.data!;
                  return Column(
                    children: [
                      _EarningsCard(earnings: data.earnings),
                      const SizedBox(height: 14),
                      _StatsRow(earnings: data.earnings, activeCount: data.activeOrders.length, rating: partner?.rating ?? 0),
                      const SizedBox(height: 22),
                      const _QuickActions(),
                      const SizedBox(height: 22),
                      _RecentActivity(future: _recentActivity),
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

class _TopBar extends StatelessWidget {
  final String? partnerName;
  final bool isAvailable;
  const _TopBar({required this.partnerName, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName == null ? 'Hello, Partner 👋' : 'Hello, ${partnerName!.split(' ').first} 👋',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isAvailable ? 'Keep going! More deliveries, more earnings.' : 'Go online to receive delivery requests.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.only(left: 12, right: 2),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isAvailable ? 'Online' : 'Offline', style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
              Switch(
                value: isAvailable,
                activeThumbColor: Colors.green,
                onChanged: (_) async {
                  try {
                    await context.read<AppState>().toggleAvailability();
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final EarningsSummary earnings;
  const _EarningsCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primary, AppTheme.primaryDark]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x33D6291B), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text("Today's Earnings", style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text('₹${earnings.todayEarnings.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text('${earnings.completedToday} deliveries completed today', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final EarningsSummary earnings;
  final int activeCount;
  final double rating;
  const _StatsRow({required this.earnings, required this.activeCount, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            value: '${earnings.completedToday}',
            label: 'Orders Delivered',
            icon: Icons.inventory_2_outlined,
            iconColor: AppTheme.primary,
            footer: earnings.completedToday > 0 ? '+${earnings.completedToday} today' : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '$activeCount',
            label: 'Ongoing',
            icon: Icons.pending_actions_outlined,
            iconColor: Colors.blue,
            showChevron: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: rating > 0 ? rating.toStringAsFixed(1) : '—',
            label: 'Rating',
            icon: Icons.star_rounded,
            iconColor: AppTheme.gold,
            showChevron: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            // No incentive/bonus mechanism exists on the backend yet —
            // shown honestly as ₹0 rather than a made-up number, same
            // approach as the Earnings screen's Incentives row.
            value: '₹0',
            label: "Today's Incentives",
            icon: Icons.card_giftcard,
            iconColor: Colors.purple,
            showChevron: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EarningsScreen())),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? footer;
  final bool showChevron;
  final VoidCallback? onTap;
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.footer,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5), overflow: TextOverflow.ellipsis)),
                if (showChevron) Icon(Icons.chevron_right, size: 13, color: Colors.grey.shade400),
              ],
            ),
            if (footer != null) Text(footer!, style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.receipt_long_outlined, 'My Orders', 'View & manage', Colors.red, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
      (Icons.currency_rupee, 'Earnings', 'Track your income', Colors.green, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EarningsScreen()))),
      (Icons.account_balance_wallet_outlined, 'Wallet', 'Manage balance', Colors.blue, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()))),
      (Icons.person_outline, 'Profile', 'Update details', Colors.purple, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: items
              .map((it) => InkWell(
                    onTap: it.$5,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 20, backgroundColor: (it.$4 as Color).withOpacity(0.12), child: Icon(it.$1, color: it.$4 as Color, size: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(it.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                                Text(it.$3, style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final Future<List<DeliveryOrder>>? future;
  const _RecentActivity({required this.future});

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<DeliveryOrder>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return const SizedBox.shrink(); // non-critical widget — fail quietly, dashboard's main content still works
            }
            final orders = (snap.data ?? []).take(3).toList();
            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
                child: Center(child: Text('No deliveries yet — completed orders will show up here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5))),
              );
            }
            return Column(
              children: orders
                  .map((o) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE6F7EC), child: Icon(Icons.check, color: Colors.green, size: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#${o.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  Text(o.restaurantName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  Text(_timeLabel(o.deliveredAt ?? o.placedAt), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFE6F7EC), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Delivered', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 26, backgroundColor: AppTheme.primary, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(partner?.name ?? 'Partner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile'), onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Wallet'), onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService.logout();
                if (context.mounted) {
                  context.read<AppState>().clear();
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
