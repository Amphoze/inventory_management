import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/orders/service/order_service.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:provider/provider.dart';

class WriteRemarkDialog extends StatefulWidget {

  final String orderId;
  final Messages? messages;
  final String message;
  final VoidCallback onSubmitted;

  const WriteRemarkDialog({
    super.key,
    required this.orderId,
    required this.messages,
    required this.message,
    required this.onSubmitted,
  });

  @override
  State<WriteRemarkDialog> createState() => _WriteRemarkDialogState();
}

class _WriteRemarkDialogState extends State<WriteRemarkDialog> {

  late TextEditingController remarkController;
  late OrdersProvider orderProvider;

  @override
  void initState() {
    orderProvider = Provider.of<OrdersProvider>(context, listen: false);
    remarkController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    List<Message> remarks = [];

    if (widget.messages != null) {
      widget.messages!.confirmerMessages.forEach((message) => remarks.add(message));
      widget.messages!.accountMessages.forEach((message) => remarks.add(message));
      widget.messages!.bookerMessages.forEach((message) => remarks.add(message));
      widget.messages!.reverseMessages.forEach((message) => remarks.add(message));
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        constraints: remarks.isEmpty ? null : BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Remarks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: remarkController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter your remark here',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                ),

                const SizedBox(width: 16),

                ElevatedButton(
                  onPressed: () async {

                    Utils.showLoadingDialog(context, 'Submitting Remark...');

                    bool status = await OrderService.writeRemark(
                      orderId: widget.orderId,
                      message: widget.message,
                      remark: remarkController.text
                    );

                    Navigator.pop(context);
                    Navigator.pop(context);

                    if (status) {
                      Utils.showSnackBar(context, 'Remark submitted Successfully :)');
                      widget.onSubmitted();
                    } else {
                      Utils.showSnackBar(context, 'Error submitting Remark..!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            if (remarks.isNotEmpty)...[
              const SizedBox(height: 20),

              _buildRemarkList(remarks),

              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemarkList(List<Message> remarks) {

    remarks.sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));

    return Expanded(
      child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: remarks.length,
          itemBuilder: (context, index) {

            final remark = remarks[index];

            String author = remark.author;
            String message = remark.message;
            String type = remark.type;
            String timestamp = remark.timestamp;

            String date = 'NA';

            try {
              date = DateFormat('dd MMM, yyyy\nHH:mm a').format(DateTime.parse(timestamp));
            } catch (e) {
              log('Cannot parse remark date ($timestamp)');
            }

            return Card(
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          author,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54
                          ),
                        ),
                      ],
                    ),

                    Text(
                      type == 'confirmerMessage'
                          ? 'Confirmer'
                          : type == 'accountMessage'
                          ? 'Account'
                          : type == 'bookerMessage'
                          ? 'Booker'
                          : type == 'reverseMessage'
                          ? 'Revert'
                          : 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: type == 'confirmerMessage'
                            ? Colors.green
                            : type == 'accountMessage'
                            ? Colors.deepOrange
                            : type == 'bookerMessage'
                            ? Colors.blueAccent
                            : type == 'reverseMessage'
                            ? Colors.red
                            : Colors.black45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  @override
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }
}


showWriteRemarkDialog({
  required BuildContext context,
  required String orderId,
  required Messages? messages,
  required String message,
  required VoidCallback onSubmitted
}) {
  showDialog(
    context: context,
    builder: (context) => WriteRemarkDialog(
      orderId: orderId,
      messages: messages,
      message: message,
      onSubmitted: onSubmitted,
    )
  );
}

