import 'message_status.dart';

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final String senderId;
  final String groupId;
  final MessageStatus status;
  final bool isFromCurrentUser;
  final String senderName;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.groupId,
    this.senderName = "[Test User]",
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.isFromCurrentUser = true,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    DateTime? timestamp,
    String? senderId,
    String? groupId,
    MessageStatus? status,
    bool? isFromCurrentUser,
    String? senderName,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      groupId: groupId ?? this.groupId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      senderName: senderName ?? this.senderName,
    );
  }
}
