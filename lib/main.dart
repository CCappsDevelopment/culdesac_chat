import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/theming_screen.dart';
import 'services/chat_repository.dart';
import 'services/auth_service.dart';
import 'services/user_repository.dart';
import 'services/group_repository.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firestore settings for both web and mobile
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kIsWeb) {
    FirebaseFirestore.instance.enableNetwork();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatRepository()),
        ChangeNotifierProvider(create: (_) => UserRepository()),
        ChangeNotifierProvider(create: (_) => GroupRepository()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ProxyProvider<UserRepository, AuthService>(
          update: (_, userRepo, __) => AuthService(userRepository: userRepo),
        ),
      ],
      child: CulDeSacChatApp(),
    );
  }
}

class CulDeSacChatApp extends StatefulWidget {
  @override
  CulDeSacChatAppState createState() => CulDeSacChatAppState();
}

class CulDeSacChatAppState extends State<CulDeSacChatApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // One-time initialization for the app
  Future<void> _initializeApp() async {
    final userRepository = context.read<UserRepository>();
    final themeProvider = context.read<ThemeProvider>();

    // Initialize user data
    await userRepository.initializeUserData();

    // Initialize theme only once
    if (!themeProvider.isInitialized) {
      await themeProvider.initializeTheme(userRepository);
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appTitle,
      theme: themeProvider.getTheme(),
      home:
          !_initialized
              ? Scaffold(body: Center(child: CircularProgressIndicator()))
              : AuthGate(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfileEditScreen(),
        '/create_group': (context) => CreateGroupScreen(),
        '/themes': (context) => ThemingScreen(),
      },
    );
  }
}

// Separated auth state handling into a standalone widget
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userRepository = context.read<UserRepository>();
    final themeProvider = context.read<ThemeProvider>();
    final groupRepository = context.read<GroupRepository>();

    return StreamBuilder<User?>(
      stream: context.read<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user != null) {
            // User is logged in, load their data
            userRepository.getUserProfile(user.uid).then((profile) {
              if (profile != null && context.mounted) {
                // Load the user's theme preference
                themeProvider.loadThemeFromProfile(profile);
              }
            });

            // Initialize general group
            groupRepository.initializeGeneralGroup();

            // Navigate to chat screen
            return ChatScreen();
          }

          // Not logged in, show login screen
          return LoginScreen();
        }

        // Waiting for auth state
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
