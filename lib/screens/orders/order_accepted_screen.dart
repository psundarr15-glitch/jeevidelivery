import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_detail.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import 'order_picked_up_screen.dart';
import '../../widgets/app_error_view.dart';

class OrderAcceptedScreen extends StatefulWidget {
  final int orderId;
  const OrderAcceptedScreen({super.key, required this.orderId});
  @override
  State<OrderAcceptedScreen> createState() => _OrderAcceptedScreenState();
}

class _OrderAcceptedScreenState extends State<OrderAcceptedScreen> {
  late Future<OrderDetail> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.orderDetails(widget.orderId);
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _markPickedUp() async {
    setState(() => _busy = true);
    try {
      final order = await _future; // already resolved — just reads the cached OrderDetail
      // The partner physically picking up the food from the restaurant
      // is what starts the delivery leg - matches order_status jumping
      // straight to out_for_delivery (see backend notes on updateStatus).
      await DeliveryService.updateStatus(widget.orderId, 'out_for_delivery');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderPickedUpScreen(orderId: widget.orderId, orderCode: order.orderCode)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<OrderDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: AppErrorView(error: snap.error!));
          final o = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Accepted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 10),
              Text('Order ID', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text('#${o.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 16),
              _InfoCard(title: 'Restaurant', name: o.restaurant.name, address: o.restaurant.address ?? '', onCall: () => _call(o.restaurant.phone)),
              _InfoCard(title: 'Customer', name: o.customerName, address: o.address == null ? '' : '${o.address!.addressLine}, ${o.address!.city} - ${o.address!.pincode}', onCall: () => _call(o.customerPhone)),
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...o.items.map((it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(child: Text('${it.quantity} x ${it.name}')),
                              Text('₹${(it.price * it.quantity).toStringAsFixed(0)}'),
                            ],
                          ),
                        )),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _markPickedUp,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Picked Up'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String name;
  final String address;
  final VoidCallback onCall;
  const _InfoCard({required this.title, required this.name, required this.address, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 3),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                if (address.isNotEmpty) Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              ],
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onCall,
            child: const CircleAvatar(backgroundColor: AppTheme.primary, radius: 18, child: Icon(Icons.call, color: Colors.white, size: 17)),
          ),
        ],
      ),
    );
  }
}
