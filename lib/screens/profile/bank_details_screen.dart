import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/partner.dart';
import '../../services/delivery_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// Lets a partner set/update their own payout details. Both a bank
/// account AND a UPI ID can be saved at once — the two tiles up top
/// just pick which one payouts should actually use as default. Unlike
/// Personal/Vehicle/Documents (still read-only — see InfoDetailScreen),
/// this one actually saves, via POST /delivery/profile/bank-details.
class BankDetailsScreen extends StatefulWidget {
  final Partner partner;
  const BankDetailsScreen({super.key, required this.partner});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _holder;
  late final TextEditingController _accountNumber;
  late final TextEditingController _ifsc;
  late final TextEditingController _upi;
  late String _defaultMethod; // 'bank' | 'upi'
  bool _obscureAccount = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _holder = TextEditingController(text: widget.partner.bankAccountHolder ?? '');
    _accountNumber = TextEditingController(text: widget.partner.bankAccountNumber ?? '');
    _ifsc = TextEditingController(text: widget.partner.bankIfsc ?? '');
    _upi = TextEditingController(text: widget.partner.upiId ?? '');
    _defaultMethod = widget.partner.defaultPayoutMethod;
    // Only mask if there's already a saved number to protect — a
    // blank field (first-time entry) should be visible so the partner
    // can see what they're typing.
    _obscureAccount = _accountNumber.text.isNotEmpty;
  }

  @override
  void dispose() {
    _holder.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    _upi.dispose();
    super.dispose();
  }

  bool get _hasBank => _accountNumber.text.trim().isNotEmpty && _ifsc.text.trim().isNotEmpty;
  bool get _hasUpi => _upi.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_defaultMethod == 'bank' && !_hasBank) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your bank account details before setting it as default.')));
      return;
    }
    if (_defaultMethod == 'upi' && !_hasUpi) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your UPI ID before setting it as default.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final message = await DeliveryService.updateBankDetails(
        bankAccountHolder: _holder.text.trim(),
        bankAccountNumber: _accountNumber.text.trim(),
        bankIfsc: _ifsc.text.trim(),
        upiId: _upi.text.trim(),
        defaultPayoutMethod: _defaultMethod,
      );
      if (!mounted) return;
      // Refresh the shared partner profile so Profile screen reflects the change immediately.
      context.read<AppState>().loadPartner().catchError((_) {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Bank Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You can save both — tap one below to set it as your default payout method.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MethodTile(
                        label: 'Bank Account',
                        icon: Icons.account_balance_outlined,
                        selected: _defaultMethod == 'bank',
                        onTap: () => setState(() => _defaultMethod = 'bank'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MethodTile(
                        label: 'UPI ID',
                        icon: Icons.qr_code,
                        selected: _defaultMethod == 'upi',
                        onTap: () => setState(() => _defaultMethod = 'upi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                Text('Bank Account', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _holder,
                  decoration: const InputDecoration(labelText: 'Account Holder Name'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountNumber,
                  keyboardType: TextInputType.number,
                  obscureText: _obscureAccount,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureAccount ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureAccount = !_obscureAccount),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ifsc,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'IFSC Code', hintText: 'e.g. SBIN0001234'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[A-Za-z]{4}0[A-Z0-9]{6}$').hasMatch(v.trim())) return 'Enter a valid IFSC code';
                    return null;
                  },
                ),

                const SizedBox(height: 22),
                Text('UPI ID', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _upi,
                  decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'e.g. yourname@okhdfcbank'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$').hasMatch(v.trim())) return 'Enter a valid UPI ID';
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppTheme.primary),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
