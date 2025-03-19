import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/highlighted_banner_card.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/order_info.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/chat_screen.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:inventory_management/provider/support_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersNewPage extends StatefulWidget {
  const OrdersNewPage({super.key});

  @override
  _OrdersNewPageState createState() => _OrdersNewPageState();
}

class _OrdersNewPageState extends State<OrdersNewPage> with TickerProviderStateMixin {
  late TabController _tabController;
  // late TextEditingController _searchController;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();
  final remarkController = TextEditingController();
  late OrdersProvider provider;
  String? email;
  String? role;

  void getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    role = prefs.getString('userPrimaryRole');
  }

  @override
  void initState() {
    provider = Provider.of(context, listen: false);
    _tabController = TabController(length: 2, vsync: this);
    // _searchController = TextEditingController();
    provider.searchControllerReady = TextEditingController();
    provider.searchControllerFailed = TextEditingController();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // setState(() {
        //   _selectedReadyDate = 'Select Date';
        //   _selectedFailedDate = 'Select Date';
        // });
        // _searchController.clear();
        provider.searchControllerReady.clear();
        provider.searchControllerFailed.clear();
        _reloadOrders();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.resetReadyFilterData();
      provider.resetFailedFilterData();
      getUserData();
      provider.initializeSocket(context);
      _reloadOrders();
      context.read<MarketplaceProvider>().fetchMarketplaces();
      context.read<LocationProvider>().fetchWarehouses();
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    // _searchController.dispose();
    provider.searchControllerReady.dispose();
    provider.searchControllerFailed.dispose();
    _pageController.dispose();
    pageController.dispose();
    remarkController.dispose();
  }

  void _reloadOrders() async {
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    await Future.wait([ordersProvider.fetchReadyOrders(), ordersProvider.fetchFailedOrders()]);
  }

  static String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  void showCustomSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const ChatScreen(),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 0, // Removes space above the tabs
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Ready to Confirm'),
        Tab(text: 'Failed Orders'),
      ],
      indicatorColor: Colors.blue,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildReadyToConfirmTab(),
        _buildFailedOrdersTab(),
      ],
    );
  }

  Widget _buildReadyToConfirmTab() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, child) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: ordersProvider.allSelectedReady,
                      onChanged: (bool? value) {
                        ordersProvider.toggleSelectAllReady(value ?? false);
                      },
                    ),
                    Text('Select All (${ordersProvider.selectedReadyItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          ordersProvider.selectedReadyDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: ordersProvider.selectedReadyDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Filter by Date',
                          onPressed: () async {
                            ordersProvider.readyPicked = await showDatePicker(
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

                            String formattedDate = DateFormat('dd-MM-yyyy').format(ordersProvider.readyPicked!);
                            setState(() {
                              ordersProvider.selectedReadyDate = formattedDate;
                            });

                            ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageReady);

                            Logger().e('picked: ${ordersProvider.readyPicked}');
                          },
                          icon: const Icon(
                            Icons.calendar_today,
                            size: 30,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        if (ordersProvider.selectedReadyDate != 'Select Date')
                          Tooltip(
                            message: 'Clear selected Date',
                            child: InkWell(
                              onTap: () async {
                                setState(() {
                                  ordersProvider.selectedReadyDate = 'Select Date';
                                  ordersProvider.readyPicked = null;
                                });
                                ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageReady);
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
                          ordersProvider.selectedReadyCourier,
                        ),
                        Consumer<MarketplaceProvider>(
                          builder: (context, provider, child) {
                            return PopupMenuButton<String>(
                              tooltip: 'Filter by Marketplace',
                              onSelected: (String value) {
                                setState(() {
                                  ordersProvider.selectedReadyCourier = value;
                                });
                                ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageReady);
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
                      onPressed: ordersProvider.isCloning
                          ? null // Disable button while loading
                          : () async {
                              List<String> selectedOrderIds = ordersProvider.readyOrders
                                  .asMap()
                                  .entries
                                  .where((entry) => ordersProvider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                String resultMessage = await ordersProvider.cloneOrders(context, selectedOrderIds);
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
                      child: ordersProvider.isCloning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Clone',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: ordersProvider.isConfirm
                          ? null
                          : () async {
                              List<String> selectedOrderIds = provider.readyOrders
                                  .asMap()
                                  .entries
                                  .where((entry) => provider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No orders selected'),
                                    backgroundColor: AppColors.cardsred,
                                  ),
                                );
                              } else {
                                Utils.showSnackBar(context, 'Confirmation Started!!');

                                // String resultMessage =
                                await provider.confirmOrders(context, selectedOrderIds);
                                // Color snackBarColor;
                                // if (resultMessage.contains('success')) {
                                //   snackBarColor = AppColors.green; // Success: Green
                                // } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                //   snackBarColor = AppColors.cardsred; // Error: Red
                                // } else {
                                //   snackBarColor = AppColors.orange; // Other: Orange
                                // }
                                //
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   SnackBar(
                                //     content: Text(resultMessage),
                                //     backgroundColor: snackBarColor,
                                //   ),
                                // );
                              }
                            },
                      child: ordersProvider.isConfirm
                          ?
                          // const SizedBox(
                          //   width: 20,
                          //   height: 20,
                          //   child: CircularProgressIndicator(color: Colors.white),
                          // )
                          ValueListenableBuilder<double>(
                              valueListenable: ordersProvider.progressNotifier,
                              builder: (context, value, child) {
                                return Text.rich(
                                  TextSpan(
                                    text: 'Progress: ',
                                    children: [
                                      TextSpan(
                                        text: '${value.toStringAsFixed(2)}%',
                                        style: const TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            )
                          : const Text(
                              'Confirm Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: ordersProvider.isCancel
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OrdersProvider>(context, listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider.readyOrders
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
                      child: ordersProvider.isCancel
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
                      onPressed: () async {
                        ordersProvider.searchControllerReady.clear();
                        ordersProvider.resetReadyFilterData();
                        await ordersProvider.fetchReadyOrders();
                        ordersProvider.resetSelections();
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 180,
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
                              controller: provider.searchControllerReady,
                              decoration: const InputDecoration(
                                hintText: 'Search Orders',
                                hintStyle: TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onSubmitted: (value) {
                                ordersProvider.resetReadyFilterData();
                                if (value.isEmpty) {
                                  ordersProvider.fetchReadyOrders();
                                  ordersProvider.clearSearchResults();
                                } else {
                                  ordersProvider.searchReadyToConfirmOrders(value);
                                }
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  ordersProvider.resetReadyFilterData();
                                  ordersProvider.fetchReadyOrders();
                                  ordersProvider.clearSearchResults();
                                }
                              },
                            ),
                          ),
                          if (provider.searchControllerReady.text.isNotEmpty)
                            InkWell(
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              onTap: () {
                                provider.searchControllerReady.clear();
                                ordersProvider.fetchReadyOrders();
                                ordersProvider.clearSearchResults();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ordersProvider.isReadyLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryBlue,
                        size: 80.0,
                      ),
                    )
                  : ordersProvider.readyOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: ordersProvider.readyOrders.length,
                          itemBuilder: (context, index) {
                            final order = ordersProvider.readyOrders[index];
                            if (order.messages?['confirmerMessage']?.toString().isNotEmpty ?? false) {
                              remarkController.clear();
                              remarkController.text = order.messages!['confirmerMessage'].toString() ?? '';
                            }
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

                            Logger().e('selectedReadyOrders: ${ordersProvider.selectedReadyOrders}');
                            //////////////////////////////////////////////////////////
                            return Stack(
                              children: [
                                // if (order.mistakeStatus ?? false)
                                //   Align(
                                //     alignment: Alignment.topLeft,
                                //     child: HighlightedBannerCard(
                                //       bannerText: 'Mistake',
                                //       cardContent: Text(order.mistakeUser ?? ''),
                                //     ),
                                //   ),
                                Card(
                                  surfaceTintColor: Colors.white,
                                  color: ordersProvider.selectedReadyOrders[index] ? Colors.grey[300] : Colors.grey[100],
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
                                              value: ordersProvider.selectedReadyOrders[index],
                                              onChanged: (value) => ordersProvider.toggleOrderSelectionReady(value ?? false, index),
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
                                                    ordersProvider.formatDate(order.date!),
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
                                            Row(
                                              children: [
                                                IconButton(
                                                  tooltip: 'Edit Order',
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
                                                      final readySearched = provider.searchControllerReady.text.trim();

                                                      log('readySearched: $readySearched');
                                                      log('result: $result');

                                                      if (readySearched.isNotEmpty) {
                                                        ordersProvider.searchReadyToConfirmOrders(readySearched);
                                                      } else {
                                                        ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageReady);
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(Icons.edit_note),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Edit warehouse',
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        String selectedWarehouse = order.warehouseName ?? '';

                                                        return StatefulBuilder(
                                                          builder: (context, setState) {
                                                            return AlertDialog(
                                                              title: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  const Text('Edit Warehouse', style: TextStyle(fontSize: 20)),
                                                                  Text(order.orderId, style: const TextStyle(fontSize: 15)),
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
                                                                      final res =
                                                                          await pro.editWarehouse(order.orderId, selectedWarehouse.trim());
                                                                      if (res == true) {
                                                                        if (ordersProvider.searchControllerReady.text.trim().isNotEmpty) {
                                                                          ordersProvider.searchReadyToConfirmOrders(
                                                                              ordersProvider.searchControllerReady.text.trim());
                                                                        } else {
                                                                          ordersProvider.fetchReadyOrders();
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
                                                  icon: const Icon(Icons.edit_location_alt_outlined),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Split Order',
                                                  onPressed: () {
                                                    final List<String> selectedItems = [];
                                                    final weightController = TextEditingController();
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext dialogContext) {
                                                        return StatefulBuilder(
                                                          builder: (BuildContext context, StateSetter setDialogState) {
                                                            return AlertDialog(
                                                              title: Text(order.orderId),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  ...remainingItems.map(
                                                                    (item) => Row(
                                                                      children: [
                                                                        Checkbox(
                                                                          value: selectedItems.contains(item.sku),
                                                                          onChanged: (value) {
                                                                            setDialogState(() {
                                                                              if (selectedItems.contains(item.sku)) {
                                                                                selectedItems.remove(item.sku);
                                                                              } else {
                                                                                selectedItems.add(item.sku ?? '');
                                                                              }
                                                                            });
                                                                          },
                                                                        ),
                                                                        Text(item.sku ?? ''),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  ...comboItemGroups.map(
                                                                    (item) => Row(
                                                                      children: [
                                                                        Checkbox(
                                                                          value: selectedItems.contains(item[0].sku),
                                                                          onChanged: (value) {
                                                                            setDialogState(() {
                                                                              if (selectedItems.contains(item[0].sku)) {
                                                                                selectedItems.remove(item[0].sku);
                                                                              } else {
                                                                                selectedItems.add(item[0].sku ?? '');
                                                                              }
                                                                            });
                                                                          },
                                                                        ),
                                                                        Text(item[0].comboSku ?? ''),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 10),
                                                                  TextField(
                                                                    controller: weightController,
                                                                    decoration: const InputDecoration(
                                                                      labelText: 'Weight Limit (Optional)',
                                                                      // border: OutlineInputBorder(),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  child: const Text('Cancel'),
                                                                  onPressed: () => Navigator.pop(context),
                                                                ),
                                                                TextButton(
                                                                  child: const Text('Submit'),
                                                                  onPressed: () async {
                                                                    showDialog(
                                                                      context: context,
                                                                      builder: (_) {
                                                                        return const AlertDialog(
                                                                          content: Row(
                                                                            children: [
                                                                              CircularProgressIndicator(),
                                                                              SizedBox(
                                                                                width: 8,
                                                                              ),
                                                                              Text('Splitting')
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    );

                                                                    List<String>? productSkus;

                                                                    setDialogState(() {
                                                                      productSkus = selectedItems;
                                                                    });

                                                                    final res = await ordersProvider.splitOrder(
                                                                        order.orderId, productSkus ?? [],
                                                                        weightLimit: weightController.text.trim());
                                                                    Navigator.pop(context);
                                                                    Navigator.pop(context);
                                                                    if (res['success'] == true) {
                                                                      ordersProvider.showSnackBar(
                                                                          context, res['message'].toString(), Colors.green);
                                                                    } else {
                                                                      ordersProvider.showSnackBar(
                                                                          context, res['message'].toString(), Colors.red);
                                                                    }
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(Icons.call_split),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Report Bug',
                                                  onPressed: () {
                                                    TextEditingController messageController = TextEditingController();
                                                    context.read<SupportProvider>().setUserData(order.orderId, email!, role!);
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
                                                                  controller: TextEditingController(text: order.orderId),
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
                                                                    .connectWithSupport(context, order.orderId, messageController.text);

                                                                Navigator.pop(context);
                                                                Navigator.pop(context);

                                                                if (result) {
                                                                  await provider.fetchReadyOrders();
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
                                                if (order.mistakeStatus ?? false) ...[
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    tooltip: 'Support Chat',
                                                    icon: const Icon(Icons.message),
                                                    onPressed: () {
                                                      context.read<SupportProvider>().setUserData(order.orderId, email!, role!);
                                                      Scaffold.of(context).openEndDrawer();
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
                                        OrderInfo(order: order, pro: ordersProvider),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
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
                                                                  text:
                                                                      "(${order.outBoundBy?['outboundBy'].toString().split('@')[0] ?? ''})",
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
                                                                )),
                                                          ],
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                          )),
                                                    ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) {
                                                          return Dialog(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16),
                                                            ),
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
                                                                    controller: remarkController,
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
                                                                                      'Submitting Remark',
                                                                                      style: TextStyle(fontSize: 16),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                          final bool res = await ordersProvider.writeRemark(
                                                                              order.id, remarkController.text);
                                                                          Navigator.of(context).pop();
                                                                          Navigator.of(context).pop();

                                                                          res ? await ordersProvider.fetchReadyOrders() : null;
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
                                                    child: (order.messages?['confirmerMessage']?.toString().isNotEmpty ?? false)
                                                        ? const Text('Edit Remark')
                                                        : const Text('Write Remark'),
                                                  ),
                                                  if (order.messages?['confirmerMessage']?.toString().isNotEmpty ?? false)
                                                    Utils().showMessage(
                                                        context, 'Confirmer Remark', order.messages!['confirmerMessage'].toString())
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
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
            CustomPaginationFooter(
              currentPage: ordersProvider.currentPageReady,
              totalPages: ordersProvider.totalReadyPages,
              buttonSize: 30,
              pageController: pageController,
              onFirstPage: () {
                ordersProvider.fetchReadyOrders(page: 1);
              },
              onLastPage: () {
                ordersProvider.fetchReadyOrders(page: ordersProvider.totalReadyPages);
              },
              onNextPage: () {
                if (ordersProvider.currentPageReady < ordersProvider.totalReadyPages) {
                  ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageReady + 1);
                }
              },
              onPreviousPage: () {
                if (ordersProvider.currentPageReady > 1) {
                  ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageReady - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= ordersProvider.totalReadyPages) {
                  ordersProvider.fetchReadyOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(pageController.text);

                if (page == null || page < 1 || page > ordersProvider.totalReadyPages) {
                  _showSnackbar(context, 'Please enter a valid page number between 1 and ${ordersProvider.totalReadyPages}.');
                  return;
                }

                ordersProvider.fetchReadyOrders(page: page);
                pageController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFailedOrdersTab() {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, child) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: ordersProvider.allSelectedFailed,
                      onChanged: (bool? value) {
                        ordersProvider.toggleSelectAllFailed(value ?? false);
                      },
                    ),
                    Text('Select All (${ordersProvider.selectedFailedItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          ordersProvider.selectedFailedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: ordersProvider.selectedFailedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                          ),
                        ),
                        Tooltip(
                          message: 'Filter by Date',
                          child: IconButton(
                            onPressed: () async {
                              ordersProvider.failedPicked = await showDatePicker(
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

                              if (ordersProvider.failedPicked != null) {
                                String formattedDate = DateFormat('dd-MM-yyyy').format(ordersProvider.failedPicked!);
                                setState(() {
                                  ordersProvider.selectedFailedDate = formattedDate;
                                });

                                ordersProvider.fetchFailedOrders(
                                  page: ordersProvider.currentPageFailed,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 30,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        if (ordersProvider.selectedFailedDate != 'Select Date')
                          Tooltip(
                            message: 'Clear selected Date',
                            child: InkWell(
                              onTap: () async {
                                setState(() {
                                  ordersProvider.selectedFailedDate = 'Select Date';
                                  ordersProvider.failedPicked = null;
                                });
                                ordersProvider.fetchReadyOrders(page: ordersProvider.currentPageFailed);
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
                          ordersProvider.selectedFailedCourier,
                        ),
                        Consumer<MarketplaceProvider>(
                          builder: (context, provider, child) {
                            return PopupMenuButton<String>(
                              tooltip: 'Filter by Marketplace',
                              onSelected: (String value) async {
                                setState(() {
                                  ordersProvider.selectedFailedCourier = value;
                                });

                                ordersProvider.fetchFailedOrders(page: ordersProvider.currentPageFailed);
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
                      onPressed: ordersProvider.isUpdating
                          ? null
                          : () async {
                              ordersProvider.setUpdating(true);
                              await ordersProvider.approveFailedOrders(context);
                              ordersProvider.setUpdating(false);
                            },
                      child: ordersProvider.isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Approve Failed Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: ordersProvider.isCancel
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OrdersProvider>(context, listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider.failedOrders
                                  .asMap()
                                  .entries
                                  .where((entry) => provider.selectedFailedOrders[entry.key])
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
                                String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

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
                      child: ordersProvider.isCancel
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
                      onPressed: () async {
                        ordersProvider.searchControllerFailed.clear();
                        ordersProvider.resetFailedFilterData();
                        await ordersProvider.fetchFailedOrders();
                        ordersProvider.resetSelections();
                        print('Failed Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 180,
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
                              controller: provider.searchControllerFailed,
                              decoration: const InputDecoration(
                                hintText: 'Search Orders',
                                hintStyle: TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              ),
                              style: const TextStyle(color: Colors.black),
                              onSubmitted: (value) {
                                ordersProvider.resetFailedFilterData();
                                if (value.isEmpty) {
                                  ordersProvider.fetchFailedOrders();
                                  ordersProvider.clearSearchResults();
                                } else {
                                  ordersProvider.searchFailedOrders(value);
                                }
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  ordersProvider.fetchFailedOrders();
                                  ordersProvider.clearSearchResults();
                                }
                              },
                            ),
                          ),
                          if (provider.searchControllerFailed.text.isNotEmpty)
                            InkWell(
                              child: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onTap: () {
                                provider.searchControllerFailed.clear();
                                ordersProvider.fetchFailedOrders();
                                ordersProvider.clearSearchResults();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ordersProvider.isFailedLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryBlue,
                        size: 80.0,
                      ),
                    )
                  : ordersProvider.failedOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: ordersProvider.failedOrders.length,
                          itemBuilder: (context, index) {
                            final order = ordersProvider.failedOrders[index];

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
                              color: ordersProvider.selectedFailedOrders[index] ? Colors.grey[300] : Colors.grey[100],
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
                                          value: ordersProvider.selectedFailedOrders[index],
                                          onChanged: (value) => ordersProvider.toggleOrderSelectionFailed(value ?? false, index),
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
                                                ordersProvider.formatDate(order.date!),
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
                                              order.totalWeight.toStringAsFixed(2),
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
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

                                            final failedSearched = provider.searchControllerFailed.text;

                                            if (result == true) {
                                              if (failedSearched.isNotEmpty) {
                                                ordersProvider.searchFailedOrders(failedSearched);
                                              } else {
                                                ordersProvider.fetchFailedOrders(page: ordersProvider.currentPageFailed);
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: AppColors.white,
                                            backgroundColor: AppColors.orange, // Set the text color to white
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          child: const Text(
                                            'Edit Order',
                                          ),
                                        )
                                      ],
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  buildLabelValueRow('Payment Mode', order.paymentMode ?? ''),
                                                  buildLabelValueRow('Currency Code', order.currencyCode ?? ''),
                                                  buildLabelValueRow('COD Amount', order.codAmount.toString() ?? ''),
                                                  buildLabelValueRow('Prepaid Amount', order.prepaidAmount.toString() ?? ''),
                                                  buildLabelValueRow('Coin', order.coin.toString() ?? ''),
                                                  buildLabelValueRow('Tax Percent', order.taxPercent.toString() ?? ''),
                                                  buildLabelValueRow('Courier Name', order.courierName ?? ''),
                                                  buildLabelValueRow('Order Type', order.orderType ?? ''),
                                                  buildLabelValueRow('Payment Bank', order.paymentBank ?? ''),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(width: 12.0),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  buildLabelValueRow('Discount Amount', order.discountAmount.toString() ?? ''),
                                                  buildLabelValueRow('Discount Scheme', order.discountScheme ?? ''),
                                                  buildLabelValueRow('Agent', order.agent ?? ''),
                                                  buildLabelValueRow('Notes', order.notes ?? ''),
                                                  buildLabelValueRow('Marketplace', order.marketplace?.name ?? ''),
                                                  buildLabelValueRow('Filter', order.filter ?? ''),
                                                  buildLabelValueRow(
                                                    'Expected Delivery Date',
                                                    order.expectedDeliveryDate != null
                                                        ? ordersProvider.formatDate(order.expectedDeliveryDate!)
                                                        : '',
                                                  ),
                                                  buildLabelValueRow('Preferred Courier', order.preferredCourier ?? ''),
                                                  buildLabelValueRow(
                                                    'Payment Date Time',
                                                    order.paymentDateTime != null
                                                        ? ordersProvider.formatDateTime(order.paymentDateTime!)
                                                        : '',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(width: 12.0),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  buildLabelValueRow('Delivery Term', order.deliveryTerm ?? ''),
                                                  buildLabelValueRow('Transaction Number', order.transactionNumber ?? ''),
                                                  buildLabelValueRow('Micro Dealer Order', order.microDealerOrder ?? ''),
                                                  buildLabelValueRow('Fulfillment Type', order.fulfillmentType ?? ''),
                                                  // buildLabelValueRow(
                                                  //     'No. of Boxes',
                                                  //     order.numberOfBoxes
                                                  //             .toString() ??
                                                  //         ''),
                                                  buildLabelValueRow('Total Quantity', order.totalQuantity.toString() ?? ''),
                                                  // buildLabelValueRow(
                                                  //     'SKU Qty',
                                                  //     order.skuQty.toString() ??
                                                  //         ''),
                                                  buildLabelValueRow('Calculation Entry No.', order.calcEntryNumber ?? ''),
                                                  buildLabelValueRow('Currency', order.currency ?? ''),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(width: 12.0),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  buildLabelValueRow(
                                                    'Dimensions',
                                                    '${order.length.toString() ?? ''} x ${order.breadth.toString() ?? ''} x ${order.height.toString() ?? ''}',
                                                  ),
                                                  buildLabelValueRow('Tracking Status', order.trackingStatus ?? ''),
                                                  const SizedBox(
                                                    height: 7,
                                                  ),
                                                  const Text(
                                                    'Customer Details:',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.primaryBlue),
                                                  ),
                                                  buildLabelValueRow(
                                                    'Customer ID',
                                                    order.customer?.customerId ?? '',
                                                  ),
                                                  buildLabelValueRow(
                                                      'Full Name',
                                                      order.customer?.firstName != order.customer?.lastName
                                                          ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'.trim()
                                                          : order.customer?.firstName ?? ''),
                                                  buildLabelValueRow(
                                                    'Email',
                                                    order.customer?.email ?? '',
                                                  ),
                                                  buildLabelValueRow(
                                                    'Phone',
                                                    maskPhoneNumber(order.customer?.phone?.toString()) ?? '',
                                                  ),
                                                  buildLabelValueRow(
                                                    'GSTIN',
                                                    order.customer?.customerGstin ?? '',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // const SizedBox(width: 12.0),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Shipping Address:',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.primaryBlue),
                                                  ),
                                                  buildLabelValueRow(
                                                    'Address',
                                                    [
                                                      order.shippingAddress?.address1,
                                                      order.shippingAddress?.address2,
                                                      order.shippingAddress?.city,
                                                      order.shippingAddress?.state,
                                                      order.shippingAddress?.country,
                                                      order.shippingAddress?.pincode?.toString(),
                                                    ]
                                                        .where((element) => element != null && element.isNotEmpty)
                                                        .join(', ')
                                                        .replaceAllMapped(RegExp('.{1,70}'), (match) => '${match.group(0)}\n'),
                                                  ),
                                                  buildLabelValueRow(
                                                    'Name',
                                                    order.shippingAddress?.firstName != order.shippingAddress?.lastName
                                                        ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                            .trim()
                                                        : order.shippingAddress?.firstName ?? '',
                                                  ),
                                                  buildLabelValueRow('Pincode', order.shippingAddress?.pincode?.toString() ?? ''),
                                                  buildLabelValueRow('Country Code', order.shippingAddress?.countryCode ?? ''),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Billing Address:',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.primaryBlue),
                                                  ),
                                                  buildLabelValueRow(
                                                    'Address',
                                                    [
                                                      order.billingAddress?.address1,
                                                      order.billingAddress?.address2,
                                                      order.billingAddress?.city,
                                                      order.billingAddress?.state,
                                                      order.billingAddress?.country,
                                                      order.billingAddress?.pincode?.toString(),
                                                    ]
                                                        .where((element) => element != null && element.isNotEmpty)
                                                        .join(', ')
                                                        .replaceAllMapped(RegExp('.{1,50}'), (match) => '${match.group(0)}\n'),
                                                  ),
                                                  buildLabelValueRow(
                                                    'Name',
                                                    order.billingAddress?.firstName != order.billingAddress?.lastName
                                                        ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                            .trim()
                                                        : order.billingAddress?.firstName ?? '',
                                                  ),
                                                  buildLabelValueRow('Pincode', order.billingAddress?.pincode?.toString() ?? ''),
                                                  buildLabelValueRow('Country Code', order.billingAddress?.countryCode ?? ''),
                                                ],
                                              ),
                                            ),
                                          ),
                                          ((order.messages?['failureReason'] ?? []).isEmpty ?? false)
                                              ? const SizedBox()
                                              : Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[50],
                                                      // Lighter shade for better readability
                                                      borderRadius: BorderRadius.circular(8.0),
                                                      border: Border.all(color: Colors.red[300]!),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              "Failure Reasons",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.red[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 12),
                                                        ...order.messages!['failureReason'].map(
                                                          (reason) => Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                            child: Row(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  '•',
                                                                  style: TextStyle(
                                                                    color: Colors.red[700],
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Expanded(
                                                                  child: Text(
                                                                    reason['type'],
                                                                    style: TextStyle(
                                                                      color: Colors.red[900],
                                                                      height: 1.3,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Column(
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
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    // Nested cards for each item in the order
                                    const SizedBox(height: 10),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: comboItemGroups.length,
                                      itemBuilder: (context, comboIndex) {
                                        final combo = comboItemGroups[comboIndex];
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
                                    //       orderStatus:
                                    //           order.orderStatus.toString(),
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
              currentPage: ordersProvider.currentPageFailed,
              totalPages: ordersProvider.totalFailedPages,
              buttonSize: 30,
              pageController: _pageController,
              onFirstPage: () {
                ordersProvider.fetchFailedOrders(page: 1);
              },
              onLastPage: () {
                ordersProvider.fetchFailedOrders(page: ordersProvider.totalFailedPages);
              },
              onNextPage: () {
                if (ordersProvider.currentPageFailed < ordersProvider.totalFailedPages) {
                  ordersProvider.fetchFailedOrders(page: ordersProvider.currentPageFailed + 1);
                }
              },
              onPreviousPage: () {
                if (ordersProvider.currentPageFailed > 1) {
                  ordersProvider.fetchFailedOrders(page: ordersProvider.currentPageFailed - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= ordersProvider.totalFailedPages) {
                  ordersProvider.fetchFailedOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(_pageController.text);

                if (page == null || page < 1 || page > ordersProvider.totalFailedPages) {
                  _showSnackbar(context, 'Please enter a valid page number between 1 and ${ordersProvider.totalFailedPages}.');
                  return;
                }

                ordersProvider.fetchFailedOrders(page: page);
                _pageController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  void showSupportDialog(BuildContext context, String orderId) {
    TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      // barrierDismissible: false,
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
                  controller: TextEditingController(text: orderId),
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
                bool result = await context.read<OrdersProvider>().connectWithSupport(context, orderId, messageController.text);

                Navigator.pop(context);
                Navigator.pop(context);

                if (result) {
                  await provider.fetchReadyOrders();
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
