import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final bool isActive;
  final int number;
  final String title;

  const StepIndicator({
    Key? key,
    required this.isActive,
    required this.number,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color:
                isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class StepConnector extends StatelessWidget {
  final bool isActive;

  const StepConnector({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
    );
  }
}
