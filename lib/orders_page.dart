import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_order_page.dart';

import 'package:inventory_management/model/orders_model.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/orders_provider.dart'; // Import the separate provider
import 'package:inventory_management/Custom-Files/colors.dart';

class OrdersNewPage extends StatefulWidget {
  const OrdersNewPage({Key? key}) : super(key: key);

  @override
  _OrdersNewPageState createState() => _OrdersNewPageState();
}

class _OrdersNewPageState extends State<OrdersNewPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late TextEditingController _searchControllerReady;
  late TextEditingController _searchControllerFailed;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _searchControllerReady = TextEditingController();
    _searchControllerFailed = TextEditingController();
    _tabController.addListener(() {
      // Reload data when the tab changes
      if (_tabController.indexIsChanging) {
        _reloadOrders();
        _searchController.clear();
        _searchControllerReady.clear();
        _searchControllerFailed.clear();
      }
    });
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
    // Access the OrdersProvider and fetch orders again
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    ordersProvider.fetchReadyOrders(); // Fetch both orders
    ordersProvider.fetchFailedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrdersProvider()
        ..fetchFailedOrders(page: 1) // Fetch failed orders on initialization
        ..fetchReadyOrders(page: 1), // Fetch ready orders on initialization
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
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
        _buildFailedOrdersTab(),
      ],
    );
  }

  Widget _buildReadyToConfirmTab() {
    return Consumer<OrdersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: LoadingAnimation(
              icon: Icons.shopping_cart,
              beginColor: Color.fromRGBO(189, 189, 189, 1),
              endColor: AppColors.primaryGreen,
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
                      value: provider.allSelectedReady,
                      onChanged: (bool? value) {
                        provider.toggleSelectAllReady(value ?? false);
                      },
                    ),
                    Text('Select All (${provider.selectedReadyItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: provider.isConfirm
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<OrdersProvider>(
                                  context,
                                  listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider
                                  .readyOrders
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      provider.selectedReadyOrders[entry.key])
                                  .map((entry) => entry.value.orderId!)
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
                                provider.setConfirmStatus(true);

                                // Call confirmOrders method with selected IDs
                                String resultMessage = await provider
                                    .confirmOrders(context, selectedOrderIds);

                                // Set loading status to false after operation completes
                                provider.setConfirmStatus(false);

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
                      child: provider.isConfirm
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Confirm Orders',
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
                        Provider.of<OrdersProvider>(context, listen: false)
                            .fetchReadyOrders();
                        Provider.of<OrdersProvider>(context, listen: false)
                            .resetSelections();
                        provider.clearSearchResults();
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
                                    provider
                                        .searchReadyToConfirmOrders(searchTerm);
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
                                provider.searchReadyToConfirmOrders(value);
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  provider.clearSearchResults();
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
                                provider.fetchReadyOrders();
                                provider.clearSearchResults();
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
              child: provider.isLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryGreen,
                        size: 80.0,
                      ),
                    )
                  : provider.filteredReadyOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.filteredReadyOrders.length,
                          itemBuilder: (context, index) {
                            final order = provider.filteredReadyOrders[index];

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
                                          value: provider
                                              .selectedReadyOrders[index],
                                          onChanged: (value) => provider
                                              .toggleOrderSelectionReady(
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
                                              provider.formatDate(order.date!),
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
                                        ElevatedButton(
                                          onPressed: () {
                                            // Handle edit order action here
                                            // provider.editOrder(order);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditOrderPage(
                                                  order: order,
                                                  isBookPage: false,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: AppColors.white,
                                            backgroundColor: AppColors
                                                .orange, // Set the text color to white
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
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            child: const SizedBox(
                                              height: 50,
                                              width: 130,
                                              child: Text(
                                                'ORDER DETAILS:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 2.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Order Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditOrderDetailsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow('Order Type',
                                                    order.orderType ?? ''),
                                                buildLabelValueRow(
                                                    'Marketplace',
                                                    order.marketplace?.name ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Transaction Number',
                                                    order.transactionNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Calc Entry No.',
                                                    order.calcEntryNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Micro Dealer Order',
                                                    order.microDealerOrder ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Fulfillment Type',
                                                    order.fulfillmentType ??
                                                        ''),
                                                buildLabelValueRow('Filter',
                                                    order.filter ?? ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Payment Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditPaymentDetailsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Payment Mode',
                                                    order.paymentMode ?? ''),
                                                buildLabelValueRow(
                                                    'Currency Code',
                                                    order.currencyCode ?? ''),
                                                buildLabelValueRow('Currency',
                                                    order.currency ?? ''),
                                                buildLabelValueRow(
                                                    'COD Amount',
                                                    order.codAmount
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Prepaid Amount',
                                                    order.prepaidAmount
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Payment Bank',
                                                    order.paymentBank ?? ''),
                                                buildLabelValueRow(
                                                  'Payment Date Time',
                                                  order.paymentDateTime != null
                                                      ? provider.formatDateTime(
                                                          order
                                                              .paymentDateTime!)
                                                      : '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 50.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Delivery Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditDeliveryDetailsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Courier Name',
                                                    order.courierName ?? ''),
                                                buildLabelValueRow(
                                                    'Tracking Status',
                                                    order.trackingStatus ?? ''),
                                                buildLabelValueRow(
                                                  'Delivery Date',
                                                  order.expectedDeliveryDate !=
                                                          null
                                                      ? provider.formatDate(order
                                                          .expectedDeliveryDate!)
                                                      : '',
                                                ),
                                                buildLabelValueRow(
                                                    'Preferred Courier',
                                                    order.preferredCourier ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Delivery Term',
                                                    order.deliveryTerm ?? ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Order Specification:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditOrderSpecificationDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Total Quantity',
                                                    order.totalQuantity
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'No. of Boxes',
                                                    order.numberOfBoxes
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'SKU Qty',
                                                    order.skuQty?.toString() ??
                                                        ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Order Dimention:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditDimensionsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                  'Dimensions',
                                                  '${order.length?.toString() ?? ''} x ${order.breadth?.toString() ?? ''} x ${order.height?.toString() ?? ''}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 29.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Discount Info:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditDiscountDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Discount Amount',
                                                    order.discountAmount
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Discount Scheme',
                                                    order.discountScheme ?? ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Additional Info:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditAdditionalInfoDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Agent', order.agent ?? ''),
                                                buildLabelValueRow(
                                                    'Notes', order.notes ?? ''),
                                                buildLabelValueRow(
                                                    'Coin',
                                                    order.coin?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Tax Percent',
                                                    order.taxPercent
                                                            ?.toString() ??
                                                        ''),
                                                const SizedBox(height: 7),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Customer Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditContactDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
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
                                          const SizedBox(width: 21.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  height: 7,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 50.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize
                                                      .min, // Adjust to fit content
                                                  children: [
                                                    const Text(
                                                      'Shipping Address:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Adjust spacing between text and icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditShippingAddressDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.shippingAddress
                                                        ?.address1,
                                                    order.shippingAddress
                                                        ?.address2,
                                                    order.shippingAddress?.city,
                                                    order
                                                        .shippingAddress?.state,
                                                    order.shippingAddress
                                                        ?.country,
                                                    order.shippingAddress
                                                        ?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
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
                                                  'Phone',
                                                  order.shippingAddress?.phone
                                                          ?.toString() ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'Email',
                                                  order.shippingAddress
                                                          ?.email ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'Country Code',
                                                  order.shippingAddress
                                                          ?.countryCode ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'Pin Code',
                                                  order.shippingAddress?.pincode
                                                          ?.toString() ??
                                                      '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 50.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Row to place 'Billing Address' and the edit icon side by side
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Billing Address:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            8.0), // Add some space between the text and icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditBillingAddressDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),

                                                // Build the other label-value rows
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.billingAddress
                                                        ?.address1,
                                                    order.billingAddress
                                                        ?.address2,
                                                    order.billingAddress?.city,
                                                    order.billingAddress?.state,
                                                    order.billingAddress
                                                        ?.country,
                                                    order
                                                        .billingAddress?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
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
                                                    'Phone',
                                                    order.billingAddress?.phone
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Email',
                                                    order.billingAddress
                                                            ?.email ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.billingAddress
                                                            ?.countryCode ??
                                                        ''),

                                                buildLabelValueRow(
                                                  'Pin Code',
                                                  order.shippingAddress?.pincode
                                                          ?.toString() ??
                                                      '',
                                                ),
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
                                    // Nested cards for each item in the order
                                    const SizedBox(height: 6),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: order.items.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = order.items[itemIndex];

                                        return OrderItemCard(
                                          item: item,
                                          index: itemIndex,
                                          courierName: order.courierName,
                                          orderStatus:
                                              order.orderStatus.toString(),
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
              currentPage: provider.currentPageReady,
              totalPages: provider.totalReadyPages,
              buttonSize: 30,
              pageController: pageController,
              onFirstPage: () {
                provider.fetchReadyOrders(page: 1);
              },
              onLastPage: () {
                provider.fetchReadyOrders(page: provider.totalReadyPages);
              },
              onNextPage: () {
                if (provider.currentPageReady < provider.totalReadyPages) {
                  provider.fetchReadyOrders(
                      page: provider.currentPageReady + 1);
                }
              },
              onPreviousPage: () {
                if (provider.currentPageReady > 1) {
                  provider.fetchReadyOrders(
                      page: provider.currentPageReady - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= provider.totalReadyPages) {
                  provider.fetchReadyOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(pageController.text);

                if (page == null ||
                    page < 1 ||
                    page > provider.totalReadyPages) {
                  _showSnackbar(context,
                      'Please enter a valid page number between 1 and ${provider.totalReadyPages}.');
                  return;
                }

                provider.fetchReadyOrders(page: page);
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
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: LoadingAnimation(
              icon: Icons.shopping_cart,
              beginColor: Color.fromRGBO(189, 189, 189, 1),
              endColor: AppColors.primaryGreen,
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
                      value: provider.allSelectedFailed,
                      onChanged: (bool? value) {
                        provider.toggleSelectAllFailed(value ?? false);
                      },
                    ),
                    Text('Select All (${provider.selectedFailedItemsCount})'),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: provider.isUpdating
                          ? null
                          : () async {
                              provider.setUpdating(true);
                              await provider.updateFailedOrders(context);
                              provider.setUpdating(false);
                            },
                      child: provider.isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Approve Failed Orders',
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
                        Provider.of<OrdersProvider>(context, listen: false)
                            .fetchFailedOrders();
                        Provider.of<OrdersProvider>(context, listen: false)
                            .resetSelections();
                        provider.clearSearchResults();

                        print('Failed Orders refreshed');
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
                              controller: _searchControllerFailed,
                              decoration: InputDecoration(
                                prefixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                  ),
                                  onPressed: () {
                                    final searchTerm =
                                        _searchControllerFailed.text;
                                    provider.searchFailedOrders(searchTerm);
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
                              style: const TextStyle(color: Colors.white),
                              onSubmitted: (value) {
                                provider.searchFailedOrders(value);
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  provider.clearSearchResults();
                                }
                              },
                            ),
                          ),
                          if (_searchControllerFailed.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchControllerFailed.clear();
                                provider.fetchFailedOrders();
                                provider.clearSearchResults();
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
              child: provider.isLoading
                  ? const Center(
                      child: LoadingAnimation(
                        icon: Icons.shopping_cart,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryGreen,
                        size: 80.0,
                      ),
                    )
                  : provider.filteredFailedOrders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.filteredFailedOrders.length,
                          itemBuilder: (context, index) {
                            final order = provider.filteredFailedOrders[index];

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
                                          value: provider
                                              .selectedReadyOrders[index],
                                          onChanged: (value) => provider
                                              .toggleOrderSelectionReady(
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
                                              provider.formatDate(order.date!),
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
                                        ElevatedButton(
                                          onPressed: () {
                                            // Handle edit order action here
                                            // provider.editOrder(order);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditOrderPage(
                                                  order: order,
                                                  isBookPage: false,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: AppColors.white,
                                            backgroundColor: AppColors
                                                .orange, // Set the text color to white
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
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            child: const SizedBox(
                                              height: 50,
                                              width: 130,
                                              child: Text(
                                                'ORDER DETAILS:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 2.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Order Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditOrderDetailsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow('Order Type',
                                                    order.orderType ?? ''),
                                                buildLabelValueRow(
                                                    'Marketplace',
                                                    order.marketplace?.name ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Transaction Number',
                                                    order.transactionNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Calc Entry No.',
                                                    order.calcEntryNumber ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Micro Dealer Order',
                                                    order.microDealerOrder ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Fulfillment Type',
                                                    order.fulfillmentType ??
                                                        ''),
                                                buildLabelValueRow('Filter',
                                                    order.filter ?? ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Payment Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditPaymentDetailsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Payment Mode',
                                                    order.paymentMode ?? ''),
                                                buildLabelValueRow(
                                                    'Currency Code',
                                                    order.currencyCode ?? ''),
                                                buildLabelValueRow('Currency',
                                                    order.currency ?? ''),
                                                buildLabelValueRow(
                                                    'COD Amount',
                                                    order.codAmount
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Prepaid Amount',
                                                    order.prepaidAmount
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Payment Bank',
                                                    order.paymentBank ?? ''),
                                                buildLabelValueRow(
                                                  'Payment Date Time',
                                                  order.paymentDateTime != null
                                                      ? provider.formatDateTime(
                                                          order
                                                              .paymentDateTime!)
                                                      : '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 50.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Delivery Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditDeliveryDetailsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Courier Name',
                                                    order.courierName ?? ''),
                                                buildLabelValueRow(
                                                    'Tracking Status',
                                                    order.trackingStatus ?? ''),
                                                buildLabelValueRow(
                                                  'Delivery Date',
                                                  order.expectedDeliveryDate !=
                                                          null
                                                      ? provider.formatDate(order
                                                          .expectedDeliveryDate!)
                                                      : '',
                                                ),
                                                buildLabelValueRow(
                                                    'Preferred Courier',
                                                    order.preferredCourier ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Delivery Term',
                                                    order.deliveryTerm ?? ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Order Specification:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditOrderSpecificationDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Total Quantity',
                                                    order.totalQuantity
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'No. of Boxes',
                                                    order.numberOfBoxes
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'SKU Qty',
                                                    order.skuQty?.toString() ??
                                                        ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Order Dimention:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditDimensionsDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                  'Dimensions',
                                                  '${order.length?.toString() ?? ''} x ${order.breadth?.toString() ?? ''} x ${order.height?.toString() ?? ''}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 29.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Discount Info:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditDiscountDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Discount Amount',
                                                    order.discountAmount
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Discount Scheme',
                                                    order.discountScheme ?? ''),
                                                const SizedBox(height: 7.0),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Additional Info:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditAdditionalInfoDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                    'Agent', order.agent ?? ''),
                                                buildLabelValueRow(
                                                    'Notes', order.notes ?? ''),
                                                buildLabelValueRow(
                                                    'Coin',
                                                    order.coin?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Tax Percent',
                                                    order.taxPercent
                                                            ?.toString() ??
                                                        ''),
                                                const SizedBox(height: 7),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Customer Details:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Add spacing between the text and the icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      padding: EdgeInsets
                                                          .zero, // Remove extra padding
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditContactDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
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
                                          const SizedBox(width: 21.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  height: 7,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 50.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize
                                                      .min, // Adjust to fit content
                                                  children: [
                                                    const Text(
                                                      'Shipping Address:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            4.0), // Adjust spacing between text and icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditShippingAddressDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.shippingAddress
                                                        ?.address1,
                                                    order.shippingAddress
                                                        ?.address2,
                                                    order.shippingAddress?.city,
                                                    order
                                                        .shippingAddress?.state,
                                                    order.shippingAddress
                                                        ?.country,
                                                    order.shippingAddress
                                                        ?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
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
                                                  'Phone',
                                                  order.shippingAddress?.phone
                                                          ?.toString() ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'Email',
                                                  order.shippingAddress
                                                          ?.email ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'Country Code',
                                                  order.shippingAddress
                                                          ?.countryCode ??
                                                      '',
                                                ),
                                                buildLabelValueRow(
                                                  'Pin Code',
                                                  order.shippingAddress?.pincode
                                                          ?.toString() ??
                                                      '',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 50.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Row to place 'Billing Address' and the edit icon side by side
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Billing Address:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width:
                                                            8.0), // Add some space between the text and icon
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size:
                                                            16, // Smaller icon size
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(), // Remove size constraints
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              EditBillingAddressDialog(
                                                                  order: order),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),

                                                // Build the other label-value rows
                                                buildLabelValueRow(
                                                  'Address',
                                                  [
                                                    order.billingAddress
                                                        ?.address1,
                                                    order.billingAddress
                                                        ?.address2,
                                                    order.billingAddress?.city,
                                                    order.billingAddress?.state,
                                                    order.billingAddress
                                                        ?.country,
                                                    order
                                                        .billingAddress?.pincode
                                                        ?.toString(),
                                                  ]
                                                      .where((element) =>
                                                          element != null &&
                                                          element.isNotEmpty)
                                                      .join(', '),
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
                                                    'Phone',
                                                    order.billingAddress?.phone
                                                            ?.toString() ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Email',
                                                    order.billingAddress
                                                            ?.email ??
                                                        ''),
                                                buildLabelValueRow(
                                                    'Country Code',
                                                    order.billingAddress
                                                            ?.countryCode ??
                                                        ''),

                                                buildLabelValueRow(
                                                  'Pin Code',
                                                  order.shippingAddress?.pincode
                                                          ?.toString() ??
                                                      '',
                                                ),
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
                                    // Nested cards for each item in the order
                                    const SizedBox(height: 6),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: order.items.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = order.items[itemIndex];

                                        return OrderItemCard(
                                          item: item,
                                          index: itemIndex,
                                          courierName: order.courierName,
                                          orderStatus:
                                              order.orderStatus.toString(),
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
              currentPage: provider.currentPageFailed,
              totalPages: provider.totalFailedPages,
              buttonSize: 30,
              pageController: _pageController,
              onFirstPage: () {
                provider.fetchFailedOrders(page: 1);
              },
              onLastPage: () {
                provider.fetchFailedOrders(page: provider.totalFailedPages);
              },
              onNextPage: () {
                if (provider.currentPageFailed < provider.totalFailedPages) {
                  provider.fetchFailedOrders(
                      page: provider.currentPageFailed + 1);
                }
              },
              onPreviousPage: () {
                if (provider.currentPageFailed > 1) {
                  provider.fetchFailedOrders(
                      page: provider.currentPageFailed - 1);
                }
              },
              onGoToPage: (page) {
                if (page > 0 && page <= provider.totalFailedPages) {
                  provider.fetchFailedOrders(page: page);
                }
              },
              onJumpToPage: () {
                final int? page = int.tryParse(_pageController.text);

                if (page == null ||
                    page < 1 ||
                    page > provider.totalFailedPages) {
                  _showSnackbar(context,
                      'Please enter a valid page number between 1 and ${provider.totalFailedPages}.');
                  return;
                }

                provider.fetchFailedOrders(page: page);
                _pageController.clear();
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
      Flexible(
        child: Text(
          value ?? '',
          softWrap: true,
          maxLines: null,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ),
    ],
  );
}

/// ----------------------------------shippingadressedit ----------------------------------//

class EditShippingAddressDialog extends StatefulWidget {
  final Order order;

  const EditShippingAddressDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditShippingAddressDialogState createState() =>
      _EditShippingAddressDialogState();
}

class _EditShippingAddressDialogState extends State<EditShippingAddressDialog> {
  late TextEditingController _shippingFirstNameController;
  late TextEditingController _shippingLastNameController;
  late TextEditingController _shippingEmailController;
  late TextEditingController _shippingAddress1Controller;
  late TextEditingController _shippingAddress2Controller;
  late TextEditingController _shippingCityController;
  late TextEditingController _shippingStateController;
  late TextEditingController _shippingCountryController;
  late TextEditingController _shippingPhoneController;
  late TextEditingController _shippingPincodeController;
  late TextEditingController _shippingCountryCodeController;

  final List<Map<String, dynamic>> dynamicItemsList = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _amountControllers = [];
  final _formKey = GlobalKey<FormState>();
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    final shippingAddress = widget.order.shippingAddress;
    _shippingFirstNameController =
        TextEditingController(text: shippingAddress?.firstName ?? '');
    _shippingLastNameController =
        TextEditingController(text: shippingAddress?.lastName ?? '');
    _shippingEmailController =
        TextEditingController(text: shippingAddress?.email ?? '');
    _shippingAddress1Controller =
        TextEditingController(text: shippingAddress?.address1 ?? '');
    _shippingAddress2Controller =
        TextEditingController(text: shippingAddress?.address2 ?? '');
    _shippingCityController =
        TextEditingController(text: shippingAddress?.city ?? '');
    _shippingStateController =
        TextEditingController(text: shippingAddress?.state ?? '');
    _shippingCountryController =
        TextEditingController(text: shippingAddress?.country ?? '');
    _shippingPhoneController = TextEditingController(
        text: widget.order.shippingAddress?.phone?.toString() ?? '');
    _shippingPincodeController = TextEditingController(
        text: widget.order.shippingAddress?.pincode?.toString() ?? '');
    _shippingCountryCodeController =
        TextEditingController(text: shippingAddress?.countryCode ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingEmailController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingCountryController.dispose();
    _shippingPhoneController.dispose();
    _shippingPincodeController.dispose();
    _shippingCountryCodeController.dispose();
    super.dispose();
  }

  void _clearFields() {
    // Clear shipping address
    _shippingFirstNameController.clear();
    _shippingLastNameController.clear();
    _shippingEmailController.clear();
    _shippingAddress1Controller.clear();
    _shippingAddress2Controller.clear();
    _shippingPhoneController.clear();
    _shippingCityController.clear();
    _shippingPincodeController.clear();
    _shippingStateController.clear();
    _shippingCountryController.clear();
    _shippingCountryCodeController.clear();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingOrder = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "shipping_addr": {
          "first_name": _shippingFirstNameController.text,
          "last_name": _shippingLastNameController.text,
          "email": _shippingEmailController.text,
          "address1": _shippingAddress1Controller.text,
          "address2": _shippingAddress2Controller.text,
          "phone": _shippingPhoneController.text,
          "city": _shippingCityController.text,
          "pincode": _shippingPincodeController.text,
          "state": _shippingStateController.text,
          "country": _shippingCountryController.text,
          "country_code": _shippingCountryCodeController.text,
        },
        'items': dynamicItemsList.map((item) {
          int index = dynamicItemsList.indexOf(item);
          return {
            'product_id': item['product_id'],
            'qty': int.tryParse(_quantityControllers[index].text) ?? 1,
            'sku': item['sku'],
            'amount': double.tryParse(_amountControllers[index].text) ?? 0.0,
          };
        }).toList(),
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('shipping address Updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order.')),
        );
      } finally {
        setState(() {
          _isSavingOrder = false;
        });
      }
    } else {
      setState(() {
        _isSavingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Shipping Address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Build input fields
              _buildTextField(
                controller: _shippingFirstNameController,
                label: 'First Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _shippingLastNameController,
                label: 'Last Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _shippingEmailController,
                label: 'Email',
                icon: Icons.email,
              ),
              // Add other fields similarly

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingAddress1Controller,
                      label: 'Address 1',
                      icon: Icons.location_on,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingAddress2Controller,
                      label: 'Address 2',
                      icon: Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingCityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingStateController,
                      label: 'State',
                      icon: Icons.map,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingCountryController,
                      label: 'Country',
                      icon: Icons.public,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _buildTextField(
                    controller: _shippingPhoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _shippingPincodeController,
                    label: 'Pincode',
                    icon: Icons.code,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _shippingCountryCodeController,
                    label: 'Country Code',
                    icon: Icons.travel_explore,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(AppColors.orange),
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12.0)),
                ),
                onPressed: _saveChanges,
                child: _isSavingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------billingaddressedit  -------------------------------------//

class EditBillingAddressDialog extends StatefulWidget {
  final Order order;

  const EditBillingAddressDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditBillingAddressDialogState createState() =>
      _EditBillingAddressDialogState();
}

class _EditBillingAddressDialogState extends State<EditBillingAddressDialog> {
  late TextEditingController _billingFirstNameController;
  late TextEditingController _billingLastNameController;
  late TextEditingController _billingEmailController;
  late TextEditingController _billingAddress1Controller;
  late TextEditingController _billingAddress2Controller;
  late TextEditingController _billingCityController;
  late TextEditingController _billingStateController;
  late TextEditingController _billingCountryController;
  late TextEditingController _billingPhoneController;
  late TextEditingController _billingPincodeController;
  late TextEditingController _billingCountryCodeController;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();

    final billingAddress = widget.order.billingAddress;
    // Initialize billing address controllers
    _billingFirstNameController = TextEditingController(
        text: widget.order.billingAddress?.firstName ?? '');
    _billingLastNameController = TextEditingController(
        text: widget.order.billingAddress?.lastName ?? '');
    _billingEmailController =
        TextEditingController(text: widget.order.billingAddress?.email ?? '');
    _billingAddress1Controller = TextEditingController(
        text: widget.order.billingAddress?.address1 ?? '');
    _billingAddress2Controller = TextEditingController(
        text: widget.order.billingAddress?.address2 ?? '');
    _billingPhoneController = TextEditingController(
        text: widget.order.billingAddress?.phone?.toString() ?? '');
    _billingCityController =
        TextEditingController(text: widget.order.billingAddress?.city ?? '');
    _billingPincodeController = TextEditingController(
        text: widget.order.billingAddress?.pincode?.toString() ?? '');
    _billingStateController =
        TextEditingController(text: widget.order.billingAddress?.state ?? '');
    _billingCountryController =
        TextEditingController(text: widget.order.billingAddress?.country ?? '');
    _billingCountryCodeController = TextEditingController(
        text: widget.order.billingAddress?.countryCode ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingEmailController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingCountryController.dispose();
    _billingPhoneController.dispose();
    _billingPincodeController.dispose();
    _billingCountryCodeController.dispose();
    super.dispose();
  }

  void _clearFields() {
    // Clear billing address
    _billingFirstNameController.clear();
    _billingLastNameController.clear();
    _billingEmailController.clear();
    _billingAddress1Controller.clear();
    _billingAddress2Controller.clear();
    _billingPhoneController.clear();
    _billingCityController.clear();
    _billingPincodeController.clear();
    _billingStateController.clear();
    _billingCountryController.clear();
    _billingCountryCodeController.clear();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingOrder = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "billing_addr": {
          "first_name": _billingFirstNameController.text,
          "last_name": _billingLastNameController.text,
          "email": _billingEmailController.text,
          "address1": _billingAddress1Controller.text,
          "address2": _billingAddress2Controller.text,
          "phone": _billingPhoneController.text,
          "city": _billingCityController.text,
          "pincode": _billingPincodeController.text,
          "state": _billingStateController.text,
          "country": _billingCountryController.text,
          "country_code": _billingCountryCodeController.text,
        },
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Billing address updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update billing address.')),
        );
      } finally {
        setState(() {
          _isSavingOrder = false;
        });
      }
    } else {
      setState(() {
        _isSavingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Billing Address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _billingFirstNameController,
                label: 'First Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _billingLastNameController,
                label: 'Last Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _billingEmailController,
                label: 'Email',
                icon: Icons.email,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingAddress1Controller,
                      label: 'Address 1',
                      icon: Icons.location_on,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingAddress2Controller,
                      label: 'Address 2',
                      icon: Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingCityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingStateController,
                      label: 'State',
                      icon: Icons.map,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingCountryController,
                      label: 'Country',
                      icon: Icons.public,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingPhoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingPincodeController,
                      label: 'Pincode',
                      icon: Icons.code,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingCountryCodeController,
                      label: 'Country Code',
                      icon: Icons.travel_explore,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: _saveChanges,
                child: _isSavingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------ContactDetailsedit  -------------------------------------//

class EditContactDialog extends StatefulWidget {
  final Order order;

  const EditContactDialog({Key? key, required this.order}) : super(key: key);

  @override
  _EditContactDialogState createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<EditContactDialog> {
  // Controllers for customer
  late TextEditingController _customerIdController;
  late TextEditingController _customerFirstNameController;
  late TextEditingController _customerLastNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerGstinController;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();

    // Initialize billing address controllers
    _customerIdController =
        TextEditingController(text: widget.order.customer?.customerId ?? '');
    _customerFirstNameController =
        TextEditingController(text: widget.order.customer?.firstName ?? '');
    _customerLastNameController =
        TextEditingController(text: widget.order.customer?.lastName ?? '');
    _customerEmailController =
        TextEditingController(text: widget.order.customer?.email ?? '');
    _customerPhoneController = TextEditingController(
        text: widget.order.customer?.phone?.toString() ?? '');
    _customerGstinController =
        TextEditingController(text: widget.order.customer?.customerGstin ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    _customerIdController.dispose();
    _customerFirstNameController.dispose();
    _customerLastNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerGstinController.dispose();
    super.dispose();
  }

  void _clearFields() {
    // Clear customer details
    _customerIdController.clear();
    _customerFirstNameController.clear();
    _customerLastNameController.clear();
    _customerEmailController.clear();
    _customerPhoneController.clear();
    _customerGstinController.clear();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingOrder = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "customer": {
          'customer_id': _customerIdController.text,
          'first_name': _customerFirstNameController.text,
          'last_name': _customerLastNameController.text,
          'phone': _customerPhoneController.text,
          'email': _customerEmailController.text,
          'customer_gstin': _customerGstinController.text
        },
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Contact address updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update billing address.')),
        );
      } finally {
        setState(() {
          _isSavingOrder = false;
        });
      }
    } else {
      setState(() {
        _isSavingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Contact Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _customerIdController,
                      label: 'Customer ID',
                      icon: Icons.perm_identity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _customerEmailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _customerFirstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _customerLastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _customerPhoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _customerGstinController,
                      label: 'Customer GSTin',
                      icon: Icons.business,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: _saveChanges,
                child: _isSavingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------orderDetailsedit  -------------------------------------//
class EditOrderDetailsDialog extends StatefulWidget {
  final Order order;

  const EditOrderDetailsDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditOrderDetailsDialogState createState() => _EditOrderDetailsDialogState();
}

class _EditOrderDetailsDialogState extends State<EditOrderDetailsDialog> {
  final List<Map<String, dynamic>> dynamicItemsList = [];
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _amountControllers = [];

  late TextEditingController _orderTypeController;
  late TextEditingController _marketplaceController;
  late TextEditingController _filterController;
  late TextEditingController _transactionNumberController;
  late TextEditingController _microDealerOrderController;
  late TextEditingController _fulfillmentTypeController;
  late TextEditingController _calcEntryNumberController;
  late TextEditingController _orderIdController;

  late OrdersProvider _ordersProvider;

  bool _isSavingInfo = false;

  @override
  void initState() {
    super.initState();
    _ordersProvider = OrdersProvider();

    // Initialize controllers with widget.order values
    _initializeControllers();
    _ordersProvider.setInitialMarketplace(_marketplaceController.text);
    _ordersProvider.setInitialFilter(_filterController.text);
  }

  void _initializeControllers() {
    _orderIdController = TextEditingController(text: widget.order.orderId);
    _transactionNumberController =
        TextEditingController(text: widget.order.transactionNumber ?? '');
    _microDealerOrderController =
        TextEditingController(text: widget.order.microDealerOrder ?? '');
    _fulfillmentTypeController =
        TextEditingController(text: widget.order.fulfillmentType ?? '');
    _orderTypeController =
        TextEditingController(text: widget.order.orderType ?? '');
    _marketplaceController = TextEditingController(
        text: widget.order.marketplace?.name?.toString() ?? '');
    _filterController = TextEditingController(text: widget.order.filter ?? '');
    _calcEntryNumberController =
        TextEditingController(text: widget.order.calcEntryNumber ?? '');
  }

  @override
  void dispose() {
    // Dispose all controllers
    _transactionNumberController.dispose();
    _microDealerOrderController.dispose();
    _fulfillmentTypeController.dispose();
    _orderTypeController.dispose();
    _marketplaceController.dispose();
    _filterController.dispose();
    _calcEntryNumberController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingInfo = true;
    });

    // Prepare the items list for the update
    List<Map<String, dynamic>> itemsList = dynamicItemsList.map((item) {
      int index = dynamicItemsList.indexOf(item);
      double amount = double.tryParse(_amountControllers[index].text) ?? 0.0;
      int qty = int.tryParse(_quantityControllers[index].text) ?? 1;
      return {
        'product_id': item['product_id'],
        'qty': qty,
        'sku': item['sku'],
        'amount': amount,
      };
    }).toList();

    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updatedData = {
        'order_id': _orderIdController.text,
        'order_type': _orderTypeController.text,
        'name': _marketplaceController.text,
        'filter':
            _filterController.text.isNotEmpty ? _filterController.text : null,
        'transaction_number': _transactionNumberController.text,
        'micro_dealer_order': _microDealerOrderController.text,
        'fulfillment_type': _fulfillmentTypeController.text,
        'calc_entry_number': _calcEntryNumberController.text,
      };

      try {
        await _ordersProvider.updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order updated successfully!')));
        _ordersProvider.fetchReadyOrders();
        _ordersProvider.fetchFailedOrders();
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update order.')));
      } finally {
        setState(() {
          _isSavingInfo = false;
        });
      }
    } else {
      setState(() {
        _isSavingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Order Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                  controller: _orderTypeController,
                  label: 'Order Type',
                  icon: Icons.shopping_cart),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChangeNotifierProvider.value(
                      value: _ordersProvider,
                      child: Consumer<OrdersProvider>(
                          builder: (context, ordersProvider, child) {
                        final String? selectedMarketplace =
                            ordersProvider.selectedMarketplace;
                        final bool isCustomMarketplace =
                            selectedMarketplace != null &&
                                selectedMarketplace.isNotEmpty &&
                                selectedMarketplace != 'Shopify' &&
                                selectedMarketplace != 'Woocommerce' &&
                                selectedMarketplace != 'Offline';

                        final List<DropdownMenuItem<String>> items = [
                          const DropdownMenuItem<String>(
                              value: 'Shopify', child: Text('Shopify')),
                          const DropdownMenuItem<String>(
                              value: 'Woocommerce', child: Text('Woocommerce')),
                          const DropdownMenuItem<String>(
                              value: 'Offline', child: Text('Offline')),
                        ];

                        if (isCustomMarketplace) {
                          items.add(DropdownMenuItem<String>(
                              value: selectedMarketplace,
                              child: Text(selectedMarketplace)));
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedMarketplace,
                          decoration: const InputDecoration(
                            labelText: 'Marketplace',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Marketplace'),
                          items: items,
                          onChanged: (value) {
                            if (value != null) {
                              ordersProvider.selectMarketplace(value);
                              _marketplaceController.text =
                                  value; // Update the marketplace controller
                            }
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                        controller: _microDealerOrderController,
                        label: 'Micro Dealer Order',
                        icon: Icons.shopping_cart),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                        controller: _fulfillmentTypeController,
                        label: 'Fulfillment Type',
                        icon: Icons.assignment),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        controller: _transactionNumberController,
                        label: 'Transaction Number',
                        icon: Icons.confirmation_number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                        controller: _calcEntryNumberController,
                        label: 'Calculation Entry Number',
                        icon: Icons.calculate),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChangeNotifierProvider.value(
                      value: _ordersProvider,
                      child: Consumer<OrdersProvider>(
                          builder: (context, ordersProvider, child) {
                        final String? selectedFilter =
                            ordersProvider.selectedFilter;

                        final List<DropdownMenuItem<String>> items = [
                          const DropdownMenuItem<String>(
                              value: 'B2B', child: Text('B2B')),
                          const DropdownMenuItem<String>(
                              value: 'B2C', child: Text('B2C')),
                        ];

                        if (selectedFilter != null &&
                            selectedFilter.isNotEmpty &&
                            selectedFilter != 'B2B' &&
                            selectedFilter != 'B2C') {
                          items.add(DropdownMenuItem<String>(
                              value: selectedFilter,
                              child: Text(selectedFilter)));
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter',
                            prefixIcon: Icon(Icons.filter_1),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Filter'),
                          items: items,
                          onChanged: (value) {
                            ordersProvider.selectFilter(value);
                            _filterController.text = value ?? '';
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: _isSavingInfo
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------additional_details_edit  -------------------------------------//
class EditAdditionalInfoDialog extends StatefulWidget {
  final Order order;

  const EditAdditionalInfoDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditAdditionalInfoDialogState createState() =>
      _EditAdditionalInfoDialogState();
}

class _EditAdditionalInfoDialogState extends State<EditAdditionalInfoDialog> {
  // Controllers for additional information
  late TextEditingController _agentController;
  late TextEditingController _notesController;
  late TextEditingController _coinController;
  late TextEditingController _taxPercentController;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingInfo = false;

  @override
  void initState() {
    super.initState();

    _agentController = TextEditingController(text: widget.order.agent ?? '');
    _notesController = TextEditingController(text: widget.order.notes ?? '');
    _coinController =
        TextEditingController(text: widget.order.coin?.toString() ?? '0');
    _taxPercentController =
        TextEditingController(text: widget.order.taxPercent?.toString() ?? '0');
  }

  @override
  void dispose() {
    _agentController.dispose();
    _notesController.dispose();
    _coinController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingInfo = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "agent": _agentController.text,
        "notes": _notesController.text,
        "coin": int.tryParse(_coinController.text) ?? 0,
        "tax_percent": double.tryParse(_taxPercentController.text) ?? 0.0,
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Additional information updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update additional information.')),
        );
      } finally {
        setState(() {
          _isSavingInfo = false;
        });
      }
    } else {
      setState(() {
        _isSavingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Additional Information'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildTextField(
                controller: _agentController,
                label: 'Agent',
                icon: Icons.person,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                icon: Icons.note,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _coinController,
                      label: 'Coin',
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _taxPercentController,
                      label: 'Tax Percent',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: _saveChanges,
                child: _isSavingInfo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------Discount_details_edit  -------------------------------------//

class EditDiscountDialog extends StatefulWidget {
  final Order order;

  const EditDiscountDialog({Key? key, required this.order}) : super(key: key);

  @override
  _EditDiscountDialogState createState() => _EditDiscountDialogState();
}

class _EditDiscountDialogState extends State<EditDiscountDialog> {
  // Controllers for discount fields
  late TextEditingController _discountAmountController;
  late TextEditingController _discountSchemeController;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingDiscount = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing order data
    _discountAmountController = TextEditingController(
        text: widget.order.discountAmount?.toString() ?? '0');
    _discountSchemeController =
        TextEditingController(text: widget.order.discountScheme ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    _discountAmountController.dispose();
    _discountSchemeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingDiscount = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "discount_amount":
            double.tryParse(_discountAmountController.text) ?? 0.0,
        "discount_scheme": _discountSchemeController.text,
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Discount details updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update discount details.')),
        );
      } finally {
        setState(() {
          _isSavingDiscount = false;
        });
      }
    } else {
      setState(() {
        _isSavingDiscount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Discount Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildTextField(
                controller: _discountAmountController,
                label: 'Discount Amount',
                icon: Icons.money_off,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _discountSchemeController,
                label: 'Discount Scheme',
                icon: Icons.card_giftcard,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: _saveChanges,
                child: _isSavingDiscount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      // Remove the required validation here
      validator: (value) {
        if (value != null && value.isEmpty) {
          return null; // Allow empty values
        }
        return null;
      },
    );
  }
}

//-------------------------EditDimensionsDialog   -------------------------------------//

class EditDimensionsDialog extends StatefulWidget {
  final Order order;

  const EditDimensionsDialog({Key? key, required this.order}) : super(key: key);

  @override
  _EditDimensionsDialogState createState() => _EditDimensionsDialogState();
}

class _EditDimensionsDialogState extends State<EditDimensionsDialog> {
  late TextEditingController _lengthController;
  late TextEditingController _breadthController;
  late TextEditingController _heightController;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingDimensions = false;

  @override
  void initState() {
    super.initState();
    _lengthController =
        TextEditingController(text: widget.order.length?.toString() ?? '');
    _breadthController =
        TextEditingController(text: widget.order.breadth?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.order.height?.toString() ?? '');
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _breadthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSavingDimensions = true);

      Map<String, dynamic> updatedDimensions = {
        'length': _lengthController.text,
        'breadth': _breadthController.text,
        'height': _heightController.text,
      };

      try {
        // Update the order dimensions in the backend or provider
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, {"dimensions": updatedDimensions});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dimensions updated successfully!')),
        );

        // Pass the updated dimensions back to the parent widget
        Navigator.of(context).pop(updatedDimensions);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update dimensions.')),
        );
      } finally {
        setState(() => _isSavingDimensions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Dimensions'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lengthController,
                      label: 'Length',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _breadthController,
                      label: 'Breadth',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height',
                      icon: Icons.height,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(), // Close dialog without saving
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSavingDimensions ? null : _saveChanges,
          child: _isSavingDimensions
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}

//-------------------------EditOrderSpecificationDialog   -------------------------------------//

class EditOrderSpecificationDialog extends StatefulWidget {
  final Order order;

  const EditOrderSpecificationDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditOrderSpecificationDialogState createState() =>
      _EditOrderSpecificationDialogState();
}

class _EditOrderSpecificationDialogState
    extends State<EditOrderSpecificationDialog> {
  // Controllers for order specification fields
  late TextEditingController _numberOfBoxesController;
  late TextEditingController _totalQuantityController;
  late TextEditingController _skuQtyController;
  final _formKey = GlobalKey<FormState>();
  bool _isSavingInfo = false;

  @override
  void initState() {
    super.initState();

    _numberOfBoxesController = TextEditingController(
        text: widget.order.numberOfBoxes?.toString() ?? '');
    _totalQuantityController = TextEditingController(
        text: widget.order.totalQuantity?.toString() ?? '');
    _skuQtyController =
        TextEditingController(text: widget.order.skuQty?.toString() ?? '');
  }

  @override
  void dispose() {
    _totalQuantityController.dispose();
    _numberOfBoxesController.dispose();
    _skuQtyController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingInfo = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "total_quantity": int.tryParse(_totalQuantityController.text) ?? 0,
        "num_of_boxes": int.tryParse(_numberOfBoxesController.text) ?? 0,
        "sku_quantity": int.tryParse(_skuQtyController.text) ?? 0,
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order specifications updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update order specifications.')),
        );
      } finally {
        setState(() {
          _isSavingInfo = false;
        });
      }
    } else {
      setState(() {
        _isSavingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Order Specifications'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildTextField(
                controller: _totalQuantityController,
                label: 'Total Quantity',
                icon: Icons.add_shopping_cart,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _numberOfBoxesController,
                label: 'Number of Boxes',
                icon: Icons.cake, // Adjust the icon as needed
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _skuQtyController,
                label: 'SKU Quantity',
                icon: Icons.view_comfortable, // Adjust the icon as needed
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: _saveChanges,
                child: _isSavingInfo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------EditDeliveryDetailsDialog   -------------------------------------//

class EditDeliveryDetailsDialog extends StatefulWidget {
  final Order order;

  const EditDeliveryDetailsDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditDeliveryDetailsDialogState createState() =>
      _EditDeliveryDetailsDialogState();
}

class _EditDeliveryDetailsDialogState extends State<EditDeliveryDetailsDialog> {
  // Controllers for delivery details fields
  late TextEditingController _courierNameController;
  late TextEditingController _trackingStatusController;
  late TextEditingController _preferredCourierController;
  late TextEditingController _deliveryTermController;
  late TextEditingController _expectedDeliveryDateController;
  late OrdersProvider _ordersProvider;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingInfo = false;

  @override
  void initState() {
    super.initState();

    _courierNameController =
        TextEditingController(text: widget.order.courierName ?? '');
    _trackingStatusController =
        TextEditingController(text: widget.order.trackingStatus ?? '');
    _preferredCourierController =
        TextEditingController(text: widget.order.preferredCourier ?? '');
    _deliveryTermController =
        TextEditingController(text: widget.order.deliveryTerm ?? '');
    _expectedDeliveryDateController = TextEditingController(
        text: widget.order.expectedDeliveryDate != null
            ? _ordersProvider.formatDate(widget.order.expectedDeliveryDate!)
            : '');
  }

  @override
  void dispose() {
    _courierNameController.dispose();
    _trackingStatusController.dispose();
    _preferredCourierController.dispose();
    _deliveryTermController.dispose();
    _expectedDeliveryDateController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingInfo = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "courier_name": _courierNameController.text,
        "tracking_status": _trackingStatusController.text,
        "preferred_courier": _preferredCourierController.text,
        "delivery_term": _deliveryTermController.text,
        "delivery_date": _expectedDeliveryDateController
            .text, // Adjust if date needs parsing
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Delivery details updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update delivery details.')),
        );
      } finally {
        setState(() {
          _isSavingInfo = false;
        });
      }
    } else {
      setState(() {
        _isSavingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Delivery Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildTextField(
                controller: _courierNameController,
                label: 'Courier Name',
                icon: Icons.local_shipping,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _trackingStatusController,
                label: 'Tracking Status',
                icon: Icons.track_changes,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _preferredCourierController,
                label: 'Preferred Courier',
                icon: Icons.business,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _deliveryTermController,
                label: 'Delivery Term',
                icon: Icons.event_note,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _expectedDeliveryDateController,
                label: 'Delivery Date',
                icon: Icons.date_range,
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
                onPressed: _saveChanges,
                child: _isSavingInfo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

//-------------------------EditPaymentDetailsDialog   -------------------------------------//

class EditPaymentDetailsDialog extends StatefulWidget {
  final Order order;

  const EditPaymentDetailsDialog({Key? key, required this.order})
      : super(key: key);

  @override
  _EditPaymentDetailsDialogState createState() =>
      _EditPaymentDetailsDialogState();
}

class _EditPaymentDetailsDialogState extends State<EditPaymentDetailsDialog> {
  // Controllers for payment details fields
  late TextEditingController _paymentModeController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _currencyController;
  late TextEditingController _codAmountController;
  late TextEditingController _prepaidAmountController;
  late TextEditingController _paymentBankController;
  late TextEditingController _paymentDateTimeController;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingInfo = false;

  @override
  void initState() {
    super.initState();

    _paymentModeController =
        TextEditingController(text: widget.order.paymentMode ?? '');
    _currencyCodeController =
        TextEditingController(text: widget.order.currencyCode ?? '');
    _currencyController =
        TextEditingController(text: widget.order.currency ?? '');
    _codAmountController =
        TextEditingController(text: widget.order.codAmount?.toString() ?? '0');
    _prepaidAmountController = TextEditingController(
        text: widget.order.prepaidAmount?.toString() ?? '0');
    _paymentBankController =
        TextEditingController(text: widget.order.paymentBank ?? '');
    _paymentDateTimeController = TextEditingController(
        text: widget.order.paymentDateTime?.toString() ?? '');
  }

  @override
  void dispose() {
    _paymentModeController.dispose();
    _currencyCodeController.dispose();
    _currencyController.dispose();
    _codAmountController.dispose();
    _prepaidAmountController.dispose();
    _paymentBankController.dispose();
    _paymentDateTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingInfo = true;
    });

    if (_formKey.currentState!.validate()) {
      // Prepare updated data
      Map<String, dynamic> updatedData = {
        "payment_mode": _paymentModeController.text,
        "currency_code": _currencyCodeController.text,
        "currency": _currencyController.text,
        "cod_amount": double.tryParse(_codAmountController.text) ?? 0.0,
        "prepaid_amount": double.tryParse(_prepaidAmountController.text) ?? 0.0,
        "payment_bank": _paymentBankController.text,
        "payment_date_time":
            _paymentDateTimeController.text, // Adjust if date parsing is needed
      };

      try {
        // Call API or provider update
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment details updated successfully!')));
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update payment details.')));
      } finally {
        setState(() {
          _isSavingInfo = false;
        });
      }
    } else {
      setState(() {
        _isSavingInfo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Payment Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildPaymentModeDropdown(),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _currencyCodeController,
                  label: 'Currency Code',
                  icon: Icons.monetization_on),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _currencyController,
                  label: 'Currency',
                  icon: Icons.attach_money),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _codAmountController,
                  label: 'COD Amount',
                  icon: Icons.money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _prepaidAmountController,
                  label: 'Prepaid Amount',
                  icon: Icons.money_off,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _paymentBankController,
                  label: 'Payment Bank',
                  icon: Icons.account_balance),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _paymentDateTimeController,
                  label: 'Payment Date Time',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.datetime),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.grey),
                  padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12.0)),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Back',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.orange),
                  padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12.0)),
                ),
                onPressed: _saveChanges,
                child: _isSavingInfo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModeDropdown() {
    return DropdownButtonFormField<String>(
      value: _paymentModeController.text.isEmpty
          ? null
          : _paymentModeController.text,
      decoration: const InputDecoration(
        labelText: 'Payment Mode',
        prefixIcon: Icon(Icons.payment),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: 'PrePaid', child: Text('PrePaid')),
        const DropdownMenuItem(value: 'COD', child: Text('COD')),
        // You can add more options here if necessary
      ],
      onChanged: (value) {
        setState(() {
          _paymentModeController.text = value!;
        });
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
