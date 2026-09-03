import 'package:flutter/material.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<DashboardData> _future;

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
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [const SizedBox(height: 80), Center(child: Text('${snap.error}'))]);
            }
            final e = snap.data!.earnings;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Row(label: 'Deliveries completed today', value: '${e.completedToday}'),
                const SizedBox(height: 12),
                _Card(title: 'This week', orders: e.weeklyOrders, amount: e.weeklyEarnings),
                const SizedBox(height: 12),
                _Card(title: 'This month', orders: e.monthlyOrders, amount: e.monthlyEarnings),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
        ]),
      );
}

class _Card extends StatelessWidget {
  final String title;
  final int orders;
  final double amount;
  const _Card({required this.title, required this.orders, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
          Text('$orders orders delivered', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
        ],
      ),
    );
  }
}
