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
    return Material(
      color: enabled ? color : Colors.grey,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8.0),
        splashColor: Colors.white.withAlpha(100),
        highlightColor: Colors.white.withAlpha(150),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 8),
              Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

}