# Changelog

### Update 1: X3DH Key Agreement Protocol Implementation
---
- Change 1: Added X3DH (Extended Triple Diffie-Hellman) protocol implementation
- Reasoning 1: Implement secure initial key agreement between users before encrypted messaging
---
- Change 2: Added one-time pre-key caching and management
- Reasoning 2: Enable proper one-time pre-key usage for enhanced security
---
###### Files affected:
   - lib/services/x3dh_service.dart
   - lib/services/key_service.dart
   - test/services/x3dh_service_test.dart

### Update #24: Key Generation and Management Service
---
- Change 1: Created KeyService for cryptographic key lifecycle management
- Reasoning 1: Provides centralized key generation and management for E2EE, including identity keys, signed pre-keys, and one-time pre-keys
---
- Change 2: Implemented automatic pre-key rotation and replenishment
- Reasoning 2: Ensures security through regular key rotation and maintains a sufficient pool of one-time pre-keys
---
- Change 3: Added comprehensive test suite for key management functionality
- Reasoning 3: Validates key generation, rotation, persistence, and proper cleanup of cryptographic material
---
###### Files affected:
- lib/services/key_service.dart (new)
- test/services/key_service_test.dart (new)

### Update #23: Secure Storage Implementation
---
- Change 1: Created secure storage abstraction layer for E2EE key management
- Reasoning 1: Provides a platform-independent way to securely store cryptographic keys using platform-specific encryption
---
- Change 2: Implemented comprehensive key management functionality
- Reasoning 2: Supports storing and retrieving identity keys, signed pre-keys, and one-time pre-keys required for E2EE
---
- Change 3: Added robust testing suite with mock secure storage
- Reasoning 3: Ensures reliable key storage operations across all platforms while enabling proper unit testing
---
###### Files affected:
- lib/services/secure_storage_service.dart (new)
- test/services/secure_storage_service_test.dart (new)
- pubspec.yaml

### Update #22: Hamburger Menu Avatar Enhancement
---
- Change 1: Added different padding for avatars based on their context
- Reasoning 1: Creates visual distinction between avatars in different UI contexts
---
- Change 2: Implemented 2px padding for drawer avatars vs. 1px for regular avatars
- Reasoning 2: Provides more visual spacing around the larger drawer avatar for better aesthetic balance
---
- Change 3: Added a new isDrawerAvatar property to the UserAvatar widget
- Reasoning 3: Makes the avatar component more versatile by allowing control over padding based on usage context
---
###### Files affected:
- lib/widgets/user_avatar.dart
- lib/screens/chat_screen.dart

### Update #21: Avatar Border Refinements
---
- Change 1: Added 1px padding between avatar circle and dashed border
- Reasoning 1: Creates visual breathing space between avatar content and border for improved aesthetic appeal
---
- Change 2: Improved avatar positioning with centered layout
- Reasoning 2: Ensures consistent avatar display across different screen sizes and device densities
---
- Change 3: Enhanced avatar border rendering with custom painter
- Reasoning 3: Provides precise control over border appearance and enables the dashed circle effect
---
###### Files affected:
- lib/widgets/user_avatar.dart

### Update #20: Avatar Styling Enhancement
---
- Change 1: Added thick, black, dashed borders to all user avatar instances
- Reasoning 1: Creates a consistent, distinctive styling for avatars that aligns with the neo-brutalist design language
---
- Change 2: Increased avatar size by 25% in chat screens
- Reasoning 2: Improves visibility and user experience by making avatars more prominent in conversations
---
- Change 3: Implemented custom painter for dashed circle border
- Reasoning 3: Standard Flutter widgets don't support dashed circular borders, so a custom implementation was needed
---
###### Files affected:
- lib/widgets/user_avatar.dart
- lib/widgets/chat_message_list.dart

### Update #19: Fixed Theme Flickering and Persistence
---
- Change 1: Completely refactored ThemeProvider implementation to prevent infinite update loops
- Reasoning 1: Original implementation caused screen flickering due to continuous state updates triggering rebuilds
---
- Change 2: Restructured app initialization flow with proper state management
- Reasoning 2: Separating initialization from render cycle prevents theme-related UI flickering during app startup
---
- Change 3: Added dedicated loadThemeFromProfile method for post-login theme loading
- Reasoning 3: Safely loads user theme preferences after authentication without triggering unnecessary rebuilds
---
- Change 4: Implemented initialization lock flags to prevent concurrent updates
- Reasoning 4: Ensures theme state is only updated once during critical lifecycle events
---
###### Files affected:
- lib/services/theme_provider.dart
- lib/main.dart
- lib/screens/login_screen.dart

