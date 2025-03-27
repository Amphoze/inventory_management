import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/revert_icon.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/packer_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../orders/widgets/write_remark_dialog.dart';
import '../provider/orders_provider.dart';
import '../provider/support_provider.dart';

class OrderComboCard extends StatefulWidget {
  final Order order;
  final Widget? checkboxWidget;
  final bool toShowOrderDetails;
  final bool isBookPage;
  final bool toShowBy;
  final bool toShowAll;
  final bool isBookedPage;
  final bool isAccountSection;
  final bool isPacked;
  final bool isAdmin;
  final bool isSuperAdmin;
  final double elevation;
  final EdgeInsets? margin;

  const OrderComboCard({
    super.key,
    this.toShowAll = false,
    required this.toShowBy,
    required this.order,
    this.checkboxWidget,
    required this.toShowOrderDetails,
    this.isBookPage = false,
    this.isPacked = false,
    this.isBookedPage = false,
    this.isAccountSection = false,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.elevation = 4,
    this.margin,
  });

  static String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  @override
  State<OrderComboCard> createState() => _OrderComboCardState();
}

class _OrderComboCardState extends State<OrderComboCard> {
  final bookRemark = TextEditingController();
  final accountsRemark = TextEditingController();
  String? email;
  String? role;

  void getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    role = prefs.getString('userPrimaryRole');
  }

  bool showBy(bool val) {
    return (val && widget.toShowBy);
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return "$date, $time";
  }

  String status = '1';

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrdersProvider>(context, listen: false);

    // log('Building OrderCard for Order ID: ${widget.order.id}');
    // log('bookerMessage in card: ${widget.order.orderId}  ${widget.order.messages?['bookerMessage']?.toString() ?? ''}');
    // log('accountMessage: ${widget.order.messages!['accountMessage']}');

    final Map<String, List<Item>> groupedComboItems = {};

    for (var item in widget.order.items) {
      if (item.isCombo == true && item.comboSku != null) {
        if (!groupedComboItems.containsKey(item.comboSku)) {
          groupedComboItems[item.comboSku!] = [];
        }
        groupedComboItems[item.comboSku]!.add(item);
      }
    }

    final List<List<Item>> comboItemGroups = groupedComboItems.values.where((items) => items.length > 1).toList();

    final List<Item> remainingItems = widget.order.items
        .where((item) => !(item.isCombo == true && item.comboSku != null && groupedComboItems[item.comboSku]!.length > 1))
        .toList();

    List<Message> confirmerMessages = widget.order.messages == null ? [] : widget.order.messages!.confirmerMessages;
    List<Message> accountMessages = widget.order.messages == null ? [] : widget.order.messages!.accountMessages;
    List<Message> bookerMessages = widget.order.messages == null ? [] : widget.order.messages!.bookerMessages;


    return Card(
      color: AppColors.white,
      elevation: widget.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.checkboxWidget != null) widget.checkboxWidget!,
                Text(
                  'Order ID: ${widget.order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blueAccent,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (widget.isBookPage) ...[
                      // IconButton(
                      //   tooltip: 'Recalculate Freight Charges',
                      //   icon: const Icon(Icons.undo),
                      //   onPressed: () async {
                      //     showDialog(
                      //       context: context,
                      //       builder: (context) {
                      //         return AlertDialog(
                      //           title: Text(widget.order.orderId),
                      //           content: Text('Are you sure you want to recalculate freight charges for ${widget.order.orderId} (${widget.order.warehouseName
                      //           })'),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () {
                      //                 Navigator.of(context).pop();
                      //               },
                      //               child: const Text('Cancel'),
                      //             ),
                      //             TextButton(
                      //               onPressed: () async {
                      //                 // close confirm dialog
                      //                 Navigator.pop(context);
                      //
                      //                 showDialog(
                      //                   barrierDismissible: false,
                      //                   context: context,
                      //                   builder: (context) {
                      //                     return const AlertDialog(
                      //                       content: Row(
                      //                         children: [
                      //                           CircularProgressIndicator(),
                      //                           SizedBox(width: 8),
                      //                           Text('Reversing'),
                      //                         ],
                      //                       ),
                      //                     );
                      //                   },
                      //                 );
                      //
                      //                 try {
                      //                   log('in revert try');
                      //                   final authPro = context.read<AuthProvider>();
                      //                   final res = await authPro.reverseOrder(widget.order.orderId);
                      //
                      //                   Navigator.pop(context);
                      //
                      //                   if (res['success'] == true) {
                      //                     Utils.showInfoDialog(context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                      //                   } else {
                      //                     Utils.showInfoDialog(context, res['message'], false);
                      //                   }
                      //                 } catch (e, s) {
                      //                   log('in revert catch: $e $s');
                      //                   Navigator.pop(context);
                      //                   Utils.showInfoDialog(context, 'An error occurred: $e', false);
                      //                 }
                      //               },
                      //               child: const Text('Submit'),
                      //             ),
                      //           ],
                      //         );
                      //       },
                      //     );
                      //   },
                      // ),
                      // const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Edit Order',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditOutboundPage(
                                order: widget.order,
                                isBookPage: true,
                              ),
                            ),
                          );

                          if (result != null && result is bool && result) {
                            final pro = Provider.of<BookProvider>(context, listen: false);
                            pro.fetchPaginatedOrdersB2C(pro.currentPageB2C);
                            pro.fetchPaginatedOrdersB2B(pro.currentPageB2B);
                            // context.read<AccountsProvider>().fetchOrdersWithStatus2();
                          }
                        },
                        icon: const Icon(Icons.edit_note),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Edit Warehouse',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              String selectedWarehouse = widget.order.warehouseName ?? '';

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Edit Warehouse', style: TextStyle(fontSize: 20)),
                                        Text(widget.order.orderId, style: const TextStyle(fontSize: 15)),
                                      ],
                                    ),
                                    content: Consumer<LocationProvider>(builder: (context, pro, child) {
                                      return DropdownButton(
                                        value: selectedWarehouse,
                                        isExpanded: true,
                                        hint: const Text('Select Warehouse'),
                                        items: pro.warehouses.map<DropdownMenuItem<String>>((dynamic warehouse) {
                                          return DropdownMenuItem<String>(
                                            value: warehouse['name'],
                                            child: Text(warehouse['name']),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              selectedWarehouse = newValue;
                                            });
                                          }
                                        },
                                      );
                                    }),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          if (selectedWarehouse.isNotEmpty) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => const AlertDialog(
                                                content: Row(
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    SizedBox(width: 8),
                                                    Text('Updating Warehouse'),
                                                  ],
                                                ),
                                              ),
                                            );
                                            final pro = Provider.of<BookProvider>(context, listen: false);
                                            final res = await pro.editWarehouse(widget.order.orderId, selectedWarehouse.trim());
                                            log('edit warehouse result: $res');
                                            if (res == true) {
                                              final b2b = pro.b2bSearchController.text.trim();
                                              final b2c = pro.b2cSearchController.text.trim();
                                              if (b2b.isNotEmpty) {
                                                pro.searchB2BOrders(b2b);
                                              } else if (b2c.isNotEmpty) {
                                                pro.searchB2COrders(b2c);
                                              } else {
                                                pro.fetchPaginatedOrdersB2C(pro.currentPageB2C);
                                                pro.fetchPaginatedOrdersB2B(pro.currentPageB2B);
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Failed to edit warehouse')),
                                                );
                                              }
                                            }
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            }
                                          }
                                        },
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        icon: const Icon(Icons.edit_location_alt_outlined),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.isSuperAdmin || widget.isAdmin)
                      // IconButton(
                      //   tooltip: 'Revert Order',
                      //   icon: const Icon(Icons.undo),
                      //   onPressed: () async {
                      //     showDialog(
                      //       context: context,
                      //       builder: (context) {
                      //         return AlertDialog(
                      //           title: const Text('Revert Order'),
                      //           content: Text('Are you sure you want to revert ${widget.order.orderId} to READY TO CONFIRM'),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () {
                      //                 Navigator.of(context).pop();
                      //               },
                      //               child: const Text('Cancel'),
                      //             ),
                      //             TextButton(
                      //               onPressed: () async {
                      //                 Navigator.pop(context);
                      //
                      //                 showDialog(
                      //                   barrierDismissible: false,
                      //                   context: context,
                      //                   builder: (context) {
                      //                     return const AlertDialog(
                      //                       content: Row(
                      //                         children: [
                      //                           CircularProgressIndicator(),
                      //                           SizedBox(width: 8),
                      //                           Text('Reversing'),
                      //                         ],
                      //                       ),
                      //                     );
                      //                   },
                      //                 );
                      //
                      //                 try {
                      //                   final authPro = context.read<AuthProvider>();
                      //                   final res = await authPro.reverseOrder(widget.order.orderId);
                      //
                      //                   Navigator.pop(context);
                      //
                      //                   if (res['success'] == true) {
                      //                     Utils.showInfoDialog(context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                      //                   } else {
                      //                     Utils.showInfoDialog(context, res['message'], false);
                      //                   }
                      //                 } catch (e) {
                      //                   Navigator.pop(context);
                      //                   Utils.showInfoDialog(context, 'An error occurred: $e', false);
                      //                 }
                      //               },
                      //               child: const Text('Submit'),
                      //             ),
                      //           ],
                      //         );
                      //       },
                      //     );
                      //   },
                      // ),
                      // IconButton(
                      //   tooltip: 'Revert Order',
                      //   icon: const Icon(Icons.undo),
                      //   onPressed: () async {
                      //     showDialog(
                      //       context: context,
                      //       builder: (context) {
                      //         return AlertDialog(
                      //           title: const Text('Revert Order'),
                      //           content: Text('Are you sure you want to revert ${widget.order.orderId} to READY TO CONFIRM'),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () {
                      //                 Navigator.of(context).pop();
                      //               },
                      //               child: const Text('Cancel'),
                      //             ),
                      //             TextButton(
                      //               onPressed: () async {
                      //                 // close confirm dialog
                      //                 Navigator.pop(context);
                      //
                      //                 showDialog(
                      //                   barrierDismissible: false,
                      //                   context: context,
                      //                   builder: (context) {
                      //                     return const AlertDialog(
                      //                       content: Row(
                      //                         children: [
                      //                           CircularProgressIndicator(),
                      //                           SizedBox(width: 8),
                      //                           Text('Reversing'),
                      //                         ],
                      //                       ),
                      //                     );
                      //                   },
                      //                 );
                      //
                      //                 try {
                      //                   log('in revert try');
                      //                   final authPro = context.read<AuthProvider>();
                      //                   final res = await authPro.reverseOrder(widget.order.orderId);
                      //
                      //                   Navigator.pop(context);
                      //
                      //                   if (res['success'] == true) {
                      //                     Utils.showInfoDialog(context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                      //                   } else {
                      //                     Utils.showInfoDialog(context, res['message'], false);
                      //                   }
                      //                 } catch (e, s) {
                      //                   log('in revert catch: $e $s');
                      //                   Navigator.pop(context);
                      //                   Utils.showInfoDialog(context, 'An error occurred: $e', false);
                      //                 }
                      //               },
                      //               child: const Text('Submit'),
                      //             ),
                      //           ],
                      //         );
                      //       },
                      //     );
                      //   },
                      // ),

                      RevertOrderWidget(
                        dropdownEnabled: true,
                        dropdownOptions: [
                          "READY-TO-CONFIRM",
                          "READY-TO-ACCOUNT"
                        ],
                        orderid:  widget.order.orderId,
                      ),

                    if (widget.isBookPage) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Report Bug',
                        onPressed: () {
                          TextEditingController messageController = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                titlePadding: EdgeInsets.zero,
                                title: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.support_agent, color: Colors.white, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Connect with Support',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                content: Container(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Order Details',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: TextEditingController(text: widget.order.orderId),
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'Order ID',
                                          prefixIcon: const Icon(Icons.shopping_cart_outlined),
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Your Message',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: messageController,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          hintText: 'Please describe your issue...',
                                          prefixIcon: const Padding(
                                            padding: EdgeInsets.only(bottom: 84),
                                            child: Icon(Icons.message_outlined),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    // icon: const Icon(Icons.close),
                                    label: const Text('Cancel'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  // const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) {
                                          return const AlertDialog(
                                            content: Row(
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(width: 20),
                                                Text('Processing...'),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      bool result = await context
                                          .read<OrdersProvider>()
                                          .connectWithSupport(context, widget.order.orderId, messageController.text);

                                      Navigator.pop(context);
                                      Navigator.pop(context);

                                      if (result) {
                                        await context.read<BookProvider>().fetchPaginatedOrdersB2C(1);
                                        await context.read<BookProvider>().fetchPaginatedOrdersB2B(1);
                                      }
                                      // _showResultDialog(context, result);
                                    },
                                    // icon: const Icon(Icons.send),
                                    label: const Text('Report'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                      ),
                      const SizedBox(width: 8),

                      if (widget.order.mistakes.any((e) => e.status)) ...[

                        const SizedBox(width: 8),

                        IconButton(
                          tooltip: 'Support Chat',
                          icon: const Icon(Icons.message),
                          onPressed: () {

                            bool canSendMessage = false;

                            if (widget.order.mistakes.isEmpty) {
                              canSendMessage = true;
                            } else {
                              canSendMessage = !widget.order.mistakes.last.status;
                            }

                            context.read<SupportProvider>().setUserData(widget.order.orderId, canSendMessage);

                            context.read<BookProvider>().scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                      ]
                    ]
                  ],
                ),
              ],
            ),

            if (widget.toShowOrderDetails)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              widget.order.date != null
                                  ? buildLabelValueRow('Date', provider.formatDate(widget.order.date!))
                                  : const SizedBox(),
                              buildLabelValueRow('Total Amount', 'Rs. ${widget.order.totalAmount ?? ''}'),
                              buildLabelValueRow('Total Items', '${widget.order.items.fold(0, (total, item) => total + item.qty!)}'),
                              buildLabelValueRow('Total Weight', '${widget.order.totalWeight ?? ''}'),
                              buildLabelValueRow('Payment Mode', widget.order.paymentMode ?? ''),
                              buildLabelValueRow('Currency Code', widget.order.currencyCode ?? ''),
                              buildLabelValueRow('COD Amount', widget.order.codAmount.toString() ?? ''),
                              buildLabelValueRow('AWB No.', widget.order.awbNumber.toString() ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabelValueRow('Discount Amount', widget.order.discountAmount.toString() ?? ''),
                              buildLabelValueRow('Discount Scheme', widget.order.discountScheme ?? ''),
                              buildLabelValueRow('Agent', widget.order.agent ?? ''),
                              buildLabelValueRow('Notes', widget.order.notes ?? ''),
                              buildLabelValueRow('Marketplace', widget.order.marketplace?.name ?? ''),
                              buildLabelValueRow('Filter', widget.order.filter ?? ''),
                              buildLabelValueRow(
                                'Expected Delivery Date',
                                widget.order.expectedDeliveryDate != null ? provider.formatDate(widget.order.expectedDeliveryDate!) : '',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabelValueRow('Delivery Term', widget.order.deliveryTerm ?? ''),
                              buildLabelValueRow('Transaction Number', widget.order.transactionNumber ?? ''),
                              buildLabelValueRow('Micro Dealer Order', widget.order.microDealerOrder ?? ''),
                              buildLabelValueRow('Fulfillment Type', widget.order.fulfillmentType ?? ''),
                              buildLabelValueRow('No. of Boxes', widget.order.numberOfBoxes.toString() ?? ''),
                              buildLabelValueRow('Total Quantity', widget.order.totalQuantity.toString() ?? ''),
                              buildLabelValueRow('SKU Qty', widget.order.skuQty.toString() ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabelValueRow(
                                'Dimensions',
                                '${widget.order.length.toString() ?? ''} x ${widget.order.breadth.toString() ?? ''} x ${widget.order.height.toString() ?? ''}',
                              ),
                              buildLabelValueRow('Tracking Status', widget.order.trackingStatus ?? ''),
                              const SizedBox(
                                height: 7,
                              ),
                              buildLabelValueRow('Tax Percent', '${widget.order.taxPercent.toString() ?? ''}%'),
                              buildLabelValueRow('Courier Name', widget.order.courierName ?? ''),
                              buildLabelValueRow('Order Type', widget.order.orderType ?? ''),
                              buildLabelValueRow('Payment Bank', widget.order.paymentBank ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildLabelValueRow('Prepaid Amount', widget.order.prepaidAmount.toString() ?? ''),
                              buildLabelValueRow('Coin', widget.order.coin.toString() ?? ''),
                              buildLabelValueRow('Preferred Courier', widget.order.preferredCourier ?? ''),
                              buildLabelValueRow(
                                'Payment Date Time',
                                widget.order.paymentDateTime != null ? provider.formatDateTime(widget.order.paymentDateTime!) : '',
                              ),
                              buildLabelValueRow('Calc Entry No.', widget.order.calcEntryNumber ?? ''),
                              buildLabelValueRow('Currency', widget.order.currency ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      thickness: 1,
                      color: AppColors.grey,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Details:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0, color: AppColors.primaryBlue),
                              ),
                              buildLabelValueRow(
                                'Customer ID',
                                widget.order.customer?.customerId ?? '',
                              ),
                              buildLabelValueRow(
                                  'Full Name',
                                  widget.order.customer?.firstName != widget.order.customer?.lastName
                                      ? '${widget.order.customer?.firstName ?? ''} ${widget.order.customer?.lastName ?? ''}'.trim()
                                      : widget.order.customer?.firstName ?? ''),
                              buildLabelValueRow(
                                'Email',
                                widget.order.customer?.email ?? '',
                              ),
                              buildLabelValueRow(
                                'Phone',
                                OrderComboCard.maskPhoneNumber(widget.order.customer?.phone?.toString()) ?? '',
                              ),
                              buildLabelValueRow(
                                'GSTIN',
                                widget.order.customer?.customerGstin ?? '',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shipping Address:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0, color: AppColors.primaryBlue),
                              ),
                              buildLabelValueRow(
                                'Address',
                                [
                                  widget.order.shippingAddress?.address1,
                                  widget.order.shippingAddress?.address2,
                                  widget.order.shippingAddress?.city,
                                  widget.order.shippingAddress?.state,
                                  widget.order.shippingAddress?.country,
                                  widget.order.shippingAddress?.pincode?.toString(),
                                ].where((element) => element != null && element.isNotEmpty).join(', '),
                              ),
                              buildLabelValueRow(
                                'Name',
                                widget.order.shippingAddress?.firstName != widget.order.shippingAddress?.lastName
                                    ? '${widget.order.shippingAddress?.firstName ?? ''} ${widget.order.shippingAddress?.lastName ?? ''}'
                                        .trim()
                                    : widget.order.shippingAddress?.firstName ?? '',
                              ),
                              buildLabelValueRow(
                                  'Phone', OrderComboCard.maskPhoneNumber(widget.order.shippingAddress?.phone?.toString()) ?? ''),
                              buildLabelValueRow('Email', widget.order.shippingAddress?.email ?? ''),
                              buildLabelValueRow('Country Code', widget.order.shippingAddress?.countryCode ?? ''),
                              if (widget.order.shippingAddress?.zipcode?.isNotEmpty ?? false)
                                buildLabelValueRow('Zipcode', widget.order.shippingAddress?.zipcode),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Billing Address:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0, color: AppColors.primaryBlue),
                              ),
                              buildLabelValueRow(
                                'Address',
                                [
                                  widget.order.billingAddress?.address1,
                                  widget.order.billingAddress?.address2,
                                  widget.order.billingAddress?.city,
                                  widget.order.billingAddress?.state,
                                  widget.order.billingAddress?.country,
                                  widget.order.billingAddress?.pincode?.toString(),
                                ].where((element) => element != null && element.isNotEmpty).join(', '),
                              ),
                              buildLabelValueRow(
                                'Name',
                                widget.order.billingAddress?.firstName != widget.order.billingAddress?.lastName
                                    ? '${widget.order.billingAddress?.firstName ?? ''} ${widget.order.billingAddress?.lastName ?? ''}'
                                        .trim()
                                    : widget.order.billingAddress?.firstName ?? '',
                              ),
                              buildLabelValueRow(
                                  'Phone', OrderComboCard.maskPhoneNumber(widget.order.billingAddress?.phone?.toString()) ?? ''),
                              buildLabelValueRow('Email', widget.order.billingAddress?.email ?? ''),
                              buildLabelValueRow('Country Code', widget.order.billingAddress?.countryCode ?? ''),
                              if (widget.order.billingAddress?.zipcode?.isNotEmpty ?? false)
                                buildLabelValueRow('Zipcode', widget.order.billingAddress?.zipcode),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.isBookedPage && (widget.order.rebookedBy?['status'] ?? false)) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.blue.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.blue.shade400, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.15),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade500,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Order Rebooked',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'New Order ID: ',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          border: Border.all(color: Colors.blue.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${widget.order.rebookedBy!['neworder_id']}',
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text.rich(
                        TextSpan(
                          text: "Warehouse Name: ",
                          children: [
                            TextSpan(
                              text: widget.order.warehouseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.isBookPage || widget.isBookedPage)
                        ElevatedButton(
                          onPressed: () {

                            showWriteRemarkDialog(
                              context: context,
                              orderId: widget.order.orderId,
                              message: 'bookerMessage',
                              messages: widget.order.messages,
                              onSubmitted: () async {

                                final bookerProvider = context.read<BookProvider>();

                                final bookedSearch = bookerProvider.searchController.text.trim();
                                final b2bSearch = bookerProvider.b2bSearchController.text.trim();
                                final b2cSearch = bookerProvider.b2cSearchController.text.trim();
                                final searchType = bookerProvider.searchType;

                                if(bookedSearch.isEmpty) {
                                  await bookerProvider.fetchBookedOrders(bookerProvider.currentPageBooked);
                                } else {
                                  await bookerProvider.searchBookedOrders(bookedSearch, searchType);
                                }

                                if(b2bSearch.isEmpty) {
                                  await bookerProvider.fetchPaginatedOrdersB2B(bookerProvider.currentPageB2B);
                                } else {
                                  await bookerProvider.searchB2BOrders(b2bSearch);
                                }

                                if(b2cSearch.isEmpty) {
                                  await bookerProvider.fetchPaginatedOrdersB2C(bookerProvider.currentPageB2C);
                                } else {
                                  await bookerProvider.searchB2COrders(b2cSearch);
                                }
                              },
                            );

                            // showDialog(
                            //   context: context,
                            //   builder: (_) {
                            //     return Dialog(
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(16),
                            //       ),
                            //       insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                            //       child: Container(
                            //         width: MediaQuery.of(context).size.width * 0.9,
                            //         constraints: const BoxConstraints(maxWidth: 600),
                            //         padding: const EdgeInsets.all(20),
                            //         child: Column(
                            //           mainAxisSize: MainAxisSize.min,
                            //           crossAxisAlignment: CrossAxisAlignment.stretch,
                            //           children: [
                            //             const Text(
                            //               'Remark',
                            //               style: TextStyle(
                            //                 fontSize: 24,
                            //                 fontWeight: FontWeight.bold,
                            //               ),
                            //             ),
                            //             const SizedBox(height: 20),
                            //             TextField(
                            //               controller: bookRemark,
                            //               maxLines: 10,
                            //               decoration: InputDecoration(
                            //                 border: OutlineInputBorder(
                            //                   borderRadius: BorderRadius.circular(8),
                            //                 ),
                            //                 hintText: 'Enter your remark here',
                            //                 filled: true,
                            //                 fillColor: Colors.grey[50],
                            //                 contentPadding: const EdgeInsets.all(16),
                            //               ),
                            //             ),
                            //             const SizedBox(height: 24),
                            //             Row(
                            //               mainAxisAlignment: MainAxisAlignment.end,
                            //               children: [
                            //                 TextButton(
                            //                   onPressed: () => Navigator.of(context).pop(),
                            //                   child: const Text(
                            //                     'Cancel',
                            //                     style: TextStyle(fontSize: 16),
                            //                   ),
                            //                 ),
                            //                 const SizedBox(width: 16),
                            //                 ElevatedButton(
                            //                   onPressed: () async {
                            //                     showDialog(
                            //                       context: context,
                            //                       barrierDismissible: false,
                            //                       builder: (_) {
                            //                         return AlertDialog(
                            //                           shape: RoundedRectangleBorder(
                            //                             borderRadius: BorderRadius.circular(16),
                            //                           ),
                            //                           insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                            //                           content: const Row(
                            //                             mainAxisSize: MainAxisSize.min,
                            //                             children: [
                            //                               CircularProgressIndicator(),
                            //                               SizedBox(width: 20),
                            //                               Text(
                            //                                 'Submitting Remark',
                            //                                 style: TextStyle(fontSize: 16),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                         );
                            //                       },
                            //                     );
                            //
                            //                     final res = await pro.writeRemark(context, widget.order.id, bookRemark.text);
                            //
                            //                     log('saved :)');
                            //
                            //                     Navigator.pop(context);
                            //                     Navigator.pop(context);
                            //
                            //                     if(res) {
                            //                       final bookedSearch = pro.searchController.text.trim();
                            //                       final b2bSearch = pro.b2bSearchController.text.trim();
                            //                       final b2cSearch = pro.b2cSearchController.text.trim();
                            //                       final searchType = pro.searchType;
                            //
                            //                       if(bookedSearch.isEmpty) {
                            //                         await pro.fetchBookedOrders(pro.currentPageBooked);
                            //                       } else {
                            //                         await pro.searchBookedOrders(bookedSearch, searchType);
                            //                       }
                            //
                            //                       if(b2bSearch.isEmpty) {
                            //                         await pro.fetchPaginatedOrdersB2B(pro.currentPageB2B);
                            //                       } else {
                            //                         await pro.searchB2BOrders(b2bSearch);
                            //                       }
                            //
                            //                       if(b2cSearch.isEmpty) {
                            //                         await pro.fetchPaginatedOrdersB2C(pro.currentPageB2C);
                            //                       } else {
                            //                         await pro.searchB2COrders(b2cSearch);
                            //                       }
                            //                     }
                            //
                            //                     // res ? await pro.fetchBookedOrders(pro.currentPageBooked) : null;
                            //                     // res ? await pro.fetchPaginatedOrdersB2B(pro.currentPageB2B) : null;
                            //                     // res ? await pro.fetchPaginatedOrdersB2C(pro.currentPageB2C) : null;
                            //                   },
                            //                   style: ElevatedButton.styleFrom(
                            //                     padding: const EdgeInsets.symmetric(
                            //                       horizontal: 24,
                            //                       vertical: 12,
                            //                     ),
                            //                   ),
                            //                   child: const Text(
                            //                     'Submit',
                            //                     style: TextStyle(fontSize: 16),
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     );
                            //   },
                            // );
                          },
                          child: Text(bookerMessages.isNotEmpty ? 'Add a Remark' : 'Write a Remark'),
                        ),

                      if (widget.isAccountSection)
                        ElevatedButton(
                          onPressed: () {

                            showWriteRemarkDialog(
                              context: context,
                              orderId: widget.order.orderId,
                              message: 'accountMessage',
                              messages: widget.order.messages,
                              onSubmitted: () async {

                                final accountProvider = context.read<AccountsProvider>();

                                final invoiceSearch = accountProvider.invoiceSearch.text.trim();
                                final searchType = accountProvider.selectedSearchType;

                                if (invoiceSearch.isEmpty) {
                                  await accountProvider.fetchInvoicedOrders(accountProvider.currentPageBooked);

                                } else {
                                  await accountProvider.searchInvoicedOrders(invoiceSearch, searchType);
                                }

                                await accountProvider.fetchOrdersWithStatus2();
                              },
                            );


                            // showDialog(
                            //   context: context,
                            //   builder: (_) {
                            //     return Dialog(
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(16),
                            //       ),
                            //       insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                            //       child: Container(
                            //         width: MediaQuery.of(context).size.width * 0.9,
                            //         constraints: const BoxConstraints(maxWidth: 600),
                            //         padding: const EdgeInsets.all(20),
                            //         child: Column(
                            //           mainAxisSize: MainAxisSize.min,
                            //           crossAxisAlignment: CrossAxisAlignment.stretch,
                            //           children: [
                            //             const Text(
                            //               'Remark',
                            //               style: TextStyle(
                            //                 fontSize: 24,
                            //                 fontWeight: FontWeight.bold,
                            //               ),
                            //             ),
                            //             const SizedBox(height: 20),
                            //             TextField(
                            //               controller: accountsRemark,
                            //               maxLines: 10,
                            //               decoration: InputDecoration(
                            //                 border: OutlineInputBorder(
                            //                   borderRadius: BorderRadius.circular(8),
                            //                 ),
                            //                 hintText: 'Enter your remark here',
                            //                 filled: true,
                            //                 fillColor: Colors.grey[50],
                            //                 contentPadding: const EdgeInsets.all(16),
                            //               ),
                            //             ),
                            //             const SizedBox(height: 24),
                            //             Row(
                            //               mainAxisAlignment: MainAxisAlignment.end,
                            //               children: [
                            //                 TextButton(
                            //                   onPressed: () => Navigator.of(context).pop(),
                            //                   child: const Text(
                            //                     'Cancel',
                            //                     style: TextStyle(fontSize: 16),
                            //                   ),
                            //                 ),
                            //                 const SizedBox(width: 16),
                            //                 ElevatedButton(
                            //                   onPressed: () async {
                            //                     showDialog(
                            //                       context: context,
                            //                       barrierDismissible: false,
                            //                       builder: (_) {
                            //                         return AlertDialog(
                            //                           shape: RoundedRectangleBorder(
                            //                             borderRadius: BorderRadius.circular(16),
                            //                           ),
                            //                           insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                            //                           content: const Row(
                            //                             mainAxisSize: MainAxisSize.min,
                            //                             children: [
                            //                               CircularProgressIndicator(),
                            //                               SizedBox(width: 20),
                            //                               Text(
                            //                                 'Submitting Remark',
                            //                                 style: TextStyle(fontSize: 16),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                         );
                            //                       },
                            //                     );
                            //
                            //                     final res = await pro.writeRemark(context, widget.order.id, accountsRemark.text);
                            //
                            //                     log('saved :)');
                            //
                            //                     Navigator.pop(context);
                            //                     Navigator.pop(context);
                            //
                            //                     if(res) {
                            //                       final invoiceSearch = pro.invoiceSearch.text.trim();
                            //                       final searchType = pro.selectedSearchType;
                            //
                            //                       if(invoiceSearch.isEmpty) {
                            //                         await pro.fetchInvoicedOrders(pro.currentPageBooked);
                            //                       } else {
                            //                         await pro.searchInvoicedOrders(invoiceSearch, searchType);
                            //                       }
                            //                     }
                            //
                            //                     res ? await pro.fetchInvoicedOrders(pro.currentPageBooked) : null;
                            //                     res ? await pro.fetchOrdersWithStatus2() : null;
                            //                   },
                            //                   style: ElevatedButton.styleFrom(
                            //                     padding: const EdgeInsets.symmetric(
                            //                       horizontal: 24,
                            //                       vertical: 12,
                            //                     ),
                            //                   ),
                            //                   child: const Text(
                            //                     'Submit',
                            //                     style: TextStyle(fontSize: 16),
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     );
                            //   },
                            // );

                          },
                          child: Text(accountMessages.isNotEmpty ? 'Add a Remark' : 'Write a Remark'),
                        ),

                      if (confirmerMessages.isNotEmpty)
                        Tooltip(
                          message: confirmerMessages.last.message,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Text(
                              confirmerMessages.last.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),

                      if (accountMessages.isNotEmpty)
                        Tooltip(
                          message: accountMessages.last.message,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Text(
                              accountMessages.last.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.deepOrange,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),

                      if (bookerMessages.isNotEmpty)
                        Tooltip(
                          message: bookerMessages.last.message,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Text(
                              bookerMessages.last.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blueAccent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                    ],

                  ),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comboItemGroups.length,
              itemBuilder: (context, comboIndex) {
                final combo = comboItemGroups[comboIndex];

                return _buildComboDetails(context, combo);
              },
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: remainingItems.length,
              itemBuilder: (context, itemIndex) {
                final item = remainingItems[itemIndex];
                print('Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                return _buildProductDetails(item);
              },
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: "Outbound: ",
                          children: [
                            TextSpan(
                              text: "${widget.order.outBoundBy?['status'] ?? false}",
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            (widget.order.outBoundBy?['outboundBy']?.toString().isNotEmpty ?? false)
                                ? TextSpan(
                                    text: "(${widget.order.outBoundBy?['outboundBy'].toString().split('@')[0] ?? ''})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  )
                                : const TextSpan(),
                          ],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      if (showBy(widget.order.confirmedBy?['status'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Confirmed By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.confirmedBy!['confirmedBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.confirmedBy!['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.confirmedBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy(widget.order.baApprovedBy?['status'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "BA Approved By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.baApprovedBy!['baApprovedBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.baApprovedBy!['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.baApprovedBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy(widget.order.checkInvoiceBy?['approved'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Invoiced By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.checkInvoiceBy!['invoiceBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.checkInvoiceBy != null && widget.order.checkInvoiceBy?['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.checkInvoiceBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy(widget.order.bookedBy?['status'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Booked By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.bookedBy!['bookedBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.bookedBy!['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.bookedBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy(widget.order.pickedBy?['status'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Picked By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.pickedBy!['pickedBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.pickedBy!['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.pickedBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy(widget.order.packedBy?['status'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Packed By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.packedBy!['packedBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.packedBy!['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.packedBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy(widget.order.checkedBy?['approved'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Checked By: ",
                              children: [
                                TextSpan(
                                    text: widget.order.checkedBy!['checkedBy']?.toString().split('@')[0] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    )),
                                if (widget.order.checkedBy!['timestamp'] != null)
                                  TextSpan(
                                      text: ' (${formatIsoDate(widget.order.checkedBy!['timestamp'])})' ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      )),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      if (showBy((widget.order.rackedBy?['approved'] ?? false)))
                        Text.rich(
                          TextSpan(
                            text: "Racked By: ",
                            children: [
                              TextSpan(
                                text: widget.order.rackedBy!['rackedBy']?.toString().split('@')[0] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              if (widget.order.rackedBy!['timestamp'] != null)
                                TextSpan(
                                  text: ' (${formatIsoDate(widget.order.rackedBy!['timestamp'])})' ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                            ],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (showBy(widget.order.manifestedBy?['approved'] ?? false))
                        Text.rich(
                          TextSpan(
                              text: "Manifested By: ",
                              children: [
                                TextSpan(
                                  text: widget.order.manifestedBy!['manifestBy']?.toString().split('@')[0] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                if (widget.order.manifestedBy!['timestamp'] != null)
                                  TextSpan(
                                    text: ' (${formatIsoDate(widget.order.manifestedBy!['timestamp'])})' ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                              ],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                      text: "Updated on: ",
                      children: [
                        TextSpan(
                            text: widget.order.updatedAt != null
                                ? DateFormat('yyyy-MM-dd, hh:mm a').format(
                                    DateTime.parse("${widget.order.updatedAt}"),
                                  )
                                : '',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            )),
                      ],
                      style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboProductDetails(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(item),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductName(item),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'SKU: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: item.product?.sku ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Qty: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: item.qty?.toString() ?? '0',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboDetails(BuildContext context, List<Item> items) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(items[0].comboSku ?? ''),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Amount: ',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Rs.${items[0].comboAmount.toString()}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                content: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, itemIndex) {
                          final item = items[itemIndex];
                          print('Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                          return _buildComboProductDetails(item);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(
                    width: 60,
                    height: 60,
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 40,
                      color: AppColors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              items[0].comboName ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Flexible(
                            child: Text(
                              "Combo",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'SKU: ',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: items[0].comboSku ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Qty: ',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: items[0].qty?.toString() ?? '0',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Amount: ',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Rs.${items[0].comboAmount.toString()}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(item),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductName(item),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'SKU: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: item.product?.sku ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Qty: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: item.qty?.toString() ?? '0',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Rate: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: 'Rs.${(item.amount! / item.qty!).toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Amount: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: 'Rs.${item.amount.toString()}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // RichText(
                      //   text: TextSpan(
                      //     children: [
                      //       const TextSpan(
                      //         text: 'Outer Package: ',
                      //         style: TextStyle(
                      //           color: Colors.blueAccent,
                      //           fontWeight: FontWeight.bold,
                      //           fontSize: 13,
                      //         ),
                      //       ),
                      //       TextSpan(
                      //         text: item.product?.outerPackage?.outerPackageName ?? '',
                      //         style: const TextStyle(
                      //           color: Colors.black87,
                      //           fontWeight: FontWeight.w500,
                      //           fontSize: 13,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabelValueRow(
    String label,
    String? value, {
    Color labelColor = Colors.black,
    Color valueColor = AppColors.primaryBlue,
    double fontSize = 10,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: fontSize,
            color: labelColor,
          ),
        ),
        Expanded(
          child: Text(
            value ?? '',
            softWrap: true,
            maxLines: null,
            style: TextStyle(
              fontSize: fontSize,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(Item item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 60,
        height: 60,
        child: item.product?.shopifyImage != null && item.product!.shopifyImage!.isNotEmpty
            ? Image.network(
                item.product!.shopifyImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: AppColors.grey,
                  );
                },
              )
            : const Icon(
                Icons.image_not_supported,
                size: 40,
                color: AppColors.grey,
              ),
      ),
    );
  }

  Widget _buildProductName(Item item) {
    return Text(
      item.product?.displayName ?? 'No Name',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> refresh() async {
    if (widget.isBookPage) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
      bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);
    } else if (widget.isPacked) {
      final packedProvider = Provider.of<PackerProvider>(context, listen: false);
      packedProvider.fetchOrdersWithStatus5();
    }
  }
}
