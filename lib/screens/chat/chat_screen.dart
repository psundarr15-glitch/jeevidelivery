import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class DeliveryChatScreen extends StatefulWidget {
  final int orderId;
  final String? customerName;
  final String? orderCode;

  const DeliveryChatScreen({
    super.key,
    required this.orderId,
    this.customerName,
    this.orderCode,
  });

  @override
  State<DeliveryChatScreen> createState() => _DeliveryChatScreenState();
}

class _DeliveryChatScreenState extends State<DeliveryChatScreen> {
  final DeliveryChatService _service = DeliveryChatService();
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _service.connect(widget.orderId);
      await _service.markRead();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.send(text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.customerName?.trim().isNotEmpty == true
        ? widget.customerName!
        : 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (widget.orderCode != null)
              Text(widget.orderCode!, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _service.messages(),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(child: Text('Unable to load messages.'));
                          }
                          final messages = snap.data ?? const <Map<String, dynamic>>[];
                          if (messages.isEmpty) {
                            return const Center(child: Text('No messages yet.'));
                          }
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[messages.length - 1 - index];
                              final mine = message['sender']?.toString() == 'delivery';
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                                  decoration: BoxDecoration(
                                    color: mine ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${message['message'] ?? ''}',
                                    style: TextStyle(color: mine ? Colors.white : Colors.black87),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  hintText: 'Message customer...',
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
