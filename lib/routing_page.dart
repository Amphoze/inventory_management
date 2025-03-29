import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/order_info.dart';
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

class _RoutingPageState extends State<RoutingPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late TextEditingController _searchControllerReady;
  late TextEditingController _searchControllerFailed;
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController pageController = TextEditingController();
  String _selectedDate = 'Select Date';
  String selectedCourier = 'All';
  DateTime? picked;

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
        _searchController.clear();
        _searchControllerReady.clear();
        _searchControllerFailed.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceProvider>().fetchMarketplaces();
      _reloadOrders();
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

  void resetFilters() {
    setState(() {
      _selectedDate = 'Select Date';
      selectedCourier = 'All';
      picked = null;
    });
  }

  void _reloadOrders() {
    final ordersProvider = Provider.of<RoutingProvider>(context, listen: false);
    ordersProvider.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: _buildAppBar(),
      body: Consumer<RoutingProvider>(
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
                              color: _selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                            ),
                          ),
                          // Tooltip(
                          //   message: 'Filter by Date',
                          //   child: IconButton(
                          //     onPressed: () async {
                          //       picked = await showDatePicker(
                          //         context: context,
                          //         initialDate: DateTime.now(),
                          //         firstDate: DateTime(2020),
                          //         lastDate: DateTime.now(),
                          //         builder: (context, child) {
                          //           return Theme(
                          //             data: Theme.of(context).copyWith(
                          //               colorScheme: const ColorScheme.light(
                          //                 primary: AppColors.primaryBlue,
                          //                 onPrimary: Colors.white,
                          //                 surface: Colors.white,
                          //                 onSurface: Colors.black,
                          //               ),
                          //             ),
                          //             child: child!,
                          //           );
                          //         },
                          //       );
                          //
                          //       if (picked != null) {
                          //         String formattedDate = DateFormat('dd-MM-yyyy').format(picked!);
                          //         setState(() {
                          //           _selectedDate = formattedDate;
                          //         });
                          //
                          //         pro.fetchOrders(date: picked, market: selectedCourier);
                          //       }
                          //     },
                          //     icon: const Icon(
                          //       Icons.calendar_today,
                          //       size: 30,
                          //       color: AppColors.primaryBlue,
                          //     ),
                          //   ),
                          // ),
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

                                  log("value: $value");
                                  log("selectedCourier: $selectedCourier");
                                  log("selectedDate: $_selectedDate");
                                  pro.fetchOrders(
                                    page: pro.currentPageReady,
                                    date: picked,
                                    market: selectedCourier,
                                  );
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
                        onPressed: pro.isConfirm
                            ? null // Disable button while loading
                            : () async {
                                final provider = Provider.of<RoutingProvider>(context, listen: false);

                                // Collect selected order IDs
                                List<String> selectedOrderIds = provider.readyOrders
                                    .asMap()
                                    .entries
                                    .where((entry) => provider.selectedOrders[entry.key])
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
                                  String resultMessage = await provider.routeOrders(context, selectedOrderIds);

                                  log('resultMessage: $resultMessage');

                                  // Set loading status to false after operation completes
                                  // provider.setConfirmStatus(false);

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
                                'Route',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade300,
                        ),
                        onPressed: () async {
                          resetFilters();
                          Provider.of<RoutingProvider>(context, listen: false).fetchOrders();
                          Provider.of<RoutingProvider>(context, listen: false).resetSelections();
                          // pro.clearSearchResults();
                        },
                        child: const Text('Reset Filters'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            pro.fetchOrders(
                              page: pro.currentPageReady,
                              date: picked,
                              market: selectedCourier,
                            );
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primaryBlue,
                          )),
                      const SizedBox(width: 8),
                      Container(
                        width: 200,
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
                                controller: _searchControllerReady,
                                decoration: const InputDecoration(
                                  hintText: 'Search Orders',
                                  hintStyle: TextStyle(
                                    color: Color.fromRGBO(117, 117, 117, 1),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                ),
                                style: const TextStyle(color: AppColors.black),
                                onSubmitted: (value) {
                                  if (value.isEmpty) {
                                    pro.fetchOrders();
                                  } else {
                                    pro.searchOrders(value);
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
                            if (_searchControllerReady.text.isNotEmpty)
                              InkWell(
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey.shade600,
                                ),
                                onTap: () {
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
                              //////////////////////////////////////////////////////////
                              return Card(
                                surfaceTintColor: Colors.white,
                                color: pro.selectedOrders[index] ? Colors.grey[300] : Colors.grey[100],
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
                                            value: pro.selectedOrders[index],
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
                                                '${order.totalWeight ?? ''}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        thickness: 1,
                                        color: AppColors.grey,
                                      ),
                                      OrderInfo(order: order, pro: pro),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text.rich(
                                          TextSpan(
                                            text: "Hold: ",
                                            children: [
                                              TextSpan(
                                                text: order.isHold.toString() ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
      ),
    );
  }

  // AppBar _buildAppBar() {
  //   return AppBar(
  //     backgroundColor: Colors.white,
  //     elevation: 0,
  //     toolbarHeight: 0, // Removes space above the tabs
  //     bottom: PreferredSize(
  //       preferredSize: const Size.fromHeight(50),
  //       child: _buildTabBar(),
  //     ),
  //   );
  // }
  //
  // Widget _buildTabBar() {
  //   return TabBar(
  //     controller: _tabController,
  //     tabs: const [
  //       Tab(text: 'Ready to Confirm'),
  //       Tab(text: 'Failed Orders'),
  //     ],
  //     indicatorColor: Colors.blue,
  //     labelColor: Colors.black,
  //     unselectedLabelColor: Colors.grey,
  //   );
  // }
  //
  // Widget _buildBody() {
  //   return TabBarView(
  //     controller: _tabController,
  //     children: [
  //       _buildOrdersTab(),
  //       // _buildFailedOrdersTab(),
  //     ],
  //   );
  // }
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
