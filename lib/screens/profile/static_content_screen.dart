import 'package:flutter/material.dart';
import '../../models/support_info.dart';

class StaticContentScreen extends StatelessWidget {
  final String title;
  final Future<StaticContentPage> future;
  const StaticContentScreen({super.key, required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EC),
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<StaticContentPage>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snap.error}')));
          final page = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (page.updated != null) Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Updated ${page.updated}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ),
              ...page.sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.heading != null) Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(s.heading!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        Text(s.body, style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
