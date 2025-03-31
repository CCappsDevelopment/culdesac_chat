// widgets/user_avatar.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;

class UserAvatar extends StatelessWidget {
  final UserProfile? userProfile;
  final String? profileUrl;
  final String? displayName;
  final double size;
  final bool isDrawerAvatar;

  /// Create an avatar from a UserProfile object
  const UserAvatar({
    super.key,
    this.userProfile,
    this.size = 40,
    this.isDrawerAvatar = false,
  }) : profileUrl = null,
       displayName = null;

  /// Create an avatar from individual properties
  const UserAvatar.fromProps({
    super.key,
    required this.profileUrl,
    required this.displayName,
    this.size = 40,
    this.isDrawerAvatar = false,
  }) : userProfile = null;

  @override
  Widget build(BuildContext context) {
    // Determine which data source to use
    final String? avatarUrl = userProfile?.avatarUrl ?? profileUrl;
    final String? name = userProfile?.displayName ?? displayName;

    // Calculate sizes with 8px padding for regular avatars
    // or 16px padding for drawer avatars
    final padding = isDrawerAvatar ? 2.0 : 1.0;
    final avatarSize = size - (padding * 8); // padding on each side

    // Create a container with the avatar and then overlay a custom painter for the dashed border
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Centered avatar with appropriate padding from border
          Positioned.fill(
            child: Center(
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image:
                      avatarUrl != null
                          ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                  color:
                      avatarUrl == null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
                child:
                    avatarUrl == null && name != null && name.isNotEmpty
                        ? Center(
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: avatarSize * 0.35,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        : null,
              ),
            ),
          ),

          // Dashed border overlay with full size
          CustomPaint(
            size: Size(size, size),
            painter: DashedCircleBorderPainter(
              color: Colors.black,
              strokeWidth: 2.5,
              dashPattern: [5, 3],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw a dashed circle border
class DashedCircleBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  DashedCircleBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Calculate dash count and angle
    final double circumference = 2 * math.pi * radius;
    final dashLength = dashPattern[0];
    final gapLength = dashPattern[1];
    final double dashAngle = (dashLength / circumference) * 2 * math.pi;
    final double gapAngle = (gapLength / circumference) * 2 * math.pi;

    // Draw dashed circle
    double currentAngle = 0;
    while (currentAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
