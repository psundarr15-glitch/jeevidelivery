import 'package:flutter/material.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import '../wallet/wallet_screen.dart';
import '../../widgets/app_error_view.dart';

enum _Period { daily, weekly, monthly }

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<DashboardData> _future;
  _Period _period = _Period.daily;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.dashboard();
  }

  Future<void> _refresh() async {
    setState(() => _future = DeliveryService.dashboard());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Earnings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return ListView(children: [const SizedBox(height: 40), AppErrorView(error: snap.error!, onRetry: _refresh)]);
            final e = snap.data!.earnings;

            final double amount;
            final int orders;
            final String label;
            switch (_period) {
              case _Period.daily:
                amount = e.todayEarnings; orders = e.completedToday; label = "Today's Earnings"; break;
              case _Period.weekly:
                amount = e.weeklyEarnings; orders = e.weeklyOrders; label = "This Week's Earnings"; break;
              case _Period.monthly:
                amount = e.monthlyEarnings; orders = e.monthlyOrders; label = "This Month's Earnings"; break;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _PeriodChip(label: 'Daily', selected: _period == _Period.daily, onTap: () => setState(() => _period = _Period.daily))),
                    const SizedBox(width: 8),
                    Expanded(child: _PeriodChip(label: 'Weekly', selected: _period == _Period.weekly, onTap: () => setState(() => _period = _Period.weekly))),
                    const SizedBox(width: 8),
                    Expanded(child: _PeriodChip(label: 'Monthly', selected: _period == _Period.monthly, onTap: () => setState(() => _period = _Period.monthly))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      _Row(label: 'Order Earnings', value: '₹${amount.toStringAsFixed(0)}'),
                      _divider(),
                      _Row(label: 'Tips', value: '₹0', hint: 'Coming soon'),
                      _divider(),
                      _Row(label: 'Incentives', value: '₹0', hint: 'Coming soon'),
                      _divider(),
                      _Row(label: 'Completed Orders', value: '$orders'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: const [
                        Expanded(child: Text('Transactions', style: TextStyle(fontWeight: FontWeight.w600))),
                        Text('View All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: AppTheme.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  const _Row({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label),
              if (hint != null) ...[
                const SizedBox(width: 6),
                Text('($hint)', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: selected ? AppTheme.primary : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
