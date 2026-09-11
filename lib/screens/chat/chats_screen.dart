import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class DeliveryChatsScreen extends StatefulWidget {
  const DeliveryChatsScreen({super.key});

  @override
  State<DeliveryChatsScreen> createState() => _DeliveryChatsScreenState();
}

class _DeliveryChatsScreenState extends State<DeliveryChatsScreen> {
  final DeliveryChatService _service = DeliveryChatService();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _service.connect();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _time(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _service.myThreads(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Unable to load chats.'));
                    }
                    final threads = snap.data ?? const <Map<String, dynamic>>[];
                    if (threads.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 56),
                            SizedBox(height: 12),
                            Text('No customer chats yet'),
                            SizedBox(height: 4),
                            Text('Customer messages will appear here.'),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: threads.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = threads[index];
                        final orderId = (t['orderId'] as num?)?.toInt();
                        if (orderId == null) return const SizedBox.shrink();
                        final customer = t['customerName']?.toString().trim();
                        final name = customer?.isNotEmpty == true ? customer! : 'Customer';
                        final orderCode = t['orderCode']?.toString();
                        final unread = (t['unreadForDelivery'] as num?)?.toInt() ?? 0;
                        return ListTile(
                          leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
                          title: Row(
                            children: [
                              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text(_time(t['lastMessageAt']), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              if (orderCode != null && orderCode.isNotEmpty) ...[
                                Text(orderCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                              ],
                              Expanded(child: Text(t['lastMessage']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          trailing: unread > 0
                              ? CircleAvatar(radius: 11, child: Text('$unread', style: const TextStyle(fontSize: 11)))
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DeliveryChatScreen(
                                orderId: orderId,
                                customerName: name,
                                orderCode: orderCode,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
