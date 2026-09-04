import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_detail.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import 'order_flow_router.dart';

class NewOrderScreen extends StatefulWidget {
  final int orderId;
  const NewOrderScreen({super.key, required this.orderId});
  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  late Future<OrderDetail> _future;
  Timer? _timer;
  int _secondsLeft = 30;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.orderDetails(widget.orderId);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        // The offer just wasn't acted on in time - back out quietly.
        // The order stays 'placed' and may still be visible to other
        // partners (or reappear on this partner's dashboard poll) since
        // this does NOT call reject().
        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await DeliveryService.acceptOrder(widget.orderId);
      _timer?.cancel();
      if (!mounted) return;
      await openOrder(context, widget.orderId, replace: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await DeliveryService.rejectOrder(widget.orderId);
      _timer?.cancel();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Order'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.notifications_none))],
      ),
      body: FutureBuilder<OrderDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snap.error}')));
          final o = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                Text('#${o.orderCode}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _StopCard(label: 'Pickup', name: o.restaurant.name, address: o.restaurant.address ?? '', phone: o.restaurant.phone),
                const SizedBox(height: 12),
                _StopCard(label: 'Drop to', name: o.customerName, address: o.address == null ? '' : '${o.address!.addressLine}, ${o.address!.city} - ${o.address!.pincode}', phone: o.customerPhone),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _MetricBox(label: 'Distance', value: o.distanceKm != null ? '${o.distanceKm!.toStringAsFixed(1)} km' : '—')),
                    const SizedBox(width: 12),
                    Expanded(child: _MetricBox(label: 'Earning', value: '₹${o.deliveryFee.toStringAsFixed(0)}')),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _reject,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _accept,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(child: Text('Auto expires in $_secondsLeft sec', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final String label;
  final String name;
  final String address;
  final String? phone;
  const _StopCard({required this.label, required this.name, required this.address, this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFF3EC), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 3),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                if (address.isNotEmpty) Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              ],
            ),
          ),
          if (phone != null && phone!.isNotEmpty)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: const CircleAvatar(backgroundColor: AppTheme.primary, radius: 18, child: Icon(Icons.call, color: Colors.white, size: 17)),
            ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFFFF3EC), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primary)),
        ],
      ),
    );
  }
}
