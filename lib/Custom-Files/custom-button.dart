import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final double fontSize;
  final String text;
  final BorderRadiusGeometry borderRadius;
  final Widget? prefixIcon; // Optional prefix icon

  const CustomButton({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
    required this.color,
    required this.textColor,
    required this.fontSize,
    required this.text,
    this.borderRadius = BorderRadius.zero,
    this.prefixIcon, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefixIcon != null) ...[
              prefixIcon!,
              const SizedBox(width: 8), 
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
