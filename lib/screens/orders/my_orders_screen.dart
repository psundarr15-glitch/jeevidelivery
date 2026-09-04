import 'package:flutter/material.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import 'order_flow_router.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _statuses = const ['all', 'active', 'delivered', 'cancelled'];
  final _labels = const {'all': 'All', 'active': 'Ongoing', 'delivered': 'Completed', 'cancelled': 'Cancelled'};
  String _status = 'all';
  late Future<List<DeliveryOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.myOrders(_status);
  }

  void _select(String status) {
    setState(() {
      _status = status;
      _future = DeliveryService.myOrders(status);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('My Orders')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              children: _statuses.map((s) {
                final selected = s == _status;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_labels[s]!),
                    selected: selected,
                    onSelected: (_) => _select(s),
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DeliveryOrder>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return Center(child: Text('No orders here yet.', style: TextStyle(color: Colors.grey.shade600)));
                }
                return RefreshIndicator(
                  onRefresh: () async => _select(_status),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => openOrder(context, o.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('#${o.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text(o.restaurantName, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(o.orderStatus.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _statusColor(o.orderStatus), fontWeight: FontWeight.w600, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
