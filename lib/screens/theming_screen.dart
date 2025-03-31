import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/user_repository.dart';

class ThemingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userRepository = Provider.of<UserRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Settings'),
        leading: BackButton(
          onPressed: () {
            // Cancel changes if navigating back without saving
            themeProvider.cancelChanges();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select theme seed color:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // Theme color grid - updated with adaptive layout
            _buildThemeColorGrid(context, themeProvider),

            SizedBox(height: 32),

            // Theme preview title moved outside of container
            Text(
              'Theme Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),

            // UI Element previews with neo-brutalist styling
            _buildUiPreviewSection(context),

            SizedBox(height: 24),

            // Save changes button
            _buildSaveButton(context, themeProvider, userRepository),
          ],
        ),
      ),
    );
  }

  // Adaptive color options layout
  Widget _buildThemeColorGrid(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    // Calculate a reasonable size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    // Make squares 25% larger than previous implementation
    final squareSize = screenWidth * 0.09375; // 0.075 * 1.25 = 0.09375

    // Determine whether to use wrap or row based on available space
    // We need to fit 6 squares with 8px spacing in between
    final totalSpacing = 5 * 8.0; // 5 spaces between 6 items
    final totalSquaresWidth = 6 * squareSize;
    final isWrapNeeded =
        totalSquaresWidth + totalSpacing >
        screenWidth - 32; // 32 for horizontal padding

    return SizedBox(
      width: double.infinity,
      child:
          isWrapNeeded
              ? Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: _buildColorSquares(themeProvider, squareSize),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:
                    _buildColorSquares(themeProvider, squareSize)
                        .map(
                          (square) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: square,
                          ),
                        )
                        .toList(),
              ),
    );
  }

  List<Widget> _buildColorSquares(ThemeProvider themeProvider, double size) {
    return ThemeProvider.availableColors.map((color) {
      final isSelected = color.toARGB32() == themeProvider.seedColor.toARGB32();

      return SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          onTap: () {
            themeProvider.changeSeedColor(color);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child:
                isSelected
                    ? Center(
                      child: Icon(
                        Icons.check,
                        color: _getContrastColor(color),
                        size: size * 0.5,
                      ),
                    )
                    : null,
          ),
        ),
      );
    }).toList();
  }

  // Preview of UI elements with the selected theme - now with neo-brutalist styling
  Widget _buildUiPreviewSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar preview
          Container(
            height: 56,
            color: theme.colorScheme.primary,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'App Bar',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Message bubbles preview
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Sender message',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 40),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 40),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Your message',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Buttons preview with neo-brutalist styling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildNeoButton(context, 'Button', () {})],
          ),
        ],
      ),
    );
  }

  // Neo-brutalist styled button
  Widget _buildNeoButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Save button with neo-brutalist styling
  Widget _buildSaveButton(
    BuildContext context,
    ThemeProvider themeProvider,
    UserRepository userRepository,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color:
              themeProvider.hasChanges
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow:
              themeProvider.hasChanges
                  ? [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                themeProvider.hasChanges
                    ? () async {
                      await themeProvider.saveChanges(userRepository);
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Theme saved successfully!')),
                        );
                        navigator.pop();
                      }
                    }
                    : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                'Save Changes',
                style: TextStyle(
                  color:
                      themeProvider.hasChanges
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to determine a contrasting text color
  Color _getContrastColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
