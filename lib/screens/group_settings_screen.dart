import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/user_profile.dart';
import '../services/group_repository.dart';
import '../services/user_repository.dart';
import '../widgets/user_avatar.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupSettingsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  GroupSettingsScreenState createState() => GroupSettingsScreenState();
}

class GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _showAddUser = false;
  List<UserProfile> _groupMembers = [];
  Group? _group;
  String? _currentUserId;
  bool _isNameChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupName);
    _nameController.addListener(_checkNameChanged);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadGroup();
  }

  void _checkNameChanged() {
    final newValue = _nameController.text != widget.groupName;
    if (_isNameChanged != newValue) {
      setState(() {
        _isNameChanged = newValue;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkNameChanged);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Capture repository before async operation
      final groupRepository = Provider.of<GroupRepository>(
        context,
        listen: false,
      );

      final group = await groupRepository.getGroupById(widget.groupId);

      if (!mounted) return;

      if (group != null) {
        _group = group;
        await _loadGroupMembers();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGroupMembers() async {
    if (_group == null) return;

    // Capture repository before async operation
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    final members = <UserProfile>[];

    for (final memberId in _group!.memberIds) {
      final member = await userRepository.getUserProfile(memberId);
      if (!mounted) return;

      if (member != null) {
        members.add(member);
      }
    }

    if (mounted) {
      setState(() {
        _groupMembers = members;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    if (newName != widget.groupName) {
      setState(() {
        _isLoading = true;
      });

      // Capture references before async operations
      final groupRepository = Provider.of<GroupRepository>(
        context,
        listen: false,
      );
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      try {
        await groupRepository.updateGroupName(widget.groupId, newName);

        if (!mounted) return;

        final error = groupRepository.error;
        if (error != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Group updated successfully')),
          );
          navigator.pop(true); // Return true to indicate update
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      Navigator.pop(context, false); // No changes made
    }
  }

  Future<void> _addUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Capture references before async operations
    final groupRepository = Provider.of<GroupRepository>(
      context,
      listen: false,
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final success = await groupRepository.addUserToGroup(
        widget.groupId,
        email,
      );

      if (!mounted) return;

      if (success) {
        _emailController.clear();
        await _loadGroup(); // Reload the group to get updated member list

        if (!mounted) return;

        setState(() {
          _showAddUser = false;
        });
      } else {
        final error = groupRepository.error;
        if (error != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeUser(String userId) async {
    // Capture navigator before async operation
    //final navigator = Navigator.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove User'),
            content: Text('Are you sure you want to remove this user?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Remove'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    // Capture repository before async operation
    final groupRepository = Provider.of<GroupRepository>(
      context,
      listen: false,
    );

    try {
      await groupRepository.removeUserFromGroup(widget.groupId, userId);

      if (!mounted) return;

      await _loadGroup(); // Reload the group to get updated member list
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _leaveGroup() async {
    // Capture navigator before async operation
    final navigator = Navigator.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Leave Group'),
            content: Text('Are you sure you want to leave this group?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Leave'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    // Capture repository before async operation
    final groupRepository = Provider.of<GroupRepository>(
      context,
      listen: false,
    );

    try {
      await groupRepository.leaveGroup(widget.groupId);

      if (!mounted) return;

      // Return to chat screen with result code to indicate group was left
      navigator.pop('left');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGroup() async {
    // Capture references before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Group'),
            content: Text(
              'Are you sure you want to delete this group? This action cannot be undone.',
              style: TextStyle(color: Colors.red[700]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    // Capture repository before async operation
    final groupRepository = Provider.of<GroupRepository>(
      context,
      listen: false,
    );

    try {
      final success = await groupRepository.deleteGroup(widget.groupId);

      if (!mounted) return;

      if (success) {
        // Return to chat screen with result code to indicate group was deleted
        navigator.pop('deleted');
      } else {
        final error = groupRepository.error;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to delete group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //final bool isNameChanged = _nameController.text != widget.groupName;
    final bool isCurrentUserCreator = _group?.creatorId == _currentUserId;
    final bool isGeneralGroup = widget.groupId == 'general';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Settings',
          style: TextStyle(
            color: Color(0xFF111111),
            fontFamily: 'EbGaramond',
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.0),
                      Text(
                        'Group Members',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_showAddUser)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter user email',
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              0,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: _addUser,
                                    ),
                                  ],
                                ),
                              ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _groupMembers.length,
                              itemBuilder: (context, index) {
                                final member = _groupMembers[index];
                                final isCurrentUser =
                                    member.uid == _currentUserId;

                                return ListTile(
                                  leading: UserAvatar.fromProps(
                                    profileUrl: member.avatarUrl,
                                    displayName: member.displayName,
                                    size: 40,
                                  ),
                                  title: Text(member.displayName),
                                  subtitle: Text(member.email),
                                  trailing:
                                      _isEditing && !isCurrentUser
                                          ? IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                () => _removeUser(member.uid),
                                          )
                                          : null,
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text('Add Users'),
                                    onPressed: () {
                                      setState(() {
                                        _showAddUser = !_showAddUser;
                                      });
                                    },
                                  ),
                                  TextButton(
                                    child: Text(_isEditing ? 'Done' : 'Edit'),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = !_isEditing;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      // Buttons section - rearranged to be side by side
                      Row(
                        children: [
                          // Save Changes Button (left)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isNameChanged ? _saveChanges : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: 2.0,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  elevation: 0,
                                  disabledBackgroundColor: Colors.grey,
                                ),
                                child: Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Leave/Delete Group Button (right)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 8.0),
                              decoration: BoxDecoration(
                                boxShadow:
                                    isGeneralGroup
                                        ? null
                                        : [
                                          BoxShadow(
                                            color: Colors.black,
                                            offset: Offset(4, 4),
                                            blurRadius: 0,
                                            spreadRadius: 0,
                                          ),
                                        ],
                              ),
                              child:
                                  isCurrentUserCreator && !isGeneralGroup
                                      ? // For creators, show delete group button
                                      ElevatedButton(
                                        onPressed: _deleteGroup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide(
                                              color: Colors.black,
                                              width: 2.0,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.0,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'DELETE Group',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                      : // For non-creators or in general group
                                      OutlinedButton(
                                        onPressed:
                                            !isGeneralGroup
                                                ? _leaveGroup
                                                : null,
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          side: BorderSide(
                                            color: Colors.black,
                                            width: 2.0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.0,
                                          ),
                                          disabledForegroundColor: Colors.grey
                                              .withValues(alpha: 0.5),
                                        ),
                                        child: Text(
                                          'Leave Group',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),

                      // Note for general group or creator status
                      if (isCurrentUserCreator && isGeneralGroup) ...[
                        SizedBox(height: 8.0),
                        Text(
                          'Note: You cannot leave the general group.',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (isCurrentUserCreator && !isGeneralGroup) ...[
                        SizedBox(height: 8.0),
                        Text(
                          'Note: As the creator, you must delete this group rather than leave it.',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
    );
  }
}
