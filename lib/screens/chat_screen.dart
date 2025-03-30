import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/message_input.dart';
import '../models/chat_message.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../services/chat_repository.dart';
import '../services/group_repository.dart';
import '../models/user_profile.dart';
import '../widgets/user_avatar.dart';
import 'create_group_screen.dart';
import 'group_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Size? _oldSize;

  // Store current group ID
  String? _currentGroupId;
  String _currentGroupName = '';
  bool _hasGroups = false;

  // Store provider references
  late ChatRepository _chatRepository;
  late GroupRepository _groupRepository;
  Stream<List<ChatMessage>>? _messagesStream;
  UserProfile? _userProfile;
  StreamSubscription<List<ChatMessage>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    // Register as an observer to detect screen size changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatRepository = Provider.of<ChatRepository>(context, listen: false);
    _groupRepository = Provider.of<GroupRepository>(context, listen: false);

    // Store current size for comparison
    _oldSize = MediaQuery.of(context).size;

    // Initialize user data
    _loadUserProfile();

    // Check if user has any groups
    _checkAndSetGroup();
  }

  @override
  void didChangeMetrics() {
    // This is called when screen metrics change (including size changes)
    super.didChangeMetrics();

    // Need to use a post-frame callback because the new MediaQuery values
    // aren't available immediately in didChangeMetrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Get new size and compare with old size
      final newSize = MediaQuery.of(context).size;
      if (_oldSize != newSize) {
        _oldSize = newSize;
        _handleResize();
      }
    });
  }

  Future<void> _checkAndSetGroup() async {
    final hasGroups = await _groupRepository.hasAnyGroups();

    setState(() {
      _hasGroups = hasGroups;
    });

    if (hasGroups) {
      // If user has groups, try to initialize with 'general' group
      _groupRepository.initializeGeneralGroup();
      _switchToGroup('general', 'General');
    } else {
      // Clear any existing message stream
      setState(() {
        _currentGroupId = null;
        _currentGroupName = '';
        _messagesStream = null;
      });
    }
  }

  Future<void> _loadMessagesForCurrentGroup() async {
    // Cancel any existing subscription first
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    if (_currentGroupId == null) {
      setState(() {
        _messagesStream = null;
      });
      return;
    }

    // Important: Set message stream immediately in the UI to allow StreamBuilder to start
    final messageStream = _chatRepository.getMessages(_currentGroupId!);
    setState(() {
      _messagesStream = messageStream;
    });

    // Now add a subscription to handle scrolling after messages load
    _messageSubscription = messageStream.listen(
      (messages) {
        // Scroll to bottom after messages load and UI updates, but only if we have messages
        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      onError: (error) {
        // Handle error gracefully, stream is already set in UI
        print('Error loading messages: $error');
      },
    );
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

  Future<void> _switchToGroup(String groupId, String groupName) async {
    if (_currentGroupId == groupId) {
      // Use a safer approach to check and close the drawer
      final ScaffoldState? scaffold = Scaffold.maybeOf(context);
      if (scaffold != null && scaffold.isDrawerOpen) {
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _currentGroupId = groupId;
      _currentGroupName = groupName;
    });

    _loadMessagesForCurrentGroup();

    // Use a safer approach to check and close the drawer
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    // Cancel message subscription to prevent memory leaks
    _messageSubscription?.cancel();

    // Remove observer when disposing
    WidgetsBinding.instance.removeObserver(this);

    // Remove listener for scroll to bottom
    _chatRepository.removeListener(_scrollToBottom);

    _scrollController.dispose();
    super.dispose();
  }

  // Handle window resize events
  void _handleResize() {
    // Check if we had an active group before resize
    if (_currentGroupId != null && mounted) {
      // Force reload of the message stream
      _loadMessagesForCurrentGroup();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || _currentGroupId == null) return;

    final currentUser =
        Provider.of<AuthService>(context, listen: false).getCurrentUser();
    if (currentUser == null) return;

    // Reload the user profile before sending a message
    _loadUserProfile().then((_) {
      final message = ChatMessage(
        text: text,
        senderId: currentUser.uid,
        groupId: _currentGroupId!,
        isFromCurrentUser: true,
        senderName: _userProfile?.displayName ?? "[User]",
      );

      // Send to Firestore
      Provider.of<ChatRepository>(context, listen: false).sendMessage(message);

      // Scroll to bottom after sending
      _scrollToBottom();
    });
  }

  Future<void> _navigateToGroupSettings() async {
    if (_currentGroupId == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GroupSettingsScreen(
              groupId: _currentGroupId!,
              groupName: _currentGroupName,
            ),
      ),
    );

    // Handle group changes
    if (result == 'left' || result == 'deleted') {
      // Reset to null state regardless of whether user has other groups
      setState(() {
        _currentGroupId = null;
        _currentGroupName = '';
        _messagesStream = null;
      });

      // Then check if user has any groups (for UI state)
      await _checkHasGroups();
    } else if (result == true) {
      // Group name was updated
      final group = await _groupRepository.getGroupById(_currentGroupId!);
      if (group != null && mounted) {
        setState(() {
          _currentGroupName = group.name;
        });
      }
    }
  }

  // Helper method to just check if user has groups without switching to one
  Future<void> _checkHasGroups() async {
    final hasGroups = await _groupRepository.hasAnyGroups();

    if (mounted) {
      setState(() {
        _hasGroups = hasGroups;
      });
    }
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateGroupScreen()),
    ).then((_) {
      // Check if user now has any groups after potentially creating one
      _checkAndSetGroup();
    });
  }

  Widget _buildEmptyGroupState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Create a new group from the menu to start chatting',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToCreateGroup,
            icon: Icon(Icons.add),
            label: Text('Create Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
                side: BorderSide(color: Colors.black, width: 2.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _userProfile;
    final bool hasActiveGroup = _currentGroupId != null;

    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.33,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userProfile?.displayName ?? "User"),
              accountEmail: Text(userProfile?.email ?? ""),
              currentAccountPicture: UserAvatar(
                userProfile: userProfile,
                size: 80,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Groups',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Create Group'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close drawer
                          _navigateToCreateGroup();
                        },
                      ),
                    ],
                  ),
                  Divider(),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Group>>(
                stream: _groupRepository.getUserGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data ?? [];

                  if (groups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No groups found.\nCreate a group to start chatting!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isSelected = group.id == _currentGroupId;

                      return ListTile(
                        title: Text(
                          group.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                        onTap: () => _switchToGroup(group.id, group.name),
                      );
                    },
                  );
                },
              ),
            ),
            Divider(),
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
          hasActiveGroup ? _currentGroupName : AppConstants.appTitle,
          style: TextStyle(
            color: Color(0xFF111111),
            fontFamily: 'EbGaramond',
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            fontSize: 28,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions:
            hasActiveGroup
                ? [
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: _navigateToGroupSettings,
                  ),
                ]
                : [],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body:
          !_hasGroups
              ? _buildEmptyGroupState()
              : Column(
                children: <Widget>[
                  Expanded(
                    child:
                        hasActiveGroup
                            ? StreamBuilder<List<ChatMessage>>(
                              stream: _messagesStream,
                              builder: (context, snapshot) {
                                if (_messagesStream == null ||
                                    snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error loading messages'),
                                  );
                                }

                                final messages = snapshot.data ?? [];

                                return ChatMessageList(
                                  messages: messages,
                                  scrollController: _scrollController,
                                );
                              },
                            )
                            : _buildEmptyGroupState(),
                  ),
                  MessageInput(
                    onSubmitted: _handleSubmitted,
                    enabled: hasActiveGroup,
                  ),
                ],
              ),
    );
  }
}
