import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'pdf_viewer_page.dart';
import 'package:intl/intl.dart' as intl;
import 'package:hive/hive.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchTextController = TextEditingController();
  String _selectedOption = "ALL";
  bool _showRecentSearches = true;
  bool _Searching = false;

  List<String> pdf_files = [];
  List<String> word_files = [];
  List<String> ppt_files = [];
  List<String> txt_files = [];
  List<String> searchHistory = [];
  List<String> SearchFiles = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }
  Future<void> _saveFiles() async {
    var box = await Hive.openBox('fileBox');
    await box.put('pdfFiles', pdf_files);
    await box.put('word_files', word_files);
    await box.put('ppt_files', ppt_files);
    await box.put('txt_files', txt_files);
    await box.put('searchHistory', searchHistory);
    await box.close(); 
  }

  Future<void> loadFiles() async {
    var box = await Hive.openBox('fileBox');
    setState(() {
      pdf_files = List<String>.from(box.get('pdfFiles', defaultValue: []));
      word_files = List<String>.from(box.get('word_files', defaultValue: []));
      ppt_files = List<String>.from(box.get('ppt_files', defaultValue: []));
      txt_files = List<String>.from(box.get('txt_files', defaultValue: []));
      searchHistory = List<String>.from(box.get('searchHistory',defaultValue: []));
        });
    await box.close();
  }
  // Future<void> loadFiles() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     pdf_files = prefs.getStringList('pdfFiles') ?? [];
  //     searchHistory = prefs.getStringList('searchHistory') ?? [];
  //     word_files = prefs.getStringList('word_files') ?? [];
  //     ppt_files = prefs.getStringList('ppt_files') ?? [];
  //     txt_files = prefs.getStringList('txt_files') ?? [];
  //   });
  // }

  // Future<void> _saveFiles() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setStringList('pdfFiles', pdf_files);
  //   await prefs.setStringList('searchHistory', searchHistory);
  //   await prefs.setStringList('word_files', word_files);
  //   await prefs.setStringList('ppt_files', ppt_files);
  //   await prefs.setStringList('txt_files', txt_files);
  // }

  void _addRecentFile(String filePath) async {
    if (!searchHistory.contains(filePath)) {
      // _RecentsFiles.add(filePath);
      searchHistory.insert(0, filePath);
    }
    var box = await Hive.openBox('fileBox');
    await box.put('searchHistory', searchHistory);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.setStringList('searchHistory', searchHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 234, 234),
      appBar: AppBar(
        titleSpacing: -2.0,
        backgroundColor: const Color.fromARGB(255, 234, 234, 234),
        elevation: 0.0,
        scrolledUnderElevation: 0.0,
        centerTitle: false,
        toolbarHeight: 140.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          width: MediaQuery.of(context).size.width - 80,
          decoration: BoxDecoration(
            // color: Colors.grey[300],
            color: const Color.fromARGB(159, 255, 255, 255),
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const Icon(Icons.search),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _searchTextController,
                  onChanged: (String value) {
                    setState(() {
                      _performSearch(value);
                      if (value.isEmpty) {
                        _Searching = false;
                      } else {
                        _Searching = true;
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search across files',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0), // Adjust height for buttons
            child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 10, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 15,
                    ),
                    const Text(
                      'File Type',
                      style: TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(255, 165, 165, 165),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildToggleButton("ALL", _selectedOption == "ALL"),
                        _buildToggleButton("PDF", _selectedOption == "PDF"),
                        _buildToggleButton("Word", _selectedOption == "Word"),
                        _buildToggleButton("PPT", _selectedOption == "PPT"),
                        _buildToggleButton("Text", _selectedOption == "Text"),
                      ],
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Searches",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color.fromARGB(255, 165, 165, 165),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => setState(() =>
                                  _showRecentSearches = !_showRecentSearches),
                              icon: Icon(
                                _showRecentSearches
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ))),
      ),
      body:
       Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildListView(
                  condition: _Searching,
                  itemCount: SearchFiles.where(
                      (filePath) => File(filePath).existsSync()).length,
                  itemBuilder: (index) {
                    String filePath = SearchFiles[index];
                    if (File(filePath).existsSync()) {
                      return PdfListTile(filePath, context);
                    }
                    return const SizedBox();
                  },
                  emptyText: 'No files found',
                ),
                _buildListView(
                  condition: !_Searching && _showRecentSearches,
                  itemCount: searchHistory
                      .where((filePath) => File(filePath).existsSync())
                      .length,
                  itemBuilder: (index) {
                    String filePath = searchHistory[index];
                    if (File(filePath).existsSync()) {
                      return PdfListTile(filePath, context);
                    }
                    return const SizedBox();
                  },
                  emptyText: 'No files found',
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedOption = text;
          String value = _searchTextController.text;

          _performSearch(value);
          if (value.isEmpty) {
            _Searching = false;
          } else {
            _Searching = true;
          }
        });
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 5, bottom: 5),
        textStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontWeight: FontWeight.w600), // Default text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        backgroundColor: isSelected
            ? _getSelectedOptionColor()
            : Colors.white, // Background color based on selection
      ),
      child: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800]),
      ),
    );
  }

  void _performSearch(String value) {
    if (value.isEmpty) {
      SearchFiles = [];
    } else {
      print(_selectedOption);
      List<String> allfile = [
        ...pdf_files,
        ...ppt_files,
        ...word_files,
        ...txt_files
      ];
      switch (_selectedOption) {
        case "ALL":
          SearchFiles = allfile
              .where((val) => path
                  .basename(val)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList();
          print("ALL");
          break;
        case "PDF":
          SearchFiles = pdf_files
              .where((val) => path
                  .basename(val)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList();
          print("PDF");

          break;
        case "PPT":
          SearchFiles = ppt_files
              .where((val) => path
                  .basename(val)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList();
          print("PPT");

          break;
        case "Word":
          SearchFiles = word_files
              .where((val) => path
                  .basename(val)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList();
          print("Word");

          break;
        case "Text":
          SearchFiles = txt_files
              .where((val) => path
                  .basename(val)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList();
          print("Text");

          break;
      }
      print(SearchFiles);
    }
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
              ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: itemCount,
                  itemBuilder: (context, index) => itemBuilder(index),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Visibility(
                                visible: !_showRecentSearches,
                                child: Text(
                                  '\n   $emptyText',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Visibility(
                                  visible: _showRecentSearches,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(25.0),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 234, 234, 234),
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: 
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/no-recent-search.png',
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              180,
                                          fit: BoxFit.cover,
                                        ),
                                        const SizedBox(height: 5.0),
                                        const Text(
                                          'No Recent Searches',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Lato'),
                                        ),
                                        const SizedBox(height: 20.0),
                                      ],
                                    ),
                                  )),
                            ]),
                      ),
                    ],
                  )),
        ));
  }

  Color _getSelectedOptionColor() {
    switch (_selectedOption) {
      case 'PDF':
        return const Color.fromRGBO(222, 32, 42, 1.000);
      case 'Text':
        return const Color.fromRGBO(99, 99, 99, 1.000);
      case 'Word':
        return const Color.fromRGBO(79, 141, 245, 1.000);
      case 'PPT':
        return const Color.fromRGBO(245, 185, 18, 1.000);
      case 'ALL':
        return Colors.black;
      default:
        return const Color.fromRGBO(
            49, 49, 61, 1.000); // Default color for unexpected options
    }
  }

  Widget _buildRecentSearchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Searches",
          style: TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 165, 165, 165),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ... placeholder for recent searches display
            IconButton(
              onPressed: () =>
                  setState(() => _showRecentSearches = !_showRecentSearches),
              icon: Icon(
                _showRecentSearches ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
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
        width: 40, // Adjust width and height as needed
        height: 40,
        filterQuality: FilterQuality.high,
      ),
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
            print("other format");
            _addRecentFile(filePath);
            Future<OpenResult> res = OpenFile.open(filePath, type: type[ext]);
            // res.whenComplete(() => _addRecentFile(filePath));
          });
        }
      },
      contentPadding: const EdgeInsets.only(left: 10, right: 16),
    ),
  );
}


  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => PDFViewerPage(file: file, key: UniqueKey())),
      );

  String DateConvert(String filepath) {
    File file = File(filepath);
    DateTime date = file.lastModifiedSync();
    return intl.DateFormat('MMM d, y, HH:mm a').format(date).toString();
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
}
