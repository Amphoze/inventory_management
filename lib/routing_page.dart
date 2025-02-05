import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/routing_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class RoutingPage extends StatefulWidget {
  const RoutingPage({super.key});

  @override
  _RoutingPageState createState() => _RoutingPageState();
}

class _RoutingPageState extends State<RoutingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late TextEditingController _searchControllerReady;
  late TextEditingController _searchControllerFailed;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();
  String _selectedDate = 'Select Date';
  String selectedCourier = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _searchControllerReady = TextEditingController();
    _searchControllerFailed = TextEditingController();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedDate = 'Select Date';
        });
        _reloadOrders();
        _searchController.clear();
        _searchControllerReady.clear();
        _searchControllerFailed.clear();
      }
    });

    context.read<MarketplaceProvider>().fetchMarketplaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchControllerReady.dispose();
    _searchControllerFailed.dispose();
    _pageController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _reloadOrders() {
    // Access the RoutingProvider and fetch orders again
    final ordersProvider = Provider.of<RoutingProvider>(context, listen: false);
    ordersProvider.fetchOrders(); // Fetch both orders
    // ordersProvider.fetchFailedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RoutingProvider()
        // ..fetchFailedOrders(page: 1) // Fetch failed orders on initialization
        ..fetchOrders(page: 1), // Fetch ready orders on initialization
      child: Scaffold(
        backgroundColor: Colors.white,
        // appBar: _buildAppBar(),
        body: _buildReadyToConfirmTab(),
      ),
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
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildReadyToConfirmTab(),
        // _buildFailedOrdersTab(),
      ],
    );
  }

  Widget _buildReadyToConfirmTab() {
    return Consumer<RoutingProvider>(
      builder: (context, pro, child) {
        if (pro.isLoading) {
          return const Center(
            child: LoadingAnimation(
              icon: Icons.route,
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
                Row(
                  children: [
                    Checkbox(
                      value: pro.allSelected,
                      onChanged: (bool? value) {
                        pro.toggleSelectAllReady(value ?? false);
                      },
                    ),
                    Text('Select All (${pro.selectedItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          _selectedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: _selectedDate == 'Select Date'
                                ? Colors.grey
                                : AppColors.primaryBlue,
                          ),
                        ),
                        Tooltip(
                          message: 'Filter by Date',
                          child: IconButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
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
                                String formattedDate =
                                    DateFormat('dd-MM-yyyy').format(picked);
                                setState(() {
                                  _selectedDate = formattedDate;
                                });

                                if (selectedCourier != 'All') {
                                  pro.fetchOrdersByMarketplace(
                                    selectedCourier,
                                    pro.currentPageReady,
                                    date: picked,
                                  );
                                } else {
                                  pro.fetchOrders(
                                    page: pro.currentPageReady,
                                    date: picked,
                                  );
                                }
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
                              onSelected: (String value) async {
                                setState(() {
                                  selectedCourier = value;
                                });

                                // String formattedDate =
                                //     DateFormat('dd-MM-yyyy').format(picked);
                                // setState(() {
                                //   _selectedReadyDate = formattedDate;
                                // });

                                if (value == 'All') {
                                  log("value: $value");
                                  log("selectedCourier: $selectedCourier");
                                  log("selectedDate: $_selectedDate");
                                  pro.fetchOrders(
                                    page: pro.currentPageReady,
                                    date: _selectedDate == 'Select Date'
                                        ? null
                                        : DateTime.parse(_selectedDate),
                                  );
                                } else {
                                  DateTime? selectedDate;
                                  if (_selectedDate != 'Select Date') {
                                    selectedDate = DateFormat('yyyy-MM-dd')
                                        .parse(_selectedDate);
                                  }

                                  log("selectedDate: $selectedDate");

                                  pro.fetchOrdersByMarketplace(
                                    value,
                                    pro.currentPageReady,
                                    date: selectedDate,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                ...provider.marketplaces
                                    .map((marketplace) => PopupMenuItem<String>(
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
                      onPressed: pro.isConfirm
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<RoutingProvider>(
                                  context,
                                  listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider
                                  .readyOrders
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      provider.selectedOrders[entry.key])
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
                                // Set loading status to true before starting the operation
                                // provider.setConfirmStatus(true);

                                // Call confirmOrders method with selected IDs
                                String resultMessage = await provider
                                    .routeOrders(context, selectedOrderIds);

                                log('resultMessage: $resultMessage');

                                // Set loading status to false after operation completes
                                // provider.setConfirmStatus(false);

                                // Determine the background color based on the result
                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor =
                                      AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') ||
                                    resultMessage.contains('failed')) {
                                  snackBarColor =
                                      AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor =
                                      AppColors.orange; // Other: Orange
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
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Route',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        // Call fetchOrders method on refresh button press
                        setState(() {
                        selectedCourier = 'All';
                        _selectedDate = 'Select Date';
                      });
                        Provider.of<RoutingProvider>(context, listen: false)
                            .fetchOrders();
                        Provider.of<RoutingProvider>(context, listen: false)
                            .resetSelections();
                        pro.clearSearchResults();
                        print('Ready to Confirm Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 200,
                      height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.green,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchControllerReady,
                              decoration: InputDecoration(
                                prefixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                  ),
                                  onPressed: () {
                                    final searchTerm =
                                        _searchControllerReady.text;

                                    if (searchTerm.isNotEmpty) {
                                      pro.searchOrders(searchTerm);
                                    }
                                  },
                                ),
                                hintText: 'Search Orders',
                                hintStyle: const TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onSubmitted: (value) {
                                pro.searchOrders(value);
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  pro.clearSearchResults();
                                }
                              },
                            ),
                          ),
                          if (_searchControllerReady.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchControllerReady.clear();
                                pro.fetchOrders();
                                pro.clearSearchResults();
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
              child: pro.isLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryBlue,
                        size: 80.0,
                      ),
                    )
                  : pro.readyOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: pro.readyOrders.length,
                          itemBuilder: (context, index) {
                            final order = pro.readyOrders[index];
                            //////////////////////////////////////////////////////////////
                            final Map<String, List<Item>> groupedComboItems =
                                {};
                            for (var item in order.items) {
                              if (item.isCombo == true &&
                                  item.comboSku != null) {
                                if (!groupedComboItems
                                    .containsKey(item.comboSku)) {
                                  groupedComboItems[item.comboSku!] = [];
                                }
                                groupedComboItems[item.comboSku]!.add(item);
                              }
                            }
                            final List<List<Item>> comboItemGroups =
                                groupedComboItems.values
                                    .where((items) => items.length > 1)
                                    .toList();

                            final List<Item> remainingItems = order.items
                                .where((item) => !(item.isCombo == true &&
                                    item.comboSku != null &&
                                    groupedComboItems[item.comboSku]!.length >
                                        1))
                                .toList();
                            //////////////////////////////////////////////////////////
                            return Card(
                              surfaceTintColor: Colors.white,
                              color: const Color.fromARGB(255, 231, 230, 230),
                              elevation: 0.5,
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Checkbox(
                                          value: pro.selectedOrders[index],
                                          onChanged: (value) =>
                                              pro.toggleOrderSelectionReady(
                                                  value ?? false, index),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Order ID: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Date: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              pro.formatDate(order.date!),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Amount: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Rs. ${order.totalAmount ?? ''}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Items: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.items.fold(0, (total, item) => total + item.qty!)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Weight: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${order.totalWeight ?? ''}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryBlue),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      thickness: 1,
                                      color: AppColors.grey,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Payment Mode',
                                                    order.paymentMode ?? ''),
                                                buildLabelValueRow(
                                                    'Currency Code',
                                                    order.currencyCode ?? ''),
                                                buildLabelValueRow(
                                                    'COD Amount',
                                                    order.codAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Prepaid Amount',
                                                    order.prepaidAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Coin',
                                                    order.coin.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Tax Percent',
                                                    order.taxPercent
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Courier Name',
                                                    order.courierName ?? ''),
                                                buildLabelValueRow('Order Type',
                                                    order.orderType ?? ''),
                                                buildLabelValueRow(
                                                    'Payment Bank',
                                                    order.paymentBank ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Discount Amount',
                                                    order.discountAmount
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Discount Scheme',
                                                    order.discountScheme ?? ''),
                                                buildLabelValueRow(
                                                    'Discount Percent',
                                                    order.discountPercent
                                                            .toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Agent', order.agent ?? ''),
                                                buildLabelValueRow(
                                                    'Notes', order.notes ?? ''),
                                                buildLabelValueRow(
                                                    'Marketplace',
                                                    order.marketplace?.name ??
                                                        ''),
                                                buildLabelValueRow('Filter',
                                                    order.filter ?? ''),
                                                buildLabelValueRow(
                                                  'Expected Delivery Date',
                                                  order.expectedDeliveryDate !=
                                                          null
                                                      ? pro.formatDate(order
                                                          .expectedDeliveryDate!)
                                                      : '',
                                                ),
                                                buildLabelValueRow(
                                                    'Preferred Courier',
                                                    order.preferredCourier ??
                                                        ''),
                                                buildLabelValueRow(
                                                  'Payment Date Time',
                                                  order.paymentDateTime != null
                                                      ? pro.formatDateTime(order
                                                          .paymentDateTime!)
                                                      : '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                    'Delivery Term',
                                                    order.deliveryTerm ?? ''),
                                                buildLabelValueRow(
                                                    'Transaction Number',
                                                    order.transactionNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Micro Dealer Order',
                                                    order.microDealerOrder ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Fulfillment Type',
                                                    order.fulfillmentType ??
                                                        ''),
                                                // buildLabelValueRow(
                                                //     'No. of Boxes',
                                                //     order.numberOfBoxes
                                                //             .toString() ??
                                                //         ''),
                                                buildLabelValueRow(
                                                    'Total Quantity',
                                                    order.totalQuantity
                                                            .toString() ??
                                                        ''),
                                                // buildLabelValueRow(
                                                //     'SKU Qty',
                                                //     order.skuQty.toString() ??
                                                //         ''),
                                                buildLabelValueRow(
                                                    'Calculation Entry No.',
                                                    order.calcEntryNumber ??
                                                        ''),
                                                buildLabelValueRow('Currency',
                                                    order.currency ?? ''),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                buildLabelValueRow(
                                                  'Dimensions',
                                                  '${order.length.toString() ?? ''} x ${order.breadth.toString() ?? ''} x ${order.height.toString() ?? ''}',
                                                ),
                                                buildLabelValueRow(
                                                    'Tracking Status',
                                                    order.trackingStatus ?? ''),
                                                const SizedBox(
                                                  height: 7,
                                                ),
                                                const Text(
                                                  'Customer Details:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                buildLabelValueRow(
                                                  'Customer ID',
                                                  order.customer?.customerId ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                    'Full Name',
                                                    order.customer?.firstName !=
                                                            order.customer
                                                                ?.lastName
                                                        ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'
                                                            .trim()
                                                        : order.customer
                                                                ?.firstName ??
                                                            ''),
                                                buildLabelValueRow(
                                                  'Email',
                                                  order.customer?.email ?? '',
                                                ),
                                                buildLabelValueRow(
                                                  'Phone',
                                                  order.customer?.phone
                                                          ?.toString() ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'GSTIN',
                                                  order.customer
                                                          ?.customerGstin ??
                                                      '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Shipping Address:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Address: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                    Text(
                                                      [
                                                        order.shippingAddress
                                                            ?.address1,
                                                        order.shippingAddress
                                                            ?.address2,
                                                        order.shippingAddress
                                                            ?.city,
                                                        order.shippingAddress
                                                            ?.state,
                                                        order.shippingAddress
                                                            ?.country,
                                                        order.shippingAddress
                                                            ?.pincode
                                                            ?.toString(),
                                                      ]
                                                          .where((element) =>
                                                              element != null &&
                                                              element
                                                                  .isNotEmpty)
                                                          .join(', ')
                                                          .replaceAllMapped(
                                                              RegExp('.{1,50}'),
                                                              (match) =>
                                                                  '${match.group(0)}\n'),
                                                      softWrap: true,
                                                      maxLines: null,
                                                      style: const TextStyle(
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                  'Name',
                                                  order.shippingAddress
                                                              ?.firstName !=
                                                          order.shippingAddress
                                                              ?.lastName
                                                      ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                          .trim()
                                                      : order.shippingAddress
                                                              ?.firstName ??
                                                          '',
                                                ),
                                                buildLabelValueRow(
                                                    'Pincode',
                                                    order.shippingAddress
                                                            ?.pincode
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.shippingAddress
                                                            ?.countryCode ??
                                                        ''),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Billing Address:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color: AppColors
                                                          .primaryBlue),
                                                ),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Address: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                    Text(
                                                      [
                                                        order.billingAddress
                                                            ?.address1,
                                                        order.billingAddress
                                                            ?.address2,
                                                        order.billingAddress
                                                            ?.city,
                                                        order.billingAddress
                                                            ?.state,
                                                        order.billingAddress
                                                            ?.country,
                                                        order.billingAddress
                                                            ?.pincode
                                                            ?.toString(),
                                                      ]
                                                          .where((element) =>
                                                              element != null &&
                                                              element
                                                                  .isNotEmpty)
                                                          .join(', ')
                                                          .replaceAllMapped(
                                                              RegExp('.{1,50}'),
                                                              (match) =>
                                                                  '${match.group(0)}\n'),
                                                      softWrap: true,
                                                      maxLines: null,
                                                      style: const TextStyle(
                                                        fontSize: 12.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                  'Name',
                                                  order.billingAddress
                                                              ?.firstName !=
                                                          order.billingAddress
                                                              ?.lastName
                                                      ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                          .trim()
                                                      : order.billingAddress
                                                              ?.firstName ??
                                                          '',
                                                ),
                                                buildLabelValueRow(
                                                    'Pincode',
                                                    order.billingAddress
                                                            ?.pincode
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.billingAddress
                                                            ?.countryCode ??
                                                        ''),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text.rich(
                                        TextSpan(
                                          text: "Warehouse ID: ",
                                          children: [
                                            TextSpan(
                                              text: order.warehouseId ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text.rich(
                                        TextSpan(
                                          text: "Warehouse Name: ",
                                          children: [
                                            TextSpan(
                                              text: order.warehouseName ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text.rich(
                                        TextSpan(
                                          text: "Hold: ",
                                          children: [
                                            TextSpan(
                                              text:
                                                  order.isHold.toString() ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text.rich(
                                        TextSpan(
                                            text: "Updated on: ",
                                            children: [
                                              TextSpan(
                                                  text: DateFormat(
                                                          'yyyy-MM-dd\',\' hh:mm a')
                                                      .format(
                                                    DateTime.parse(
                                                        "${order.updatedAt}"),
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  )),
                                            ],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            )),
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: comboItemGroups.length,
                                      itemBuilder: (context, comboIndex) {
                                        final combo =
                                            comboItemGroups[comboIndex];
                                        return BigComboCard(
                                          items: combo,
                                          index: comboIndex,
                                        );
                                      },
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: remainingItems.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = remainingItems[itemIndex];
                                        print(
                                            'Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
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
                  _showSnackbar(context,
                      'Please enter a valid page number between 1 and ${pro.totalReadyPages}.');
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
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Widget buildLabelValueRow(String label, String? value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label: ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
      Text(
        value ?? '',
        softWrap: true,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 12.0,
        ),
      ),
    ],
  );
}
