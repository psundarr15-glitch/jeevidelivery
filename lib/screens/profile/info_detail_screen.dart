import 'package:flutter/material.dart';
import '../../theme.dart';

class InfoDetailScreen extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> fields;
  const InfoDetailScreen({super.key, required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: fields
                  .map((f) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 130, child: Text(f.key, style: TextStyle(color: Colors.grey.shade600))),
                            Expanded(child: Text(f.value.isEmpty ? '—' : f.value, style: const TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text('To update these details, contact your operations team for now — in-app editing is coming soon.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
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
                Text('Reach out to your operations/admin team through the channel they\'ve shared with you — in-app chat support for partners is coming soon.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
