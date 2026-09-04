class WalletTransaction {
  final int id;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String description;
  final DateTime? createdAt;

  WalletTransaction({required this.id, required this.type, required this.amount, required this.description, this.createdAt});

  factory WalletTransaction.fromJson(Map<String, dynamic> j) => WalletTransaction(
        id: int.parse(j['id'].toString()),
        type: j['type']?.toString() ?? 'credit',
        amount: double.tryParse(j['amount']?.toString() ?? '') ?? 0,
        description: j['description']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

class WalletData {
  final double balance;
  final List<WalletTransaction> transactions;
  WalletData({required this.balance, required this.transactions});

  factory WalletData.fromJson(Map<String, dynamic> j) => WalletData(
        balance: double.tryParse(j['balance']?.toString() ?? '') ?? 0,
        transactions: (j['transactions'] as List? ?? []).map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
