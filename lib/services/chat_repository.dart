import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/message_status.dart';

class ChatRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ChatMessage> _messages = [];
  
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _firestore.collection('groups/${message.groupId}/messages').add({
        'text': message.text,
        'senderId': message.senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': message.status.index,
      });
    } catch (e) {
      _messages.add(message.copyWith(status: MessageStatus.error));
      notifyListeners();
    }
  }

  Stream<List<ChatMessage>> getMessages(String groupId) {
    return _firestore
        .collection('groups/$groupId/messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage(
                  text: doc['text'],
                  senderId: doc['senderId'],
                  groupId: groupId,
                  timestamp: (doc['timestamp'] as Timestamp).toDate(),
                  status: MessageStatus.values[doc['status']],
                ))
            .toList());
  }

  
}
