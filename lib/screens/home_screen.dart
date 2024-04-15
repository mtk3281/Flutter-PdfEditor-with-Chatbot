import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'HomePage/load_pdf_file.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'HomePage/pdf_api.dart';
import 'HomePage/pdf_viewer_page.dart';
import 'package:intl/intl.dart' as intl;
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import 'package:pdfeditor/widget/RenameDialogue.dart';
import 'HomePage/DeleteDialogue.dart';
import 'HomePage/sort file.dart';
import 'HomePage/SearchPage.dart';
import 'package:pdfeditor/screens/HomePage/loadfile.dart';
import 'package:hive/hive.dart';

void main() async{
  bool isBookmarked = false;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(isBookmarked: isBookmarked));
}

class MyApp extends StatelessWidget {
  final bool isBookmarked;

  const MyApp({super.key, required this.isBookmarked});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDF Editor',
      theme: ThemeData(
        primaryColor: Colors.white,
        fontFamily: 'Lato',
      ),
      home: HomeScreen(isBookmarked: isBookmarked),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isBookmarked;
  final GlobalKey<PdfEditorState> pdfEditorKey = GlobalKey<PdfEditorState>();

  HomeScreen({super.key, required this.isBookmarked});

  @override
  PdfEditorState createState() => PdfEditorState();

  static PdfEditorState? of(BuildContext context) {
    final state = context.findAncestorStateOfType<PdfEditorState>();
    if (state != null) {
      return state;
    }
    return null;
  }
}

class PdfEditorState extends State<HomeScreen> with WidgetsBindingObserver {
  String _selectedOption = 'PDF files';
  final List<String> _categories = [
    "PDF files",
    "Word",
    "PPT",
    "Text",
    "Recents"
  ];

  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  late Map<String, List<String>> scanFiles;
  List<String> pdf_files = [];
  List<String> word_files = [];
  List<String> ppt_files = [];
  List<String> txt_files = [];
  List<String> _RecentsFiles = [];
  final List<String> _SearchFiles = [];
  List<String> Bookmarked = [];

  static const double kMinFlingVelocity = 200.0;
  double _dragStartX = 0.0;
  double dismissThreshold = 0.1; // Adjust as needed
  double _dragOffset = 0.0;
  double _previousDragOffset = 0.0;
  final double _dragVelocity = 0.0;
  bool _isCategoryChangePending = false;

