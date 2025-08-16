import 'package:flutter/material.dart';

class TalkButton extends StatelessWidget {
  final VoidCallback onPress;
  const TalkButton({super.key, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 200), shape: const CircleBorder()),
      onPressed: onPress,
      child: const Text("Talk to PetitPal"),
    );
  }
}
