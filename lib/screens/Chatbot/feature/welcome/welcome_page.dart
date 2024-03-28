import 'package:pdfeditor/screens/Chatbot/core/config/assets_constants.dart';
import 'package:pdfeditor/screens/Chatbot/core/extension/context.dart';
import 'package:pdfeditor/screens/Chatbot/feature/welcome/widgets/api_key_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              const Positioned(
                left: -300,
                top: -00,
                child: SizedBox(
                  height: 500,
                  width: 600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(
                      height: 40,
                    ),
                    Lottie.asset(
                      AssetConstants.onboardingAnimation,
                    ),
                    Text(
                      'Chat with PDF!',
                      style: context.textTheme.bodyLarge!.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final TextEditingController apiKeyController =
                            TextEditingController();

                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return APIKeyBottomSheet(
                              apiKeyController: apiKeyController,
                              isCalledFromHomePage: false,
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 48, 48),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: Text(
                        'Get Started',
                        style: context.textTheme.labelLarge!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
