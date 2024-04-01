import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart' as intl;
import 'package:pdfeditor/widget/searchpdf.dart';


class FileSelectionPage extends StatefulWidget {
  final List<String> filepaths;
  final String type;

  const FileSelectionPage({Key? key, required this.filepaths, required this.type})
      : super(key: key);

  @override
  _FileSelectionPageState createState() => _FileSelectionPageState();
}

class _FileSelectionPageState extends State<FileSelectionPage> {
  String? _selectedFilePath;

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
        color: Colors.grey[100], // Set body color to grey
        child: _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: widget.filepaths.length,
      itemBuilder: (context, index) {
        String filePath = widget.filepaths[index];
        if(File(filePath).existsSync())
        {
        return _buildListTile(filePath);

        }
        else
        {
           return const SizedBox();
        }
      },
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
        onTap: () {
          setState(() {
            _selectedFilePath = filePath; // Update selected file path
          });
          Navigator.pop(context, _selectedFilePath); // Return selected file path
        },
      ),
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
