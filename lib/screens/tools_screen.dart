import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            '  ToolBox',
            style: TextStyle(fontFamily: 'Lato'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildToolSection(title: ' Create PDF', icons: [
                Icons.image,
                Icons.text_snippet,
                Icons.table_chart,
              ], names: [
                'Create from Images',
                'Text to PDF',
                'Excel to PDF',
              ]),
              const SizedBox(height: 24),
              buildToolSection(title: ' Security', icons: [
                Icons.lock,
                Icons.lock_open,
              ], names: [
                'Add Password',
                'Remove Password',
              ]),
              const SizedBox(height: 24),
              buildToolSection(title: ' Edit PDF', icons: [
                Icons.merge_type,
                Icons.image,
                Icons.sort,
              ], names: [
                'Combine Files',
                'Export to Pictures',
                'Arrange Pages',
              ]),
            ], // Space sections evenly
          ),
        ),
      ),
    );
  }
}

Widget buildToolSection(
    {required String title,
    required List<IconData> icons,
    required List<String> names}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontFamily: 'Lato', fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 15, // Space buttons evenly
        children: List.generate(icons.length,
            (index) => buildToolButton(icons[index], names[index])),
      ),
    ],
  );
}

Widget buildToolButton(IconData icon, String name) {
  return InkWell(
    borderRadius: BorderRadius.circular(16.0),
    splashColor: const Color.fromARGB(255, 167, 197, 250),
    // Wrap with InkWell for clickability
    onTap: () {
      print('Button Pressed: $name');
    },
    child: Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: const Color.fromARGB(171, 228, 242, 255),
      ),
      padding: const EdgeInsets.fromLTRB(6, 26, 6, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 35), // Increased icon size
          const SizedBox(height: 8),
          Text(
            textAlign: TextAlign.center,
            name,
            style: const TextStyle(fontFamily: 'Lato', fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
