import 'package:flutter/material.dart';

class RoundButtonWidget extends StatelessWidget {
  final VoidCallback onClicked;

  const RoundButtonWidget({
    super.key,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      right: 45,
      child: SizedBox(
        width: 64,
        height: 64,
        child: ElevatedButton(
            onPressed: onClicked,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(8),
              fixedSize: const Size(64, 64),
              backgroundColor: const Color.fromARGB(255, 228, 242, 255),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
            ),
            child: const Icon(
              Icons.folder,
              color: Color.fromARGB(255, 241, 175, 10),
              weight: 10.0,
              size: 35,
            )),
      ),
    );
  }
}
