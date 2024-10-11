import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
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
    super.dispose();
  }

  void _reloadOrders() {
    // Access the OrdersProvider and fetch orders again
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    ordersProvider.fetchOrders(); // Fetch both orders
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
        ..fetchOrders(), // Fetch orders when initializing provider
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
                            .fetchOrders();
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
                            ],
                          ),
                          const Divider(
                            thickness: 1,
                            color: AppColors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  //color: AppColors.primaryBlue,
                                  child: const SizedBox(
                                    height: 50,
                                    width: 200,
                                    child: Text(
                                      'ORDER DETAILS:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                // Container(
                                //   color: Colors.pink,
                                //   child: const SizedBox(height: 10, width: 200.0),
                                // ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Payment Mode: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.paymentMode ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'COD Amount: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.codAmount ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Prepaid Amount: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.prepaidAmount ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Discount Scheme: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.discountScheme ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Discount Percent: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.discountPercent ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Discount Amount: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.discountAmount ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Tax Percent: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.taxPercent ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Shipping Address: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.shippingAddress?.address1 ??
                                            'No address available'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row(
                                    //   children: [
                                    //     const Text(
                                    //       'Delivery: ',
                                    //       style: TextStyle(
                                    //           fontWeight: FontWeight.bold),
                                    //     ),
                                    //     Text(
                                    //         '${order.freightCharge!.delhivery ?? ''}'),
                                    //   ],
                                    // ),
                                    // const SizedBox(width: 8.0),
                                    // Row(
                                    //   children: [
                                    //     const Text(
                                    //       'Shiprocket: ',
                                    //       style: TextStyle(
                                    //           fontWeight: FontWeight.bold),
                                    //     ),
                                    //     Text(
                                    //         '${order.freightCharge!.shiprocket ?? ''}'),
                                    //   ],
                                    // ),
                                    // const SizedBox(width: 8.0),
                                    // Row(
                                    //   children: [
                                    //     const Text(
                                    //       'Standard Shipping: ',
                                    //       style: TextStyle(
                                    //           fontWeight: FontWeight.bold),
                                    //     ),
                                    //     Text(
                                    //         '${order.freightCharge!.standardShipping ?? ''}'),
                                    //   ],
                                    // ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Agent: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.agent ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Notes: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.notes ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                  ],
                                ),

                                const SizedBox(width: 20.0),
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

                              return Card(
                                color: AppColors.white,
                                elevation: 0.5,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Product ${itemIndex + 1}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 2.0),
                                          if (item.product?.shopifyImage !=
                                                  null &&
                                              item.product!.shopifyImage!
                                                  .isNotEmpty)
                                            Image.network(
                                              item.product!.shopifyImage!,
                                              key: ValueKey(
                                                  item.product!.shopifyImage),
                                              width: 140,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const SizedBox(
                                                  width: 100,
                                                  height: 100,
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 70,
                                                    color: AppColors.grey,
                                                  ),
                                                );
                                              },
                                            )
                                          else
                                            const SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Icon(
                                                Icons.image,
                                                size: 70,
                                                color: AppColors.grey,
                                              ),
                                            ),
                                          const SizedBox(height: 5.0),
                                          Container(
                                            width:
                                                370, // Set your desired width here
                                            child: Text(
                                              item.product?.displayName ??
                                                  'No Name',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(
                                                'SKU:', item.product?.sku),
                                            _buildInfoRow('Quantity:',
                                                item.qty?.toString()),
                                            _buildInfoRow('Total Amount:',
                                                'Rs.${item.amount}'),
                                            _buildInfoRow('Description:',
                                                item.product?.description),
                                            _buildInfoRow('Technical Name:',
                                                item.product?.technicalName),
                                            const Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                          'Dimensions:',
                                                          '${item.product?.dimensions?.length} x ${item.product?.dimensions?.width} x ${item.product?.dimensions?.height}'),
                                                      _buildInfoRow(
                                                          'Tax Rule:',
                                                          item.product
                                                              ?.taxRule),
                                                      _buildInfoRow('Brand:',
                                                          item.product?.brand),
                                                      _buildInfoRow('MRP:',
                                                          'Rs.${item.product?.mrp}'),
                                                      _buildInfoRow('EAN:',
                                                          'Rs.${item.product?.ean}'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                          'Product Grade:',
                                                          item.product?.grade),
                                                      _buildInfoRow(
                                                          'Parent SKU:',
                                                          item.product
                                                              ?.parentSku),
                                                      _buildInfoRow(
                                                          'Active:',
                                                          item.product?.active
                                                              ?.toString()),
                                                      _buildInfoRow(
                                                          'Courier Name:',
                                                          order.courierName),
                                                      _buildInfoRow(
                                                          'Order Status:',
                                                          '${order.orderStatus}'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                        'Net Weight:',
                                                        item.product?.netWeight !=
                                                                null
                                                            ? '${item.product!.netWeight} kg'
                                                            : 'N/A',
                                                      ),
                                                      _buildInfoRow(
                                                        'Gross Weight:',
                                                        item.product?.grossWeight !=
                                                                null
                                                            ? '${item.product!.grossWeight} kg'
                                                            : 'N/A',
                                                      ),
                                                      if (item.product
                                                                  ?.boxSize !=
                                                              null &&
                                                          item.product!.boxSize!
                                                              .isNotEmpty) ...[
                                                        _buildInfoRow(
                                                            'Box Size:',
                                                            '${item.product!.boxSize}'),
                                                      ]
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
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
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
                            .fetchOrders();
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
                            ],
                          ),
                          const Divider(
                            thickness: 1,
                            color: AppColors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  //color: AppColors.primaryBlue,
                                  child: const SizedBox(
                                    height: 50,
                                    width: 200,
                                    child: Text(
                                      'ORDER DETAILS:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                // Container(
                                //   color: Colors.pink,
                                //   child: const SizedBox(height: 10, width: 200.0),
                                // ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Payment Mode: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.paymentMode ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'COD Amount: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.codAmount ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Prepaid Amount: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.prepaidAmount ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Discount Scheme: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.discountScheme ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Discount Percent: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.discountPercent ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Discount Amount: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.discountAmount ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Tax Percent: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text('${order.taxPercent ?? ''}'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Shipping Address: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.shippingAddress?.address1 ??
                                            'No address available'),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row(
                                    //   children: [
                                    //     const Text(
                                    //       'Delivery: ',
                                    //       style:
                                    //           TextStyle(fontWeight: FontWeight.bold),
                                    //     ),
                                    //     Text(
                                    //         '${order.freightCharge!.delhivery ?? ''}'),
                                    //   ],
                                    // ),
                                    // const SizedBox(width: 8.0),
                                    // Row(
                                    //   children: [
                                    //     const Text(
                                    //       'Shiprocket: ',
                                    //       style:
                                    //           TextStyle(fontWeight: FontWeight.bold),
                                    //     ),
                                    //     Text(
                                    //         '${order.freightCharge!.shiprocket ?? ''}'),
                                    //   ],
                                    // ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Agent: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.agent ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: [
                                        const Text(
                                          'Notes: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(order.notes ?? ''),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                  ],
                                ),

                                const SizedBox(width: 20.0),
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

                              return Card(
                                color: AppColors.white,
                                elevation: 0.5,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Product ${itemIndex + 1}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 2.0),
                                          if (item.product?.shopifyImage !=
                                                  null &&
                                              item.product!.shopifyImage!
                                                  .isNotEmpty)
                                            Image.network(
                                              item.product!.shopifyImage!,
                                              key: ValueKey(
                                                  item.product!.shopifyImage),
                                              width: 140,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const SizedBox(
                                                  width: 100,
                                                  height: 100,
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 70,
                                                    color: AppColors.grey,
                                                  ),
                                                );
                                              },
                                            )
                                          else
                                            const SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Icon(
                                                Icons.image,
                                                size: 70,
                                                color: AppColors.grey,
                                              ),
                                            ),
                                          const SizedBox(height: 5.0),
                                          Container(
                                            width:
                                                370, // Set your desired width here
                                            child: Text(
                                              item.product?.displayName ??
                                                  'No Name',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(
                                                'SKU:', item.product?.sku),
                                            _buildInfoRow('Quantity:',
                                                item.qty?.toString()),
                                            _buildInfoRow('Total Amount:',
                                                'Rs.${item.amount}'),
                                            _buildInfoRow('Description:',
                                                item.product?.description),
                                            _buildInfoRow('Technical Name:',
                                                item.product?.technicalName),
                                            const Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                          'Dimensions:',
                                                          '${item.product?.dimensions?.length} x ${item.product?.dimensions?.width} x ${item.product?.dimensions?.height}'),
                                                      _buildInfoRow(
                                                          'Tax Rule:',
                                                          item.product
                                                              ?.taxRule),
                                                      _buildInfoRow('Brand:',
                                                          item.product?.brand),
                                                      _buildInfoRow('MRP:',
                                                          'Rs.${item.product?.mrp}'),
                                                      _buildInfoRow('EAN:',
                                                          'Rs.${item.product?.ean}'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                          'Product Grade:',
                                                          item.product?.grade),
                                                      _buildInfoRow(
                                                          'Parent SKU:',
                                                          item.product
                                                              ?.parentSku),
                                                      _buildInfoRow(
                                                          'Active:',
                                                          item.product?.active
                                                              ?.toString()),
                                                      _buildInfoRow(
                                                          'Courier Name:',
                                                          order.courierName),
                                                      _buildInfoRow(
                                                          'Order Status:',
                                                          '${order.orderStatus}'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                        'Net Weight:',
                                                        item.product?.netWeight !=
                                                                null
                                                            ? '${item.product!.netWeight} kg'
                                                            : 'N/A',
                                                      ),
                                                      _buildInfoRow(
                                                        'Gross Weight:',
                                                        item.product?.grossWeight !=
                                                                null
                                                            ? '${item.product!.grossWeight} kg'
                                                            : 'N/A',
                                                      ),
                                                      if (item.product
                                                                  ?.boxSize !=
                                                              null &&
                                                          item.product!.boxSize!
                                                              .isNotEmpty) ...[
                                                        _buildInfoRow(
                                                            'Box Size:',
                                                            '${item.product!.boxSize}'),
                                                      ]
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
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper method to build each info row
Widget _buildInfoRow(String label, String? value) {
  return Row(
    children: [
      Text(
        '$label ',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Flexible(
        child: Text(
          value ?? 'N/A',
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
