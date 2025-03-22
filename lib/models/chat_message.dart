import 'message_status.dart';

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final String senderId;
  final String groupId;
  final MessageStatus status;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.groupId,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    DateTime? timestamp,
    String? senderId,
    String? groupId,
    MessageStatus? status,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      groupId: groupId ?? this.groupId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
