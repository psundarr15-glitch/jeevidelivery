import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/delivery_service.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import 'change_password_screen.dart';
import 'static_content_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _notificationsEnabled;
  String? _version;

  @override
  void initState() {
    super.initState();
    NotificationService.isEnabled().then((v) {
      if (mounted) setState(() => _notificationsEnabled = v);
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((_) {});
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      await NotificationService.setEnabled(value);
    } catch (e) {
      if (mounted) {
        setState(() => _notificationsEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              value: _notificationsEnabled ?? true,
              onChanged: _notificationsEnabled == null ? null : _toggleNotifications,
              activeThumbColor: AppTheme.primary,
              title: const Text('Push Notifications'),
              subtitle: const Text('New order alerts on this device', style: TextStyle(fontSize: 12.5)),
            ),
          ),
          const SizedBox(height: 10),
          _NavTile(
            icon: Icons.lock_reset,
            label: 'Change Password',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          _NavTile(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StaticContentScreen(title: 'About', future: DeliveryService.aboutPage()),
            )),
          ),
          const SizedBox(height: 20),
          Center(child: Text(_version == null ? '' : 'App version $_version', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.onTap});

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
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14.5))),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
