import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/chat/conversation_screen.dart';
import 'theme/scifi_theme.dart';

/// Entry point for Project Kevin.
///
/// Initializes the Flutter app with the SciFi theme and launches the
/// [ConversationScreen] as the home screen.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark theme and portrait orientation on mobile.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const KevinApp());
}

/// The root widget for Project Kevin.
///
/// Applies [SciFiTheme] globally and sets [ConversationScreen] as the home.
class KevinApp extends StatelessWidget {
  const KevinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kevin',
      debugShowCheckedModeBanner: false,
      theme: SciFiTheme.themeData,
      home: const ConversationScreen(),
    );
  }
}
