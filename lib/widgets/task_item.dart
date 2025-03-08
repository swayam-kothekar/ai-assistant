import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isCompleted;
  final bool isCurrent;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;

  const TaskItem({
    Key? key,
    required this.icon,
    required this.text,
    this.isCompleted = false,
    this.isCurrent = false,
    this.iconColor = Colors.blue,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? iconColor.withOpacity(0.7) : backgroundColor,
          width: 1.5,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: iconColor,
                decorationThickness: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}