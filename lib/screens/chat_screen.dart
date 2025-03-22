import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/message_input.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          senderId: 'test_user', // Temporary value
          groupId: 'test_group', // Temporary value
        ),
      );
    });

    // Scroll to the bottom after the UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Since we're using reverse: true, 0.0 is the bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearAllMessages() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.33,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Text(
                AppConstants.appTitle,
                style: TextStyle(color: Color(0xFF222222), fontSize: 24),
              ),
            ),
            // Add drawer items here
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          AppConstants.appTitle,
          style: TextStyle(
            color: Color(0xFF111111),
            fontFamily: 'EbGaramond',
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            fontSize: 32,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Trash can icon for debugging
          IconButton(
            icon: Icon(Icons.delete, color: Color(0xFF222222)),
            onPressed: _clearAllMessages,
            tooltip: 'Clear all messages',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ChatMessageList(
              messages: _messages,
              scrollController: _scrollController,
            ),
          ),
          MessageInput(onSubmitted: _handleSubmitted),
        ],
      ),
    );
  }
}
