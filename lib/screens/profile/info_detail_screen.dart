import 'package:flutter/material.dart';

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
          Text('Identity and vehicle details are managed by the operations team for verification and safety.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
        ],
      ),
    );
  }
}

