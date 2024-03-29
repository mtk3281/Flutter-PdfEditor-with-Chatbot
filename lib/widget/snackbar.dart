import 'package:flutter/material.dart';

SnackBar buildCustomSnackBar(String text, double width) {
  return SnackBar(
    content: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 4.0),
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.transparent,
          backgroundImage: AssetImage('assets/icon/launch-icon.png'),
        ),
        SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    backgroundColor: Color.fromARGB(255, 0, 0, 0),
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25.0),
    ),
    width: width,
  );
}
