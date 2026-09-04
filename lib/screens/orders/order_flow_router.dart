import 'package:flutter/material.dart';
import '../../services/delivery_service.dart';
import 'new_order_screen.dart';
import 'order_accepted_screen.dart';
import 'on_the_way_screen.dart';
import 'order_delivered_screen.dart';

/// Single entry point for opening an order from anywhere (dashboard
/// auto-popup, My Orders list tap, notification tap) — fetches the
/// current order and routes to whichever stage screen matches its
/// order_status, so callers never have to know the status themselves.
/// Pass [replace] to swap the current route instead of pushing on top
/// (used when a screen advances its own order to the next stage).
Future<void> openOrder(BuildContext context, int orderId, {bool replace = false}) async {
  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  try {
    final order = await DeliveryService.orderDetails(orderId);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close the loading spinner

    Widget? screen;
    switch (order.orderStatus) {
      case 'placed':
        screen = NewOrderScreen(orderId: orderId);
        break;
      case 'confirmed':
      case 'preparing':
        screen = OrderAcceptedScreen(orderId: orderId);
        break;
      case 'out_for_delivery':
        screen = OnTheWayScreen(orderId: orderId);
        break;
      case 'delivered':
        screen = OrderDeliveredScreen(orderId: orderId);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This order was cancelled.')));
    }
    if (screen == null || !context.mounted) return;

    if (replace) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen!));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
