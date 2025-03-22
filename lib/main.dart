import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'screens/chat_screen.dart';
import 'services/chat_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firestore settings for both web and mobile
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kIsWeb) {
    // Additional web-specific configuration if needed
    // For example, you might want to configure network connectivity assumptions
    FirebaseFirestore.instance.enableNetwork();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatRepository(),
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
      home: ChatScreen(),
    );
  }
}
