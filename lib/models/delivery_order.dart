class DeliveryOrder {
  final int id;
  final String orderCode;
  final String orderStatus;
  final double total;
  final String paymentMethod;
  final String? placedAt;
  final String customerName;
  final String? customerPhone;
  final String restaurantName;
  final double? restaurantLat;
  final double? restaurantLng;
  final double? distanceKm;

  DeliveryOrder({
    required this.id,
    required this.orderCode,
    required this.orderStatus,
    required this.total,
    required this.paymentMethod,
    this.placedAt,
    required this.customerName,
    this.customerPhone,
    required this.restaurantName,
    this.restaurantLat,
    this.restaurantLng,
    this.distanceKm,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> j) => DeliveryOrder(
        id: int.parse(j['id'].toString()),
        orderCode: j['order_code']?.toString() ?? '',
        orderStatus: j['order_status']?.toString() ?? 'placed',
        total: double.tryParse(j['total']?.toString() ?? '') ?? 0,
        paymentMethod: j['payment_method']?.toString() ?? 'cod',
        placedAt: j['placed_at']?.toString(),
        customerName: j['customer_name']?.toString() ?? '',
        customerPhone: j['customer_phone']?.toString(),
        restaurantName: j['restaurant_name']?.toString() ?? '',
        restaurantLat: double.tryParse(j['restaurant_lat']?.toString() ?? ''),
        restaurantLng: double.tryParse(j['restaurant_lng']?.toString() ?? ''),
        distanceKm: j['distance_km'] == null ? null : double.tryParse(j['distance_km'].toString()),
      );
}

/// Weekly/monthly/today earnings summary, part of the dashboard payload.
class EarningsSummary {
  final int completedToday;
  final int weeklyOrders;
  final double weeklyEarnings;
  final int monthlyOrders;
  final double monthlyEarnings;

  EarningsSummary({
    required this.completedToday,
    required this.weeklyOrders,
    required this.weeklyEarnings,
    required this.monthlyOrders,
    required this.monthlyEarnings,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> j) => EarningsSummary(
        completedToday: int.tryParse(j['completed_today']?.toString() ?? '') ?? 0,
        weeklyOrders: int.tryParse(j['weekly_orders']?.toString() ?? '') ?? 0,
        weeklyEarnings: double.tryParse(j['weekly_earnings']?.toString() ?? '') ?? 0,
        monthlyOrders: int.tryParse(j['monthly_orders']?.toString() ?? '') ?? 0,
        monthlyEarnings: double.tryParse(j['monthly_earnings']?.toString() ?? '') ?? 0,
      );
}

class DashboardData {
  final List<DeliveryOrder> pendingOrders;
  final List<DeliveryOrder> activeOrders;
  final EarningsSummary earnings;
  DashboardData({required this.pendingOrders, required this.activeOrders, required this.earnings});
}
