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
  Timer? _poll;
  final Set<int> _seenPendingIds = {};
  bool _firstLoad = true;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final future = DeliveryService.dashboard();
    if (!silent) setState(() => _future = future);
    try {
      final data = await future;
      _checkForNewOrders(data.pendingOrders);
      if (silent && mounted) setState(() => _future = Future.value(data));
    } catch (_) {
      // silent polling failures shouldn't interrupt whatever's on screen
    }
  }

  void _checkForNewOrders(List<DeliveryOrder> pending) {
    final partner = context.read<AppState>().partner;
    final ids = pending.map((o) => o.id).toSet();
    if (_firstLoad) {
      // Don't pop up for orders that were already pending before this
      // screen opened - only genuinely new ones.
      _seenPendingIds.addAll(ids);
      _firstLoad = false;
      return;
    }
    final newIds = ids.difference(_seenPendingIds);
    _seenPendingIds.addAll(ids);
    if (newIds.isNotEmpty && (partner?.isAvailable ?? false) && !_popupShowing && mounted) {
      _popupShowing = true;
      openOrder(context, newIds.first).whenComplete(() => _popupShowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      drawer: _AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
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
                      _QuickActions(),
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
      children: [
        Builder(
          builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
        Expanded(
          child: Text(
            partnerName == null ? 'Hello, Partner 👋' : 'Hello, ${partnerName!.split(' ').first} 👋',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(isAvailable ? 'Online' : 'Offline', style: TextStyle(color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Earnings", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${earnings.todayEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
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
        Expanded(child: _StatBox(value: '${earnings.completedToday}', label: 'Orders Delivered', icon: Icons.inventory_2_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(value: '$activeCount', label: 'Ongoing', icon: Icons.pending_actions_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(value: rating > 0 ? rating.toStringAsFixed(1) : '—', label: 'Rating', icon: Icons.star_border)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatBox({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.receipt_long_outlined, 'My Orders', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
      (Icons.currency_rupee, 'Earnings', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EarningsScreen()))),
      (Icons.account_balance_wallet_outlined, 'Wallet', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()))),
      (Icons.person_outline, 'Profile', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        const SizedBox(height: 12),
        Row(
          children: items
              .map((it) => Expanded(
                    child: InkWell(
                      onTap: it.$3,
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(it.$1, color: AppTheme.primary)),
                          const SizedBox(height: 6),
                          Text(it.$2, style: const TextStyle(fontSize: 11.5), textAlign: TextAlign.center),
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
