import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_repository.dart';
import '../models/user_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  ProfileEditScreenState createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  bool _isLoading = false;
  UserProfile? _userProfile;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Capture the repository before the async operation
      final userRepository = context.read<UserRepository>();

      _userProfile = await userRepository.getUserProfile(currentUser.uid);

      if (!mounted) return;

      if (_userProfile != null) {
        _displayNameController = TextEditingController(
          text: _userProfile!.displayName,
        );
      } else {
        _displayNameController = TextEditingController();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Capture the repository before the async operation
    final userRepository = context.read<UserRepository>();

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (!mounted) return;

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, we need to handle XFile differently
        final bytes = await pickedFile.readAsBytes();

        if (!mounted) return;

        await userRepository.updateProfileImageWeb(bytes, pickedFile.name);
      } else {
        // For mobile platforms
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await userRepository.updateProfileImage(_imageFile!);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Update display name
        await context.read<UserRepository>().updateUserProfile(
          displayName: _displayNameController.text,
        );

        // Update profile image if selected
        if (_imageFile != null) {
          await _formKey.currentContext!
              .read<UserRepository>()
              .updateProfileImage(_imageFile!);
        }

        // Update local cache
        await _loadUserProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update profile')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _userProfile;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body:
          userProfile == null
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (userProfile.avatarUrl != null
                                          ? NetworkImage(userProfile.avatarUrl!)
                                              as ImageProvider
                                          : null),
                              child:
                                  (userProfile.avatarUrl == null &&
                                          _imageFile == null)
                                      ? Text(
                                        userProfile.displayName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 40,
                                          color: Colors.white,
                                        ),
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a display name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      Container(
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
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Colors.black, width: 2.0),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            elevation: 0,
                            minimumSize: Size(double.infinity, 50),
                            disabledBackgroundColor: Colors.grey,
                          ).copyWith(
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  Set<WidgetState> states,
                                ) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.8);
                                  }
                                  return null;
                                }),
                          ),
                          child:
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
