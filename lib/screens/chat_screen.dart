import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/message_input.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../services/chat_repository.dart';
import '../models/user_profile.dart';

class ChatScreen extends StatefulWidget {
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final String defaultGroupId = 'general';

  // Store provider references
  ChatRepository? _chatRepository;
  Stream<List<ChatMessage>>? _messagesStream;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    // Don't access providers here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatRepository = Provider.of<ChatRepository>(context, listen: false);

    // Initialize message stream if not already initialized
    if (_messagesStream == null) {
      _messagesStream = _chatRepository!.getMessages(defaultGroupId);
      _chatRepository!.addListener(_scrollToBottom);
    }

    // Always reload the user profile when dependencies change
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userProfile = await Provider.of<UserRepository>(
        context,
        listen: false,
      ).getUserProfile(currentUser.uid);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    // Use stored reference instead of accessing context
    if (_chatRepository != null) {
      _chatRepository!.removeListener(_scrollToBottom);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    final currentUser =
        Provider.of<AuthService>(context, listen: false).getCurrentUser();
    if (currentUser == null) return;

    // Reload the user profile before sending a message
    _loadUserProfile().then((_) {
      final message = ChatMessage(
        text: text,
        senderId: currentUser.uid,
        groupId: defaultGroupId,
        isFromCurrentUser: true,
        senderName: _userProfile?.displayName ?? "[User]",
      );

      // Send to Firestore
      Provider.of<ChatRepository>(context, listen: false).sendMessage(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _userProfile;

    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.33,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userProfile?.displayName ?? "User"),
              accountEmail: Text(userProfile?.email ?? ""),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage:
                    userProfile?.avatarUrl != null
                        ? NetworkImage(userProfile!.avatarUrl!)
                        : null,
                child:
                    userProfile == null || userProfile.avatarUrl == null
                        ? Text(
                          userProfile?.displayName
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              "U",
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        )
                        : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                Navigator.pop(context); // Close drawer first
                await Provider.of<AuthService>(
                  context,
                  listen: false,
                ).signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
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
        actions: [],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (_messagesStream == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }

                final messages = snapshot.data ?? [];

                return ChatMessageList(
                  messages: messages,
                  scrollController: _scrollController,
                );
              },
            ),
          ),
          MessageInput(onSubmitted: _handleSubmitted),
        ],
      ),
    );
  }
}
