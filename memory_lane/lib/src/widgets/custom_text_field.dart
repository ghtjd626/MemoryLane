import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final Function(String) onChanged;

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(labelText: labelText),
    );
  }
}
