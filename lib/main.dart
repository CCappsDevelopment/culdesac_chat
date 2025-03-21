import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(CulDeSacChatApp());
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
