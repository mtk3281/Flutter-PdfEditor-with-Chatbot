import 'package:flutter/material.dart';
import 'package:hive/hive.dart';


class FilterModalBottomSheet extends StatefulWidget {
  final Function(String sortBy, String orderBy) onApply;

  const FilterModalBottomSheet({super.key, required this.onApply});

  @override
  _FilterModalBottomSheetState createState() => _FilterModalBottomSheetState();
}

class _FilterModalBottomSheetState extends State<FilterModalBottomSheet> {
  // late SharedPreferences prefs; // Declare SharedPreferences
  late Box<String> prefsBox;
  String sortBy = 'File';
  String orderBy = 'Ascending';
  int selectedIndex = 0;
  int OrderIndex = 0;

  @override
  void initState() {
    super.initState();
    initPreferences();
  }

  // Future<void> initPreferences() async {
  //   prefs = await SharedPreferences.getInstance();
  //   final savedSortBy =
  //       prefs.getString('sortBy') ?? 'File'; // Default to 'File'
  //   final savedOrderBy =
  //       prefs.getString('orderBy') ?? 'Ascending'; // Default to 'Ascending'
  //   setState(() {
  //     sortBy = savedSortBy;
  //     orderBy = savedOrderBy;
  //     setSelectedIndex(); // Update selected index based on fetched sortBy
  //     setOrderIndex(); // Update order index based on fetched orderBy
  //   });
  //   print(sortBy);
  //   print(orderBy);
  // }

  // // Function to persist selected values
  // void savePreferences() async {
  //   await prefs.setString('sortBy', sortBy);
  //   await prefs.setString('orderBy', orderBy);
  // }


  Future<void> initPreferences() async {
    final hive = await Hive.openBox<String>('preferences');
    prefsBox = hive;
    final savedSortBy = prefsBox.get('sortBy') ?? 'File';
    final savedOrderBy = prefsBox.get('orderBy') ?? 'Ascending';
    setState(() {
      sortBy = savedSortBy;
      orderBy = savedOrderBy;
      setSelectedIndex(); // Update selected index based on fetched sortBy
      setOrderIndex(); // Update order index based on fetched orderBy
    });
    print(sortBy);
    print(orderBy);
  }

  // Function to persist selected values
  void savePreferences() {
    prefsBox.put('sortBy', sortBy);
    prefsBox.put('orderBy', orderBy);
  }

  // Function to set selected index based on sortBy
  void setSelectedIndex() {
    switch (sortBy) {
      case 'File':
        selectedIndex = 0;
        break;
      case 'Date':
        selectedIndex = 1;
        break;
      case 'Size':
        selectedIndex = 2;
        break;
      default:
        selectedIndex = 0; // Default to 'File'
    }
  }

  // Function to set order index based on orderBy
  void setOrderIndex() {
    OrderIndex = orderBy == 'Ascending' ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.38,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 20.0, right: 20, top: 20, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                        sortBy, orderBy); // Call the callback function
                    savePreferences(); // Persist selected values
                    Navigator.pop(context); // Close the modal bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    // primary: Colors.red,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 16, top: 15, bottom: 10),
            child: Text(
              'Sort by',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildToggleButton(
                  icon: Icons.text_fields_rounded,
                  text: 'File Name',
                  index: 0,
                  isSelected: selectedIndex == 0,
                  onPressed: () {
                    setState(() {
                      selectedIndex = 0;
                      sortBy = 'File';
                    });
                  }),
              const SizedBox(width: 16), // Adjust spacing between buttons
              buildToggleButton(
                  icon: Icons.date_range,
                  text: 'Created Date',
                  index: 1,
                  isSelected: selectedIndex == 1,
                  onPressed: () {
                    setState(() {
                      selectedIndex = 1;
                      sortBy = 'Date';
                    });
                  }),
              const SizedBox(width: 16), // Adjust spacing between buttons
              buildToggleButton(
                  icon: Icons.insert_drive_file,
                  text: 'File Size',
                  index: 2,
                  isSelected: selectedIndex == 2,
                  onPressed: () {
                    setState(() {
                      selectedIndex = 2;
                      sortBy = 'Size';
                    });
                  }),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 16, top: 24, bottom: 15),
            child: Text(
              'Order by',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildToggleButton1(
                  text: 'Ascending',
                  icon: Icons.upload_file,
                  index: 0,
                  isSelected: OrderIndex == 0,
                  onPressed: () {
                    setState(() {
                      OrderIndex = 0;
                      orderBy = 'Ascending';
                    });
                  }),
              const SizedBox(width: 28), // Spacing between buttons
              buildToggleButton1(
                  text: 'Descending',
                  icon: Icons
                      .sim_card_download_outlined, // Different icon for distinction
                  index: 1,
                  isSelected: OrderIndex == 1,
                  onPressed: () {
                    setState(() {
                      OrderIndex = 1;
                      orderBy = 'Descending';
                    });
                  }),
            ],
          ),
        ],
      ),
    );
  }

// Function to build each toggle button
  Container buildToggleButton({
    required IconData icon,
    required String text,
    required int index,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0), // Adjust corner radius
        color: Colors.transparent, // Transparent background
      ),
      child: Material(
        color: Colors.transparent, // Material for splash effect
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0), // Match decoration
          onTap: onPressed,
          splashColor: const Color.fromARGB(
              255, 250, 228, 228), // Set splash color (semi-transparent)
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 26.0, vertical: 8.0), // Adjust padding
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200, // Circular icon background
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Adjust icon padding
                    child: Icon(
                      icon,
                      size: 26.0, // Adjust icon size
                      color: isSelected
                          ? Colors.red
                          : Colors.black, // Change icon color
                    ),
                  ),
                ),
                const SizedBox(height: 8.0), // Spacing between icon and text
                Text(
                  text,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container buildToggleButton1({
    required String text,
    required IconData icon,
    required int index,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 23, right: 20, top: 12, bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isSelected
            ? const Color.fromARGB(255, 250, 228, 228)
            : const Color.fromARGB(255, 245, 245, 245),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onPressed,
        hoverColor: Colors.grey.shade200, // Add hover color
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.transparent, // Make the inner Ink transparent
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color.fromARGB(255, 240, 38, 38)
                      : Colors.black,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
