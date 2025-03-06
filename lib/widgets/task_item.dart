import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isCompleted;
  final bool isCurrent;

  const TaskItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : (isCurrent ? Colors.black : Colors.white),
              border: Border.all(
                color: isCompleted ? Colors.green : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 16)
                : (isCurrent ? Icon(icon, color: Colors.white, size: 16) : Container()),
            ),
          ),
          SizedBox(width: 15),
          Text(
            text,
            style: TextStyle(
              color: isCurrent ? Colors.black : Colors.grey[600],
              fontSize: 16,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}