### Update #18: Theme Persistence Fix
---
- Change 1: Converted main app widget to StatefulWidget for proper initialization
- Reasoning 1: Ensures that user data and theme preferences are properly loaded after app is initialized
---
- Change 2: Enhanced theme initialization flow with proper timing and state management
- Reasoning 2: Prevents theme from reverting to default on app restart by ensuring theme loads after authentication
---
- Change 3: Added explicit theme loading during login process
- Reasoning 3: Ensures user's theme preference is applied immediately after login without requiring app restart
---
- Change 4: Added diagnostic logs to theme loading process
- Reasoning 4: Improves debuggability of theme persistence issues by tracking theme changes in the console
---
###### Files affected:
- lib/main.dart
- lib/services/theme_provider.dart
- lib/screens/login_screen.dart

### Update #17: Fixed Post-Dispose setState() Errors
---
- Change 1: Added proper mounted state checking throughout ChatScreen async methods
- Reasoning 1: Prevents crashes when setState is called after widget is disposed due to asynchronous operations
---
- Change 2: Enhanced ThemeProvider with proper disposal handling
- Reasoning 2: Ensures theme updates don't trigger notifyListeners() after the provider is disposed
---
- Change 3: Improved message subscription lifecycle handling
- Reasoning 3: Prevents memory leaks and crashes when navigating away during active stream operations
---
###### Files affected:
- lib/screens/chat_screen.dart
- lib/services/theme_provider.dart

### Update #16: Theming Feature Implementation and Fixes
---
- Change 1: Implemented theme customization with user-selectable seed colors
- Reasoning 1: Allows users to personalize their app experience with color themes that persist across sessions
---
- Change 2: Added theme provider service to manage app-wide theme state
- Reasoning 2: Centralizes theme management and provides a clean API for theme changes throughout the app
---
- Change 3: Fixed theme initialization to prevent build-time setState errors
- Reasoning 3: Resolves the circular dependency that was causing app crashes by initializing themes before the widget tree builds
---
- Change 4: Styled theming UI elements with neo-brutalist design
- Reasoning 4: Maintains design consistency with the rest of the application while providing clear visual feedback
---
- Change 5: Optimized color selection grid for various screen sizes
- Reasoning 5: Ensures the theme color squares display properly on all devices without overwhelming the UI
---
###### Files affected:
- lib/services/theme_provider.dart (new)
- lib/screens/theming_screen.dart (new)
- lib/main.dart
- lib/models/user_profile.dart
- lib/services/user_repository.dart
- lib/screens/chat_screen.dart

### Update #15: User Registration Display Name Fix
---
- Change 1: Fixed display name not being correctly saved to Firestore user document during registration
- Reasoning 1: The previous implementation only updated the Firebase Authentication display name but not the Firestore document
---
- Change 2: Directly set user profile fields in Firestore during account creation
- Reasoning 2: Ensures all user data (including display name) is consistently saved in both Auth and Firestore
---
###### Files affected:
- lib/services/auth_service.dart

### Update #14: User Registration Feature Implementation
---
- Change 1: Created a registration screen with form validation and password visibility toggles
- Reasoning 1: Allows new users to create accounts with proper validation and security feedback
---
- Change 2: Extended AuthService to support user registration and email existence checking
- Reasoning 2: Provides secure user creation with proper validation and prevents duplicate accounts
---
- Change 3: Added registration route to app navigation system
- Reasoning 3: Makes the registration feature accessible from the login screen
---
###### Files affected:
- lib/screens/register_screen.dart (new)
- lib/services/auth_service.dart
- lib/main.dart

### Update #13: Authentication Method Name Fix
---
- Change 1: Fixed method name in LoginScreen from 'signInWithEmailPassword' to 'signInWithEmailAndPassword'
- Reasoning 1: Corrected the method call to match the actual method name defined in the AuthService class
---
###### Files affected:
- lib/screens/login_screen.dart

