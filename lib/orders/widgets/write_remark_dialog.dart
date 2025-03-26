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
  final List<Message> remarks;
  final String message;
  final VoidCallback onSubmitted;

  const WriteRemarkDialog({
    super.key,
    required this.orderId,
    required this.remarks,
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        // height: MediaQuery.of(context).size.height * 0.75,
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

            if (widget.remarks.isNotEmpty)...[
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.remarks.length,
                    itemBuilder: (context, index) {

                      final remark = widget.remarks[index];

                      String author = remark.author;
                      String message = remark.message;
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

                        child: ListTile(
                          title: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),

                          subtitle: Text(
                            author,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54
                            ),
                          ),

                          trailing: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                ),
              ),

              const SizedBox(height: 20),
            ],
          ],
        ),
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
  required List<Message> remarks,
  required String message,
  required VoidCallback onSubmitted
}) {
  showDialog(
    context: context,
    builder: (context) => WriteRemarkDialog(
      orderId: orderId,
      remarks: remarks,
      message: message,
      onSubmitted: onSubmitted,
    )
  );
}

