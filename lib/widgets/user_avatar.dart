// widgets/user_avatar.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserAvatar extends StatelessWidget {
  final UserProfile? userProfile;
  final String? profileUrl;
  final String? displayName;
  final double size;

  /// Create an avatar from a UserProfile object
  const UserAvatar({Key? key, this.userProfile, this.size = 40})
    : profileUrl = null,
      displayName = null,
      super(key: key);

  /// Create an avatar from individual properties
  const UserAvatar.fromProps({
    Key? key,
    required this.profileUrl,
    required this.displayName,
    this.size = 40,
  }) : userProfile = null,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine which data source to use
    final String? avatarUrl = userProfile?.avatarUrl ?? profileUrl;
    final String? name = userProfile?.displayName ?? displayName;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child:
          avatarUrl == null && name != null && name.isNotEmpty
              ? Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
    );
  }
}
