import 'package:flutter/material.dart';
import '../../services/delivery_service.dart';
import 'new_order_screen.dart';
import 'order_accepted_screen.dart';
import 'order_picked_up_screen.dart';
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
        // The restaurant hasn't confirmed this yet (see
        // Admin\OrderController::updateStatus on the backend) - a
        // partner has no business being shown this at all. In normal
        // operation this case shouldn't be reachable (dashboard() only
        // ever returns 'confirmed' orders as pending), so this only
        // matters as a defensive fallback for a stale link/notification.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This order is still awaiting restaurant confirmation.')));
        break;
      case 'confirmed':
        // Restaurant has confirmed it and it's now up for grabs - this
        // is the "New Order" (accept/reject) stage.
        screen = NewOrderScreen(orderId: orderId);
        break;
      case 'preparing':
        // A partner has accepted it (see DeliveryApiController::acceptOrder)
        // and it's being prepared for pickup.
        screen = OrderAcceptedScreen(orderId: orderId);
        break;
      case 'picked_up':
        screen = OrderPickedUpScreen(orderId: orderId, orderCode: order.orderCode);
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

    // Await the pushed route. The dashboard uses this future to keep its
    // pending-order popup locked while the partner is working on the order.
    // Without awaiting, the popup flag resets immediately and the same
    // confirmed order can be opened again by the 2-second poll.
    if (replace) {
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen!));
    } else {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
