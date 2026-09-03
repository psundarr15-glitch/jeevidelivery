import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';

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
                    radius: 44,
                    backgroundColor: AppTheme.primary,
                    backgroundImage: (partner.photo != null && partner.photo!.isNotEmpty) ? NetworkImage(partner.photo!) : null,
                    child: (partner.photo == null || partner.photo!.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 44) : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19))),
                if (partner.ratingCount > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${partner.rating.toStringAsFixed(1)} (${partner.ratingCount})', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _InfoTile(icon: Icons.email_outlined, label: 'Email', value: partner.email ?? '—'),
                _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: partner.phone ?? '—'),
                _InfoTile(icon: Icons.two_wheeler, label: 'Vehicle', value: [partner.vehicleType, partner.vehicleNumber].where((e) => e != null && e.isNotEmpty).join(' • ').ifEmpty('—')),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
    );
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 14.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
