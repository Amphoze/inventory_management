import 'package:flutter/material.dart';

import '../../Custom-Files/colors.dart';


Widget buildTextField({
  required TextEditingController controller,
  required String label,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  FocusNode? focusNode,
  FocusNode? nextFocus,
  bool isRequired = false,
  int maxLines = 1,
  IconData? prefixIcon,
  Widget? suffix,
  required BuildContext context
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 0.0),
    child: TextFormField(
      controller: controller,
      focusNode: focusNode,
      // maxLength: label == 'Vendor Phone' ? 10 : null,
      decoration: InputDecoration(
        hintText: isRequired ? '$label *' : label,
        hintStyle: TextStyle(color: AppColors.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue.withAlpha(120)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue.withAlpha(120), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        // contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
        errorStyle: TextStyle(color: Colors.red[700]),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        if (validator != null) {
          return validator(value);
        }
        return null;
      },
      maxLines: maxLines,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
    ),
  );
}