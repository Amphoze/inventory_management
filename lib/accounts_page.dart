import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/order_info.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDate = 'Select Date';
  final remarkController = TextEditingController();
  DateTime? picked;
  final accountsRemark = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountsProvider>(context, listen: false).fetchOrdersWithStatus2();
      context.read<MarketplaceProvider>().fetchMarketplaces();
    });
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<AccountsProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return " ($date, $time)";
  }

  static String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  String selectedSearchType = 'Order ID'; // Default selection
  String selectedCourier = 'All';
  String? selectedPaymentMode = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsProvider>(
      builder: (context, accountsProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 180,
                      height: 40,
                      margin: const EdgeInsets.only(right: 16),
                      child: DropdownButtonFormField<String>(
                        value: selectedSearchType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Order ID', child: Text('Order ID')),
                          DropdownMenuItem(value: 'Transaction No.', child: Text('Transaction No.')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedSearchType = value!;
                          });
                        },
                      ),
                    ),

                    Container(
                      height: 40,
                      width: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(183, 6, 90, 216),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: 'Search by Order ID',
                                hintStyle: TextStyle(color: Colors.black),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              ),
                              onChanged: (query) {
                                setState(() {});
                                if (query.isEmpty) {
                                  setState(() {
                                    selectedCourier = 'All';
                                    picked = null;
                                    selectedPaymentMode = '';
                                  });
                                  accountsProvider.fetchOrdersWithStatus2();
                                }
                              },
                              onTap: () {
                                setState(() {});
                              },
                              onSubmitted: (query) {
                                if (query.isNotEmpty) {
                                  accountsProvider.searchOrders(query, selectedSearchType);
                                } else {
                                  accountsProvider.fetchOrdersWithStatus2();
                                }
                              },
                              onEditingComplete: () {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                accountsProvider.fetchOrdersWithStatus2();
                                accountsProvider.clearAllSelections();
                              },
                            ),
                        ],
                      ),
                    ),
                    // const SizedBox(width: 8),
                    //
                    // ElevatedButton(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.primaryBlue,
                    //   ),
                    //   onPressed: _searchController.text.isNotEmpty ? _onSearchButtonPressed : null,
                    //   child: const Text(
                    //     'Search',
                    //     style: TextStyle(color: Colors.white),
                    //   ),
                    // ),
                    const Spacer(),
                    // const SizedBox(width: 8),
                    // Refresh Button
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(selectedPaymentMode ?? ''),
                            PopupMenuButton<String>(
                              tooltip: 'Filter by Payment Mode',
                              onSelected: (String? value) {
                                if (value != '' && value != null) {
                                  setState(() {
                                    selectedPaymentMode = value;
                                  });
                                  accountsProvider.fetchOrdersWithStatus2(
                                      mode: selectedPaymentMode ?? '', date: picked, market: selectedCourier);
                                }
                                // if (selectedCourier != 'All') {
                                //   accountsProvider.fetchOrdersByMarketplace(selectedCourier, 2, accountsProvider.currentPage,
                                //       date: picked, mode: selectedPaymentMode);
                                // }
                                log('Selected: $value');
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                ...[
                                  'COD',
                                  'Prepaid',
                                  'Partial Payment',
                                ].map(
                                  (paymentMode) => PopupMenuItem<String>(
                                    value: paymentMode,
                                    child: Text(paymentMode),
                                  ),
                                ),
                              ],
                              child: const IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.payment,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              _selectedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                              ),
                            ),
                            Tooltip(
                              message: 'Filter by Date',
                              child: IconButton(
                                onPressed: () async {
                                  picked = await showDatePicker(
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

                                  Logger().e('picked: $picked');

                                  if (picked != null) {
                                    String formattedDate = DateFormat('dd-MM-yyyy').format(picked!);
                                    setState(() {
                                      _selectedDate = formattedDate;
                                    });

                                    // if (selectedCourier != 'All') {
                                    //   accountsProvider.fetchOrdersByMarketplace(selectedCourier, 2, accountsProvider.currentPage,
                                    //       date: picked, mode: selectedPaymentMode);
                                    // } else {
                                    Logger().e('else me hai');
                                    accountsProvider.fetchOrdersWithStatus2(
                                        date: picked, mode: selectedPaymentMode, market: selectedCourier);
                                    // }
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
                              selectedCourier,
                            ),
                            Consumer<MarketplaceProvider>(
                              builder: (context, provider, child) {
                                return PopupMenuButton<String>(
                                  tooltip: 'Filter by Marketplace',
                                  onSelected: (String value) {
                                    Logger().e('ye hai value: $value');
                                    // if (value == 'All') {
                                    setState(() {
                                      selectedCourier = value;
                                    });
                                    accountsProvider.fetchOrdersWithStatus2(
                                        date: picked, mode: selectedPaymentMode, market: selectedCourier);
                                    // } else {
                                    //   Logger().e('ye hai else value: $value');
                                    //   setState(() {
                                    //     selectedCourier = value;
                                    //   });
                                    //   accountsProvider.fetchOrdersByMarketplace(value, 2, accountsProvider.currentPage,
                                    //       date: picked, mode: selectedPaymentMode);
                                    // }
                                    // log('Selected: $value');
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    ...provider.marketplaces.map((marketplace) => PopupMenuItem<String>(
                                          value: marketplace.name,
                                          child: Text(marketplace.name),
                                        )), // Fetched marketplaces
                                    const PopupMenuItem<String>(
                                      value: 'All', // Hardcoded marketplace
                                      child: Text('All'),
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
                          onPressed: () async {
                            final res = await accountsProvider.statusUpdate(context);
                            if (res == true) {
                              // if (selectedCourier != 'All') {
                              //   await accountsProvider.fetchOrdersByMarketplace(selectedCourier, 2, accountsProvider.currentPage,
                              //       date: picked, mode: selectedPaymentMode);
                              // } else {
                              await accountsProvider.fetchOrdersWithStatus2(
                                  date: picked, mode: selectedPaymentMode, market: selectedCourier);
                              // }
                            }
                          },
                          child: accountsProvider.isUpdatingOrder
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Confirm',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardsred,
                          ),
                          // onPressed: () async {
                          //   await accountsProvider.statusUpdate(context);
                          // },
                          onPressed: accountsProvider.isCancel
                              ? null // Disable button while loading
                              : () async {
                                  final provider = Provider.of<AccountsProvider>(context, listen: false);

                                  // Collect selected order IDs
                                  List<String> selectedOrderIds = provider.orders
                                      .asMap()
                                      .entries
                                      .where((entry) => provider.selectedProducts[entry.key])
                                      .map((entry) => entry.value.orderId)
                                      .toList();

                                  if (selectedOrderIds.isEmpty) {
                                    // Show an error message if no orders are selected
                                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
                                      // if (selectedCourier != 'All') {
                                      //   await accountsProvider.fetchOrdersByMarketplace(selectedCourier, 2, accountsProvider.currentPage,
                                      //       date: picked, mode: selectedPaymentMode);
                                      // } else {
                                      await accountsProvider.fetchOrdersWithStatus2(
                                          date: picked, mode: selectedPaymentMode, market: selectedCourier);
                                      // }

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
                          child: accountsProvider.isCancel
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cancel Orders',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: accountsProvider.isRefreshingOrders
                              ? null
                              : () async {
                                  setState(() {
                                    selectedCourier = 'All';
                                    _selectedDate = 'Select Date';
                                    picked = null;
                                    selectedPaymentMode = '';
                                  });
                                  await accountsProvider.fetchOrdersWithStatus2();
                                },
                          child: accountsProvider.isRefreshingOrders
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Refresh',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildTableHeader(accountsProvider.orders.length, accountsProvider),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (accountsProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.account_box_rounded,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (accountsProvider.orders.isEmpty)
                      const Center(
                        child: Text(
                          'No Orders Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: accountsProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = accountsProvider.orders[index];

                          ///////////////////////////////////////////////////////////////////
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

                          return Card(
                            surfaceTintColor: Colors.white,
                            color: accountsProvider.selectedProducts[index] ? Colors.grey[300] : Colors.grey[100],
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
                                        value: accountsProvider.selectedProducts[index],
                                        onChanged: (isSelected) {
                                          accountsProvider.handleRowCheckboxChange(index, isSelected!);
                                        },
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Date: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          if (order.date != null)
                                            Text(
                                              accountsProvider.formatDate(order.date!),
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                            )
                                          else
                                            const SizedBox()
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
                                            '${order.totalWeight ?? ''}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Row(
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
                                                final searched = _searchController.text;

                                                // Ready
                                                if (searched.isNotEmpty) {
                                                  accountsProvider.searchOrders(searched, selectedSearchType);
                                                } else {
                                                  accountsProvider.fetchOrdersWithStatus2(date: picked, mode: selectedPaymentMode, market: selectedCourier);
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: AppColors.white,
                                              backgroundColor: AppColors.orange,
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
                                            tooltip: 'Revert to Status 1',
                                            icon: const Icon(Icons.undo),
                                            onPressed: () async {
                                              showDialog(
                                                  context: context,
                                                  barrierDismissible: true,
                                                  builder: (context) {
                                                    return const AlertDialog(
                                                      content: Row(
                                                        children: [CircularProgressIndicator(), SizedBox(width: 8), Text('Reversing')],
                                                      ),
                                                    );
                                                  });

                                              final res = await context.read<AuthProvider>().reverseOrder(order.orderId, '1');
                                              Navigator.pop(context);

                                              if (res['success'] == true) {
                                                Utils.showInfoDialog(
                                                    context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                                              } else {
                                                Utils.showInfoDialog(context, res['message'], false);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
                                  OrderInfo(order: order, pro: accountsProvider),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text.rich(
                                      TextSpan(
                                          text: "Outbound: ",
                                          children: [
                                            TextSpan(
                                                text: "${order.outBoundBy?['status'] ?? false}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                )),
                                            (order.outBoundBy?['outboundBy']?.toString().isNotEmpty ?? false) ?
                                            TextSpan(
                                              text: "(${order.outBoundBy?['outboundBy'].toString().split('@')[0] ?? ''})",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ) : const TextSpan()
                                          ],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                    ),
                                  ),
                                  // const SizedBox(height: 6),
                                  if (order.confirmedBy!['status'] == true)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text.rich(
                                        TextSpan(
                                            text: "Confirmed By: ",
                                            children: [
                                              TextSpan(
                                                  text: order.confirmedBy!['confirmedBy'].toString().split('@')[0],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                  )),
                                              TextSpan(
                                                  text: formatIsoDate(order.confirmedBy!['timestamp']),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                  )),
                                            ],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            )),
                                      ),
                                    ),
                                  if (order.baApprovedBy?['status'] ?? false)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text.rich(
                                        TextSpan(
                                            text: "BA Approved By: ",
                                            children: [
                                              TextSpan(
                                                  text: order.baApprovedBy!['baApprovedBy'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                  )),
                                              TextSpan(
                                                  text: formatIsoDate(order.baApprovedBy!['timestamp']),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                  )),
                                            ],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            )),
                                      ),
                                    ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
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
                                                    )),
                                              ],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              )),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                final pro = context.read<AccountsProvider>();
                                                setState(() {
                                                  accountsRemark.text = order.messages?['accountMessage']?.toString() ?? '';
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder: (_) {
                                                    return Dialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                                      child: Container(
                                                        width: MediaQuery.of(context).size.width * 0.9,
                                                        constraints: const BoxConstraints(maxWidth: 600),
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
                                                                      barrierDismissible: false,
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
                                                                              Text(
                                                                                'Submitting Remark',
                                                                                style: TextStyle(fontSize: 16),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    );

                                                                    final res = await pro.writeRemark(context, order.id, accountsRemark.text);

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
                                              child: (order.messages?['accountMessage']?.toString().isNotEmpty ?? false)
                                                  ? const Text('Edit Remark')
                                                  : const Text('Write Remark'),
                                            ),
                                            if (order.messages?['confirmerMessage']?.toString().isNotEmpty ?? false) ...[
                                              Utils()
                                                  .showMessage(context, 'Confirmer Remark', order.messages!['confirmerMessage'].toString())
                                            ],
                                            if (order.messages?['accountMessage']?.toString().isNotEmpty ?? false) ...[
                                              Utils().showMessage(context, 'Account Remark', order.messages!['accountMessage'].toString()),
                                            ],
                                          ],
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
                                      // print(
                                      //     'Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                                      return BigComboCard(
                                        items: combo,
                                        index: comboIndex,
                                        // courierName: order.courierName,
                                        // orderStatus:
                                        //     order.orderStatus.toString(),
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
                                        // courierName: order.courierName,
                                        // orderStatus:
                                        //     order.orderStatus.toString(),
                                      );
                                    },
                                  ),
                                  // ListView.builder(
                                  //   shrinkWrap: true,
                                  //   physics:
                                  //       const NeverScrollableScrollPhysics(),
                                  //   itemCount: order.items.length,
                                  //   itemBuilder: (context, itemIndex) {
                                  //     final item = order.items[itemIndex];

                                  //     return ProductDetailsCard(
                                  //       item: item,
                                  //       index: itemIndex,
                                  //       courierName: order.courierName,
                                  //       // orderStatus:
                                  //       //     order.orderStatus.toString(),
                                  //     );
                                  //   },
                                  // ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              CustomPaginationFooter(
                currentPage: accountsProvider.currentPage,
                totalPages: accountsProvider.totalPages,
                buttonSize: 30,
                pageController: accountsProvider.textEditingController,
                onFirstPage: () {
                  accountsProvider.goToPage(1);
                },
                onLastPage: () {
                  accountsProvider.goToPage(accountsProvider.totalPages);
                },
                onNextPage: () {
                  if (accountsProvider.currentPage < accountsProvider.totalPages) {
                    accountsProvider.goToPage(accountsProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (accountsProvider.currentPage > 1) {
                    accountsProvider.goToPage(accountsProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  accountsProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(accountsProvider.textEditingController.text);
                  if (page != null && page > 0 && page <= accountsProvider.totalPages) {
                    accountsProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildOrderCard(
  //     Order order, int index, AccountsProvider accountsProvider) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Checkbox(
  //           value: accountsProvider
  //               .selectedProducts[index], // Accessing selected products
  //           onChanged: (isSelected) {
  //             accountsProvider.handleRowCheckboxChange(index, isSelected!);
  //           },
  //         ),
  //         Expanded(
  //           flex: 5,
  //           child: Row(
  //             mainAxisAlignment:
  //                 MainAxisAlignment.spaceBetween, // Space between elements
  //             children: [
  //               Expanded(
  //                 child:
  //                     OrderCard(order: order), // Your existing OrderCard widget
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 20),
  //         // if (dispatchProvider.isReturning)
  //         //   Center(
  //         //     child: CircularProgressIndicator(), // Loading indicator
  //         //   ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTableHeader(int totalCount, AccountsProvider accountsProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: accountsProvider.selectAll,
              onChanged: (value) {
                accountsProvider.toggleSelectAll(value!);
              },
            ),
          ),
          Text(
            'Select All(${accountsProvider.selectedCount})',
          ),
          buildHeader('ORDERS')
        ],
      ),
    );
  }

  Widget buildHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget buildCell(Widget content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Center(child: content),
      ),
    );
  }
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
