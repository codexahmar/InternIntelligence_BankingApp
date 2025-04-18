import 'package:flutter/material.dart';

class PasswordRequirementIndicator extends StatelessWidget {
  final String text;
  final bool isChecked;

  const PasswordRequirementIndicator({
    Key? key,
    required this.text,
    required this.isChecked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: isChecked ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
