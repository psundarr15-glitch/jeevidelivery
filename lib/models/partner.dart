class Partner {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final bool isAvailable;
  final double rating;
  final int ratingCount;
  final String? photo;
  final String? vehicleType;
  final String? vehicleNumber;

  Partner({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.isAvailable = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.photo,
    this.vehicleType,
    this.vehicleNumber,
  });

  factory Partner.fromJson(Map<String, dynamic> j) => Partner(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString(),
        phone: j['phone']?.toString(),
        isAvailable: j['is_available'] == true || j['is_available'].toString() == '1',
        rating: double.tryParse(j['rating']?.toString() ?? '') ?? 0,
        ratingCount: int.tryParse(j['rating_count']?.toString() ?? '') ?? 0,
        photo: j['photo']?.toString(),
        vehicleType: j['vehicle_type']?.toString(),
        vehicleNumber: j['vehicle_number']?.toString(),
      );

  Partner copyWith({bool? isAvailable}) => Partner(
        id: id,
        name: name,
        email: email,
        phone: phone,
        isAvailable: isAvailable ?? this.isAvailable,
        rating: rating,
        ratingCount: ratingCount,
        photo: photo,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
      );
}
