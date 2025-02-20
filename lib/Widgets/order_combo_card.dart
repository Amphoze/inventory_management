import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:provider/provider.dart';

import '../provider/orders_provider.dart'; // Adjust the import based on your project structure

class OrderComboCard extends StatefulWidget {
  final Order order;
  final Widget? checkboxWidget;
  final bool toShowOrderDetails;
  final bool isBookPage;
  final bool toShowBy;
  final bool toShowAll;
  final bool isBookedPage;
  final bool isAccountSection;

  const OrderComboCard({
    super.key,
    this.toShowAll = false,
    required this.toShowBy,
    required this.order,
    this.checkboxWidget,
    required this.toShowOrderDetails,
    this.isBookPage = false,
    this.isBookedPage = false,
    this.isAccountSection = false,
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

  bool showBy(bool val) {
    return (val && widget.toShowBy);
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return "$date, $time";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrdersProvider>(context, listen: false);
    final orderProvider = context.read<OrdersProvider>();

    print('Building OrderCard for Order ID: ${widget.order.id}');

    final Map<String, List<Item>> groupedComboItems = {};

    for (var item in widget.order.items) {
      if (item.isCombo == true && item.comboSku != null) {
        if (!groupedComboItems.containsKey(item.comboSku)) {
          groupedComboItems[item.comboSku!] = [];
        }
        groupedComboItems[item.comboSku]!.add(item);
      }
    }

    // Filter out groups with more than one item
    final List<List<Item>> comboItemGroups = groupedComboItems.values.where((items) => items.length > 1).toList();

    // Remaining items that do not satisfy the combo condition
    final List<Item> remainingItems = widget.order.items
        .where((item) => !(item.isCombo == true && item.comboSku != null && groupedComboItems[item.comboSku]!.length > 1))
        .toList();

    return Card(
      color: AppColors.white,
      elevation: 4, // Reduced elevation for less shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Slightly smaller rounded corners
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding for a smaller card
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
                      ElevatedButton(
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
                          // log("resulttt$result");
                          if (result != null && result is bool && result) {
                            final pro = Provider.of<BookProvider>(context, listen: false);
                            pro.fetchPaginatedOrdersB2C(pro.currentPageB2C);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          foregroundColor: AppColors.white,
                          backgroundColor: AppColors.orange,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        child: const Text(
                          'Edit Order',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController warehouse = TextEditingController(text: widget.order.warehouseName);
                              return AlertDialog(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Edit Warehouse', style: TextStyle(fontSize: 20)),
                                    Text(widget.order.orderId, style: const TextStyle(fontSize: 15)),
                                  ],
                                ),
                                content: TextField(
                                  controller: warehouse,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Warehouse Name',
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const AlertDialog(
                                            title: Row(
                                          children: [
                                            CircularProgressIndicator(),
                                            Text(
                                              'Updating Warehouse',
                                            ),
                                          ],
                                        )),
                                      );
                                      final pro = Provider.of<BookProvider>(context, listen: false);
                                      final res = await pro.editWarehouse(widget.order.id, warehouse.text.trim());
                                      log('edit warehouse result: $res');
                                      if (res == true) {
                                        pro.fetchPaginatedOrdersB2C(pro.currentPageB2C);
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
                                    },
                                    child: const Text('Submit'),
                                  ),
                                ],
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
                        child: const Text(
                          'Edit Warehouse',
                          // style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
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
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isBookedPage && widget.order.rebookedBy!['status']) ...[
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
                              color: Colors.blue.withOpacity(0.15),
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
                                        '${widget.order.rebookedBy!['neworder_id']}', // Replace with your new order ID
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
                    if (widget.isBookPage) ...[
                      Text.rich(
                        TextSpan(
                          text: "Warehouse ID: ",
                          children: [
                            TextSpan(
                              text: widget.order.warehouseId ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: "Warehouse Name: ",
                          children: [
                            TextSpan(
                              text: widget.order.warehouseName ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ],
                ),
                // const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    widget.isBookedPage
                        ? ElevatedButton(
                            onPressed: () {
                              final pro = context.read<BookProvider>();
                              setState(() {
                                bookRemark.text = widget.order.messages!['bookerMessage'].toString() ?? '';
                              });
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    // Making dialog wider by using custom insetPadding
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
                                      constraints: const BoxConstraints(maxWidth: 600), // Maximum width limit
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const Text(
                                            'Remark',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: bookRemark,
                                            maxLines: 10,
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
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
                                                    builder: (_) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                                        content: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            CircularProgressIndicator(),
                                                            SizedBox(width: 20), // Adjust to create horizontal spacing
                                                            Text(
                                                              'Submitting Remark',
                                                              style: TextStyle(fontSize: 16),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );

                                                  final res = await pro.writeRemark(context, widget.order.id, bookRemark.text);

                                                  log('saved :)');

                                                  Navigator.pop(context);
                                                  Navigator.pop(context);

                                                  res ? await pro.fetchBookedOrders(pro.currentPageBooked) : null;
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
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: widget.order.messages != null &&
                                    widget.order.messages!['bookerMessage'] != null &&
                                    widget.order.messages!['bookerMessage'].toString().isNotEmpty
                                ? const Text('Edit Remark')
                                : const Text('Write Remark'),
                          )
                        : const SizedBox(),
                    widget.isAccountSection
                        ? ElevatedButton(
                            onPressed: () {
                              final pro = context.read<AccountsProvider>();
                              setState(() {
                                accountsRemark.text = widget.order.messages!['accountMessage'].toString() ?? '';
                              });
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    // Making dialog wider by using custom insetPadding
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
                                      constraints: const BoxConstraints(maxWidth: 600), // Maximum width limit
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const Text(
                                            'Remark',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: accountsRemark,
                                            maxLines: 10,
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
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
                                                    builder: (_) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                                        content: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            CircularProgressIndicator(),
                                                            SizedBox(width: 20), // Adjust to create horizontal spacing
                                                            Text(
                                                              'Submitting Remark',
                                                              style: TextStyle(fontSize: 16),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );

                                                  final res = await pro.writeRemark(context, widget.order.id, accountsRemark.text);

                                                  log('saved :)');

                                                  Navigator.pop(context);
                                                  Navigator.pop(context);

                                                  res ? await pro.fetchAccountedOrders(pro.currentPageBooked) : null;
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
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: widget.order.messages != null &&
                                    widget.order.messages!['Message'] != null &&
                                    widget.order.messages!['accountMessage'].toString().isNotEmpty
                                ? const Text('Edit Remark')
                                : const Text('Write Remark'),
                          )
                        : const SizedBox(),
                    ///////////////////////////////////////////////////////////////
                    if (widget.order.messages != null &&
                        widget.order.messages!['confirmerMessage'] != null &&
                        widget.order.messages!['confirmerMessage'].toString().isNotEmpty) ...[
                      Utils().showMessage(context, 'Confirmer Remark', widget.order.messages!['confirmerMessage'].toString())
                    ],
                    ///////////////////////////////////////////////////////////
                    if (widget.order.messages != null &&
                        widget.order.messages!['accountMessage'] != null &&
                        widget.order.messages!['accountMessage'].toString().isNotEmpty) ...[
                      Utils().showMessage(context, 'Account Remark', widget.order.messages!['accountMessage'].toString()),
                    ],
                    /////////////////////////////////////////////////////////
                    if (widget.order.messages != null &&
                        widget.order.messages!['bookerMessage'] != null &&
                        widget.order.messages!['bookerMessage'].toString().isNotEmpty &&
                        widget.isBookedPage) ...[
                      Utils().showMessage(context, 'Booker Remark', widget.order.messages!['bookerMessage'].toString())
                    ],
                  ],
                ),
              ],
            ),
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comboItemGroups.length,
              itemBuilder: (context, comboIndex) {
                final combo = comboItemGroups[comboIndex];
                // print(
                //     'Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(widget.order.outBoundBy.toString()),
                    Text.rich(
                      TextSpan(
                          text: "Outbound: ",
                          children: [
                            TextSpan(
                                text: "${widget.order.outBoundBy?['status'] ?? false}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                )),
                          ],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    if (showBy(widget.order.outBoundBy != null && widget.order.outBoundBy!['status']))
                      Text.rich(
                        TextSpan(
                          text: "Outbound By: ",
                          children: [
                            TextSpan(
                              text: widget.order.outBoundBy!['outBoundBy'].toString().split('@')[0] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            if (widget.order.outBoundBy!['timestamp'] != null)
                              TextSpan(
                                text: ' (${formatIsoDate(widget.order.outBoundBy!['timestamp'])})' ?? '',
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
                    if (showBy(widget.order.confirmedBy != null && widget.order.confirmedBy!['status']))
                      Text.rich(
                        TextSpan(
                            text: "Confirmed By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.confirmedBy!['confirmedBy'].toString().split('@')[0] ?? '',
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
                    if (showBy(widget.order.baApprovedBy != null && widget.order.baApprovedBy!['status']))
                      Text.rich(
                        TextSpan(
                            text: "BA Approved By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.baApprovedBy!['baApprovedBy'].toString().split('@')[0] ?? '',
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
                    if (showBy(widget.order.checkInvoiceBy != null && widget.order.checkInvoiceBy!['approved'] != null))
                      Text.rich(
                        TextSpan(
                            text: "Accounted By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.checkInvoiceBy!['invoiceBy'].toString().split('@')[0] ?? '',
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
                    if (widget.order.bookedBy != null && showBy(widget.order.bookedBy!['status']))
                      Text.rich(
                        TextSpan(
                            text: "Booked By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.bookedBy!['bookedBy'].toString().split('@')[0] ?? '',
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
                    if (showBy(widget.order.pickedBy != null && widget.order.pickedBy!['status']))
                      Text.rich(
                        TextSpan(
                            text: "Picked By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.pickedBy!['pickedBy'].toString().split('@')[0] ?? '',
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
                    if (showBy(widget.order.packedBy != null && widget.order.packedBy!['status']))
                      Text.rich(
                        TextSpan(
                            text: "Packed By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.packedBy!['packedBy'].toString().split('@')[0] ?? '',
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
                    if (showBy(widget.order.checkedBy != null && widget.order.checkedBy!['approved'] != null))
                      Text.rich(
                        TextSpan(
                            text: "Checked By: ",
                            children: [
                              TextSpan(
                                  text: widget.order.checkedBy!['checkedBy'].toString().split('@')[0] ?? '',
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
                    if (showBy(widget.order.rackedBy != null && (widget.order.rackedBy?['approved'] ?? false)))
                      Text.rich(
                        TextSpan(
                            text: "Racked By: ",
                            children: [
                              TextSpan(
                                text: widget.order.rackedBy!['rackedBy'].toString().split('@')[0] ?? '',
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
                            )),
                      ),
                    if (showBy(widget.order.manifestedBy != null && widget.order.manifestedBy!['approved'] != null))
                      Text.rich(
                        TextSpan(
                            text: "Manifested By: ",
                            children: [
                              TextSpan(
                                text: widget.order.manifestedBy!['manifestBy'].toString().split('@')[0] ?? '',
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      )),
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
        borderRadius: BorderRadius.circular(10), // Slightly smaller rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Lighter shadow for smaller card
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced padding inside product card
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(item),
            const SizedBox(width: 8.0), // Reduced spacing between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductName(item),
                  const SizedBox(height: 6.0), // Reduced spacing between text elements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between widgets
                    children: [
                      // SKU at the extreme left
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'SKU: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: item.product?.sku ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Qty in the center
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Qty: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: item.qty?.toString() ?? '0',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
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
                              // fontSize: 13, // Reduced font size
                            ),
                          ),
                          TextSpan(
                            text: 'Rs.${items[0].comboAmount.toString()}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              // fontSize: 13, // Reduced font size
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                content: SizedBox(
                  width: 500, // Set a specific width for the dialog
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
            // color: Colors.blue,
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(10), // Slightly smaller rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // Lighter shadow for smaller card
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0), // Reduced padding inside product card
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildProductImage(items[0]),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(
                    width: 60, // Smaller image size
                    height: 60,
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 40, // Smaller fallback icon size
                      color: AppColors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0), // Reduced spacing between image and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // _buildProductName(items[0]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              items[0].comboName ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Reduced font size
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
                                fontSize: 14, // Reduced font size
                                color: AppColors.primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0), // Reduced spacing between text elements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between widgets
                        children: [
                          // SKU at the extreme left
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'SKU: ',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13, // Reduced font size
                                  ),
                                ),
                                TextSpan(
                                  text: items[0].comboSku ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13, // Reduced font size
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Qty in the center
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Qty: ',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13, // Reduced font size
                                  ),
                                ),
                                TextSpan(
                                  text: items[0].qty?.toString() ?? '0',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13, // Reduced font size
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
                                    fontSize: 13, // Reduced font size
                                  ),
                                ),
                                TextSpan(
                                  text: 'Rs.${items[0].comboAmount.toString()}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13, // Reduced font size
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
        borderRadius: BorderRadius.circular(10), // Slightly smaller rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Lighter shadow for smaller card
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced padding inside product card
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(item),
            const SizedBox(width: 8.0), // Reduced spacing between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductName(item),
                  const SizedBox(height: 6.0), // Reduced spacing between text elements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between widgets
                    children: [
                      // SKU at the extreme left
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'SKU: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: item.product?.sku ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Qty in the center
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Qty: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: item.qty?.toString() ?? '0',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rate
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Rate: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: 'Rs.${(item.amount! / item.qty!).toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Amount at the extreme right
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Amount: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: 'Rs.${item.amount.toString()}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
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
        Flexible(
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
        width: 60, // Smaller image size
        height: 60,
        child: item.product?.shopifyImage != null && item.product!.shopifyImage!.isNotEmpty
            ? Image.network(
                item.product!.shopifyImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 40, // Smaller fallback icon size
                    color: AppColors.grey,
                  );
                },
              )
            : const Icon(
                Icons.image_not_supported,
                size: 40, // Smaller fallback icon size
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
        fontSize: 14, // Reduced font size
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
