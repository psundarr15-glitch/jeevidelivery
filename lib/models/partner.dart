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
  final String? dob;
  final String? city;
  final String? district;
  final String? pincode;
  final String? aadhaarNumber;
  final String? licenseNumber;
  final String? rcNumber;
  final String? idProofDocument;
  final String? rcDocument;
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final double walletBalance;

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
    this.dob,
    this.city,
    this.district,
    this.pincode,
    this.aadhaarNumber,
    this.licenseNumber,
    this.rcNumber,
    this.idProofDocument,
    this.rcDocument,
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankIfsc,
    this.walletBalance = 0,
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
        dob: j['dob']?.toString(),
        city: j['city']?.toString(),
        district: j['district']?.toString(),
        pincode: j['pincode']?.toString(),
        aadhaarNumber: j['aadhaar_number']?.toString(),
        licenseNumber: j['license_number']?.toString(),
        rcNumber: j['rc_number']?.toString(),
        idProofDocument: j['id_proof_document']?.toString(),
        rcDocument: j['rc_document']?.toString(),
        bankAccountHolder: j['bank_account_holder']?.toString(),
        bankAccountNumber: j['bank_account_number']?.toString(),
        bankIfsc: j['bank_ifsc']?.toString(),
        walletBalance: double.tryParse(j['wallet_balance']?.toString() ?? '') ?? 0,
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
        dob: dob,
        city: city,
        district: district,
        pincode: pincode,
        aadhaarNumber: aadhaarNumber,
        licenseNumber: licenseNumber,
        rcNumber: rcNumber,
        idProofDocument: idProofDocument,
        rcDocument: rcDocument,
        bankAccountHolder: bankAccountHolder,
        bankAccountNumber: bankAccountNumber,
        bankIfsc: bankIfsc,
        walletBalance: walletBalance,
      );
}
