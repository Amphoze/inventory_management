import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/provider/all_orders_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/model/orders_model.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  _AllOrdersPageState createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  bool areOrdersFetched = false;
  String selectedCourier = 'All';
  String selectedStatus = 'All';
  String _selectedDate = 'Select Date';
  List<Map<String, String>> statuses = [];

  @override
  void initState() {
    super.initState();
    // _searchController.addListener(() {
    //   if (_searchController.text.isEmpty) {
    //     _refreshBookedOrders();
    //     Provider.of<AllOrdersProvider>(context, listen: false)
    //         .clearSearchResults();
    //   }
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allOrdersProvider =
          Provider.of<AllOrdersProvider>(context, listen: false);
      allOrdersProvider.fetchAllOrders(page: allOrdersProvider.currentPage);
    });

    context.read<MarketplaceProvider>().fetchMarketplaces();

    fetchStatuses();
  }

  void fetchStatuses() async {
    final allOrdersProvider =
        Provider.of<AllOrdersProvider>(context, listen: false);
    statuses = await allOrdersProvider.getTrackingStatuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AllOrdersProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: _buildOrderList(),
        ),
      ),
    );
  }

// Refresh ordersBooked for both B2B and B2C
  void _refreshBookedOrders() {
    final allOrdersProvider =
        Provider.of<AllOrdersProvider>(context, listen: false);
    allOrdersProvider.fetchAllOrders(page: allOrdersProvider.currentPage);
  }

  Widget _searchBar() {
    final TextEditingController controller = _searchController;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
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
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Color.fromRGBO(117, 117, 117, 1),
                    ),
                    onPressed: () {},
                  ),
                  hintText: 'Search Orders',
                  hintStyle: const TextStyle(
                    color: Color.fromRGBO(117, 117, 117, 1),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
                style: const TextStyle(color: AppColors.black),
                onChanged: (text) {
                  if (text.isEmpty) {
                    context.read<AllOrdersProvider>().fetchAllOrders();
                    // Provider.of<AllOrdersProvider>(context, listen: false)
                    //     .clearSearchResults();
                  }
                },
                onSubmitted: (text) {
                  Provider.of<AllOrdersProvider>(context, listen: false)
                      .searchOrders(text);
                },
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  controller.clear();
                  Provider.of<AllOrdersProvider>(context, listen: false)
                      .clearSearchResults();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context);
    List<Order> ordersBooked = allOrdersProvider.ordersBooked;

    int selectedCount = ordersBooked.where((order) => order.isSelected).length;

    // Update flag when ordersBooked are fetched
    if (ordersBooked.isNotEmpty) {
      areOrdersFetched =
          true; // Set flag to true when ordersBooked are available
    }

    return Column(
      children: [
        Row(
          children: [
            _searchBar(),
            const Spacer(),
            // Add the Confirm button here
            _buildConfirmButtons(),
          ],
        ),
        _buildTableHeader(selectedCount),
        Expanded(
          child: allOrdersProvider.isLoading
              ? const Center(
                  child: LoadingAnimation(
                    icon: Icons.apps,
                    beginColor: Color.fromRGBO(189, 189, 189, 1),
                    endColor: AppColors.primaryBlue,
                    size: 80.0,
                  ),
                )
              : ordersBooked.isEmpty
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
                      itemCount: ordersBooked.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            _buildOrderCard(ordersBooked[index]),
                            const Divider(thickness: 1, color: Colors.grey),
                          ],
                        );
                      },
                    ),
        ),
        if (areOrdersFetched)
          CustomPaginationFooter(
            currentPage: allOrdersProvider.currentPage,
            totalPages: allOrdersProvider.totalPages,
            buttonSize: 30,
            pageController: _pageController,
            onFirstPage: () {
              allOrdersProvider.goToPage(1);
            },
            onLastPage: () {
              allOrdersProvider.goToPage(allOrdersProvider.totalPages);
            },
            onNextPage: () {
              int currentPage = allOrdersProvider.currentPage;

              int totalPages = allOrdersProvider.totalPages;

              if (currentPage < totalPages) {
                allOrdersProvider.goToPage(allOrdersProvider.currentPage + 1);
              }
            },
            onPreviousPage: () {
              int currentPage = allOrdersProvider.currentPage;

              if (currentPage > 1) {
                allOrdersProvider.goToPage(allOrdersProvider.currentPage - 1);
              }
            },
            onGoToPage: (int page) {
              int totalPages = allOrdersProvider.totalPages;

              if (page > 0 && page <= totalPages) {
                allOrdersProvider.goToPage(page);
              } else {
                _showSnackbar(context,
                    'Please enter a valid page number between 1 and $totalPages.');
              }
            },
            onJumpToPage: () {
              final String pageText = _pageController.text;
              int? page = int.tryParse(pageText);
              int totalPages = allOrdersProvider.totalPages;

              if (page == null || page < 1 || page > totalPages) {
                _showSnackbar(context,
                    'Please enter a valid page number between 1 and $totalPages.');
                return;
              }

              allOrdersProvider.goToPage(page);

              _pageController.clear();
            },
          ),
      ],
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildConfirmButtons() {
    final allOrdersProvider =
        Provider.of<AllOrdersProvider>(context, listen: false);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
                ElevatedButton(
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
                          DateFormat('yyyy-MM-dd').format(picked);
                      setState(() {
                        _selectedDate = formattedDate;
                      });

                      if (selectedCourier != 'All') {
                        allOrdersProvider.fetchOrdersByMarketplace(
                          selectedCourier,
                          allOrdersProvider.currentPage,
                          picked,
                          selectedStatus,
                        );
                      } else {
                        allOrdersProvider.fetchAllOrders(
                          date: picked,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text(
                    'Filter by Date',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  selectedStatus,
                ),
                Consumer<AllOrdersProvider>(
                  builder: (context, provider, child) {
                    log('building');
                    return PopupMenuButton<String>(
                      tooltip: 'Filter by Tracking Status',
                      initialValue: selectedStatus,
                      onSelected: (String value) {
                        setState(() {
                          selectedStatus = value;
                        });
                        log('value: $value');
                        if (value == 'All') {
                          allOrdersProvider.fetchAllOrders(
                            page: allOrdersProvider.currentPage,
                            date: _selectedDate == 'Select Date'
                                ? null
                                : DateTime.parse(_selectedDate),
                          );
                        } else {
                          log('selectedCourier: $selectedCourier');
                          log('selectedStatus: $selectedStatus');

                          log('fff${statuses.firstWhere((map) => map.containsKey(selectedStatus), orElse: () => {})[value]!}');

                          allOrdersProvider.fetchOrdersByStatus(
                            selectedCourier,
                            allOrdersProvider.currentPage,
                            _selectedDate == 'Select Date'
                                ? null
                                : DateTime.parse(_selectedDate),
                            statuses.firstWhere(
                                (map) => map.containsKey(selectedStatus),
                                orElse: () => {})[value]!,
                          );
                        }
                        log('Selected: $value');
                      },
                      itemBuilder: (BuildContext context) {
                        List<String> temp =
                            statuses.map((item) => item.keys.first).toList();
                        return <PopupMenuEntry<String>>[
                          ...temp.map((status) => PopupMenuItem<String>(
                                value: status.toString(),
                                child: Text(status.toString()),
                              )),
                          const PopupMenuItem<String>(
                            value: 'All',
                            child: Text('All'),
                          ),
                        ];
                      },
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: const Text(
                          'Filter by Tracking Status',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  selectedCourier,
                ),
                Consumer<MarketplaceProvider>(
                  builder: (context, provider, child) {
                    return PopupMenuButton<String>(
                      tooltip: 'Filter by Marketplace',
                      initialValue: selectedCourier,
                      onSelected: (String value) {
                        setState(() {
                          selectedCourier = value;
                        });
                        if (value == 'All') {
                          allOrdersProvider.fetchAllOrders(
                            page: allOrdersProvider.currentPage,
                            date: _selectedDate == 'Select Date'
                                ? null
                                : DateTime.parse(_selectedDate),
                          );
                        } else {
                          allOrdersProvider.fetchOrdersByMarketplace(
                              value,
                              allOrdersProvider.currentPage,
                              _selectedDate == 'Select Date'
                                  ? null
                                  : DateTime.parse(_selectedDate),
                              selectedStatus);
                        }
                        log('Selected: $value');
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
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: const Text(
                          'Filter by Marketplace',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),
            // _buildBookButton('Cancel', orderType, AppColors.cardsred),
            // const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardsred,
              ),
              onPressed: allOrdersProvider.isCancel
                  ? null // Disable button while loading
                  : () async {
                      log("B2C");
                      final provider = Provider.of<AllOrdersProvider>(context,
                          listen: false);

                      // Collect selected order IDs
                      List<String> selectedOrderIds = provider.ordersBooked
                          .asMap()
                          .entries
                          .where(
                              (entry) => provider.selectedProducts[entry.key])
                          .map((entry) => entry.value.orderId)
                          .toList();

                      if (selectedOrderIds.isEmpty) {
                        // Show an error message if no ordersBooked are selected
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No ordersBooked selected'),
                            backgroundColor: AppColors.cardsred,
                          ),
                        );
                      } else {
                        // Set loading status to true before starting the operation
                        provider.setCancelStatus(true);

                        // Call confirmOrders method with selected IDs
                        String resultMessage = await provider.cancelOrders(
                            context, selectedOrderIds);

                        // Set loading status to false after operation completes
                        provider.setCancelStatus(false);

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
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(resultMessage),
                            backgroundColor: snackBarColor,
                          ),
                        );
                      }
                    },
              child: allOrdersProvider.isCancel
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
                backgroundColor: AppColors.primaryBlue,
              ),
              onPressed: allOrdersProvider.isRefreshingOrders
                  ? null
                  : () async {
                      _refreshBookedOrders();
                    },
              child: allOrdersProvider.isRefreshingOrders
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
      ),
    );
  }

  Widget _buildTableHeader(int selectedCount) {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context);
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: allOrdersProvider.selectAll,
                  onChanged: (value) {
                    allOrdersProvider.toggleSelectAll(value!);
                  },
                ),
                Text("Select All ($selectedCount)"),
              ],
            ),
          ),
          buildHeader('ORDERS', flex: 5),
          buildHeader('STATUS', flex: 1),
          buildHeader('TRACKING\nSTATUS', flex: 1),
        ],
      ),
    );
  }

  Widget buildHeader(String title, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context);
    Widget? checkboxWidget;
    bool isBookPage = true;

    // checkbox widget if it's for the book page
    if (isBookPage) {
      checkboxWidget = SizedBox(
        width: 30,
        height: 30,
        child: Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: order.isSelected,
            onChanged: (value) {
              allOrdersProvider.handleRowCheckboxChangeBooked(
                order.orderId,
                value!,
              );
            },
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: OrderComboCard(
            order: order,
            // toShowAll: true,
            toShowBy: true,
            toShowOrderDetails: true,
            checkboxWidget: checkboxWidget,
          ),
        ),
        // const SizedBox(width: 50),
        buildCell(
            order.orderStatusMap!.last.status!
                .split('_')
                .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                .join(' '),
            flex: 1),

        if (order.awbNumber == '')
          const Expanded(
              flex: 1,
              child: Center(
                child: Text('Not Available'),
              ))
        else ...[
          if (order.bookingCourier == 'Delhivery')
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  children: [
                    Text(order.awbNumber),
                    FutureBuilder(
                      future: allOrdersProvider
                          .fetchDelhiveryTrackingStatus(order.awbNumber),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                              strokeWidth: 2,
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            )
          else if (order.bookingCourier == 'Shiprocket')
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  children: [
                    Text(order.awbNumber),
                    FutureBuilder(
                      future: allOrdersProvider
                          .fetchShiprocketTrackingStatus(order.awbNumber),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                              strokeWidth: 2,
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            )
        ],
        // buildCell(order['isBooked']['status'], flex: 1),
      ],
    );
  }

  Widget buildCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(child: Text(title)),
    );
  }
}
