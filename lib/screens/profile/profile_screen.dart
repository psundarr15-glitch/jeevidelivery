import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';
import 'info_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.logout();
    if (context.mounted) {
      context.read<AppState>().clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = context.watch<AppState>().partner;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Profile')),
      body: partner == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primary,
                    backgroundImage: (partner.photo != null && partner.photo!.isNotEmpty) ? NetworkImage(partner.photo!) : null,
                    child: (partner.photo == null || partner.photo!.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19))),
                Center(child: Text(partner.phone ?? '', style: TextStyle(color: Colors.grey.shade600))),
                if (partner.email != null) Center(child: Text(partner.email!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5))),
                const SizedBox(height: 24),
                _NavTile(
                  icon: Icons.badge_outlined,
                  label: 'Personal Details',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoDetailScreen(title: 'Personal Details', fields: [
                        MapEntry('Name', partner.name),
                        MapEntry('Phone', partner.phone ?? ''),
                        MapEntry('Email', partner.email ?? ''),
                        MapEntry('Date of Birth', partner.dob ?? ''),
                        MapEntry('City', partner.city ?? ''),
                        MapEntry('District', partner.district ?? ''),
                        MapEntry('Pincode', partner.pincode ?? ''),
                      ]))),
                ),
                _NavTile(
                  icon: Icons.two_wheeler,
                  label: 'Vehicle Details',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoDetailScreen(title: 'Vehicle Details', fields: [
                        MapEntry('Vehicle Type', partner.vehicleType ?? ''),
                        MapEntry('Vehicle Number', partner.vehicleNumber ?? ''),
                        MapEntry('RC Number', partner.rcNumber ?? ''),
                        MapEntry('License Number', partner.licenseNumber ?? ''),
                      ]))),
                ),
                _NavTile(
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoDetailScreen(title: 'Documents', fields: [
                        MapEntry('Aadhaar Number', partner.aadhaarNumber ?? ''),
                        MapEntry('ID Proof', (partner.idProofDocument?.isNotEmpty ?? false) ? 'Uploaded' : 'Not uploaded'),
                        MapEntry('RC Document', (partner.rcDocument?.isNotEmpty ?? false) ? 'Uploaded' : 'Not uploaded'),
                      ]))),
                ),
                _NavTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Bank Details',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoDetailScreen(title: 'Bank Details', fields: [
                        MapEntry('Account Holder', partner.bankAccountHolder ?? ''),
                        MapEntry('Account Number', partner.bankAccountNumber ?? ''),
                        MapEntry('IFSC', partner.bankIfsc ?? ''),
                      ]))),
                ),
                _NavTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => _showSettings(context)),
                _NavTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                const SizedBox(height: 8),
                _NavTile(icon: Icons.logout, label: 'Logout', color: Colors.red, onTap: () => _logout(context)),
              ],
            ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              SizedBox(height: 12),
              Text('More settings (language, notification preferences) are coming soon.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _NavTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14.5, color: color))),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
