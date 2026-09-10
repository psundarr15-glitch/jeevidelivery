import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_detail.dart';
import '../../services/delivery_service.dart';
import '../../services/location_tracker.dart';
import '../../theme.dart';

const _statusFlow = ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Future<OrderDetail>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = DeliveryService.orderDetails(widget.orderId));

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _accept() => _act(() => DeliveryService.acceptOrder(widget.orderId));
  Future<void> _reject() => _act(() => DeliveryService.rejectOrder(widget.orderId), popOnSuccess: true);

  Future<void> _advanceStatus(String current) async {
    final i = _statusFlow.indexOf(current);
    if (i < 0 || i >= _statusFlow.length - 1) return;
    final next = _statusFlow[i + 1];
    await _act(() => DeliveryService.updateStatus(widget.orderId, next), popOnSuccess: next == 'delivered');
    if (next == 'out_for_delivery') {
      LocationTracker.instance.start();
    } else if (next == 'delivered') {
      LocationTracker.instance.stop();
    }
  }

  Future<void> _act(Future<void> Function() action, {bool popOnSuccess = false}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (popOnSuccess) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      _load();
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snap.error}')));
          }
          final o = snap.data!;
          final isPending = o.orderStatus == 'placed';
          final isTerminal = o.orderStatus == 'delivered' || o.orderStatus == 'cancelled';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.orderCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 2),
                          Text(o.orderStatus.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _CardSection(
                title: 'Pickup from',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.restaurant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (o.restaurant.address != null) Text(o.restaurant.address!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ActionChip(icon: Icons.call, label: 'Call restaurant', onTap: () => _call(o.restaurant.phone)),
                        const SizedBox(width: 8),
                        _ActionChip(icon: Icons.directions, label: 'Directions', onTap: () => _openMap(o.restaurant.lat, o.restaurant.lng)),
                      ],
                    ),
                  ],
                ),
              ),

              if (o.address != null)
                _CardSection(
                  title: 'Deliver to',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${o.address!.addressLine}, ${o.address!.city}, ${o.address!.state} - ${o.address!.pincode}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ActionChip(icon: Icons.call, label: 'Call customer', onTap: () => _call(o.customerPhone)),
                          const SizedBox(width: 8),
                          _ActionChip(icon: Icons.directions, label: 'Directions', onTap: () => _openMap(o.address!.lat, o.address!.lng)),
                        ],
                      ),
                    ],
                  ),
                ),

              if (o.address?.lat != null && o.address?.lng != null)
                Container(
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 14),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: LatLng(o.address!.lat!, o.address!.lng!), initialZoom: 14, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.jeevi.delivery_partner_app'),
                      MarkerLayer(markers: [
                        Marker(point: LatLng(o.address!.lat!, o.address!.lng!), width: 36, height: 36, child: const Icon(Icons.location_on, color: AppTheme.primary, size: 36)),
                      ]),
                    ],
                  ),
                ),

              _CardSection(
                title: 'Items (${o.items.length})',
                child: Column(
                  children: o.items
                      .map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: it.isVeg ? Colors.green : Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${it.name} x${it.quantity}')),
                                Text('₹${(it.price * it.quantity).toStringAsFixed(0)}'),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

              _CardSection(
                title: 'Payment',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(o.paymentMethod.toUpperCase()),
                    Text(o.paymentStatus == 'paid' ? 'Paid' : 'Collect ₹${o.total.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: o.paymentStatus == 'paid' ? Colors.green : AppTheme.primary)),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _reject,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _accept,
                        child: const Text('Accept order'),
                      ),
                    ),
                  ],
                )
              else if (!isTerminal)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : () => _advanceStatus(o.orderStatus),
                    child: Text(_busy ? 'Please wait…' : _nextActionLabel(o.orderStatus)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _nextActionLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Mark as preparing';
      case 'preparing':
        return 'Mark picked up — out for delivery';
      case 'out_for_delivery':
        return 'Mark as delivered';
      default:
        return 'Update status';
    }
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFFFFF3EC), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppTheme.primary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
