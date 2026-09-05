class CashTransaction {
  final int id;
  final String type; // 'collected' | 'remit_requested'
  final double amount;
  final String status; // 'confirmed' | 'pending' | 'rejected'
  final String? note;
  final int? orderId;
  final DateTime? createdAt;

  CashTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.note,
    this.orderId,
    this.createdAt,
  });

  factory CashTransaction.fromJson(Map<String, dynamic> j) => CashTransaction(
        id: int.parse(j['id'].toString()),
        type: j['type']?.toString() ?? 'collected',
        amount: double.tryParse(j['amount']?.toString() ?? '') ?? 0,
        status: j['status']?.toString() ?? 'confirmed',
        note: j['note']?.toString(),
        orderId: j['order_id'] == null ? null : int.tryParse(j['order_id'].toString()),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

class CashData {
  final double cashInHand;
  final List<CashTransaction> transactions;
  CashData({required this.cashInHand, required this.transactions});

  factory CashData.fromJson(Map<String, dynamic> j) => CashData(
        cashInHand: double.tryParse(j['cash_in_hand']?.toString() ?? '') ?? 0,
        transactions: (j['transactions'] as List? ?? []).map((e) => CashTransaction.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
