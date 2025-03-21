class ChatMessage {
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