### Update #12: Neo-brutalist Button Design Implementation
---
- Change 1: Updated buttons with hard rectangular shapes and 2px black borders
- Reasoning 1: Aligns with neo-brutalist design philosophy for more raw and intentionally unpolished UI elements
---
- Change 2: Added consistent 4px black drop shadow offset to the right and down
- Reasoning 2: Creates the characteristic neo-brutalist "off-kilter" visual effect that emphasizes directness and intentionality
---
- Change 3: Rearranged buttons in the Group Settings screen to side-by-side layout
- Reasoning 3: Improves screen real estate usage and creates a more balanced UI with the save button on the left and action buttons on the right
---
- Change 4: Applied consistent styling across login, profile edit, create group and group settings screens
- Reasoning 4: Ensures visual cohesion throughout the application while maintaining the distinctive neo-brutalist aesthetic
---
###### Files affected:
- lib/screens/login_screen.dart
- lib/screens/profile_edit_screen.dart
- lib/screens/create_group_screen.dart
- lib/screens/group_settings_screen.dart

### Update #11: Fixed Message Loading and Scrolling Issues
---
- Change 1: Simplified message loading logic to ensure immediate display
- Reasoning 1: Previous implementation was causing messages to not appear until a new message was sent
---
- Change 2: Converted ChatMessageList to StatefulWidget with auto-scroll functionality
- Reasoning 2: Ensures automatic scrolling to bottom when messages first load or update
---
- Change 3: Added explicit scroll behavior during message list updates
- Reasoning 3: Fixes issue where messages would load but not automatically scroll to the bottom
---
- Change 4: Improved stream handling to prevent UI from getting stuck in loading state
- Reasoning 4: Immediately sets message stream in UI before setting up additional listeners
---
###### Files affected:
- lib/screens/chat_screen.dart
- lib/widgets/chat_message_list.dart

### Update #10: Fixed Message Loading Issues
---
- Change 1: Completely redesigned message loading mechanism using explicit stream subscriptions
- Reasoning 1: Fixes indeterminate loading issues when navigating to chat screens from any part of the app
---
- Change 2: Added proactive stream event handling with timeout fallback
- Reasoning 2: Ensures messages always display, even if the initial stream fetch is slow
---
- Change 3: Implemented proper stream cleanup to prevent memory leaks
- Reasoning 3: Cancels message subscriptions when switching groups or disposing the screen
---
- Change 4: Created forced initialization trigger for message streams
- Reasoning 4: Eliminates the scenario where messages only appear after receiving a new message
---
###### Files affected:
- lib/screens/chat_screen.dart

### Update #9: Fixed Window Resizing Mechanism
---
- Change 1: Replaced MediaQueryData listener with WidgetsBindingObserver pattern
- Reasoning 1: MediaQueryData doesn't have listener methods, causing compilation errors
---
- Change 2: Implemented proper size change detection with didChangeMetrics lifecycle hook
- Reasoning 2: This provides a standard Flutter approach to detecting screen dimension changes
---
- Change 3: Added size comparison logic to efficiently detect actual size changes
- Reasoning 3: Prevents unnecessary UI rebuilds by comparing old and new screen dimensions
---
###### Files affected:
- lib/screens/chat_screen.dart

### Update #8: Method Return Type Fix
---
- Change 1: Fixed return type of _navigateToGroupSettings method
- Reasoning 1: Changed method signature from void to Future<void> to match its implementation that returns futures
---
- Change 2: Ensured consistent return behavior when early-exiting the method
- Reasoning 2: Used Future.value() to maintain return type consistency throughout all code paths
---
###### Files affected:
- lib/screens/chat_screen.dart

### Update #7: Group Management Fixes
---
- Change 1: Prevented group creators from leaving their own groups
- Reasoning 1: Prevents orphaned groups in the database that no one can delete
---
- Change 2: Added explanatory message for group creators
- Reasoning 2: Clearly informs creators they must delete rather than leave groups they created
---
- Change 3: Fixed navigation after leaving/deleting a group
- Reasoning 3: Ensures users always return to the null group state after leaving or deleting a group
---
- Change 4: Added helper method to check group membership status
- Reasoning 4: Separates the group existence check from group switching for better UI handling
---
###### Files affected:
- lib/screens/group_settings_screen.dart
- lib/screens/chat_screen.dart

