import 'package:flutter/material.dart';
import '../../models/order_detail.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import '../../widgets/root_shell.dart';
import '../../widgets/app_error_view.dart';
import '../wallet/wallet_screen.dart';

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
          if (snap.hasError) return Center(child: AppErrorView(error: snap.error!));
          final o = snap.data!;
          // By the time this screen loads, the backend has already
          // marked a COD order's payment_status 'paid' and credited
          // cash_in_hand (see updateStatus()) — so this is a receipt of
          // what already happened, not a pending amount still owed.
          final wasCodCollection = o.paymentMethod == 'cod';

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
                      if (wasCodCollection) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: const [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 6), Text('Cash Collected')]),
                            Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Added to your Cash in Hand — remit it to the office from the Wallet tab.', style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                      ],
                    ],
                  ),
                ),
                if (wasCodCollection) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
                    child: const Text('View Cash in Hand'),
                  ),
                ],
                const SizedBox(height: 18),
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
