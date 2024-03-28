// ignore_for_file: use_build_context_synchronously

import 'package:pdfeditor/screens/Chatbot/core/extension/context.dart';
import 'package:pdfeditor/screens/Chatbot/core/navigation/route.dart';
import 'package:pdfeditor/screens/Chatbot/core/util/secure_storage.dart';

import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SecureStorage secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _navigateToNextPage();
  }

  Future<void> _navigateToNextPage() async {
    final String? apiKey = await secureStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      AppRoute.welcome.go(context);
    } else {
      AppRoute.home.go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'AI Chat',
          textAlign: TextAlign.center,
          style: context.textTheme.headlineLarge,
        ),
      ),
    );
  }
}
