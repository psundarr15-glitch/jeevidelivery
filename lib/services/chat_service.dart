import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'api_client.dart';
class DeliveryChatService {
  static final _db=FirebaseFirestore.instance; String? _threadId; int? _customerId; String? _orderCode; int? _partnerId;
  Future<void> connect(int orderId) async { final res=await ApiClient.get(ApiConfig.chatFirebaseToken(orderId)); final token=res['token']?.toString(); _threadId=res['thread_id']?.toString(); _customerId=(res['customer_id'] as num?)?.toInt(); _orderCode=res['order_code']?.toString(); _partnerId=int.tryParse(FirebaseAuth.instance.currentUser?.uid.split('_').last ?? ''); if(token==null||_threadId==null) throw Exception('Chat authentication failed.'); await FirebaseAuth.instance.signInWithCustomToken(token); }
  Stream<List<Map<String,dynamic>>> messages(){if(_threadId==null)return const Stream.empty();return _db.collection('chat_threads').doc(_threadId).collection('messages').orderBy('createdAt').snapshots().map((s)=>s.docs.map((d)=>d.data()).toList());}
  Future<void> markRead() async { if (_threadId == null) return; final ref=_db.collection('chat_threads').doc(_threadId); if ((await ref.get()).exists) await ref.update({'unreadForDelivery':0}); }
  Future<void> send(String text) async {if(_threadId==null)throw Exception('Chat is not connected.'); final ref=_db.collection('chat_threads').doc(_threadId); final snap=await ref.get(); if(!snap.exists){if(_customerId==null||_partnerId==null)throw Exception('Customer chat is unavailable.'); await ref.set({'userId':_customerId,'recipientRole':'delivery','deliveryPartnerId':_partnerId,'orderId':int.parse(_threadId!.split('_')[2]),'orderCode':_orderCode,'lastMessage':text,'lastMessageAt':FieldValue.serverTimestamp(),'unreadForDelivery':0,'unreadForCustomer':1,'status':'open'});}else{await ref.update({'lastMessage':text,'lastMessageAt':FieldValue.serverTimestamp(),'unreadForCustomer':FieldValue.increment(1),'unreadForDelivery':0});} await ref.collection('messages').add({'sender':'delivery','message':text,'type':'text','createdAt':FieldValue.serverTimestamp()});}
}
