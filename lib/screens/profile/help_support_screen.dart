import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/support_info.dart';
import '../../services/delivery_service.dart';
import '../../theme.dart';

/// Pulls from GET /pages/support — the same admin-configurable contact
/// info the customer app uses (Admin > Help & Support Settings), rather
/// than a hardcoded phone number that would go stale.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late Future<SupportInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = DeliveryService.supportInfo();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Help & Support')),
      body: FutureBuilder<SupportInfo>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            // Support info failing to load shouldn't leave the partner
            // with nothing — fall back to a generic message rather than
            // a bare error screen for something this important.
            return _fallback(context);
          }
          final info = snap.data!;
          if (!info.hasAnyContact && (info.message == null || info.message!.isEmpty)) {
            return _fallback(context);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent, color: AppTheme.primary, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      info.message ?? 'Need help with an order, your account, or a payout? Reach us directly:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (info.phone != null)
                _ContactTile(icon: Icons.call, label: 'Call Support', value: info.phone!, onTap: () => _call(info.phone!)),
              if (info.whatsapp != null)
                _ContactTile(icon: Icons.chat, label: 'WhatsApp', value: info.whatsapp!, onTap: () => _whatsapp(info.whatsapp!)),
              if (info.email != null)
                _ContactTile(icon: Icons.email_outlined, label: 'Email Support', value: info.email!, onTap: () => _email(info.email!)),
            ],
          );
        },
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.support_agent, color: AppTheme.primary, size: 32),
              SizedBox(height: 10),
              Text('Need help with an order, your account, or a payout?', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Reach out to your operations/admin team through the channel they\'ve shared with you.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: const Color(0xFFFFF3EC), child: Icon(icon, color: AppTheme.primary)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
