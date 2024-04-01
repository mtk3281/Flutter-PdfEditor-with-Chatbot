import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart' as intl;
import 'package:pdfeditor/widget/searchpdf.dart';


class FileSelectionPage extends StatefulWidget {
  final List<String> filepaths;
  final String type;
  final bool multipleChoice; // Added parameter for multiple selection

  const FileSelectionPage({
    Key? key,
    required this.filepaths,
    required this.type,
    this.multipleChoice = false, // Default to single selection
  }) : super(key: key);

  @override
  _FileSelectionPageState createState() => _FileSelectionPageState();
}

class _FileSelectionPageState extends State<FileSelectionPage> {
  String? _selectedFilePath; // For single selection
  final List<String> _selectedFilePaths = []; // For multiple selection
bool _multipleSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                scrolledUnderElevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, null); // Return selected file path
          },
        ),
        actions: [
                if (!widget.multipleChoice)
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: () async{
                    String? result;
                    await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchPage(),
                          ),
                        ).then((selectedFilePath) {
                          if (selectedFilePath != null) {
                            result = selectedFilePath;
                          }
                        });
                        if (result != null && result!.isNotEmpty) {
                        setState(() {
                         _selectedFilePath = result; // Update selected file path
                       });
                        }
                      Navigator.pop(context, _selectedFilePath);
                   
                  },
                ),

                ],
        title: Text('${widget.type}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        
      ),
       body: Container(
        color: Colors.grey[100],
        child: widget.multipleChoice ? _buildMultiSelectListView() : _buildSingleSelectListView(),
      ),
      floatingActionButton: widget.multipleChoice
          ? _buildSubmitButton()
          : null, // Show submit button only in multiple selection mode
    );
  }



  Widget _buildSingleSelectListView() {
    return ListView.builder(
      itemCount: widget.filepaths.length,
      itemBuilder: (context, index) {
        String filePath = widget.filepaths[index];
        if (File(filePath).existsSync()) {
          return _buildListTile(filePath);
        } else {
          return const SizedBox();
        }
      },
    );
  }

Widget _buildMultiSelectListView() {
  return ListView.builder(
    itemCount: widget.filepaths.length,
    itemBuilder: (context, index) {
      String filePath = widget.filepaths[index];
      if (File(filePath).existsSync()) {
        return Container(
      margin: EdgeInsets.only(left:12,right: 12,top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: 
        ListTile(
          contentPadding: EdgeInsets.only(left:12,right: 15), 
          minVerticalPadding: 1,
          leading: _buildFileIcon(filePath),
          title: CheckboxListTile(
            contentPadding: EdgeInsets.only(left:1,right: 1),
            checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),),
            title: Text(
              path.basename(filePath),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_getDate(filePath)),
                SizedBox(width: 15),
                Text(_getFileSize(filePath)),
              ],
            ),
            value: _selectedFilePaths.contains(filePath),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _selectedFilePaths.add(filePath);
                } else {
                  _selectedFilePaths.remove(filePath);
                }
              });
            },
          ),
        ),
        );
      } else {
        return const SizedBox();
      }
    },
  );
}


Widget _buildFileIcon(String filePath) {
  String ext = path.basename(filePath).split('.').last.toLowerCase();
  String imagepath = 'assets/$ext.png';
  if (ext == 'pptx') {
    imagepath = 'assets/ppt.png';
  }
  return Image.asset(
    imagepath,
    width: 42,
    height: 42,
    filterQuality: FilterQuality.high,
  );
}

  Widget _buildListTile(String filePath) {
    String ext = path.basename(filePath).split('.').last.toLowerCase();
    String imagepath = 'assets/$ext.png';
    if (ext == 'pptx') {
      imagepath = 'assets/ppt.png';
    }
    return Container(
      margin: EdgeInsets.only(left:12,right: 12,top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.only(left:12,right: 15), 
        title: Text(
          path.basename(filePath),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_getDate(filePath)),
            SizedBox(width: 15),
            Text(_getFileSize(filePath)),
          ],
        ),
        leading: Image.asset(
          imagepath,
          width: 45,
          height: 45,
          filterQuality: FilterQuality.high,
        ),
        onTap: widget.multipleChoice
           ? null // Disable tap for multi-select mode
           : () {
               setState(() {
                 _selectedFilePath = filePath;
               });
               Navigator.pop(context, _selectedFilePath);
             },
     ),
   );
 }

Widget _buildSubmitButton() {
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width;
      double buttonWidth = screenWidth - 50;

      return Container(
        width: buttonWidth,
        child: FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 17, 0),
          onPressed: _selectedFilePaths.isNotEmpty
              ? () {
                  Navigator.pop(context, _selectedFilePaths);
                }
              : null,
          label: const Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 21,
            ),
          ),
        ),
      );
    },
  );
}


  String _getFileSize(String filePath) {
    File file = File(filePath);
    int fileSizeInBytes = file.lengthSync();
    double fileSizeInKb = fileSizeInBytes / 1024;

    if (fileSizeInKb > 1023.9) {
      String fileSize = (fileSizeInKb / 1024).toStringAsFixed(2);
      return ('$fileSize MB');
    } else {
      String fileSize = (fileSizeInBytes / 1024).toStringAsFixed(2);
      return ('$fileSize KB');
    }
  }

  String _getDate(String filepath) {
    File file = File(filepath);
    DateTime date = file.lastModifiedSync();
    return intl.DateFormat('MMM d, y, HH:mm a').format(date).toString();
  }
}
