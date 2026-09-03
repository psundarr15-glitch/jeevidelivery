import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../orders/order_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _future;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Light polling so newly-broadcast orders show up without a manual
    // pull-to-refresh — there's no push-notification channel for
    // delivery partners yet (see backend notes).
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
      if (silent && mounted) setState(() => _future = Future.value(data));
    } catch (_) {
      // silent polling failures shouldn't interrupt whatever's on screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              _AvailabilityBar(isAvailable: partner?.isAvailable ?? false),
              Expanded(
                child: FutureBuilder<DashboardData>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError && snap.data == null) {
                      return ListView(children: [
                        const SizedBox(height: 80),
                        Center(child: Text('${snap.error}', style: TextStyle(color: Colors.grey.shade600))),
                      ]);
                    }
                    final data = snap.data!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        _EarningsRow(earnings: data.earnings),
                        const SizedBox(height: 20),
                        if (data.activeOrders.isNotEmpty) ...[
                          const _SectionHeader('Active deliveries'),
                          ...data.activeOrders.map((o) => _OrderCard(order: o, mode: _CardMode.active, onChanged: _refresh)),
                          const SizedBox(height: 16),
                        ],
                        const _SectionHeader('New order requests'),
                        if (data.pendingOrders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                (partner?.isAvailable ?? false) ? 'No new orders right now — we\'ll show them here as they come in.' : 'You\'re offline. Go online to start receiving orders.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        else
                          ...data.pendingOrders.map((o) => _OrderCard(order: o, mode: _CardMode.pending, onChanged: _refresh)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBar extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBar({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.primary : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(isAvailable ? Icons.wifi_tethering : Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAvailable ? "You're online" : "You're offline",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5),
            ),
          ),
          Switch(
            value: isAvailable,
            activeThumbColor: Colors.white,
            onChanged: (_) async {
              try {
                await context.read<AppState>().toggleAvailability();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final EarningsSummary earnings;
  const _EarningsRow({required this.earnings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _EarningsCard(label: 'Today', value: '${earnings.completedToday}', sub: 'orders')),
        const SizedBox(width: 10),
        Expanded(child: _EarningsCard(label: 'This week', value: '₹${earnings.weeklyEarnings.toStringAsFixed(0)}', sub: '${earnings.weeklyOrders} orders')),
        const SizedBox(width: 10),
        Expanded(child: _EarningsCard(label: 'This month', value: '₹${earnings.monthlyEarnings.toStringAsFixed(0)}', sub: '${earnings.monthlyOrders} orders')),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _EarningsCard({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}

enum _CardMode { pending, active }

class _OrderCard extends StatefulWidget {
  final DeliveryOrder order;
  final _CardMode mode;
  final Future<void> Function() onChanged;
  const _OrderCard({required this.order, required this.mode, required this.onChanged});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await widget.onChanged();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
      ).then((_) => widget.onChanged()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(o.orderCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(o.restaurantName, style: const TextStyle(fontSize: 13.5)),
            Text('to ${o.customerName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            if (o.distanceKm != null) Text('${o.distanceKm!.toStringAsFixed(1)} km away', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 8),
            if (widget.mode == _CardMode.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _act(() => DeliveryService.rejectOrder(o.id)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _act(() => DeliveryService.acceptOrder(o.id)),
                      child: _busy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Accept'),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(o.orderStatus.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
