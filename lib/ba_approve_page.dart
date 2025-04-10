import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/order_info.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/provider/ba_approve_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'model/orders_model.dart';

class BaApprovePage extends StatefulWidget {
  const BaApprovePage({super.key});

  @override
  State<BaApprovePage> createState() => _BaApprovePageState();
}

class _BaApprovePageState extends State<BaApprovePage> {
  String _selectedDate = 'Select Date';
  final remarkController = TextEditingController();
  DateTime? picked;
  String selectedCourier = 'All';
  late BaApproveProvider baApproveProvider;
  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        selectedCourier = 'All';
        _selectedDate = 'Select Date';
        picked = null;
      });
      baApproveProvider.fetchOrdersWithStatus2();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      baApproveProvider.searchOrders(value);
    });
  }

  @override
  void initState() {
    baApproveProvider = Provider.of<BaApproveProvider>(context, listen: false);
    baApproveProvider.searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      baApproveProvider.fetchOrdersWithStatus2(date: picked, market: selectedCourier);
      // context.read<MarketplaceProvider>().fetchMarketplaces();
    });
    super.initState();
  }

  void _onSearchButtonPressed() {
    final query = baApproveProvider.searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<BaApproveProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return " ($date, $time)";
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // baApproveProvider.searchController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BaApproveProvider>(
      builder: (context, baApproveProvider, child) {
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
                      height: 35,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(183, 6, 90, 216),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: baApproveProvider.searchController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Search by Order ID',
                          hintStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: (query) {
                          setState(() {
                            selectedCourier = 'All';
                            _selectedDate = 'Select Date';
                            picked = null;
                          });
                          if (query.trim().isNotEmpty) {
                            baApproveProvider.searchOrders(query);
                          } else {
                            baApproveProvider.fetchOrdersWithStatus2();
                          }
                        },
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        // Date Filter
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

                                  if (picked != null) {
                                    String formattedDate = DateFormat('dd-MM-yyyy').format(picked!);
                                    setState(() {
                                      _selectedDate = formattedDate;
                                    });

                                    baApproveProvider.fetchOrdersWithStatus2(date: picked, market: selectedCourier);
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 30,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            if (_selectedDate != 'Select Date')
                              Tooltip(
                                message: 'Clear selected Date',
                                child: InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _selectedDate = 'Select Date';
                                      picked = null;
                                    });
                                    baApproveProvider.fetchOrdersWithStatus2();
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

                        // Marketplace Filter
                        StatefulBuilder(builder: (context, setState) {
                          return Column(
                            children: [
                              Text(
                                selectedCourier,
                              ),
                              Consumer<MarketplaceProvider>(
                                builder: (context, provider, child) {
                                  return PopupMenuButton<String>(
                                    tooltip: 'Filter by Marketplace',
                                    onSelected: (String value) {
                                      log('Value: $value');
                                      setState(() {
                                        selectedCourier = value;
                                      });
                                      baApproveProvider.fetchOrdersWithStatus2(date: picked, market: selectedCourier);
                                      log('Selected: $value');
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
                          );
                        }),

                        const SizedBox(width: 8),

                        // Approve
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: () async {
                            await baApproveProvider.statusUpdate(context);
                          },
                          child: baApproveProvider.isUpdatingOrder
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),

                        const SizedBox(width: 8),

                        // Cancel
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardsred,
                          ),
                          // onPressed: () async {
                          //   await baApproveProvider.statusUpdate(context);
                          // },
                          onPressed: baApproveProvider.isCancel
                              ? null // Disable button while loading
                              : () async {
                                  final provider = Provider.of<BaApproveProvider>(context, listen: false);

                                  // Collect selected order IDs
                                  List<String> selectedOrderIds = provider.orders
                                      .asMap()
                                      .entries
                                      .where((entry) => provider.selectedOrders[entry.key])
                                      .map((entry) => entry.value.orderId)
                                      .toList();

                                  if (selectedOrderIds.isEmpty) {
                                    Utils.showSnackBar(context, 'No orders selected',
                                        isError: true, toRemoveCurr: true);
                                  } else {
                                    String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

                                    Color snackBarColor;
                                    if (resultMessage.contains('success')) {
                                      snackBarColor = AppColors.green; // Success: Green
                                    } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                      snackBarColor = AppColors.cardsred; // Error: Red
                                    } else {
                                      snackBarColor = AppColors.orange; // Other: Orange
                                    }

                                    Utils.showSnackBar(context, resultMessage,
                                        color: snackBarColor, toRemoveCurr: true);
                                  }
                                },
                          child: baApproveProvider.isCancel
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

                        // Reset
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade300,
                          ),
                          onPressed: () async {
                            setState(() {
                              selectedCourier = 'All';
                              _selectedDate = 'Select Date';
                            });
                            await baApproveProvider.fetchOrdersWithStatus2();
                          },
                          child: const Text('Reset Filters'),
                        ),

                        const SizedBox(width: 8),

                        // Refresh
                        IconButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              baApproveProvider.fetchOrdersWithStatus2(date: picked, market: selectedCourier);
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.primaryBlue,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildTableHeader(baApproveProvider.orders.length, baApproveProvider),
              const SizedBox(height: 4),
              Expanded(
                child: (baApproveProvider.isLoading)
                    ? const Center(
                        child: LoadingAnimation(
                          icon: Icons.approval,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    : (baApproveProvider.orders.isEmpty)
                        ? const Center(
                            child: Text(
                              'No Orders Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: baApproveProvider.orders.length,
                            itemBuilder: (context, index) {
                              final order = baApproveProvider.orders[index];
                              final percentDelhivery = double.parse(
                                  (((order.freightCharge?.delhivery ?? 0) / (order.totalAmount ?? 1)) * 100)
                                      .toStringAsFixed(2));
                              final percentShiprocket = double.parse(
                                  (((order.freightCharge?.shiprocket ?? 0) / (order.totalAmount ?? 1)) * 100)
                                      .toStringAsFixed(2));
                              ////////////////////////////////////////////////////////////////////////////

                              final Map<String, List<Item>> groupedComboItems = {};
                              for (var item in order.items) {
                                if (item.isCombo == true && item.comboSku != null) {
                                  if (!groupedComboItems.containsKey(item.comboSku)) {
                                    groupedComboItems[item.comboSku!] = [];
                                  }
                                  groupedComboItems[item.comboSku]!.add(item);
                                }
                              }
                              final List<List<Item>> comboItemGroups =
                                  groupedComboItems.values.where((items) => items.length > 1).toList();

                              Logger().e('comboItemGroups: $comboItemGroups');

                              final List<Item> remainingItems = order.items
                                  .where((item) => !(item.isCombo == true &&
                                      item.comboSku != null &&
                                      groupedComboItems[item.comboSku]!.length > 1))
                                  .toList();

                              return Card(
                                surfaceTintColor: Colors.white,
                                color: baApproveProvider.selectedOrders[index] ? Colors.grey[300] : Colors.grey[100],
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
                                            value: baApproveProvider.selectedOrders[index],
                                            onChanged: (isSelected) {
                                              baApproveProvider.handleRowCheckboxChange(index, isSelected!);
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
                                              Text(
                                                baApproveProvider.formatDate(order.date!),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
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
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
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
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
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
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                              ),
                                            ],
                                          ),
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
                                                final searched = baApproveProvider.searchController.text.trim();

                                                // Ready
                                                if (searched.isNotEmpty) {
                                                  baApproveProvider.searchOrders(searched);
                                                } else {
                                                  baApproveProvider.fetchOrdersWithStatus2(
                                                      date: picked, market: selectedCourier);
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
                                        ],
                                      ),
                                      const Divider(
                                        thickness: 1,
                                        color: AppColors.grey,
                                      ),
                                      OrderInfo(order: order, pro: baApproveProvider),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text.rich(
                                              TextSpan(
                                                text: "Delhivery: ",
                                                children: [
                                                  TextSpan(
                                                      text: "Rs. ${order.freightCharge?.delhivery ?? 0} ",
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.normal,
                                                      )),
                                                  TextSpan(
                                                    text: "($percentDelhivery %)",
                                                    style: TextStyle(
                                                      color:
                                                          percentDelhivery > 20 ? AppColors.cardsred : AppColors.green,
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                text: "Shiprocket: ",
                                                children: [
                                                  TextSpan(
                                                    text: "Rs. ${order.freightCharge?.shiprocket ?? 0} ",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: "($percentShiprocket %)",
                                                    style: TextStyle(
                                                      color:
                                                          percentShiprocket > 20 ? AppColors.cardsred : AppColors.green,
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
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
                                                            text:
                                                                "(${order.outBoundBy?['outboundBy'].toString().split('@')[0] ?? ''})",
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.normal,
                                                            ),
                                                          )
                                                        : const TextSpan()
                                                  ],
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                            )
                                          ],
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
                                            if (order.messages?.confirmerMessages.isNotEmpty ?? false)
                                              Tooltip(
                                                message: order.messages!.confirmerMessages.last.message,
                                                child: SizedBox(
                                                  width: MediaQuery.of(context).size.width * 0.3,
                                                  child: Text(
                                                    order.messages!.confirmerMessages.last.message,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.green,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
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
                                          print(
                                              'Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
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
              ),
              CustomPaginationFooter(
                currentPage: baApproveProvider.currentPage,
                totalPages: baApproveProvider.totalPages,
                totalCount: baApproveProvider.totalOrders,
                buttonSize: 30,
                pageController: baApproveProvider.textEditingController,
                onFirstPage: () {
                  baApproveProvider.goToPage(1);
                },
                onLastPage: () {
                  baApproveProvider.goToPage(baApproveProvider.totalPages);
                },
                onNextPage: () {
                  if (baApproveProvider.currentPage < baApproveProvider.totalPages) {
                    baApproveProvider.goToPage(baApproveProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (baApproveProvider.currentPage > 1) {
                    baApproveProvider.goToPage(baApproveProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  baApproveProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(baApproveProvider.textEditingController.text);
                  if (page != null && page > 0 && page <= baApproveProvider.totalPages) {
                    baApproveProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(int totalCount, BaApproveProvider baApproveProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: baApproveProvider.selectAll,
              onChanged: (value) {
                baApproveProvider.toggleSelectAll(value!);
              },
            ),
          ),
          Text(
            'Select All(${baApproveProvider.selectedCount})',
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
