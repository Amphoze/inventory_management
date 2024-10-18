import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_order_page.dart';
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
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _tabController.addListener(() {
      // Reload data when the tab changes
      if (_tabController.indexIsChanging) {
        _reloadOrders();
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  void _onSearchChanged(String searchTerm) {
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    if (_tabController.index == 0) {
      // Check if in Ready to Confirm tab
      ordersProvider.searchReadyToConfirmOrders(searchTerm);
    } else {
      // Check if in Failed Orders tab
      ordersProvider.searchFailedOrders(searchTerm);
    }
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
      title: _buildSearchBar(),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Handle filter action
          },
          color: Colors.black,
        ),
        _buildSortDropdown(),
        const SizedBox(width: 10),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 200,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color.fromARGB(183, 6, 90, 216),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search Orders',
            hintStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: 'Sort by',
      items: const [
        DropdownMenuItem(value: 'Sort by', child: Text('Sort by')),
        DropdownMenuItem(value: 'Date', child: Text('Date')),
        DropdownMenuItem(value: 'Amount', child: Text('Amount')),
      ],
      onChanged: (value) {
        // Handle sorting logic
      },
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
          return const Center(child: OrdersLoadingAnimation());
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
                      onPressed: () async {
                        // Get the provider instance
                        final provider =
                            Provider.of<OrdersProvider>(context, listen: false);

                        // Collect selected order IDs
                        List<String> selectedOrderIds = provider.readyOrders
                            .asMap()
                            .entries
                            .where((entry) => provider.selectedReadyOrders[
                                entry.key]) // Filter selected orders
                            .map((entry) =>
                                entry.value.orderId!) // Map to their IDs
                            .toList();

                        if (selectedOrderIds.isEmpty) {
                          // Show an error message if no orders are selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No orders selected'),
                              backgroundColor: AppColors
                                  .cardsred, // Red background for error
                            ),
                          );
                        } else {
                          // Call confirmOrders method with selected IDs
                          String resultMessage = await provider.confirmOrders(
                              context, selectedOrderIds);

                          // Determine the background color based on the result
                          Color snackBarColor;
                          if (resultMessage.contains('success')) {
                            snackBarColor = AppColors.green; // Success: Green
                          } else if (resultMessage.contains('error') ||
                              resultMessage.contains('failed')) {
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
                      child: const Text('Confirm Orders'),
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
                        print('Ready to Confirm Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: provider.readyOrders.length,
                itemBuilder: (context, index) {
                  final order = provider.readyOrders[index];

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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Checkbox(
                                value: provider.selectedReadyOrders[index],
                                onChanged: (value) =>
                                    provider.toggleOrderSelectionReady(
                                        value ?? false, index),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order ID: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Amount: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Items: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Weight: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                      builder: (context) => EditOrderPage(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: const SizedBox(
                                    height: 50,
                                    width: 130,
                                    child: Text(
                                      'ORDER DETAILS:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildLabelValueRow('Payment Mode',
                                          order.paymentMode ?? ''),
                                      buildLabelValueRow('Currency Code',
                                          order.currencyCode ?? ''),
                                      buildLabelValueRow('COD Amount',
                                          order.codAmount?.toString() ?? ''),
                                      buildLabelValueRow(
                                          'Prepaid Amount',
                                          order.prepaidAmount?.toString() ??
                                              ''),
                                      buildLabelValueRow(
                                          'Coin', order.coin?.toString() ?? ''),
                                      buildLabelValueRow('Tax Percent',
                                          order.taxPercent?.toString() ?? ''),
                                      buildLabelValueRow('Courier Name',
                                          order.courierName ?? ''),
                                      buildLabelValueRow(
                                          'Order Type', order.orderType ?? ''),
                                      buildLabelValueRow('Payment Bank',
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
                                          order.discountAmount?.toString() ??
                                              ''),
                                      buildLabelValueRow('Discount Scheme',
                                          order.discountScheme ?? ''),
                                      buildLabelValueRow(
                                          'Agent', order.agent ?? ''),
                                      buildLabelValueRow(
                                          'Notes', order.notes ?? ''),
                                      buildLabelValueRow('Marketplace',
                                          order.marketplace?.name ?? ''),
                                      buildLabelValueRow(
                                          'Filter', order.filter ?? ''),
                                      buildLabelValueRow(
                                        'Expected Delivery Date',
                                        order.expectedDeliveryDate != null
                                            ? provider.formatDate(
                                                order.expectedDeliveryDate!)
                                            : '',
                                      ),
                                      buildLabelValueRow('Preferred Courier',
                                          order.preferredCourier ?? ''),
                                      buildLabelValueRow(
                                        'Payment Date Time',
                                        order.paymentDateTime != null
                                            ? provider.formatDateTime(
                                                order.paymentDateTime!)
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
                                      buildLabelValueRow('Delivery Term',
                                          order.deliveryTerm ?? ''),
                                      buildLabelValueRow('Transaction Number',
                                          order.transactionNumber ?? ''),
                                      buildLabelValueRow('Micro Dealer Order',
                                          order.microDealerOrder ?? ''),
                                      buildLabelValueRow('Fulfillment Type',
                                          order.fulfillmentType ?? ''),
                                      buildLabelValueRow(
                                          'No. of Boxes',
                                          order.numberOfBoxes?.toString() ??
                                              ''),
                                      buildLabelValueRow(
                                          'Total Quantity',
                                          order.totalQuantity?.toString() ??
                                              ''),
                                      buildLabelValueRow('SKU Qty',
                                          order.skuQty?.toString() ?? ''),
                                      buildLabelValueRow('Calc Entry No.',
                                          order.calcEntryNumber ?? ''),
                                      buildLabelValueRow(
                                          'Currency', order.currency ?? ''),
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
                                        '${order.length?.toString() ?? ''} x ${order.breadth?.toString() ?? ''} x ${order.height?.toString() ?? ''}',
                                      ),
                                      buildLabelValueRow('AWB No.',
                                          order.awbNumber?.toString() ?? ''),
                                      buildLabelValueRow('Tracking Status',
                                          order.trackingStatus ?? ''),
                                      buildLabelValueRow(
                                        'Customer ID',
                                        order.customer?.customerId ?? '',
                                      ),
                                      buildLabelValueRow(
                                          'Full Name',
                                          order.customer?.firstName !=
                                                  order.customer?.lastName
                                              ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'
                                                  .trim()
                                              : order.customer?.firstName ??
                                                  ''),
                                      buildLabelValueRow(
                                        'Email',
                                        order.customer?.email ?? '',
                                      ),
                                      buildLabelValueRow(
                                        'Phone',
                                        order.customer?.phone?.toString() ?? '',
                                      ),
                                      buildLabelValueRow(
                                        'GSTIN',
                                        order.customer?.customerGstin ?? '',
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
                                      const Text(
                                        'Shipping Address:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Address:',
                                            style: TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12.0),
                                          ),
                                          Flexible(
                                            child: Text(
                                              [
                                                order.shippingAddress?.address1,
                                                order.shippingAddress?.address2,
                                                order.shippingAddress?.city,
                                                order.shippingAddress?.state,
                                                order.shippingAddress?.country,
                                                order.shippingAddress?.pincode
                                                    ?.toString(),
                                              ]
                                                  .where((element) =>
                                                      element != null &&
                                                      element.isNotEmpty)
                                                  .join(', '),
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Name:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress
                                                          ?.firstName !=
                                                      order.shippingAddress
                                                          ?.lastName
                                                  ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                      .trim()
                                                  : order.shippingAddress
                                                          ?.firstName ??
                                                      '',
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Phone:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress?.phone
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress?.email ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Country Code:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress
                                                      ?.countryCode ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Text(
                                        'Billing Address:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Address:',
                                            style: TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12.0),
                                          ),
                                          Flexible(
                                            child: Text(
                                              [
                                                order.billingAddress?.address1,
                                                order.billingAddress?.address2,
                                                order.billingAddress?.city,
                                                order.billingAddress?.state,
                                                order.billingAddress?.country,
                                                order.billingAddress?.pincode
                                                    ?.toString(),
                                              ]
                                                  .where((element) =>
                                                      element != null &&
                                                      element.isNotEmpty)
                                                  .join(', '),
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Name:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress?.firstName !=
                                                      order.billingAddress
                                                          ?.lastName
                                                  ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                      .trim()
                                                  : order.billingAddress
                                                          ?.firstName ??
                                                      '',
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Phone:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress?.phone
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress?.email ?? '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Country Code:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress
                                                      ?.countryCode ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
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
                          const Divider(
                            thickness: 1,
                            color: AppColors.grey,
                          ),
                          // Nested cards for each item in the order
                          const SizedBox(height: 6),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            itemBuilder: (context, itemIndex) {
                              final item = order.items[itemIndex];

                              return OrderItemCard(
                                item: item,
                                index: itemIndex,
                                courierName: order.courierName,
                                orderStatus: order.orderStatus.toString(),
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
          return const Center(child: OrdersLoadingAnimation());
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
                      onPressed: () {
                        provider.updateFailedOrders(context);
                      },
                      child: const Text('Approve Failed Orders'),
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

                        print('Failed Orders refreshed');
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: provider.failedOrders.length,
                itemBuilder: (context, index) {
                  final order = provider.failedOrders[index];

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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Checkbox(
                                value: provider.selectedFailedOrders[index],
                                onChanged: (value) =>
                                    provider.toggleOrderSelectionFailed(
                                        value ?? false, index),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order ID: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Amount: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Items: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Weight: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                                      builder: (context) => EditOrderPage(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: const SizedBox(
                                    height: 50,
                                    width: 130,
                                    child: Text(
                                      'ORDER DETAILS:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildLabelValueRow('Payment Mode',
                                          order.paymentMode ?? ''),
                                      buildLabelValueRow('Currency Code',
                                          order.currencyCode ?? ''),
                                      buildLabelValueRow('COD Amount',
                                          order.codAmount?.toString() ?? ''),
                                      buildLabelValueRow(
                                          'Prepaid Amount',
                                          order.prepaidAmount?.toString() ??
                                              ''),
                                      buildLabelValueRow(
                                          'Coin', order.coin?.toString() ?? ''),
                                      buildLabelValueRow('Tax Percent',
                                          order.taxPercent?.toString() ?? ''),
                                      buildLabelValueRow('Courier Name',
                                          order.courierName ?? ''),
                                      buildLabelValueRow(
                                          'Order Type', order.orderType ?? ''),
                                      buildLabelValueRow('Payment Bank',
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
                                          order.discountAmount?.toString() ??
                                              ''),
                                      buildLabelValueRow('Discount Scheme',
                                          order.discountScheme ?? ''),
                                      buildLabelValueRow(
                                          'Agent', order.agent ?? ''),
                                      buildLabelValueRow(
                                          'Notes', order.notes ?? ''),
                                      buildLabelValueRow('Marketplace',
                                          order.marketplace?.name ?? ''),
                                      buildLabelValueRow(
                                          'Filter', order.filter ?? ''),
                                      buildLabelValueRow(
                                        'Expected Delivery Date',
                                        order.expectedDeliveryDate != null
                                            ? provider.formatDate(
                                                order.expectedDeliveryDate!)
                                            : '',
                                      ),
                                      buildLabelValueRow('Preferred Courier',
                                          order.preferredCourier ?? ''),
                                      buildLabelValueRow(
                                        'Payment Date Time',
                                        order.paymentDateTime != null
                                            ? provider.formatDateTime(
                                                order.paymentDateTime!)
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
                                      buildLabelValueRow('Delivery Term',
                                          order.deliveryTerm ?? ''),
                                      buildLabelValueRow('Transaction Number',
                                          order.transactionNumber ?? ''),
                                      buildLabelValueRow('Micro Dealer Order',
                                          order.microDealerOrder ?? ''),
                                      buildLabelValueRow('Fulfillment Type',
                                          order.fulfillmentType ?? ''),
                                      buildLabelValueRow(
                                          'No. of Boxes',
                                          order.numberOfBoxes?.toString() ??
                                              ''),
                                      buildLabelValueRow(
                                          'Total Quantity',
                                          order.totalQuantity?.toString() ??
                                              ''),
                                      buildLabelValueRow('SKU Qty',
                                          order.skuQty?.toString() ?? ''),
                                      buildLabelValueRow('Calc Entry No.',
                                          order.calcEntryNumber ?? ''),
                                      buildLabelValueRow(
                                          'Currency', order.currency ?? ''),
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
                                        '${order.length?.toString() ?? ''} x ${order.breadth?.toString() ?? ''} x ${order.height?.toString() ?? ''}',
                                      ),
                                      buildLabelValueRow('AWB No.',
                                          order.awbNumber?.toString() ?? ''),
                                      buildLabelValueRow('Tracking Status',
                                          order.trackingStatus ?? ''),
                                      buildLabelValueRow(
                                        'Customer ID',
                                        order.customer?.customerId ?? '',
                                      ),
                                      buildLabelValueRow(
                                          'Full Name',
                                          order.customer?.firstName !=
                                                  order.customer?.lastName
                                              ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'
                                                  .trim()
                                              : order.customer?.firstName ??
                                                  ''),
                                      buildLabelValueRow(
                                        'Email',
                                        order.customer?.email ?? '',
                                      ),
                                      buildLabelValueRow(
                                        'Phone',
                                        order.customer?.phone?.toString() ?? '',
                                      ),
                                      buildLabelValueRow(
                                        'GSTIN',
                                        order.customer?.customerGstin ?? '',
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
                                      const Text(
                                        'Shipping Address:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Address:',
                                            style: TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12.0),
                                          ),
                                          Flexible(
                                            child: Text(
                                              [
                                                order.shippingAddress?.address1,
                                                order.shippingAddress?.address2,
                                                order.shippingAddress?.city,
                                                order.shippingAddress?.state,
                                                order.shippingAddress?.country,
                                                order.shippingAddress?.pincode
                                                    ?.toString(),
                                              ]
                                                  .where((element) =>
                                                      element != null &&
                                                      element.isNotEmpty)
                                                  .join(', '),
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Name:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress
                                                          ?.firstName !=
                                                      order.shippingAddress
                                                          ?.lastName
                                                  ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                      .trim()
                                                  : order.shippingAddress
                                                          ?.firstName ??
                                                      '',
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Phone:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress?.phone
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress?.email ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Country Code:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.shippingAddress
                                                      ?.countryCode ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Text(
                                        'Billing Address:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Address:',
                                            style: TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12.0),
                                          ),
                                          Flexible(
                                            child: Text(
                                              [
                                                order.billingAddress?.address1,
                                                order.billingAddress?.address2,
                                                order.billingAddress?.city,
                                                order.billingAddress?.state,
                                                order.billingAddress?.country,
                                                order.billingAddress?.pincode
                                                    ?.toString(),
                                              ]
                                                  .where((element) =>
                                                      element != null &&
                                                      element.isNotEmpty)
                                                  .join(', '),
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                  fontSize: 12.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Name:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress?.firstName !=
                                                      order.billingAddress
                                                          ?.lastName
                                                  ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                      .trim()
                                                  : order.billingAddress
                                                          ?.firstName ??
                                                      '',
                                              softWrap: true,
                                              maxLines: 4,
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Phone:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress?.phone
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Email:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress?.email ?? '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Country Code:',
                                            style: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              order.billingAddress
                                                      ?.countryCode ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
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
                          const Divider(
                            thickness: 1,
                            color: AppColors.grey,
                          ),
                          // Nested cards for each item in the order
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            itemBuilder: (context, itemIndex) {
                              final item = order.items[itemIndex];

                              return OrderItemCard(
                                item: item,
                                index: itemIndex,
                                courierName: order.courierName,
                                orderStatus: order.orderStatus.toString(),
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
