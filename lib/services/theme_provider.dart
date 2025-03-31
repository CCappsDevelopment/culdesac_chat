import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/user_profile.dart';
import 'user_repository.dart';

class ThemeProvider extends ChangeNotifier {
  Color _seedColor;
  Color _previousSeedColor;
  bool _hasChanges = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Default theme color as specified - #FF00F5 (pink)
  static const Color defaultSeedColor = Color(0xFFFF00F5);

  // Available theme colors
  static const List<Color> availableColors = [
    Color(0xFF7DF9FF), // Cyan
    Color(0xFF2FFF2F), // Green
    Color(0xFFFF00F5), // Pink (default)
    Color(0xFF3300FF), // Blue
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF4911), // Orange
  ];

  ThemeProvider()
    : _seedColor = defaultSeedColor,
      _previousSeedColor = defaultSeedColor;

  Color get seedColor => _seedColor;
  bool get hasChanges => _hasChanges;
  bool get isInitialized => _isInitialized;

  // Get the theme data based on the current seed color
  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
    );
  }

  // Change theme temporarily (until saved or canceled)
  void changeSeedColor(Color color) {
    if (_seedColor.toARGB32() == color.toARGB32() || _isDisposed) return;

    _seedColor = color;
    _hasChanges = _seedColor.toARGB32() != _previousSeedColor.toARGB32();
    notifyListeners();
  }

  // Initialize theme from stored preferences - only called once on app startup
  Future<void> initializeTheme(UserRepository userRepository) async {
    if (_isDisposed || _isInitialized) return;

    // Only set this flag to true after we've completed initialization
    // to prevent repeated calls during app startup

    final user = userRepository.currentUserProfile;

    if (user != null && user.themeSeedColor != null) {
      _seedColor = Color(user.themeSeedColor!);
      _previousSeedColor = _seedColor;
    }

    _isInitialized = true;

    // Only notify listeners once at the end
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Load theme when user profile is available
  Future<void> loadThemeFromProfile(UserProfile? profile) async {
    if (_isDisposed || profile == null) return;

    if (profile.themeSeedColor != null) {
      final newColor = Color(profile.themeSeedColor!);

      // Only update if different
      if (newColor.toARGB32() != _seedColor.toARGB32()) {
        _seedColor = newColor;
        _previousSeedColor = newColor;
        _hasChanges = false;

        if (!_isDisposed) {
          notifyListeners();
        }
      }
    }
  }

  // Save theme changes
  Future<void> saveChanges(UserRepository userRepository) async {
    if (!_hasChanges || _isDisposed) return;

    final currentSeedColor = _seedColor.toARGB32();
    await userRepository.updateUserTheme(currentSeedColor);
    _previousSeedColor = _seedColor;
    _hasChanges = false;

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Cancel theme changes
  void cancelChanges() {
    if (!_hasChanges || _isDisposed) return;

    _seedColor = _previousSeedColor;
    _hasChanges = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Static helper to get the provider from context
  static ThemeProvider of(BuildContext context) =>
      Provider.of<ThemeProvider>(context, listen: false);
}
