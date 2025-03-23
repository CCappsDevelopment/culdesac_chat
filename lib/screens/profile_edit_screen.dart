import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userProfile = await context.read<UserRepository>().getUserProfile(
        currentUser.uid,
      );
      if (_userProfile != null) {
        _displayNameController = TextEditingController(
          text: _userProfile!.displayName,
        );
      } else {
        _displayNameController = TextEditingController();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await context.read<UserRepository>().updateUserProfile(
          displayName: _displayNameController.text,
        );

        // Update local cache after successful save
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
    // Use the cached user profile instead of watching
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
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage:
                            userProfile.avatarUrl != null
                                ? NetworkImage(userProfile.avatarUrl!)
                                : null,
                        child:
                            userProfile.avatarUrl == null
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
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator()
                                : Text('Save Profile'),
                      ),
                      // Future feature: Avatar upload button
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: Icon(Icons.image),
                        label: Text('Change Avatar (Coming Soon)'),
                        onPressed: null, // Disabled for now
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
