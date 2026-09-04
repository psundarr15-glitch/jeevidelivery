import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_detail.dart';
import '../../services/delivery_service.dart';
import '../../services/location_tracker.dart';
import '../../theme.dart';
import 'order_delivered_screen.dart';
import '../../widgets/app_error_view.dart';

class OnTheWayScreen extends StatefulWidget {
  final int orderId;
  const OnTheWayScreen({super.key, required this.orderId});
  @override
  State<OnTheWayScreen> createState() => _OnTheWayScreenState();
}

class _OnTheWayScreenState extends State<OnTheWayScreen> {
  late Future<OrderDetail> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.orderDetails(widget.orderId);
    LocationTracker.instance.start();
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _reachedCustomer() async {
    setState(() => _busy = true);
    try {
      await DeliveryService.updateStatus(widget.orderId, 'delivered');
      LocationTracker.instance.stop();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderDeliveredScreen(orderId: widget.orderId)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('On the Way')),
      body: FutureBuilder<OrderDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: AppErrorView(error: snap.error!));
          final o = snap.data!;
          final lat = o.address?.lat;
          final lng = o.address?.lng;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Order ID #${o.orderCode}', style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
              Expanded(
                child: (lat != null && lng != null)
                    ? FlutterMap(
                        options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 14),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.jeevi.delivery_partner_app'),
                          MarkerLayer(markers: [
                            Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.location_on, color: AppTheme.primary, size: 40)),
                          ]),
                        ],
                      )
                    : Container(color: const Color(0xFFFFF3EC), child: const Center(child: Icon(Icons.map_outlined, size: 48, color: Colors.grey))),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deliver to', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (o.address != null)
                                Text('${o.address!.addressLine}, ${o.address!.city} - ${o.address!.pincode}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _call(o.customerPhone),
                          child: const CircleAvatar(backgroundColor: AppTheme.primary, radius: 18, child: Icon(Icons.call, color: Colors.white, size: 17)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _reachedCustomer,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Reached Customer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
