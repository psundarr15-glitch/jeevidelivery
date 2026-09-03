class OrderItemInfo {
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;
  OrderItemInfo({required this.name, required this.price, required this.quantity, required this.isVeg});

  factory OrderItemInfo.fromJson(Map<String, dynamic> j) => OrderItemInfo(
        name: j['item_name']?.toString() ?? '',
        price: double.tryParse(j['price']?.toString() ?? '') ?? 0,
        quantity: int.tryParse(j['quantity']?.toString() ?? '') ?? 1,
        isVeg: j['is_veg'] == true || j['is_veg'].toString() == '1',
      );
}

class RestaurantInfo {
  final String name;
  final String? phone;
  final String? address;
  final double? lat;
  final double? lng;
  RestaurantInfo({required this.name, this.phone, this.address, this.lat, this.lng});

  factory RestaurantInfo.fromJson(Map<String, dynamic> j) => RestaurantInfo(
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString(),
        address: j['address']?.toString(),
        lat: double.tryParse(j['lat']?.toString() ?? ''),
        lng: double.tryParse(j['lng']?.toString() ?? ''),
      );
}

class DeliveryAddressInfo {
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final double? lat;
  final double? lng;
  DeliveryAddressInfo({required this.addressLine, required this.city, required this.state, required this.pincode, this.lat, this.lng});

  factory DeliveryAddressInfo.fromJson(Map<String, dynamic> j) => DeliveryAddressInfo(
        addressLine: j['address_line']?.toString() ?? '',
        city: j['city']?.toString() ?? '',
        state: j['state']?.toString() ?? '',
        pincode: j['pincode']?.toString() ?? '',
        lat: double.tryParse(j['lat']?.toString() ?? ''),
        lng: double.tryParse(j['lng']?.toString() ?? ''),
      );
}

class OrderDetail {
  final int id;
  final String orderCode;
  final String orderStatus;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String customerName;
  final String? customerPhone;
  final List<OrderItemInfo> items;
  final RestaurantInfo restaurant;
  final DeliveryAddressInfo? address;
  final double? distanceKm;

  OrderDetail({
    required this.id,
    required this.orderCode,
    required this.orderStatus,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.customerName,
    this.customerPhone,
    required this.items,
    required this.restaurant,
    this.address,
    this.distanceKm,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final order = j['order'] as Map<String, dynamic>;
    return OrderDetail(
      id: int.parse(order['id'].toString()),
      orderCode: order['order_code']?.toString() ?? '',
      orderStatus: order['order_status']?.toString() ?? 'placed',
      subtotal: double.tryParse(order['subtotal']?.toString() ?? '') ?? 0,
      discount: double.tryParse(order['discount']?.toString() ?? '') ?? 0,
      deliveryFee: double.tryParse(order['delivery_fee']?.toString() ?? '') ?? 0,
      total: double.tryParse(order['total']?.toString() ?? '') ?? 0,
      paymentMethod: order['payment_method']?.toString() ?? 'cod',
      paymentStatus: order['payment_status']?.toString() ?? 'pending',
      customerName: order['customer_name']?.toString() ?? '',
      customerPhone: order['customer_phone']?.toString(),
      items: (j['items'] as List? ?? []).map((e) => OrderItemInfo.fromJson(e as Map<String, dynamic>)).toList(),
      restaurant: RestaurantInfo.fromJson((j['restaurant'] as Map?)?.cast<String, dynamic>() ?? {}),
      address: j['address'] == null ? null : DeliveryAddressInfo.fromJson((j['address'] as Map).cast<String, dynamic>()),
      distanceKm: j['distance_km'] == null ? null : double.tryParse(j['distance_km'].toString()),
    );
  }
}
