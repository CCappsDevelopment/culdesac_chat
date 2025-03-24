// widgets/user_avatar.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserAvatar extends StatelessWidget {
  final UserProfile? userProfile;
  final double radius;

  const UserAvatar({super.key, required this.userProfile, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage:
          userProfile?.avatarUrl != null
              ? NetworkImage(userProfile!.avatarUrl!)
              : null,
      child:
          userProfile?.avatarUrl == null
              ? Text(
                userProfile?.displayName.substring(0, 1).toUpperCase() ?? "?",
                style: TextStyle(
                  fontSize: radius * 0.8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
    );
  }
}
