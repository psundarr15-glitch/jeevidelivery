import 'package:flutter/material.dart';
import '../../models/order_detail.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import '../../widgets/root_shell.dart';

class OrderDeliveredScreen extends StatefulWidget {
  final int orderId;
  const OrderDeliveredScreen({super.key, required this.orderId});
  @override
  State<OrderDeliveredScreen> createState() => _OrderDeliveredScreenState();
}

class _OrderDeliveredScreenState extends State<OrderDeliveredScreen> {
  late Future<OrderDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.orderDetails(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Delivered'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<OrderDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final o = snap.data!;
          final cashToCollect = o.paymentMethod == 'cod' && o.paymentStatus != 'paid' ? o.total : 0;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(color: Color(0xFFFFF3EC), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: AppTheme.gold, size: 76),
                ),
                const SizedBox(height: 20),
                const Text('Order Delivered\nSuccessfully', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3EC), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Earning', style: TextStyle(color: Colors.grey.shade600)),
                          Text('₹${o.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
                        ],
                      ),
                      if (cashToCollect > 0) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cash to Collect', style: TextStyle(color: Colors.grey.shade600)),
                            Text('₹${cashToCollect.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery-proof photo upload is coming soon.')),
                    ),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Upload Proof'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootShell()), (r) => false),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
