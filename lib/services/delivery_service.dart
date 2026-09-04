import '../config/api_config.dart';
import '../models/partner.dart';
import '../models/delivery_order.dart';
import '../models/order_detail.dart';
import '../models/wallet.dart';
import 'api_client.dart';

class DeliveryService {
  static Future<Partner> me() async {
    final res = await ApiClient.get(ApiConfig.me);
    return Partner.fromJson(res['partner'] as Map<String, dynamic>);
  }

  static Future<bool> toggleAvailability() async {
    final res = await ApiClient.post(ApiConfig.toggleAvailability);
    return res['is_available'] == true;
  }

  static Future<DashboardData> dashboard() async {
    final res = await ApiClient.get(ApiConfig.dashboard);
    return DashboardData(
      pendingOrders: (res['pending_orders'] as List? ?? []).map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>)).toList(),
      activeOrders: (res['active_orders'] as List? ?? []).map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>)).toList(),
      earnings: EarningsSummary.fromJson(res),
    );
  }

  static Future<OrderDetail> orderDetails(int orderId) async {
    final res = await ApiClient.get(ApiConfig.orderDetails(orderId));
    return OrderDetail.fromJson(res);
  }

  /// status: 'all' | 'active' | 'delivered' | 'cancelled'
  static Future<List<DeliveryOrder>> myOrders(String status) async {
    final res = await ApiClient.get(ApiConfig.myOrders(status));
    return (res['orders'] as List? ?? []).map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<WalletData> wallet() async {
    final res = await ApiClient.get(ApiConfig.wallet);
    return WalletData.fromJson(res);
  }

  static Future<String> withdraw(double amount) async {
    final res = await ApiClient.post(ApiConfig.walletWithdraw, {'amount': amount});
    return res['message']?.toString() ?? 'Withdrawal requested.';
  }

  static Future<void> acceptOrder(int orderId) => ApiClient.post(ApiConfig.acceptOrder(orderId));

  static Future<void> rejectOrder(int orderId) => ApiClient.post(ApiConfig.rejectOrder(orderId));

  static Future<void> updateStatus(int orderId, String status) =>
      ApiClient.post(ApiConfig.updateStatus(orderId), {'order_status': status});

  static Future<void> updateLocation(double lat, double lng) =>
      ApiClient.post(ApiConfig.updateLocation, {'lat': lat, 'lng': lng});
}
