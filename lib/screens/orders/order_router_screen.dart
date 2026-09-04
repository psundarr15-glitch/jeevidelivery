import 'package:flutter/material.dart';
import 'order_flow_router.dart';

/// Route target for notification taps and deep links: shows a spinner
/// for one frame, then replaces itself with whichever stage screen
/// [openOrder] decides fits the order's current status.
class OrderRouterScreen extends StatefulWidget {
  final int orderId;
  const OrderRouterScreen({super.key, required this.orderId});

  @override
  State<OrderRouterScreen> createState() => _OrderRouterScreenState();
}

class _OrderRouterScreenState extends State<OrderRouterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openOrder(context, widget.orderId, replace: true);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
