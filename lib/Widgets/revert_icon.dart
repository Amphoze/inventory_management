import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Api/auth_provider.dart';
import '../Custom-Files/colors.dart';
import '../Custom-Files/utils.dart';
import '../planning.dart';
import 'Textfeild/custom_textfeild.dart';

class RevertOrderWidget extends StatefulWidget {
  final bool dropdownEnabled;
  final List<String> dropdownOptions;
  final String orderid;
  final String status;
  final String revertStatus;

  const RevertOrderWidget(
      {super.key,
      this.dropdownEnabled = false,
      this.dropdownOptions = const [],
      this.orderid = '',
      this.status = '',
      this.revertStatus = ''});

  @override
  _RevertOrderWidgetState createState() => _RevertOrderWidgetState();
}

class _RevertOrderWidgetState extends State<RevertOrderWidget> {

  String? selectedValue;

  TextEditingController remarkController = TextEditingController();

  final FocusNode _remark = FocusNode();
  final formKey = GlobalKey<FormState>();

  void _showRevertDialog(GlobalKey<FormState> formKey) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Revert Order"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.dropdownEnabled) ...[

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    items: widget.dropdownOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    style: const TextStyle(color: AppColors.primaryBlue),
                    decoration: InputDecoration(
                      labelText: "Select an option",
                      border: const OutlineInputBorder(
                          borderRadius: UIConstants.defaultBorderRadius),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: UIConstants.defaultBorderRadius,
                        borderSide: BorderSide(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: UIConstants.defaultBorderRadius,
                        borderSide: BorderSide(
                            color: AppColors.primaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    validator: (value) => value == null
                        ? 'Please select a Status to be reverted'
                        : null,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                      });
                    },
                  ),
                ] else
                  Text.rich(
                    TextSpan(
                      text: 'Order is reverted back to ',
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: widget.status,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                buildTextField(
                  controller: remarkController,
                  label: 'Remark',
                  context: context,
                  isRequired: true,
                  focusNode: _remark,
                  maxLines: 2,
                  validator: (value) {
                    if (value!.isEmpty)
                      return 'Remark is required to revert the order';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _confirmRevert();
                    }
                  },
                  child: const Text("Revert"),
                ),
              ],
            ),
          ));
      },
    );
  }

  void _confirmRevert() {

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: Text.rich(
          TextSpan(
            text: 'Are you sure you want to revert ',
            style: const TextStyle(color: Colors.black),
            children: [
              TextSpan(
                text: widget.orderid,
                style: const TextStyle(color: AppColors.primaryBlue),
              ),
              const TextSpan(
                text: ' to ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: widget.dropdownEnabled
                    ? selectedValue
                    : widget.status.toUpperCase(),
                style: const TextStyle(color: AppColors.primaryBlue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              remarkController.clear();
              selectedValue = null;
              Navigator.pop(context);
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _revertOrder();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _revertOrder() async {
    try {
      final authPro = context.read<AuthProvider>();

      String revertStatus = widget.revertStatus;

      if (widget.dropdownEnabled) {
        if (selectedValue == "READY-TO-CONFIRM") {
          revertStatus = '1';
        } else if (selectedValue == "READY-TO-ACCOUNT") {
          revertStatus = '2';
        }
      }

      log('revert payload data ---> ${widget.orderid} ${remarkController.text} $revertStatus');

      final res = await authPro.reverseOrder(
          widget.orderid, remarkController.text, revertStatus);
      Navigator.pop(context);

      if (res['success'] == true) {
        Utils.showInfoDialog(
            context,
            "${widget.orderid} is revered back to ${widget.status} successfully",
            true);

        // Utils.showInfoDialog(
        //     context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
      } else {
        Utils.showInfoDialog(context, res['message'], false);
      }
    } catch (e) {
      Utils.showSnackBar(context, 'Failed to revert order', details: e.toString(), isError: true);

    }
  }

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Revert Order',
      icon: const Icon(Icons.undo, color: Colors.red),
      onPressed: () => _showRevertDialog(formKey),
    );
  }
}
