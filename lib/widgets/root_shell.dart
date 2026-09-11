import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/orders/my_orders_screen.dart';
import '../screens/home/earnings_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  static const _tabs = [DashboardScreen(), MyOrdersScreen(), EarningsScreen(), WalletScreen(), ProfileScreen()];
  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
    (Icons.currency_rupee_rounded, Icons.currency_rupee_rounded, 'Earnings'),
    (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Wallet'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];
  @override void initState() { super.initState(); context.read<AppState>().loadPartner().catchError((_) {}); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x16000000), blurRadius: 20, offset: Offset(0, -5))]),
        child: SafeArea(top: false, child: SizedBox(height: 78, child: Row(children: List.generate(_items.length, (i) {
          final selected = i == _index; final item = _items[i];
          return Expanded(child: InkWell(onTap: () => setState(() => _index = i), child: Center(child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 64, height: 58, decoration: BoxDecoration(color: selected ? const Color(0xFFFFEEF1) : Colors.transparent, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(selected ? item.$1 : item.$2, size: 23, color: selected ? const Color(0xFFF22549) : const Color(0xFF697386)),
            const SizedBox(height: 4), Text(item.$3, style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? const Color(0xFFF22549) : const Color(0xFF697386))),
          ]))));
        }))),
      ),
    );
  }
}
