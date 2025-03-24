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
import 'screens/profile_edit_screen.dart';
import 'services/chat_repository.dart';
import 'services/auth_service.dart';
import 'services/user_repository.dart';

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

  final userRepository = UserRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChatRepository()),
        ChangeNotifierProvider(create: (context) => userRepository),
        Provider<AuthService>(
          create: (_) => AuthService(userRepository: userRepository),
        ),
      ],
      child: CulDeSacChatApp(),
    ),
  );
}

class CulDeSacChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF01F6)),
      ),
      home: StreamBuilder<User?>(
        stream: context.read<AuthService>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;
            if (user != null) {
              // Initialize user data when authenticated
              context.read<UserRepository>().getUserProfile(user.uid);
              return ChatScreen();
            }
            return LoginScreen();
          }
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfileEditScreen(),
      },
    );
  }
}
