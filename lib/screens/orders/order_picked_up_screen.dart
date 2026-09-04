import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/location_tracker.dart';
import 'on_the_way_screen.dart';

class OrderPickedUpScreen extends StatelessWidget {
  final int orderId;
  final String orderCode;
  const OrderPickedUpScreen({super.key, required this.orderId, required this.orderCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Order Picked Up')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(color: const Color(0xFFFFF3EC), shape: BoxShape.circle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_bag, color: AppTheme.primary, size: 90),
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Order Picked Up\nSuccessfully', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Order ID', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
            Text('#$orderCode', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  LocationTracker.instance.start();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OnTheWayScreen(orderId: orderId)));
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Start Delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