  bool shouldStopDraging = false;
  bool _permStatus = false;
  bool Loading = false;
  int _len = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    loadFiles();
  }

  void loadBookmarks() {
    if (widget.isBookmarked && !_permStatus) {
      _requestPermission();
    }
    // _saveFiles();
    loadFiles();
  }

  void _initPermissions() async {
    _showStoragePermissionBottomSheet();
  }

  Future<void> _requestPermission() async {
    PermissionStatus status1 = await Permission.storage.request();
    PermissionStatus status2 = await Permission.manageExternalStorage.request();
    if (status1.isGranted && status2.isGranted) {
      setState(() {
        _permStatus = true;
      });
      var box = await Hive.openBox('permissionBox');
      await box.put('permissionStatus', true);
      await box.close();
      await loadPerm();
      if (_selectedOption == 'PDF files' &&
          pdf_files.isEmpty &&
          !widget.isBookmarked) {
        _scanPdfFiles();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _saveFiles();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _isScrolling = _scrollController.offset > 0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveFiles(); // Save recent files when the app is paused or inactive
    }
  }

  Future<void> _scanPdfFiles() async {
    print("Scanning");
    if (pdf_files.isEmpty &&
        word_files.isEmpty &&
        ppt_files.isEmpty &&
        txt_files.isEmpty) {
      setState(() {
        Loading = true;
      });
    }
    scanFiles = await FileFinder.findFiles(
        'storage/emulated/0', ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt']);
    setState(() {
      pdf_files = scanFiles['pdf'] ?? [];
      word_files = (scanFiles['doc'] ?? []) +
          (scanFiles['docx']?.toList() ?? []);
      ppt_files = (scanFiles['ppt'] ?? []) +
          (scanFiles['pptx']?.toList() ?? []);
      txt_files = scanFiles['txt'] ?? [];
    });
    String sortBy = 'File';
    String orderBy = 'Ascending';
    sortPathfile(sortBy, orderBy);
    await updateRecents();
    await _saveFiles();
    setState(() {
      Loading = false;
    });
  }

  Future<void> _saveFiles() async {
    print("Saving");
    var box = await Hive.openBox('fileBox');
    await box.put('pdfFiles', pdf_files);
    await box.put('recentFiles', _RecentsFiles);
    await box.put('word_files', word_files);
    await box.put('ppt_files', ppt_files);
    await box.put('txt_files', txt_files);
    await box.put('bookmarked', Bookmarked);
    _len = pdf_files.length;
    await box.close(); 
  }

  Future<void> loadPerm() async {
    print("Loading Perm");
    var perm = await Hive.openBox('permissionBox');
    setState(() {
      _permStatus = perm.get('permissionStatus', defaultValue: false);
    });
    await perm.close();
  }

  Future<void> loadFiles() async {
    print("Loading");
    var box = await Hive.openBox('fileBox');
    var perm = await Hive.openBox('permissionBox');
    setState(() {
      pdf_files = List<String>.from(box.get('pdfFiles', defaultValue: []));
      _RecentsFiles = List<String>.from(box.get('recentFiles', defaultValue: []));
      word_files = List<String>.from(box.get('word_files', defaultValue: []));
      ppt_files = List<String>.from(box.get('ppt_files', defaultValue: []));
      txt_files = List<String>.from(box.get('txt_files', defaultValue: []));
      Bookmarked = List<String>.from(box.get('bookmarked', defaultValue: []));
      _permStatus = perm.get('permissionStatus', defaultValue: false);
      _len = pdf_files.length;
    });
    await box.close();
    await perm.close();
  }

  Future<void> updateRecents() async {
    print("updateRecents");
    var box = await Hive.openBox('fileBox');
    List<String> updatedRecents = [];
    if(_RecentsFiles.length !=0)
    {
      for (var file in _RecentsFiles) {
          bool fileExists = false;
          for (var files in scanFiles.values) {
            if (files.contains(file)) {
              fileExists = true;
              break;
            }
          }
          if (fileExists) {
            updatedRecents.add(file);
          }
        }
        await box.put('recentFiles', updatedRecents);
        setState(() {
          _RecentsFiles = updatedRecents;
        });
    }
    await box.close();
    print("updateRecents complete"); 
  }
  
  void _addRecentFile(String filePath) async { 
      var box = await Hive.openBox('fileBox');
      List<String> _RecentsFiles = List<String>.from(box.get('recentFiles', defaultValue: []));
      setState((){
        if (_RecentsFiles.contains(filePath)) {
          _RecentsFiles.remove(filePath);
        }
        _RecentsFiles.insert(0, filePath);
        print(_RecentsFiles.length);
      });
      await box.put('recentFiles', _RecentsFiles);
      await loadFiles();
      await box.close();
  }

  Future<void> _sortRecentFile() async {
    var box = await Hive.openBox('fileBox');
    List<String> _RecentsFiles = List<String>.from(box.get('recentFiles', defaultValue: []));
    _RecentsFiles.sort();
    await box.put('recentFiles', _RecentsFiles);
    await box.close();
  }

  Color _getSelectedOptionColor() {
    switch (_selectedOption) {
      case 'PDF files':
        return const Color.fromRGBO(222, 32, 42, 1.000);
      case 'Text':
        return const Color.fromRGBO(99, 99, 99, 1.000);
      case 'Word':
        return const Color.fromRGBO(79, 141, 245, 1.000);
      case 'PPT':
        return const Color.fromRGBO(245, 185, 18, 1.000);
      case 'Recents':
        return Colors.black;
      default:
        return const Color.fromRGBO(
            49, 49, 61, 1.000); // Default color for unexpected options
    }
  }

  void _changeCategoryToRight() {
    int currentIndex = _categories.indexOf(_selectedOption);
    if (currentIndex < _categories.length - 1 && _selectedOption != 'Recents') {
      // Allow swipe right if not on the last category ("Recents")
      setState(() {
        _selectedOption = _categories[currentIndex + 1];
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _changeCategoryToLeft() {
    int currentIndex = _categories.indexOf(_selectedOption);
    if (currentIndex > 0 && _selectedOption != 'PDF files') {
      setState(() {
        _selectedOption = _categories[currentIndex - 1];
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    double currentX = details.globalPosition.dx;
    double deltaX = currentX - _dragStartX;
    double deltaY = details.delta.dy;
    _dragOffset = deltaX.clamp(-32.0, 32.0);
    _isCategoryChangePending = _dragOffset.abs() > dismissThreshold * 10;
    if (deltaY.abs() > 0.5) {
      _dragOffset = 0.0; // Reset offset to prevent category change
      _isCategoryChangePending = false; // Reset category change flag
    }
    setState(() {});
  }

  void _handleDragStart(DragStartDetails details) {
    _previousDragOffset = 0.0;
    _dragStartX = details.globalPosition.dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isCategoryChangePending) {
      // User swiped past the threshold (flag set in _handleDragUpdate)
      if (_dragOffset > 0) {
        HapticFeedback.lightImpact();
        _changeCategoryToLeft();
      } else {
        HapticFeedback.lightImpact();
        _changeCategoryToRight();
      }
      _dragOffset = 0.0;
      _isCategoryChangePending = false;
    } else {
      // User didn't swipe far enough or cancelled the drag, reset offset
      _dragOffset = 0.0;
    }
    setState(() {});
  }

void sortPathfile(String sortBy, String orderBy) async {
      switch (sortBy) {
        case "File":
          if (orderBy == "Ascending") {
            pdf_files.sort((a, b) => _getBaseName(a)
                .toLowerCase()
                .compareTo(_getBaseName(b).toLowerCase()));
            word_files.sort((a, b) => _getBaseName(a)
                .toLowerCase()
                .compareTo(_getBaseName(b).toLowerCase()));
            ppt_files.sort((a, b) => _getBaseName(a)
                .toLowerCase()
                .trim()
                .compareTo(_getBaseName(b).toLowerCase().trim()));
            txt_files.sort((a, b) => _getBaseName(a)
                .toLowerCase()
                .compareTo(_getBaseName(b).toLowerCase()));
            _RecentsFiles.sort((a, b) => _getBaseName(a)
                .toLowerCase()
                .compareTo(_getBaseName(b).toLowerCase()));
          } else {
            pdf_files.sort((a, b) => _getBaseName(b)
                .toLowerCase()
                .compareTo(_getBaseName(a).toLowerCase()));
            word_files.sort((a, b) => _getBaseName(b)
                .toLowerCase()
                .compareTo(_getBaseName(a).toLowerCase()));
            ppt_files.sort((a, b) => _getBaseName(b)
                .toLowerCase()
                .trim()
                .compareTo(_getBaseName(a).toLowerCase().trim()));
            txt_files.sort((a, b) => _getBaseName(b)
                .toLowerCase()
                .compareTo(_getBaseName(a).toLowerCase()));
            _RecentsFiles.sort((a, b) => _getBaseName(b)
                .toLowerCase()
                .compareTo(_getBaseName(a).toLowerCase()));
          }
          break;
        case "Date":
          if (orderBy == "Ascending") {
            pdf_files.sort((a, b) =>
                getFileCreationDate(a).compareTo(getFileCreationDate(b)));
            word_files.sort((a, b) =>
                getFileCreationDate(a).compareTo(getFileCreationDate(b)));
            ppt_files.sort((a, b) =>
                getFileCreationDate(a).compareTo(getFileCreationDate(b)));
            txt_files.sort((a, b) =>
                getFileCreationDate(a).compareTo(getFileCreationDate(b)));
            _RecentsFiles.sort((a, b) =>
                getFileCreationDate(a).compareTo(getFileCreationDate(b)));
          } else {
            pdf_files.sort((a, b) =>
                getFileCreationDate(b).compareTo(getFileCreationDate(a)));
            word_files.sort((a, b) =>
                getFileCreationDate(b).compareTo(getFileCreationDate(a)));
            ppt_files.sort((a, b) =>
                getFileCreationDate(b).compareTo(getFileCreationDate(a)));
            txt_files.sort((a, b) =>
                getFileCreationDate(b).compareTo(getFileCreationDate(a)));
            _RecentsFiles.sort((a, b) =>
                getFileCreationDate(b).compareTo(getFileCreationDate(a)));
          }
          break;
        case "Size":
          // Sort by size
          if (orderBy == "Ascending") {
            pdf_files.sort(
                (a, b) => File(a).lengthSync().compareTo(File(b).lengthSync()));
            word_files.sort(
                (a, b) => File(a).lengthSync().compareTo(File(b).lengthSync()));
            ppt_files.sort(
                (a, b) => File(a).lengthSync().compareTo(File(b).lengthSync()));
            txt_files.sort(
                (a, b) => File(a).lengthSync().compareTo(File(b).lengthSync()));
            _RecentsFiles.sort(
                (a, b) => File(a).lengthSync().compareTo(File(b).lengthSync()));
          } else {
            pdf_files.sort(
                (a, b) => File(b).lengthSync().compareTo(File(a).lengthSync()));
            word_files.sort(
                (a, b) => File(b).lengthSync().compareTo(File(a).lengthSync()));
            ppt_files.sort(
                (a, b) => File(b).lengthSync().compareTo(File(a).lengthSync()));
            txt_files.sort(
                (a, b) => File(b).lengthSync().compareTo(File(a).lengthSync()));
            _RecentsFiles.sort(
                (a, b) => File(b).lengthSync().compareTo(File(a).lengthSync()));
          }
          break;
      }
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setStringList(
      //     'pdfFiles', pdf_files); // Await saving operation
      // await prefs.setStringList('recentFiles', _RecentsFiles);
      // await prefs.setStringList('word_files', word_files);
      // await prefs.setStringList('ppt_files', ppt_files);
      // await prefs.setStringList('txt_files', txt_files);
      // await prefs.setStringList("bookmarked", Bookmarked);
      var box = await Hive.openBox('fileBox');
      await box.put('pdfFiles', pdf_files);
      await box.put('recentFiles', _RecentsFiles);
      await box.put('word_files', word_files);
      await box.put('ppt_files', ppt_files);
      await box.put('txt_files', txt_files);
      await box.put('bookmarked', Bookmarked);
      await box.close();
  }

  String _getBaseName(String filePath) {
    List<String> parts = filePath.split(Platform.pathSeparator);
    String fileName = parts.last;
    List<String> nameParts = fileName.split('.');
    String baseName = nameParts.first;
    baseName = baseName.trim();
    return baseName;
  }

  DateTime getFileCreationDate(String filePath) {
    File file = File(filePath);
    try {
      if (file.existsSync()) {
        return file.lastModifiedSync();
      } else {
        return DateTime.now();
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor:
            _getSelectedOptionColor(), // Dynamic color based on selection
        scrolledUnderElevation: 0.0,
        title: const Text('  PDF Editor'), // Leading space for alignment
        centerTitle: false,
        // titleSpacing: 20.0, // Adjust title spacing
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontFamily: 'Lato',
          fontSize: 24,
        ),
        // Adjust toolbar height
        toolbarHeight: 65.0,
        actions: widget.isBookmarked
            ? []
            : [
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  width: 10,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.folder_open_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () async {
                    final file = await PDFApi.pickFile();
                    if (file == null) return;
                    openPDF(context, file);
                    _RecentsFiles.add(file.path);
                  },
                ),
                const SizedBox(
                  width: 10,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.sort,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return FilterModalBottomSheet(
                          onApply: (sortBy, orderBy) {
                            setState(() {
                              sortPathfile(sortBy, orderBy);
                            });
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(60.0), // Adjust bottom section height
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Scroll horizontally
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0), // Adjust padding
            child: ToggleButtons(
              isSelected: [
                _selectedOption == 'PDF files',
                _selectedOption == 'Word',
                _selectedOption == 'PPT',
                _selectedOption == 'Text',
                _selectedOption == 'Recents',
              ],
              onPressed: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      _selectedOption = 'PDF files';
                    case 1:
                      _selectedOption = 'Word';
                    case 2:
                      _selectedOption = 'PPT';
                    case 3:
                      _selectedOption = 'Text';
                    case 4:
                      _selectedOption = 'Recents';
                    default:
                      _selectedOption = 'PDF files';
                    // Default color for unexpected options
                  }
                });
              },
              color: Color.fromARGB(255, 191, 177, 177),
              selectedColor: const Color.fromARGB(255, 255, 255, 255),
              selectedBorderColor: Colors.transparent,
              fillColor: Colors.transparent,
              splashColor: const Color.fromARGB(142, 133, 133, 133),
              borderRadius: BorderRadius.circular(15),
              borderWidth: 1,
              renderBorder: false,
              textStyle: const TextStyle(fontSize: 18, fontFamily: 'Lato'),
              children: const [
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16),
                  child: Text(
                    'PDF',style: TextStyle(fontSize: 17),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16),
                  child: Text(
                    'Word',style: TextStyle(fontSize: 17),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16),
                  child: Text(
                    'PPT',style: TextStyle(fontSize: 17),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16),
                  child: Text(
                    'Text',style: TextStyle(fontSize: 17),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16),
                  child: Text(
                    'Recents',style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: Transform.translate(
          offset: Offset(_dragOffset, 0.0),
          child: Stack(
            children: [
              Visibility(
                  visible: Loading,
                  child: const Center(child: CircularProgressIndicator())),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Visibility(
                      visible: !_permStatus && !Loading,
                      child: _buildPermissionDeniedScreen(context),
                    ),

                    //pdf files
                    _buildListView(
                      condition: _selectedOption == 'PDF files' &&
                          _permStatus &&
                          !widget.isBookmarked &&
                          !Loading,
                      itemCount: pdf_files
                          .where((filePath) => File(filePath).existsSync())
                          .length,
                      itemBuilder: (index) {
                        String filePath = pdf_files[index];
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No PDF files found',
                      emptyText: 'PDF',
                    ),

                    //word files
                    _buildListView(
                      condition: _selectedOption == 'Word' &&
                          _permStatus &&
                          !widget.isBookmarked &&
                          !Loading,
                      itemCount: word_files
                          .where((filePath) => File(filePath).existsSync())
                          .length,
                      itemBuilder: (index) {
                        String filePath = word_files[index];
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Word files found',
                      emptyText: 'Word',
                    ),

                    //ppt files
                    _buildListView(
                      condition: _selectedOption == 'PPT' &&
                          _permStatus &&
                          !widget.isBookmarked &&
                          !Loading,
                      itemCount: ppt_files
                          .where((filePath) => File(filePath).existsSync())
                          .length,
                      itemBuilder: (index) {
                        String filePath = ppt_files[index];
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No PPT files found',
                      emptyText: 'PPT',
                    ),

                    //Text files
                    _buildListView(
                      condition: _selectedOption == 'Text' &&
                          _permStatus &&
                          !widget.isBookmarked &&
                          !Loading,
                      itemCount: txt_files
                          .where((filePath) => File(filePath).existsSync())
                          .length,
                      itemBuilder: (index) {
                        String filePath = txt_files[index];
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Text files found',
                      emptyText: 'Text',
                    ),

                    // bookmarked pdf
                    _buildListView(
                      condition: _selectedOption == 'PDF files' &&
                          _permStatus &&
                          widget.isBookmarked,
                      itemCount: Bookmarked.where(
                          (path) => path.toLowerCase().endsWith(".pdf")).length,
                      itemBuilder: (index) {
                        String filePath = Bookmarked.where(
                                (path) => path.toLowerCase().endsWith(".pdf"))
                            .elementAt(index);
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Bookmarked PDF files found',
                      emptyText: 'Bookmarked PDF',
                    ),

                    // bookmarked text
                    _buildListView(
                      condition: _selectedOption == 'Text' &&
                          _permStatus &&
                          widget.isBookmarked,
                      itemCount: Bookmarked.where(
                          (path) => path.toLowerCase().endsWith(".txt")).length,
                      itemBuilder: (index) {
                        String filePath = Bookmarked.where(
                                (path) => path.toLowerCase().endsWith(".txt"))
                            .elementAt(index);
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Bookmarked Text files found',
                      emptyText: 'Bookmarked Text',
                    ),

                    // bookmarked ppt
                    _buildListView(
                      condition: _selectedOption == 'PPT' &&
                          _permStatus &&
                          widget.isBookmarked,
                      itemCount: Bookmarked.where(
                                  (path) => path.toLowerCase().endsWith(".ppt"))
                              .length +
                          Bookmarked.where((path) =>
                              path.toLowerCase().endsWith(".pptx")).length,
                      itemBuilder: (index) {
                        String filePath = Bookmarked.where((path) =>
                                path.toLowerCase().endsWith(".ppt") ||
                                path.toLowerCase().endsWith(".pptx"))
                            .elementAt(index);
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Bookmarked PPT files found',
                      emptyText: 'Bookmarked PPT',
                    ),

                    // bookmarked word
                    _buildListView(
                      condition: _selectedOption == 'Word' &&
                          _permStatus &&
                          widget.isBookmarked,
                      itemCount: Bookmarked.where(
                                  (path) => path.toLowerCase().endsWith(".doc"))
                              .length +
                          Bookmarked.where((path) =>
                              path.toLowerCase().endsWith(".docx")).length,
                      itemBuilder: (index) {
                        String filePath = Bookmarked.where((path) =>
                                path.toLowerCase().endsWith(".doc") ||
                                path.toLowerCase().endsWith(".docx"))
                            .elementAt(index);
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Bookmarked Word files found',
                      emptyText: 'Bookmarked Word',
                    ),

                    //Recents
                    _buildListView(
                      condition: _selectedOption == 'Recents' && _permStatus,
                      itemCount: _RecentsFiles.length,
                      itemBuilder: (index) {
                        String filePath = _RecentsFiles[index];
                        if (File(filePath).existsSync()) {
                          return PdfListTile(filePath, context);
                        }
                        return const SizedBox();
                      },
                      // emptyText: 'No Recent files found',
                      emptyText: 'Recent',
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

  Widget _buildListView({
    required bool condition,
    required int itemCount,
    required Widget Function(int) itemBuilder,
    String? emptyText,
  }) {
    return Visibility(
      visible: condition,
      child: Expanded(
        child: itemCount > 0
            ? RefreshIndicator(
                color: Colors.black,
                onRefresh: () {
                  _scanPdfFiles();
                  return Future<void>.value();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: itemCount,
                  itemBuilder: (context, index) => itemBuilder(index),
                ),
              )
            : RefreshIndicator(
                color: Colors.black,
                onRefresh: () {
                  if (_selectedOption == 'Recents' || widget.isBookmarked) {
                    _saveFiles();
                    loadFiles();
                  } else if (!widget.isBookmarked) {
                    _scanPdfFiles();
                  }
                  return Future<void>.value();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/no-recent-search.png',
                            width: MediaQuery.of(context).size.width - 140,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 15.0),
                          Text(
                            'No $emptyText Files',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato'),
                          ),
                          const SizedBox(height: 20.0),
                        ],
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/no-permission.png',
            width: MediaQuery.of(context).size.width - 150,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20.0),
          const Text(
            'Permission Required',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
          ),
          const SizedBox(height: 20.0),
          const Text(
            'Allow PDF Editor to access your files',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () {
              _showStoragePermissionBottomSheet();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            ),
            child: const Text(
              'Allow',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoragePermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.49,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Storage Permission Required',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Due to system restrictions, PDF files Access permission is required to read all local files.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.asset(
                  'assets/access-permission.png',
                  width: MediaQuery.of(context).size.width - 130,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _requestPermission();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  minimumSize: Size(MediaQuery.of(context).size.width - 70, 55),
                  backgroundColor: const Color.fromARGB(255, 242, 53, 39),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12.0),
                ),
                child: const Text(
                  'Allow',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Lato'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String DateConvert(String filepath) {
    File file = File(filepath);
    DateTime date = file.lastModifiedSync();
    return intl.DateFormat('MMM d, y, HH:mm a').format(date).toString();
  }

  Container PdfListTile(String filePath, BuildContext context) {
  var type = {
    "txt": "text/plain",
    "doc": "application/msword",
    "docx":
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "ppt": "application/vnd.ms-powerpoint",
    "pptx":
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  };

  String ext = path.basename(filePath).split('.').last.toLowerCase();
  String imagepath = 'assets/$ext.png';

  if (ext == 'pptx') {
    imagepath = 'assets/ppt.png';
  }

  return Container(
    margin: EdgeInsets.only(left:0,right: 0,top: 8,bottom: 0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15.0),
    ),
    child: ListTile(
      title: Text(path.basename(filePath),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateConvert(filePath)),
          const SizedBox(
            width: 15,
          ),
          Text(filesize(filePath)),
        ],
      ),
      leading: Image(
        image: AssetImage(imagepath), // Replace with your image path
        width: 43, // Adjust width and height as needed
        height: 43,
        filterQuality: FilterQuality.high,
      ),
      trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _kebabmenuBottomSheet(filePath);
          }),
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      minVerticalPadding: 16.0,
      onTap: () {
        if (ext == 'pdf') {
          setState(() {
            openPDF(
                context, File(filePath)); // Use the 'File' class from 'dart:io'
            _addRecentFile(filePath);
          });
        } else {
          setState(() {
            _addRecentFile(filePath);
            Future<OpenResult> res = OpenFile.open(filePath, type: type[ext]);
            
          });
        }
      },
      contentPadding: const EdgeInsets.only(left: 10, right: 6),
    ),
  );
}


  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => PDFViewerPage(file: file, key: UniqueKey())),
      );

  void _kebabmenuBottomSheet(String filePath) {
    String ext = path.basename(filePath).split('.').last.toLowerCase();
    String imagepath = 'assets/$ext.png';

    if (ext == 'pptx') {
      imagepath = 'assets/ppt.png';
    }
    showModalBottomSheet(
      context: context,
      // enableDrag: false,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height *
            0.27, // Adjust height as needed
        width: MediaQuery.of(context).size.width - 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 25, left: 16, right: 16),
          child: Column(
            children: [
              Row(
                // Align icon, name, and path horizontally
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 2), // Add padding to move the image down
                    child: Image(
                      image:
                          AssetImage(imagepath), // Replace with your image path
                      width: 58,
                      height: 58,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      // Align name and path vertically within the column
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.basename(filePath),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(
                            height: 5), // Adjust spacing between name and path
                        Text(
                          filePath,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.grey),
              // const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Center buttons horizontally
                  children: [
                    //details
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: detailsdialogue(filePath)),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 234, 237, 240),
                            ),
                            child: Icon(
                              Icons.info, // Use Icons.info for details
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text('Details'),
                        ],
                      ),
                    ),

                    //bookmarked
                    InkWell(
                      onTap: () => setState(() {
                        final isBookmarked = Bookmarked.contains(filePath);
                        if (isBookmarked) {
                          Bookmarked.remove(filePath);
                        } else {
                          Bookmarked.insert(0, filePath);
                        }

                        _saveFiles();

                        final snackBarContent = isBookmarked
                            ? ' removed from Bookmarks'
                            : ' added to the Bookmarks';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 4.0),
                                  isBookmarked
                                      ? const Icon(
                                          Icons.bookmark_border_outlined,
                                          color: Colors.white)
                                      : const Icon(Icons.bookmark_added,
                                          color: Colors.red),
                                  const SizedBox(
                                      width: 4.0), // Adjust spacing if needed
                                  Expanded(
                                    child: Text(
                                      snackBarContent,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            backgroundColor:
                                Colors.black, // Black background color
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 10.0), // Adjust padding if needed
                            behavior: SnackBarBehavior.floating,
                            duration: Durations.extralong3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              // Rounded corners
                            ),
                            width: 230,
                          ),
                        );
                        Navigator.pop(context);
                      }),
                      child: Column(
                        // Wrap icon and label in a column
                        mainAxisSize:
                            MainAxisSize.min, // Avoid excessive vertical space
                        children: [
                          Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 234, 237, 240),
                              ),
                              child: Visibility(
                                visible: Bookmarked.contains(filePath),
                                replacement: Icon(
                                  Icons.bookmark_border_outlined,
                                  color: Colors.grey[800],
                                ),
                                child: const Icon(
                                  Icons.bookmark_added,
                                  color: Colors.red,
                                ),
                              )),
                          const SizedBox(
                              height: 5), // Spacing between icon and label
                          const Text('Bookmark'), // Add label text
                        ],
                      ),
                    ),

                    //Rename
                    InkWell(
                      onTap: () {
                        final name = path.basenameWithoutExtension(filePath);
                        Navigator.pop(context);

                        _showRenameDialog(
                            context, path.basename(name), filePath);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 234, 237, 240),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text('Rename'),
                        ],
                      ),
                    ),

                    //delete
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteDialog(context, filePath);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 234, 237, 240),
                            ),
                            child: Icon(
                              Icons.delete,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text('Delete'),
                        ],
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

  void _showDeleteDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteDialog(filePath: filePath);
      },
    ).then((result) {
      if (result != null && result) {
        setState(() {
          if (pdf_files.contains(filePath)) {
            pdf_files.remove(filePath);
          }
          if (_RecentsFiles.contains(filePath)) {
            _RecentsFiles.remove(filePath);
          }
          if (word_files.contains(filePath)) {
            word_files.remove(filePath);
          }
          if (ppt_files.contains(filePath)) {
            ppt_files.remove(filePath);
          }
          if (txt_files.contains(filePath)) {
            txt_files.remove(filePath);
          }
          if (Bookmarked.contains(filePath)) {
            Bookmarked.remove(filePath);
          }

          _saveFiles();
        });
        print('File deleted successfully');
      }
    });
  }

  void _showRenameDialog(
      BuildContext context, String currentName, String filePath) async {
    String? newpath = await showDialog<String>(
      context: context,
      builder: (context) {
        return RenameDialog(
          currentName: currentName,
          filePath: filePath,
        );
      },
    );

    if (newpath != null) {
      String ext = path.basename(filePath).split('.').last.toLowerCase();
      setState(() {
        List<List<String>> allFileLists = [
          pdf_files,
          _RecentsFiles,
          word_files,
          ppt_files,
          txt_files,
          Bookmarked
        ];
        for (var fileList in allFileLists) {
          if (fileList.contains(filePath)) {
            fileList.remove(filePath);
          }
        }
        if (newpath.endsWith(".pdf")) {
          pdf_files.insert(0, newpath);
        } else if (newpath.endsWith(".docx") || newpath.endsWith(".doc")) {
          word_files.insert(0, newpath);
        } else if (newpath.endsWith('.ppt') || newpath.endsWith('.pptx')) {
          ppt_files.insert(0, newpath);
        } else if (newpath.endsWith('txt')) {
          txt_files.insert(0, newpath);
        }
        _saveFiles();
      });
    }

    setState(() {
      _saveFiles(); // Save updated lists
    });
  }

  String filesize(String filePath) {
    File file = File(filePath);
    int fileSizeInBytes = file.lengthSync();
    double fileSizeInKb = fileSizeInBytes / 1024;

    if (fileSizeInKb > 1023.9) {
      String fileSize = (fileSizeInKb / 1024).toStringAsFixed(2);
      return ('${fileSize}MB');
    } else {
      String fileSize = (fileSizeInBytes / 1024).toStringAsFixed(2);
      return ('${fileSize}KB');
    }
  }

  Container detailsdialogue(String filePath) {
    File file = File(filePath);
    int fileSizeInBytes = file.lengthSync();

    String fileSize = (fileSizeInBytes / 1024).toStringAsFixed(2);

    final formattedDate = DateConvert(filePath);

    List<String> Title = [
      "Title",
      "File Type",
      "Path",
      "Size",
      "Last Modified"
    ];
    List<String> values = [
      path.basename(filePath),
      path.extension(filePath),
      filePath,
      "$fileSize KB",
      formattedDate,
    ];

    return Container(
      padding: const EdgeInsets.all(25.0), // Add padding to the container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Content fits within screen
        crossAxisAlignment: CrossAxisAlignment.start, // Align elements left
        children: [
          const Row(
            // Row for title
            children: [
              Text(
                'File Info',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15.0), // Spacing between title and text

          for (int i = 0; i < 5; i++)
            Column(
              mainAxisSize: MainAxisSize.min, // Content fits within screen
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align elements left
              children: [
                Text(
                  Title[i],
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 66, 66, 66),
                  ),
                ),
                const SizedBox(
                    height: 3.0), // Spacing between text1 and text2/text3
                Text(
                  values[i],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 25.0),
              ],
            )
        ],
      ),
    );
  }
}
