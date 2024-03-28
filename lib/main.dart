import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/tools_screen.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'screens/HomePage/pdf_viewer_page.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdfeditor/screens/Chatbot/core/app/app.dart';
import 'package:pdfeditor/screens/Chatbot/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:loggy/loggy.dart';
import 'package:path_provider/path_provider.dart';

final List<GlobalKey<PdfEditorState>> _pdfEditorKeys = [
  GlobalKey<PdfEditorState>(),
  GlobalKey<PdfEditorState>(),
];
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialize the app
  WidgetsFlutterBinding.ensureInitialized();
  _initLoggy();
  _initGoogleFonts();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive
    ..init(appDocumentDir.path)
    ..registerAdapter(ChatBotAdapter());
  await Hive.openBox<ChatBot>('chatbots');

  // Run the app
  runApp(const MyApp());

  // Listen to media sharing intents
  ReceiveSharingIntent.getMediaStream().listen((value) {
    File pdf = File(value[0].path);
    openPDF(navigatorKey.currentContext!, pdf);
  }, onError: (err) {
    print("getMediaStream error: $err");
  });

  List<SharedMediaFile> sharedFiles =
      await ReceiveSharingIntent.getInitialMedia();
  if (sharedFiles.isNotEmpty) {
    File pdf = File(sharedFiles[0].path);
    openPDF(navigatorKey.currentContext!, pdf);
  }
}

void _initLoggy() {
  Loggy.initLoggy(
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.warning,
    ),
    logPrinter: const PrettyPrinter(),
  );
}

void _initGoogleFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
}

void openPDF(BuildContext context, File file) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? recentFiles = prefs.getStringList('recentFiles') ?? [];
  recentFiles.insert(0, file.path);
  await prefs.setStringList('recentFiles', recentFiles);
  await _pdfEditorKeys[0].currentState?.loadFiles();
  await _pdfEditorKeys[1].currentState?.loadFiles();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PDFViewerPage(file: file, key: UniqueKey()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: BottomTabBar(),
    );
  }
}

class BottomTabBar extends StatefulWidget {
  BottomTabBar({super.key});

  @override
  State<BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<BottomTabBar> {
  int _index = 0;

  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
          key: _pdfEditorKeys[0], isBookmarked: _index == 0 ? false : true),
      HomeScreen(
          key: _pdfEditorKeys[1], isBookmarked: _index == 0 ? false : true),
      const ProviderScope(
        child: AIBuddy(),
      ),
      const ToolsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: screens.asMap().entries.map((entry) {
          final int index = entry.key;
          final Widget screen = entry.value;
          return Offstage(
            offstage: _index != index,
            child: screen,
          );
        }).toList(),
      ),
      bottomNavigationBar: SlidingClippedNavBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        onButtonPressed: (value) {
          setState(() {
            _index = value;
          });
          if (value == 1) {
            _loadBookmarksInHomeScreen();
          }
        },
        iconSize: 30,
        activeColor: const Color.fromARGB(255, 195, 11, 11),
        barItems: [
          BarItem(
            icon: Icons.maps_home_work_rounded,
            title: 'Home',
          ),
          BarItem(
            icon: Icons.bookmark_added_rounded,
            title: 'Bookmarks',
          ),
          BarItem(
            icon: Icons.chat,
            title: 'ChatBot',
          ),
          BarItem(
            icon: Icons.settings,
            title: 'Tools',
          ),
        ],
      ),
    );
  }

  void _loadBookmarksInHomeScreen() {
    final PdfEditorState? homeScreenState = _pdfEditorKeys[_index].currentState;
    if (homeScreenState != null) {
      homeScreenState.loadBookmarks();
    }
  }
}
