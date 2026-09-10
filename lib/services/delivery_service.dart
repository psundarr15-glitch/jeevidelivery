import '../config/api_config.dart';
import '../models/partner.dart';
import '../models/delivery_order.dart';
import '../models/order_detail.dart';
import '../models/wallet.dart';
import '../models/cash.dart';
import '../models/support_info.dart';
import 'api_client.dart';

class DeliveryService {
  static Future<Partner> me() async {
    final res = await ApiClient.get(ApiConfig.me);
    return Partner.fromJson(res['partner'] as Map<String, dynamic>);
  }

  /// Both a bank account AND a UPI ID can be saved at once —
  /// [defaultPayoutMethod] ('bank' | 'upi') just says which one payouts
  /// should actually use.
  static Future<String> updateBankDetails({
    String? bankAccountHolder,
    String? bankAccountNumber,
    String? bankIfsc,
    String? upiId,
    required String defaultPayoutMethod,
  }) async {
    final res = await ApiClient.post(ApiConfig.updateBankDetails, {
      'bank_account_holder': bankAccountHolder ?? '',
      'bank_account_number': bankAccountNumber ?? '',
      'bank_ifsc': bankIfsc ?? '',
      'upi_id': upiId ?? '',
      'default_payout_method': defaultPayoutMethod,
    });
    return res['message']?.toString() ?? 'Payout details updated.';
  }

  static Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    final res = await ApiClient.post(ApiConfig.changePassword, {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return res['message']?.toString() ?? 'Password changed.';
  }

  static Future<SupportInfo> supportInfo() async {
    final res = await ApiClient.get(ApiConfig.pagesSupport);
    return SupportInfo.fromJson(res);
  }

  static Future<StaticContentPage> aboutPage() async {
    final res = await ApiClient.get(ApiConfig.pagesAbout);
    return StaticContentPage.fromJson(res);
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

  /// COD cash the partner is currently holding, separate from wallet
  /// earnings — see the backend's DeliveryCashTransactionModel.
  static Future<CashData> cash() async {
    final res = await ApiClient.get(ApiConfig.cash);
    return CashData.fromJson(res);
  }

  /// Declares cash was handed over to the office. This does NOT reduce
  /// cash-in-hand immediately — it stays pending until an admin confirms
  /// receipt (see the admin Cash Remittances screen).
  static Future<String> remitCash(double amount, {String? note}) async {
    final res = await ApiClient.post(ApiConfig.cashRemit, {'amount': amount, if (note != null && note.isNotEmpty) 'note': note});
    return res['message']?.toString() ?? 'Remittance submitted.';
  }

  static Future<void> acceptOrder(int orderId) => ApiClient.post(ApiConfig.acceptOrder(orderId));

  static Future<void> rejectOrder(int orderId) => ApiClient.post(ApiConfig.rejectOrder(orderId));

  static Future<void> updateStatus(int orderId, String status) =>
      ApiClient.post(ApiConfig.updateStatus(orderId), {'order_status': status});

  static Future<void> verifyDeliveryOtp(int orderId, String otp) =>
      ApiClient.post(ApiConfig.verifyDeliveryOtp(orderId), {'otp': otp});

  static Future<void> updateLocation(double lat, double lng) =>
      ApiClient.post(ApiConfig.updateLocation, {'lat': lat, 'lng': lng});
}
