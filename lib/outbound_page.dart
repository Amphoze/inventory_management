import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/order_info.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/outbound_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class OutboundPage extends StatefulWidget {
  const OutboundPage({super.key});

  @override
  _OutboundPageState createState() => _OutboundPageState();
}

class _OutboundPageState extends State<OutboundPage> with TickerProviderStateMixin {
  // late TextEditingController _searchController;
  // late TextEditingController _searchControllerFailed;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();
  // String _selectedDate = 'Select Date';
  // String selectedCourier = 'All';
  // DateTime? picked;

  late OutboundProvider provider;

  @override
  void initState() {
    super.initState();
    provider = context.read<OutboundProvider>();
    // _tabController = TabController(length: 2, vsync: this);
    // _searchController = TextEditingController();
    provider.searchController = TextEditingController();
    // _searchControllerFailed = TextEditingController();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadOrders();
    });
    // _searchController.clear();
    provider.searchController.clear();
    // _searchControllerFailed.clear();

    // context.read<MarketplaceProvider>().fetchMarketplaces();
  }

  @override
  void dispose() {
    // _searchController.dispose();
    provider.searchController.dispose();
    // _searchControllerFailed.dispose();
    _pageController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _reloadOrders() async {
    // Access the OutboundProvider and fetch orders again
    await provider.fetchOrders(); // Fetch both orders
    // ordersProvider.fetchFailedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildReadyToConfirmTab(),
    );
  }

  Widget _buildReadyToConfirmTab() {
    return Consumer<OutboundProvider>(
      builder: (context, pro, child) {
        if (pro.isLoading) {
          return const Center(
            child: LoadingAnimation(
              icon: Icons.outbond,
              beginColor: Color.fromRGBO(189, 189, 189, 1),
              endColor: AppColors.primaryBlue,
              size: 80.0,
            ),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // !isEditOrder
                //     ?
                Row(
                  children: [
                    Checkbox(
                      value: pro.allSelectedReady,
                      onChanged: (bool? value) {
                        pro.toggleSelectAllReady(value ?? false);
                      },
                    ),
                    Text('Select All (${pro.selectedReadyItemsCount})'),
                  ],
                ),
                // : const SizedBox(),
                Row(
                  children: [
                    // IconButton(
                    //     onPressed: () {
                    //       setState(() {
                    //         isEditOrder = !isEditOrder;
                    //       });
                    //     },
                    //     icon: const Icon(Icons.call)),
                    // if (!isEditOrder) ...[

                    pro.rtoCount != null && pro.dispatchCount != null
                        ? Chip(
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: "RTO: ",
                                    children: [
                                      TextSpan(
                                        text: '${pro.rtoCount} (${(pro.rtoCount! / pro.allCount! * 100).round()}%)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: AppColors.cardsred,
                                        ),
                                      ),
                                    ],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: "Delivered: ",
                                    children: [
                                      TextSpan(
                                        text: '${pro.dispatchCount} (${(pro.dispatchCount! / pro.allCount! * 100).round()}%)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                    const SizedBox(
                      width: 8,
                    ),

                    Column(
                      children: [
                        Text(
                          pro.selectedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: pro.selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                          ),
                        ),
                        Tooltip(
                          message: 'Filter by Date',
                          child: IconButton(
                            onPressed: () async {
                              pro.picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primaryBlue,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pro.picked != null) {
                                String formattedDate = DateFormat('dd-MM-yyyy').format(pro.picked!);
                                setState(() {
                                  pro.selectedDate = formattedDate;
                                });

                                pro.fetchOrders(page: pro.currentPageReady);
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 30,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Text(
                          pro.selectedCourier,
                        ),
                        Consumer<MarketplaceProvider>(
                          builder: (context, provider, child) {
                            return PopupMenuButton<String>(
                              tooltip: 'Filter by Marketplace',
                              onSelected: (String value) {
                                setState(() {
                                  pro.selectedCourier = value;
                                });
                                pro.fetchOrders(page: pro.currentPageReady);
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'All', // Hardcoded marketplace
                                  child: Text('All'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Shopify', // Hardcoded marketplace
                                  child: Text('Shopify'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Woocommerce', // Hardcoded marketplace
                                  child: Text('Woocommerce'),
                                ),
                              ],
                              child: const IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.filter_alt_outlined,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: pro.isConfirm
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OutboundProvider>(context, listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider.outboundOrders
                                  .asMap()
                                  .entries
                                  .where((entry) => provider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              log('selectedOrderIds: $selectedOrderIds');

                              if (selectedOrderIds.isEmpty) {
                                // Show an error message if no orders are selected
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                String resultMessage = await provider.approveOrders(context, selectedOrderIds);

                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor = AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                  snackBarColor = AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor = AppColors.orange; // Other: Orange
                                }

                                // Show feedback based on the result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resultMessage),
                                    backgroundColor: snackBarColor,
                                  ),
                                );
                              }
                            },
                      child: pro.isConfirm
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Approve',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: pro.isCancel
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OutboundProvider>(context, listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider.outboundOrders
                                  .asMap()
                                  .entries
                                  .where((entry) => provider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                // Show an error message if no orders are selected
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                // Set loading status to true before starting the operation
                                provider.setCancelStatus(true);

                                // Call confirmOrders method with selected IDs
                                String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

                                // Set loading status to false after operation completes
                                provider.setCancelStatus(false);

                                // Determine the background color based on the result
                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor = AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                  snackBarColor = AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor = AppColors.orange; // Other: Orange
                                }

                                // Show feedback based on the result
                                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(resultMessage),
                                    backgroundColor: snackBarColor,
                                  ),
                                );
                              }
                            },
                      child: pro.isCancel
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Cancel Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        pro.searchController.clear();
                        pro.resetFilter();
                        pro.fetchOrders();
                        pro.resetSelections();
                        pro.clearSearchResults();
                        print('Ready to Confirm Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 300,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: provider.searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Orders By ID/Phone',
                                hintStyle: TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onSubmitted: (value) async {
                                pro.resetFilter();

                                if (value.startsWith(RegExp(r'^[0-9]'))) {
                                  await pro.searchOrdersByPhone(value);
                                } else if (value.contains('-')) {
                                  await pro.searchOrdersByID(value);
                                } else {
                                  await pro.fetchOrders();
                                }
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  pro.clearSearchResults();
                                  pro.fetchOrders();
                                }
                              },
                            ),
                          ),
                          if (provider.searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                provider.searchController.clear();
                                pro.fetchOrders();
                                pro.clearSearchResults();
                              },
                            ),
                        ],
                      ),
                    ),

                    // ] else
                    //   const SizedBox(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: pro.isLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryBlue,
                        size: 80.0,
                      ),
                    )
                  : pro.outboundOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: pro.outboundOrders.length,
                          itemBuilder: (context, index) {
                            final order = pro.outboundOrders[index];

                            Map<String, int> counts = order.countCallStatuses();

                            int notAnsweredCount = counts["not answered"] ?? 0;
                            int answeredCount = counts["answered"] ?? 0;
                            int notReachCount = counts["not reach"] ?? 0;
                            int busyCount = counts["busy"] ?? 0;

                            print("Not Answered: $notAnsweredCount");
                            print("Answered: $answeredCount");
                            print("Not Reach: $notReachCount");
                            print("Busy: $busyCount");
                            //////////////////////////////////////////////////////////////
                            final Map<String, List<Item>> groupedComboItems = {};
                            for (var item in order.items) {
                              if (item.isCombo == true && item.comboSku != null) {
                                if (!groupedComboItems.containsKey(item.comboSku)) {
                                  groupedComboItems[item.comboSku!] = [];
                                }
                                groupedComboItems[item.comboSku]!.add(item);
                              }
                            }
                            final List<List<Item>> comboItemGroups = groupedComboItems.values.where((items) => items.length > 1).toList();

                            final List<Item> remainingItems = order.items
                                .where((item) =>
                                    !(item.isCombo == true && item.comboSku != null && groupedComboItems[item.comboSku]!.length > 1))
                                .toList();

                            Logger().e('order details: ${order.orderId} ${order.orderStatus} ${order.merged!['status']}');
                            //////////////////////////////////////////////////////////
                            return Card(
                              surfaceTintColor: Colors.white,
                              color: pro.selectedReadyOrders[index] ? Colors.grey[300] : Colors.grey[100],
                              elevation: 2,
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Checkbox(
                                          value: pro.selectedReadyOrders[index],
                                          onChanged: (value) => pro.toggleOrderSelectionReady(value ?? false, index),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Order ID: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              order.orderId ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (order.date != null)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Date: ',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                pro.formatDate(order.date!),
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                              ),
                                            ],
                                          ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Amount: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Rs. ${order.totalAmount ?? ''}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Items: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.items.fold(0, (total, item) => total + item.qty!)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Weight: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              order.totalWeight.toStringAsFixed(2) ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Flexible(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => EditOutboundPage(
                                                        order: order,
                                                        isBookPage: false,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    final readySearched = provider.searchController.text.trim();

                                                    // Ready
                                                    if (readySearched.isNotEmpty) {
                                                      pro.searchOrdersByID(readySearched);
                                                    } else {
                                                      pro.fetchOrders(page: pro.currentPageReady);
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: AppColors.white,
                                                  backgroundColor: AppColors.orange,
                                                  // Set the text color to white
                                                  textStyle: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Edit Order',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Call customer',
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
                                                            Text('Calling...'),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                  final result = await pro.sendSingleCall(
                                                    context,
                                                    order.orderId,
                                                  );

                                                  if (result) {
                                                    Navigator.pop(context);
                                                    _showStatusDialog(order.orderId);
                                                  }
                                                },
                                                icon: const Icon(
                                                    // Icons.call_outlined,
                                                    FontAwesomeIcons.phone
                                                    // color: Colors.blue,
                                                    // size: 20,
                                                    ),
                                              ),
                                              // IconButton(
                                              //   tooltip: 'Mark call status',
                                              //   onPressed: () => _showStatusDialog(order.orderId),
                                              //   icon: const Icon(Icons.more_vert),
                                              // )
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
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text.rich(
                                          style: const TextStyle(fontSize: 14),
                                          TextSpan(
                                            text: 'Answered: ',
                                            children: [
                                              TextSpan(
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                                  text: answeredCount.toString()),
                                            ],
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            text: 'Not Answered: ',
                                            children: [
                                              TextSpan(
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                                  text: notAnsweredCount.toString()),
                                            ],
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            text: 'Not Reached: ',
                                            children: [
                                              TextSpan(
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                                  text: notReachCount.toString()),
                                            ],
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            text: 'Busy: ',
                                            children: [
                                              TextSpan(
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                                  text: busyCount.toString()),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    OrderInfo(order: order, pro: pro),
                                    // Padding(
                                    //   padding: const EdgeInsets.all(8.0),
                                    //   child: Row(
                                    //     crossAxisAlignment: CrossAxisAlignment.start,
                                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //     children: [
                                    //       Expanded(
                                    //         child: Padding(
                                    //           padding: const EdgeInsets.only(right: 8.0),
                                    //           child: Column(
                                    //             crossAxisAlignment: CrossAxisAlignment.start,
                                    //             children: [
                                    //               buildLabelValueRow('Payment Mode', order.paymentMode ?? ''),
                                    //               buildLabelValueRow('Currency Code', order.currencyCode ?? ''),
                                    //               buildLabelValueRow('COD Amount', order.codAmount.toString() ?? ''),
                                    //               buildLabelValueRow('Prepaid Amount', order.prepaidAmount.toString() ?? ''),
                                    //               buildLabelValueRow('Coin', order.coin.toString() ?? ''),
                                    //               buildLabelValueRow('Tax Percent', order.taxPercent.toString() ?? ''),
                                    //               buildLabelValueRow('Courier Name', order.courierName ?? ''),
                                    //               buildLabelValueRow('Order Type', order.orderType ?? ''),
                                    //               buildLabelValueRow('Payment Bank', order.paymentBank ?? ''),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //       ),
                                    //       // const SizedBox(width: 12.0),
                                    //       Expanded(
                                    //         child: Padding(
                                    //           padding: const EdgeInsets.only(right: 8.0),
                                    //           child: Column(
                                    //             crossAxisAlignment: CrossAxisAlignment.start,
                                    //             children: [
                                    //               buildLabelValueRow('Discount Amount', order.discountAmount.toString() ?? ''),
                                    //               buildLabelValueRow('Discount Scheme', order.discountScheme ?? ''),
                                    //               buildLabelValueRow('Discount Percent', order.discountPercent.toString() ?? ''),
                                    //               buildLabelValueRow('Agent', order.agent ?? ''),
                                    //               buildLabelValueRow('Notes', order.notes ?? ''),
                                    //               buildLabelValueRow('Marketplace', order.marketplace?.name ?? ''),
                                    //               buildLabelValueRow('Filter', order.filter ?? ''),
                                    //               buildLabelValueRow(
                                    //                 'Expected Delivery Date',
                                    //                 order.expectedDeliveryDate != null ? pro.formatDate(order.expectedDeliveryDate!) : '',
                                    //               ),
                                    //               buildLabelValueRow('Preferred Courier', order.preferredCourier ?? ''),
                                    //               buildLabelValueRow(
                                    //                 'Payment Date Time',
                                    //                 order.paymentDateTime != null ? pro.formatDateTime(order.paymentDateTime!) : '',
                                    //               ),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //       ),
                                    //       // const SizedBox(width: 12.0),
                                    //       Expanded(
                                    //         child: Padding(
                                    //           padding: const EdgeInsets.only(right: 8.0),
                                    //           child: Column(
                                    //             crossAxisAlignment: CrossAxisAlignment.start,
                                    //             children: [
                                    //               buildLabelValueRow('Delivery Term', order.deliveryTerm ?? ''),
                                    //               buildLabelValueRow('Transaction Number', order.transactionNumber ?? ''),
                                    //               buildLabelValueRow('Micro Dealer Order', order.microDealerOrder ?? ''),
                                    //               buildLabelValueRow('Fulfillment Type', order.fulfillmentType ?? ''),
                                    //               // buildLabelValueRow(
                                    //               //     'No. of Boxes',
                                    //               //     order.numberOfBoxes
                                    //               //             .toString() ??
                                    //               //         ''),
                                    //               buildLabelValueRow('Total Quantity', order.totalQuantity.toString() ?? ''),
                                    //               // buildLabelValueRow(
                                    //               //     'SKU Qty',
                                    //               //     order.skuQty.toString() ??
                                    //               //         ''),
                                    //               buildLabelValueRow('Calculation Entry No.', order.calcEntryNumber ?? ''),
                                    //               buildLabelValueRow('Currency', order.currency ?? ''),
                                    //             ],
                                    //           ),
                                    //         ),
                                    //       ),
                                    //       // const SizedBox(width: 12.0),
                                    //       Expanded(
                                    //         child: Column(
                                    //           crossAxisAlignment: CrossAxisAlignment.start,
                                    //           children: [
                                    //             buildLabelValueRow(
                                    //               'Dimensions',
                                    //               '${order.length.toString() ?? ''} x ${order.breadth.toString() ?? ''} x ${order.height.toString() ?? ''}',
                                    //             ),
                                    //             buildLabelValueRow('Tracking Status', order.trackingStatus ?? ''),
                                    //             const SizedBox(
                                    //               height: 7,
                                    //             ),
                                    //             const Text(
                                    //               'Customer Details:',
                                    //               style:
                                    //                   TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.primaryBlue),
                                    //             ),
                                    //             buildLabelValueRow(
                                    //               'Customer ID',
                                    //               order.customer?.customerId ?? '',
                                    //             ),
                                    //             buildLabelValueRow(
                                    //                 'Full Name',
                                    //                 order.customer?.firstName != order.customer?.lastName
                                    //                     ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'.trim()
                                    //                     : order.customer?.firstName ?? ''),
                                    //             buildLabelValueRow(
                                    //               'Email',
                                    //               order.customer?.email ?? '',
                                    //             ),
                                    //             buildLabelValueRow(
                                    //               'Phone',
                                    //               maskPhoneNumber(order.customer?.phone?.toString()) ?? '',
                                    //             ),
                                    //             buildLabelValueRow(
                                    //               'GSTIN',
                                    //               order.customer?.customerGstin ?? '',
                                    //             ),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //       // const SizedBox(width: 12.0),
                                    //     ],
                                    //   ),
                                    // ),
                                    // const SizedBox(height: 6),
                                    // Row(
                                    //   mainAxisAlignment: MainAxisAlignment.center,
                                    //   children: [
                                    //     Expanded(
                                    //       child: FittedBox(
                                    //         fit: BoxFit.scaleDown,
                                    //         child: Column(
                                    //           crossAxisAlignment: CrossAxisAlignment.start,
                                    //           children: [
                                    //             const Text(
                                    //               'Shipping Address:',
                                    //               style:
                                    //                   TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.primaryBlue),
                                    //             ),
                                    //             Row(
                                    //               crossAxisAlignment: CrossAxisAlignment.start,
                                    //               children: [
                                    //                 const Text(
                                    //                   'Address: ',
                                    //                   style: TextStyle(
                                    //                     fontWeight: FontWeight.bold,
                                    //                     fontSize: 12.0,
                                    //                   ),
                                    //                 ),
                                    //                 Text(
                                    //                   [
                                    //                     order.shippingAddress?.address1,
                                    //                     order.shippingAddress?.address2,
                                    //                     order.shippingAddress?.city,
                                    //                     order.shippingAddress?.state,
                                    //                     order.shippingAddress?.country,
                                    //                     order.shippingAddress?.pincode?.toString(),
                                    //                   ]
                                    //                       .where((element) => element != null && element.isNotEmpty)
                                    //                       .join(', ')
                                    //                       .replaceAllMapped(RegExp('.{1,50}'), (match) => '${match.group(0)}\n'),
                                    //                   softWrap: true,
                                    //                   maxLines: null,
                                    //                   style: const TextStyle(
                                    //                     fontSize: 12.0,
                                    //                   ),
                                    //                 ),
                                    //               ],
                                    //             ),
                                    //             buildLabelValueRow(
                                    //               'Name',
                                    //               order.shippingAddress?.firstName != order.shippingAddress?.lastName
                                    //                   ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                    //                       .trim()
                                    //                   : order.shippingAddress?.firstName ?? '',
                                    //             ),
                                    //             buildLabelValueRow('Pincode', order.shippingAddress?.pincode?.toString() ?? ''),
                                    //             buildLabelValueRow('Country Code', order.shippingAddress?.countryCode ?? ''),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     Expanded(
                                    //       child: FittedBox(
                                    //         fit: BoxFit.scaleDown,
                                    //         child: Column(
                                    //           crossAxisAlignment: CrossAxisAlignment.start,
                                    //           children: [
                                    //             const Text(
                                    //               'Billing Address:',
                                    //               style:
                                    //                   TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.primaryBlue),
                                    //             ),
                                    //             Row(
                                    //               crossAxisAlignment: CrossAxisAlignment.start,
                                    //               children: [
                                    //                 const Text(
                                    //                   'Address: ',
                                    //                   style: TextStyle(
                                    //                     fontWeight: FontWeight.bold,
                                    //                     fontSize: 12.0,
                                    //                   ),
                                    //                 ),
                                    //                 Text(
                                    //                   [
                                    //                     order.billingAddress?.address1,
                                    //                     order.billingAddress?.address2,
                                    //                     order.billingAddress?.city,
                                    //                     order.billingAddress?.state,
                                    //                     order.billingAddress?.country,
                                    //                     order.billingAddress?.pincode?.toString(),
                                    //                   ]
                                    //                       .where((element) => element != null && element.isNotEmpty)
                                    //                       .join(', ')
                                    //                       .replaceAllMapped(RegExp('.{1,50}'), (match) => '${match.group(0)}\n'),
                                    //                   softWrap: true,
                                    //                   maxLines: null,
                                    //                   style: const TextStyle(
                                    //                     fontSize: 12.0,
                                    //                   ),
                                    //                 ),
                                    //               ],
                                    //             ),
                                    //             buildLabelValueRow(
                                    //               'Name',
                                    //               order.billingAddress?.firstName != order.billingAddress?.lastName
                                    //                   ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                    //                       .trim()
                                    //                   : order.billingAddress?.firstName ?? '',
                                    //             ),
                                    //             buildLabelValueRow('Pincode', order.billingAddress?.pincode?.toString() ?? ''),
                                    //             buildLabelValueRow('Country Code', order.billingAddress?.countryCode ?? ''),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text.rich(
                                                TextSpan(
                                                    text: "Merged: ",
                                                    children: [
                                                      TextSpan(
                                                          text: "${order.merged?['status'] ?? false}",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.normal,
                                                          )),
                                                    ],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                              ),
                                              Text.rich(
                                                TextSpan(
                                                    text: "Outbound: ",
                                                    children: [
                                                      TextSpan(
                                                          text: "${order.outBoundBy?['status'] ?? false}",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.normal,
                                                          )),
                                                      (order.outBoundBy?['outboundBy']?.toString().isNotEmpty ?? false)
                                                          ? TextSpan(
                                                              text: "(${order.outBoundBy?['outboundBy'].toString().split('@')[0] ?? ''})",
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.normal,
                                                              ),
                                                            )
                                                          : const TextSpan()
                                                    ],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                              ),
                                              Text.rich(
                                                TextSpan(
                                                    text: "Warehouse: ",
                                                    children: [
                                                      TextSpan(
                                                        text: "${order.warehouseName}",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              ),
                                              if (order.updatedAt != null)
                                                Text.rich(
                                                  TextSpan(
                                                      text: "Updated on: ",
                                                      children: [
                                                        TextSpan(
                                                          text: DateFormat('yyyy-MM-dd\',\' hh:mm a').format(
                                                            DateTime.parse("${order.updatedAt}"),
                                                          ),
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
                                          // from - 0/1, to-1
                                          if ((order.orderStatus == 0 || order.orderStatus == 1) && (order.merged!['status'] == false))
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) {
                                                    final orderIdController = TextEditingController();
                                                    return AlertDialog(
                                                      title: const Text('Merge to:'),
                                                      content: TextField(
                                                        controller: orderIdController,
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          hintText: 'Enter the Order ID',
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            final mergeTo = orderIdController.text.trim();
                                                            showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              // Prevent dismissing the dialog by tapping outside
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
                                                                      SizedBox(width: 20),
                                                                      // Adjust to create horizontal spacing
                                                                      Text(
                                                                        'Merging Orders',
                                                                        style: TextStyle(fontSize: 16),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                            final res = await pro.mergeOrders(context, order.orderId, mergeTo);

                                                            log('saved :)');

                                                            Navigator.pop(context);
                                                            Navigator.pop(context);

                                                            res ? await pro.fetchOrders() : null;
                                                          },
                                                          child: const Text('Merge'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: const Text('Merge Orders'),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    // Nested cards for each item in the order
                                    const SizedBox(height: 6),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: comboItemGroups.length,
                                      itemBuilder: (context, comboIndex) {
                                        final combo = comboItemGroups[comboIndex];
                                        return BigComboCard(
                                          items: combo,
                                          index: comboIndex,
                                        );
                                      },
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: remainingItems.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = remainingItems[itemIndex];
                                        print('Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                                        return ProductDetailsCard(
                                          item: item,
                                          index: itemIndex,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            CustomPaginationFooter(
              currentPage: pro.currentPageReady,
              totalPages: pro.totalReadyPages,
              buttonSize: 30,
              pageController: pageController,
              onFirstPage: () {
                pro.fetchOrders(page: 1);
              },
              onLastPage: () {
                pro.fetchOrders(page: pro.totalReadyPages);
              },
              onNextPage: () {
                if (pro.currentPageReady < pro.totalReadyPages) {
                  pro.fetchOrders(page: pro.currentPageReady + 1);
                }
              },
              onPreviousPage: () {
                if (pro.currentPageReady > 1) {
                  pro.fetchOrders(page: pro.currentPageReady - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= pro.totalReadyPages) {
                  pro.fetchOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(pageController.text);

                if (page == null || page < 1 || page > pro.totalReadyPages) {
                  _showSnackbar(context, 'Please enter a valid page number between 1 and ${pro.totalReadyPages}.');
                  return;
                }

                pro.fetchOrders(page: page);
                pageController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  String _selectedValue = "not answered"; // Default selected value

  void _showStatusDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String tempValue = _selectedValue; // Temporary value to update inside dialog

        // enum: ["not answered", "answered", "not reach","busy"],

        return AlertDialog(
          title: const Text("Select Status"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text("Not Answered"),
                    value: "not answered",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                  RadioListTile(
                    title: const Text("Answered"),
                    value: "answered",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                  RadioListTile(
                    title: const Text("Not Reached"),
                    value: "not reach",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                  RadioListTile(
                    title: const Text("Busy"),
                    value: "busy",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            // TextButton(
            //   child: const Text("Cancel"),
            //   onPressed: () => Navigator.pop(context),
            // ),
            TextButton(
              child: const Text("Ok"),
              onPressed: () async {
                setState(() {
                  _selectedValue = tempValue; // Save selected value
                });
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Updating Status'),
                        ],
                      ),
                    );
                  },
                );
                final res = await context.read<OutboundProvider>().updateCallStatus(context, orderId, tempValue);
                if (res) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  await context.read<OutboundProvider>().fetchOrders();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Widget buildLabelValueRow(String label, String? value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label: ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
      Flexible(
        child: Tooltip(
          message: value ?? '',
          child: Text(
            value ?? '',
            // softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12.0,
            ),
          ),
        ),
      ),
    ],
  );
}
