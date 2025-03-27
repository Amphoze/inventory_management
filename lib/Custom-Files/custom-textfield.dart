import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final int maxLines;
  final double height;
  final double width;
  final IconData? icon;
  final String? unit;
  final String? prefix;
  final String? label;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.maxLines = 1,
    this.height = 52,
    this.width = 550,
    this.icon,
    this.unit,
    this.prefix,
    this.keyboardType = TextInputType.text,
    required this.controller,
    this.validator,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: TextFormField(
        cursorWidth: 1.0,
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          prefixIcon: icon != null && prefix == null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(icon),
                )
              : prefix != null
                  ? Padding(
                      padding: const EdgeInsets.all(9.0),
                      child: Text(
                        prefix!,
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    )
                  : null,
          suffix: unit != null ? Text(unit!, style: TextStyle(color: Colors.blue.shade800)) : null,
          errorStyle: const TextStyle(height: 0.1, color: Colors.redAccent),
          fillColor: Colors.blue.shade50,
          filled: true,
          hintText: label ?? '',
          label: Text(label ?? ''),
          labelStyle: const TextStyle(fontSize: 15),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.blue.shade800, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 8),
        ),
        validator: validator,
      ),
    );
  }
}
