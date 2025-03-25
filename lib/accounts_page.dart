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
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final remarkController = TextEditingController();
  final accountsRemark = TextEditingController();
  bool? isSuperAdmin = false;
  bool? isAdmin = false;
  late AccountsProvider accountsProvider;

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
      isAdmin = prefs.getBool('_isAdminAssigned');
    });
  }

  @override
  void initState() {
    super.initState();
    accountsProvider = context.read<AccountsProvider>();
    accountsProvider.accountsSearch.clear();
    _fetchUserRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      accountsProvider.resetFilterData();
      Provider.of<AccountsProvider>(context, listen: false).fetchOrdersWithStatus2();
      context.read<MarketplaceProvider>().fetchMarketplaces();
    });
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return " ($date, $time)";
  }

  @override
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }

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
                        value: accountsProvider.selectedSearchType,
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
                            accountsProvider.selectedSearchType = value!;
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
                              controller: accountsProvider.accountsSearch,
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
                                  accountsProvider.resetFilterData();
                                  accountsProvider.fetchOrdersWithStatus2();
                                }
                              },
                              onTap: () {
                                setState(() {});
                              },
                              onSubmitted: (query) {
                                accountsProvider.resetFilterData();
                                if (query.trim().isNotEmpty) {
                                  accountsProvider.searchOrders(query, accountsProvider.selectedSearchType);
                                } else {
                                  accountsProvider.fetchOrdersWithStatus2();
                                }
                              },
                              onEditingComplete: () {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          if (accountsProvider.accountsSearch.text.isNotEmpty)
                            InkWell(
                              child: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onTap: () {
                                setState(() {
                                  accountsProvider.accountsSearch.clear();
                                });
                                accountsProvider.fetchOrdersWithStatus2();
                                accountsProvider.clearAllSelections();
                              },
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(accountsProvider.selectedPaymentMode!),
                            PopupMenuButton<String>(
                              tooltip: 'Filter by Payment Mode',
                              onSelected: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    accountsProvider.selectedPaymentMode = value;
                                  });
                                  accountsProvider.fetchOrdersWithStatus2();
                                }

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
                              accountsProvider.selectedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: accountsProvider.selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                              ),
                            ),
                            Tooltip(
                              message: 'Filter by Date',
                              child: IconButton(
                                onPressed: () async {
                                  accountsProvider.picked = await showDatePicker(
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

                                  if (accountsProvider.picked != null) {
                                    String formattedDate = DateFormat('dd-MM-yyyy').format(accountsProvider.picked!);
                                    setState(() {
                                      accountsProvider.selectedDate = formattedDate;
                                    });

                                    Logger().e('else me hai');
                                    accountsProvider.fetchOrdersWithStatus2();
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 30,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            if (accountsProvider.selectedDate != 'Select Date')
                              Tooltip(
                                message: 'Clear selected Date',
                                child: InkWell(
                                  onTap: () async {
                                    setState(() {
                                      accountsProvider.selectedDate = 'Select Date';
                                      accountsProvider.picked = null;
                                    });
                                    accountsProvider.fetchOrdersWithStatus2();
                                  },
                                  child: const Icon(
                                    Icons.clear,
                                    size: 12,
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
                              accountsProvider.selectedCourier,
                            ),
                            Consumer<MarketplaceProvider>(
                              builder: (context, provider, child) {
                                return PopupMenuButton<String>(
                                  tooltip: 'Filter by Marketplace',
                                  onSelected: (String value) {
                                    Logger().e('ye hai value: $value');
                                    setState(() {
                                      accountsProvider.selectedCourier = value;
                                    });
                                    accountsProvider.fetchOrdersWithStatus2();
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    ...provider.marketplaces.map((marketplace) => PopupMenuItem<String>(
                                          value: marketplace.name,
                                          child: Text(marketplace.name),
                                        )),
                                    const PopupMenuItem<String>(
                                      value: 'All',
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
                              await accountsProvider.fetchOrdersWithStatus2();
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
                          onPressed: accountsProvider.isCancel
                              ? null
                              : () async {
                                  final provider = Provider.of<AccountsProvider>(context, listen: false);

                                  List<String> selectedOrderIds = provider.orders
                                      .asMap()
                                      .entries
                                      .where((entry) => provider.selectedProducts[entry.key])
                                      .map((entry) => entry.value.orderId)
                                      .toList();

                                  if (selectedOrderIds.isEmpty) {
                                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No orders selected'),
                                        backgroundColor: AppColors.cardsred,
                                      ),
                                    );
                                  } else {
                                    String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

                                    Color snackBarColor;
                                    if (resultMessage.contains('success')) {
                                      await accountsProvider.fetchOrdersWithStatus2();

                                      snackBarColor = AppColors.green;
                                    } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                      snackBarColor = AppColors.cardsred;
                                    } else {
                                      snackBarColor = AppColors.orange;
                                    }

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
                            backgroundColor: Colors.orange.shade300,
                          ),
                          onPressed: () async {
                            accountsProvider.accountsSearch.clear();
                            accountsProvider.resetFilterData();
                            await accountsProvider.fetchOrdersWithStatus2();
                          },
                          child: const Text('Reset Filters'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await accountsProvider.fetchOrdersWithStatus2();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.primaryBlue,
                            )
                        ),

                        // ElevatedButton(
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: AppColors.primaryBlue,
                        //   ),
                        //   onPressed: accountsProvider.isLoading
                        //       ? null
                        //       : () async {
                        //           accountsProvider.accountsSearch.clear();
                        //           accountsProvider.resetFilterData();
                        //           await accountsProvider.fetchOrdersWithStatus2();
                        //         },
                        //   child: accountsProvider.isLoading
                        //       ? const SizedBox(
                        //           width: 16,
                        //           height: 16,
                        //           child: CircularProgressIndicator(
                        //             color: Colors.white,
                        //             strokeWidth: 2,
                        //           ),
                        //         )
                        //       : const Text(
                        //           'Refresh',
                        //           style: TextStyle(color: Colors.white),
                        //         ),
                        // ),
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
                                            order.totalWeight.toStringAsFixed(2),
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
                                                final searched = accountsProvider.accountsSearch.text.trim();

                                                if (searched.isNotEmpty) {
                                                  accountsProvider.searchOrders(searched, accountsProvider.selectedSearchType);
                                                } else {
                                                  accountsProvider.fetchOrdersWithStatus2();
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
                                          if ((isSuperAdmin ?? false) || (isAdmin ?? false)) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: 'Revert Order',
                                              icon: const Icon(Icons.undo),
                                              onPressed: () async {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: const Text('Revert Order'),
                                                      content: Text('Are you sure you want to revert ${order.orderId} to READY TO CONFIRM'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Text('Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            Navigator.pop(context);

                                                            showDialog(
                                                              barrierDismissible: false,
                                                              context: context,
                                                              builder: (context) {
                                                                return const AlertDialog(
                                                                  content: Row(
                                                                    children: [
                                                                      CircularProgressIndicator(),
                                                                      SizedBox(width: 8),
                                                                      Text('Reversing'),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );

                                                            try {
                                                              final authPro = context.read<AuthProvider>();
                                                              final res = await authPro.reverseOrder(order.orderId);

                                                              Navigator.pop(context);

                                                              if (res['success'] == true) {
                                                                Utils.showInfoDialog(
                                                                    context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                                                              } else {
                                                                Utils.showInfoDialog(context, res['message'], false);
                                                              }
                                                            } catch (e) {
                                                              Navigator.pop(context);
                                                              Utils.showInfoDialog(context, 'An error occurred: $e', false);
                                                            }
                                                          },
                                                          child: const Text('Submit'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ]
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Row(
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
                                              if (order.confirmedBy!['status'] == true)
                                                Text.rich(
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
                                              if (order.baApprovedBy?['status'] ?? false)
                                                Text.rich(
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
                                                            )),
                                                      ],
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      )),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.end,
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

                                                                      final res =
                                                                          await pro.writeRemark(context, order.id, accountsRemark.text);

                                                                      log('saved :)');

                                                                      Navigator.pop(context);
                                                                      Navigator.pop(context);

                                                                      final searched = pro.accountsSearch.text.trim();
                                                                      final type = pro.selectedSearchType;

                                                                      if (res) {
                                                                        if (searched.isEmpty)
                                                                          await pro.fetchOrdersWithStatus2();
                                                                        else
                                                                          await pro.searchOrders(searched, type);
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
                                                Utils().showMessage(
                                                    context, 'Confirmer Remark', order.messages!['confirmerMessage'].toString())
                                              ],
                                              if (order.messages?['accountMessage']?.toString().isNotEmpty ?? false) ...[
                                                Utils()
                                                    .showMessage(context, 'Account Remark', order.messages!['accountMessage'].toString()),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
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
                  ],
                ),
              ),
              CustomPaginationFooter(
                currentPage: accountsProvider.currentPage,
                totalPages: accountsProvider.totalPages,
                buttonSize: 30,
                pageController: accountsProvider.textEditingController,
                onFirstPage: () {
                  goToPage(1);
                },
                onLastPage: () {
                  goToPage(accountsProvider.totalPages);
                },
                onNextPage: () {
                  if (accountsProvider.currentPage < accountsProvider.totalPages) {
                    goToPage(accountsProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (accountsProvider.currentPage > 1) {
                    goToPage(accountsProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(accountsProvider.textEditingController.text);
                  if (page != null && page > 0 && page <= accountsProvider.totalPages) {
                    goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

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

  void goToPage(int page) {
    if (page < 1 || page > accountsProvider.totalPages) return;
    accountsProvider.setCurrentPage(page);
    accountsProvider.fetchOrdersWithStatus2();
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
