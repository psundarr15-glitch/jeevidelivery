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

  Future<void> _reachedCustomer(OrderDetail o) async {
    final isCodPending = o.paymentMethod == 'cod' && o.paymentStatus != 'paid';
    if (isCodPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm cash collected'),
          content: Text('Confirm you have collected ₹${o.total.toStringAsFixed(0)} in cash from ${o.customerName} before marking this order delivered.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes, I've collected it")),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await _requestAndVerifyOtp(o);
  }

  Future<void> _requestAndVerifyOtp(OrderDetail o) async {
    setState(() => _busy = true);
    try {
      // OTP is intentionally generated only at the customer's doorstep.
      // Starting the trip never sends an OTP.
      await DeliveryService.sendDeliveryOtp(widget.orderId);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (mounted) setState(() => _busy = false);

    if (!mounted) return;
    final verified = await _showOtpDialog(o);
    if (verified != true) return;

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

  Future<bool?> _showOtpDialog(OrderDetail o) async {
    final controller = TextEditingController();
    bool sending = false;
    bool verifying = false;
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Confirm Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ask ${o.customerName} for the latest 6-digit delivery OTP.'),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Delivery OTP',
                  errorText: error,
                  counterText: '',
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: sending || verifying
                    ? null
                    : () async {
                        setDialogState(() { sending = true; error = null; });
                        try {
                          await DeliveryService.sendDeliveryOtp(widget.orderId);
                          controller.clear();
                          if (ctx.mounted) {
                            setDialogState(() { sending = false; });
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('A fresh OTP has been sent to the customer.')));
                          }
                        } catch (e) {
                          if (ctx.mounted) setDialogState(() { sending = false; error = e.toString(); });
                        }
                      },
                icon: sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                label: const Text('Resend OTP'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: sending || verifying ? null : () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: sending || verifying || controller.text.trim().length != 6
                  ? null
                  : () async {
                      setDialogState(() { verifying = true; error = null; });
                      try {
                        await DeliveryService.verifyDeliveryOtp(widget.orderId, controller.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) setDialogState(() { verifying = false; error = e.toString(); });
                      }
                    },
              child: verifying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify & Deliver'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
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
                        onPressed: _busy ? null : () => _reachedCustomer(o),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(o.paymentMethod == 'cod' && o.paymentStatus != 'paid' ? 'Collect ₹${o.total.toStringAsFixed(0)} & Send OTP' : 'Reached Customer & Send OTP'),
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
