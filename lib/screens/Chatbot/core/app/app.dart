import 'package:pdfeditor/screens/Chatbot/core/app/style.dart';
import 'package:pdfeditor/screens/Chatbot/core/navigation/router.dart';
import 'package:flutter/material.dart';

class AIBuddy extends StatelessWidget {
  const AIBuddy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Chat',
      theme: darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
