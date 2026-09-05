import 'package:flutter/material.dart';
import '../../models/wallet.dart';
import '../../models/cash.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import '../../widgets/app_error_view.dart';

/// Two clearly separate balances live here:
/// - Wallet = money the platform owes the partner (delivery fees earned).
/// - Cash in Hand = COD money the partner is currently holding that they
///   owe back to the platform, until they remit it and an admin confirms
///   receipt. Mixing these into one number would hide the fact that a
///   partner "having money" from COD isn't the same as having earned it.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<WalletData> _walletFuture;
  late Future<CashData> _cashFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _walletFuture = DeliveryService.wallet();
    _cashFuture = DeliveryService.cash();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshWallet() async => setState(() => _walletFuture = DeliveryService.wallet());
  Future<void> _refreshCash() async => setState(() => _cashFuture = DeliveryService.cash());

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
      _refreshWallet();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _remitCash(double cashInHand) async {
    final amountController = TextEditingController(text: cashInHand > 0 ? cashInHand.toStringAsFixed(0) : '');
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remit Cash to Office'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Only submit this after you\'ve actually handed the cash over — the office still needs to confirm receipt before it clears.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ ', helperText: 'Cash in hand: ₹${cashInHand.toStringAsFixed(0)}'),
            ),
            const SizedBox(height: 10),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. handed to Mr. Kumar at the office')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return;
    try {
      final message = await DeliveryService.remitCash(amount, note: noteController.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _refreshCash();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(
        title: const Text('Wallet'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: 'Earnings'), Tab(text: 'COD Cash')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWalletTab(), _buildCashTab()],
      ),
    );
  }

  Widget _buildWalletTab() {
    return RefreshIndicator(
      onRefresh: _refreshWallet,
      child: FutureBuilder<WalletData>(
        future: _walletFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ListView(children: [const SizedBox(height: 40), AppErrorView(error: snap.error!, onRetry: _refreshWallet)]);
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
    );
  }

  Widget _buildCashTab() {
    return RefreshIndicator(
      onRefresh: _refreshCash,
      child: FutureBuilder<CashData>(
        future: _cashFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ListView(children: [const SizedBox(height: 40), AppErrorView(error: snap.error!, onRetry: _refreshCash)]);
          final c = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Cash in Hand (COD)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('₹${c.cashInHand.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('This is money you owe the office — not your earnings.', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: c.cashInHand > 0 ? () => _remitCash(c.cashInHand) : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange.shade800),
                        child: const Text('Remit Cash to Office'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              const SizedBox(height: 10),
              if (c.transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No COD collections yet.\nThis fills in once you deliver a cash-on-delivery order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...c.transactions.map(_cashTransactionRow),
            ],
          );
        },
      ),
    );
  }

  Widget _cashTransactionRow(CashTransaction t) {
    final isCollection = t.type == 'collected';
    String title;
    Color amountColor;
    String sign;
    if (isCollection) {
      title = 'Cash collected' + (t.orderId != null ? ' — order #${t.orderId}' : '');
      amountColor = Colors.green.shade700;
      sign = '+';
    } else {
      switch (t.status) {
        case 'confirmed':
          title = 'Remitted to office (confirmed)';
          amountColor = Colors.green.shade700;
          break;
        case 'rejected':
          title = 'Remittance rejected';
          amountColor = Colors.red.shade700;
          break;
        default:
          title = 'Remittance pending confirmation';
          amountColor = Colors.orange.shade800;
      }
      sign = t.status == 'confirmed' ? '-' : '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (t.note != null && t.note!.isNotEmpty) Text(t.note!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                if (t.createdAt != null) Text(_relativeTime(t.createdAt!), style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
              ],
            ),
          ),
          Text('$sign₹${t.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: amountColor)),
        ],
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
