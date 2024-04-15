import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart' as intl;
import 'package:hive/hive.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _selectedFilePath;
  
  final _searchTextController = TextEditingController();
  bool _Searching = false;

  List<String> pdf_files = [];
  List<String> SearchFiles = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    var box = await Hive.openBox('fileBox');

    setState(() {
      pdf_files = List<String>.from(box.get('pdfFiles', defaultValue: []));
      // pdf_files = prefs.getStringList('pdfFiles') ?? [];
    });
    await box.close();
  }

  Future<void> _saveFiles() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setStringList('pdfFiles', pdf_files); // Await saving operation
    var box = await Hive.openBox('fileBox');
    await box.put('pdfFiles', pdf_files);
    await box.close();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 234, 234),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 234, 234, 234),
        elevation: 0.0,
        scrolledUnderElevation: 0.0,
        centerTitle: false,
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
              ],
            ),
          ),
        ],
      ),
    );

  }

  void _performSearch(String value) {
    if (value.isEmpty) {
      SearchFiles = [];
    } else {
          SearchFiles = pdf_files
              .where((val) => path
                  .basename(val)
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList();
          print("PDF");
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
                              Center(child:Text(
                                  '\n   $emptyText',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),)
                                
                                      ],
                                    ),
                                  ),],),
                            ),
                      ),
    );
  }

  Color _getSelectedOptionColor() {
        return const Color.fromRGBO(222, 32, 42, 1.000);
  }


  Container PdfListTile(String filePath, BuildContext context) {


  String ext = path.basename(filePath).split('.').last.toLowerCase();
  String imagepath = 'assets/$ext.png';

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
        setState(() {
            _selectedFilePath = filePath; // Update selected file path
          });
          Navigator.pop(context, _selectedFilePath); 
      },
      contentPadding: const EdgeInsets.only(left: 10, right: 16),
    ),
  );
}



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
