import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/message_status.dart';
import '../models/user_profile.dart';
import '../widgets/user_avatar.dart';
import '../services/user_repository.dart';

class ChatMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  @override
  void initState() {
    super.initState();
    // Schedule a scroll to bottom after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Scroll to bottom when messages change
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (widget.messages.isEmpty || !widget.scrollController.hasClients) return;

    widget.scrollController.animateTo(
      widget.scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      child: Scrollbar(
        controller: widget.scrollController,
        thumbVisibility: false,
        child: ListView.builder(
          controller: widget.scrollController,
          reverse: false,
          padding: const EdgeInsets.all(8.0),
          itemCount: widget.messages.length,
          physics: BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            // Get the message
            final message = widget.messages[index];
            // Format the timestamp with contextual date information
            final formattedTime = _getFormattedTimestamp(message.timestamp);
            // Calculate avatar size based on device type
            final double avatarSize = _getAvatarSize(context);
            // Process the message text to ensure line breaks are preserved
            final processedText = _processMarkdownText(message.text);

            return FutureBuilder<UserProfile?>(
              future: Provider.of<UserRepository>(
                context,
                listen: false,
              ).getUserProfile(message.senderId),
              builder: (context, snapshot) {
                final displayName =
                    snapshot.data?.displayName ?? message.senderName;

                return Column(
                  crossAxisAlignment:
                      message.isFromCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    // Sender info row
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        bottom: 4.0,
                        right: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            message.isFromCurrentUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        children: [
                          Text(
                            displayName, // Use the latest display name
                            style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontSize: 14.0,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (message.isFromCurrentUser) ...[
                            SizedBox(width: 8.0),
                            _buildStatusIcon(message.status),
                          ],
                        ],
                      ),
                    ),
                    // Message with avatar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar for other users (left side)
                        if (!message.isFromCurrentUser) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildAvatar(context, message, avatarSize),
                          ),
                          SizedBox(width: 8.0),
                        ],
                        // Message bubble
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                              bottom: 16.0,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color:
                                  message.isFromCurrentUser
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                      : Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4.0, 4.0),
                                  blurRadius: 0.0,
                                ),
                              ],
                            ),
                            child: MarkdownBody(
                              data: processedText,
                              softLineBreak: false,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontSize: 18.0,
                                ),
                                textAlign: WrapAlignment.start,
                              ),
                            ),
                          ),
                        ),
                        // Avatar for current user (right side)
                        if (message.isFromCurrentUser) ...[
                          SizedBox(width: 8.0),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildAvatar(context, message, avatarSize),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Helper method to display message status icon
  Widget _buildStatusIcon(MessageStatus status) {
    const iconSize = 12.0;
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.check, size: iconSize, color: Colors.grey);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: iconSize, color: Colors.grey);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: iconSize, color: Colors.blue);
      case MessageStatus.error:
        return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
    }
  }

  Widget _buildAvatar(BuildContext context, ChatMessage message, double size) {
    return FutureBuilder<UserProfile?>(
      future: Provider.of<UserRepository>(
        context,
        listen: false,
      ).getUserProfile(message.senderId),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return UserAvatar(userProfile: profile, size: size);
      },
    );
  }

  // Helper method to process markdown text to preserve line breaks
  String _processMarkdownText(String text) {
    // Replace single newlines with two spaces followed by newline
    // This is the markdown way to force a line break
    return text.replaceAll('\n', '  \n');
  }

  // Helper method to determine avatar size based on device
  double _getAvatarSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen width
    if (screenWidth < 360) {
      return 56.0; // Small phones
    } else if (screenWidth < 600) {
      return 56.0; // Regular phones
    } else if (screenWidth < 900) {
      return 56.0; // Tablets
    } else {
      return 56.0; // Desktop or large tablets
    }
  }

  // Helper method to format timestamp with contextual date information
  String _getFormattedTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MM/dd');

    if (messageDate == today) {
      return 'Today at ${timeFormat.format(timestamp)}';
    } else if (messageDate == yesterday) {
      return 'Yesterday at ${timeFormat.format(timestamp)}';
    } else {
      return '${dateFormat.format(timestamp)} at ${timeFormat.format(timestamp)}';
    }
  }
}
