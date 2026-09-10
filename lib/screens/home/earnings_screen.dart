import 'package:flutter/material.dart';
import '../../models/delivery_order.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';
import '../wallet/wallet_screen.dart';
import '../../widgets/app_error_view.dart';

enum _Period { daily, weekly, monthly }

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<DashboardData> _future;

  _Period _period = _Period.daily;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.dashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DeliveryService.dashboard();
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Wallet',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WalletScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refresh,
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _EarningsLoading();
            }

            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 70),
                  AppErrorView(
                    error: snap.error!,
                    onRetry: _refresh,
                  ),
                ],
              );
            }

            if (!snap.hasData) {
              return const Center(
                child: Text('No earnings data available'),
              );
            }

            final e = snap.data!.earnings;

            final double amount;
            final int orders;
            final String label;
            final String periodDescription;

            switch (_period) {
              case _Period.daily:
                amount = e.todayEarnings;
                orders = e.completedToday;
                label = "Today's Earnings";
                periodDescription = 'Today';
                break;

              case _Period.weekly:
                amount = e.weeklyEarnings;
                orders = e.weeklyOrders;
                label = "This Week's Earnings";
                periodDescription = 'This Week';
                break;

              case _Period.monthly:
                amount = e.monthlyEarnings;
                orders = e.monthlyOrders;
                label = "This Month's Earnings";
                periodDescription = 'This Month';
                break;
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              children: [
                // ─────────────────────────────
                // PERIOD SELECTOR
                // ─────────────────────────────
                _PeriodSelector(
                  selected: _period,
                  onChanged: (period) {
                    setState(() {
                      _period = period;
                    });
                  },
                ),

                const SizedBox(height: 18),

                // ─────────────────────────────
                // MAIN EARNINGS CARD
                // ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -28,
                        top: -35,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 35,
                        bottom: -55,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.14),
                                  borderRadius:
                                      BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.currency_rupee_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    periodDescription,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Text(
                                    'Earnings Overview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.14),
                          ),

                          const SizedBox(height: 15),

                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white70,
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '$orders completed orders',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─────────────────────────────
                // SUMMARY
                // ─────────────────────────────
                const Text(
                  'Earnings Summary',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Orders',
                        value: '$orders',
                        subtitle: 'Completed',
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.payments_outlined,
                        title: 'Order Earnings',
                        value: '₹${amount.toStringAsFixed(0)}',
                        subtitle: periodDescription,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─────────────────────────────
                // BREAKDOWN
                // ─────────────────────────────
                const Text(
                  'Earnings Breakdown',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 11),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.035),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _EarningRow(
                        icon: Icons.delivery_dining_rounded,
                        iconBackground:
                            const Color(0xFFFFEFED),
                        iconColor: AppTheme.primary,
                        label: 'Order Earnings',
                        value:
                            '₹${amount.toStringAsFixed(0)}',
                      ),

                      _divider(),

                      _EarningRow(
                        icon: Icons.volunteer_activism_outlined,
                        iconBackground:
                            const Color(0xFFFFF7E6),
                        iconColor:
                            const Color(0xFFE89B00),
                        label: 'Tips',
                        value: '₹0',
                        hint: 'Coming soon',
                      ),

                      _divider(),

                      _EarningRow(
                        icon: Icons.bolt_rounded,
                        iconBackground:
                            const Color(0xFFEFF7FF),
                        iconColor:
                            const Color(0xFF3182CE),
                        label: 'Incentives',
                        value: '₹0',
                        hint: 'Coming soon',
                      ),

                      _divider(),

                      _EarningRow(
                        icon: Icons.check_circle_outline_rounded,
                        iconBackground:
                            const Color(0xFFECFDF3),
                        iconColor:
                            const Color(0xFF16A34A),
                        label: 'Completed Orders',
                        value: '$orders',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─────────────────────────────
                // WALLET / TRANSACTIONS
                // ─────────────────────────────
                const Text(
                  'Wallet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 11),

                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WalletScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFED),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.primary,
                            size: 23,
                          ),
                        ),

                        const SizedBox(width: 13),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transactions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View your earnings history',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Text(
                          'View All',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(width: 3),

                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.primary,
                          size: 21,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Footer
                Center(
                  child: Text(
                    'Earnings are updated automatically',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 18,
      endIndent: 18,
      color: Colors.grey.shade200,
    );
  }
}

// ─────────────────────────────────────────
// PERIOD SELECTOR
// ─────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              label: 'Daily',
              icon: Icons.today_rounded,
              selected: selected == _Period.daily,
              onTap: () => onChanged(_Period.daily),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              label: 'Weekly',
              icon: Icons.date_range_rounded,
              selected: selected == _Period.weekly,
              onTap: () => onChanged(_Period.weekly),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              label: 'Monthly',
              icon: Icons.calendar_month_rounded,
              selected: selected == _Period.monthly,
              onTap: () => onChanged(_Period.monthly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? Colors.white
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SUMMARY CARD
// ─────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFED),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 19,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// EARNING ROW
// ─────────────────────────────────────────

class _EarningRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String value;
  final String? hint;

  const _EarningRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// LOADING STATE
// ─────────────────────────────────────────

class _EarningsLoading extends StatelessWidget {
  const _EarningsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}