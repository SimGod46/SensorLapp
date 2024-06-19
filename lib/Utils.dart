import 'package:flutter/material.dart';

class ButtonCustom extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final IconData icon;
  final String text;
  final bool enabled;

  ButtonCustom({
    required this.onPressed,
    required this.color,
    required this.icon,
    required this.text,
    required this.enabled});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}