### Update #6: Scaffold Context Fix
---
- Change 1: Fixed FlutterError caused by invalid Scaffold context access
- Reasoning 1: The application was throwing an exception when trying to access Scaffold.of() from a context that didn't contain a Scaffold
---
- Change 2: Replaced Scaffold.of() with the safer Scaffold.maybeOf() approach
- Reasoning 2: Using maybeOf() pattern returns null instead of throwing exceptions when no Scaffold exists in the context
---
###### Files affected:
- lib/screens/chat_screen.dart

### Update #5: Drawer Navigation Fix
---
- Change 1: Fixed StateError in _switchToGroup method during window resizing
- Reasoning 1: The code was unconditionally calling Navigator.pop() without checking if the drawer was actually open
---
- Change 2: Added safety check for drawer state before attempting navigation
- Reasoning 2: Prevents "Bad state: No element" exception when resizing the application window
---
###### Files affected:
- lib/screens/chat_screen.dart

### Update #4: Group Management Enhancements
---
- Change 1: Added leave group and delete group functionality
- Reasoning 1: Users need the ability to leave or delete groups they no longer want to participate in
---
- Change 2: Added confirmation dialogs for destructive actions
- Reasoning 2: Preventing accidental group deletions or user removals enhances user experience
---
- Change 3: Created empty state UI for users with no groups
- Reasoning 3: Provides a clear message and call to action when a user has no available chat groups
---
- Change 4: Fixed button enable state in group settings
- Reasoning 4: Save Changes button now properly activates when group name is edited
---
- Change 5: Enhanced MessageInput widget with enabled/disabled state
- Reasoning 5: Message input is now properly disabled when no group is active
---
###### Files affected:
- lib/screens/group_settings_screen.dart
- lib/screens/chat_screen.dart
- lib/services/group_repository.dart
- lib/widgets/message_input.dart

### Update #3: Fixed UserAvatar Property in ChatMessageList
---
- Change 1: Updated the ChatMessageList to use the correct `size` property for UserAvatar widget
- Reasoning 1: The ChatMessageList was using a `radius` property which doesn't exist in the current UserAvatar implementation
---
###### Files affected:
- lib/widgets/chat_message_list.dart

### Update #2: UserAvatar Widget Enhancement
---
- Change 1: Enhanced UserAvatar widget to support multiple initialization patterns
- Reasoning 1: Made the widget more flexible by allowing it to be created either from a UserProfile object or from direct property inputs
---
- Change 2: Added UserAvatar.fromProps named constructor
- Reasoning 2: Enables creating avatars with individual properties for cases where a full UserProfile isn't available
---
- Change 3: Updated references in GroupSettingsScreen and ChatScreen
- Reasoning 3: Ensured proper usage of the enhanced UserAvatar widget throughout the application
---
###### Files affected:
- lib/widgets/user_avatar.dart
- lib/screens/group_settings_screen.dart
- lib/screens/chat_screen.dart

### Update #1: Group Functionality Implementation
---
- Change 1: Created Group model for representing chat groups
- Reasoning 1: Needed a structured way to store group data including name, members, and metadata
---
- Change 2: Created GroupRepository service
- Reasoning 2: Implemented a dedicated service for group management operations with Firebase including creation, updating, and managing membership
---
- Change 3: Added screens for group creation and management
- Reasoning 3: Users need interfaces to create new groups and manage existing ones including adding/removing users
---
- Change 4: Updated ChatScreen to support multiple groups
- Reasoning 4: Extended the interface to allow users to select different groups and view messages specific to each group
---
- Change 5: Updated drawer menu to display list of user's groups
- Reasoning 5: Makes navigating between different chat groups intuitive and matches the requested functionality
---
- Change 6: Refactored general group to include member list
- Reasoning 6: Standardized the data structure for all groups including the default general group
---
###### Files affected:
- lib/models/group.dart (new)
- lib/services/group_repository.dart (new)
- lib/screens/create_group_screen.dart (new)
- lib/screens/group_settings_screen.dart (new)
- lib/screens/chat_screen.dart
- lib/main.dart

