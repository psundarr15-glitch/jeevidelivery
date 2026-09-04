import 'package:flutter/material.dart';
import '../../models/wallet.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import '../../widgets/app_error_view.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<WalletData> _future;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.wallet();
  }

  Future<void> _refresh() async => setState(() => _future = DeliveryService.wallet());

  Future<void> _withdraw(double available) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ ', helperText: 'Available: ₹${available.toStringAsFixed(0)}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)), child: const Text('Withdraw')),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      final message = await DeliveryService.withdraw(amount);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<WalletData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return ListView(children: [const SizedBox(height: 40), AppErrorView(error: snap.error!, onRetry: _refresh)]);
            final w = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('₹${w.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _withdraw(w.balance),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary),
                          child: const Text('Withdraw'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                const SizedBox(height: 10),
                if (w.transactions.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 24), child: Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey.shade600))))
                else
                  ...w.transactions.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (t.createdAt != null)
                                    Text(_relativeTime(t.createdAt!), style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                                ],
                              ),
                            ),
                            Text(
                              '${t.type == 'credit' ? '+' : '-'}₹${t.amount.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: t.type == 'credit' ? Colors.green.shade700 : Colors.red.shade700),
                            ),
                          ],
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
