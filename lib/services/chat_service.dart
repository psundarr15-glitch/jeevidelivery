import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class DeliveryChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _threadId;
  int? _customerId;
  String? _orderCode;
  int? _partnerId;

  Future<void> connect([int? orderId]) async {
    final res = await ApiClient.get(ApiConfig.chatFirebaseToken(orderId));
    final token = res['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Chat authentication failed.');
    }

    _threadId = res['thread_id']?.toString();
    _customerId = (res['customer_id'] as num?)?.toInt();
    _orderCode = res['order_code']?.toString();
    _partnerId = (res['delivery_partner_id'] as num?)?.toInt();

    await FirebaseAuth.instance.signInWithCustomToken(token);
  }

  Stream<List<Map<String, dynamic>>> myThreads() {
    final partnerId = _partnerId;
    if (partnerId == null) return const Stream.empty();

    return _db
        .collection('chat_threads')
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => {...d.data(), 'threadId': d.id})
              .where((d) => d['recipientRole'] == 'delivery')
              .toList();
          items.sort((a, b) {
            final at = a['lastMessageAt'];
            final bt = b['lastMessageAt'];
            if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
            if (bt is Timestamp) return 1;
            if (at is Timestamp) return -1;
            return 0;
          });
          return items;
        });
  }

  Stream<List<Map<String, dynamic>>> messages() {
    if (_threadId == null) return const Stream.empty();
    return _db
        .collection('chat_threads')
        .doc(_threadId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> markRead() async {
    if (_threadId == null) return;
    final ref = _db.collection('chat_threads').doc(_threadId);
    if ((await ref.get()).exists) {
      await ref.update({'unreadForDelivery': 0});
    }
  }

  Future<void> send(String text) async {
    if (_threadId == null) throw Exception('Chat is not connected.');

    final ref = _db.collection('chat_threads').doc(_threadId);
    final snap = await ref.get();
    final orderId = _threadId!.split('_').length > 2
        ? int.tryParse(_threadId!.split('_')[2])
        : null;

    if (!snap.exists) {
      if (_customerId == null || _partnerId == null || orderId == null) {
        throw Exception('Customer chat is unavailable.');
      }
      await ref.set({
        'userId': _customerId,
        'recipientRole': 'delivery',
        'deliveryPartnerId': _partnerId,
        'orderId': orderId,
        'orderCode': _orderCode,
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForDelivery': 0,
        'unreadForCustomer': 1,
        'status': 'open',
      });
    } else {
      await ref.update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForCustomer': FieldValue.increment(1),
        'unreadForDelivery': 0,
        'status': 'open',
      });
    }

    await ref.collection('messages').add({
      'sender': 'delivery',
      'message': text,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
