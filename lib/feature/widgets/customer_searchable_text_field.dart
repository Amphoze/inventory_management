import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class CustomerSearchableTextField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> items;
  final String label;
  final IconData icon;

  const CustomerSearchableTextField({
    super.key,
    required this.controller,
    required this.items,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Focus(
          child: Builder(
            builder: (BuildContext focusContext) {
              final bool isFocused = Focus.of(focusContext).hasFocus;
              final bool isEmpty = controller.text.isEmpty;

              return TypeAheadField<String>(
                controller: controller,
                suggestionsCallback: (pattern) async {
                  return items
                      .where((item) => item.toLowerCase().contains(pattern.toLowerCase()))
                      .toList();
                },
                itemBuilder: (context, value) {
                  return ListTile(
                    title: Text(value),
                  );
                },
                onSelected: (value) {
                  controller.text = value;
                  setState(() {});
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(
                      color: isFocused ? AppColors.primaryBlue : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isFocused || !isEmpty
                            ? AppColors.primaryBlue
                            : Colors.grey.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        icon,
                        color: isFocused ? AppColors.primaryBlue : Colors.grey[700],
                      ),
                      suffixIcon: isEmpty
                          ? null
                          : IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          controller.clear();
                          setState(() {});
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                    ),
                    cursorColor: AppColors.primaryBlue,
                  );
                },
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No State Found'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}