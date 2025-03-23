import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/message_status.dart';

class ChatRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ChatMessage> _messages = [];
  Map<String, Stream<List<ChatMessage>>> _messageStreams = {};

  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _firestore.collection('groups/${message.groupId}/messages').add({
        'text': message.text,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': message.status.index,
      });
    } catch (e) {
      _messages.add(message.copyWith(status: MessageStatus.error));
      notifyListeners();
    }
  }

  Stream<List<ChatMessage>> getMessages(String groupId) {
    // Return cached stream if it exists
    if (_messageStreams.containsKey(groupId)) {
      return _messageStreams[groupId]!;
    }

    // Create and cache new stream
    final stream = _firestore
        .collection('groups/$groupId/messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          final currentUser = FirebaseAuth.instance.currentUser;
          return snapshot.docs
              .map(
                (doc) => ChatMessage(
                  text: doc['text'],
                  senderId: doc['senderId'],
                  groupId: groupId,
                  senderName: doc['senderName'] ?? 'Unknown User',
                  timestamp:
                      (doc['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  status: MessageStatus.values[doc['status'] ?? 0],
                  isFromCurrentUser:
                      currentUser != null && doc['senderId'] == currentUser.uid,
                ),
              )
              .toList();
        });

    _messageStreams[groupId] = stream;
    return stream;
  }

  void clearCache() {
    _messageStreams.clear();
    _messages.clear();
    notifyListeners();
  }
}
