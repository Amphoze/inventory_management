import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/booked_order_card.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/model/orders_model.dart';

class BookedPage extends StatefulWidget {
  const BookedPage({super.key});

  @override
  _BookedPageState createState() => _BookedPageState();
}

class _BookedPageState extends State<BookedPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  bool areOrdersFetched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _refreshOrders();
        Provider.of<BookProvider>(context, listen: false).clearSearchResults();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
    });

    context.read<MarketplaceProvider>().fetchMarketplaces();
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
      create: (_) => BookProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: _buildOrderList(),
        ),
      ),
    );
  }

// Refresh orders for both B2B and B2C
  void _refreshOrders() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
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
                    Provider.of<BookProvider>(context, listen: false)
                        .clearSearchResults();
                  }
                },
                onSubmitted: (text) {
                  Provider.of<BookProvider>(context, listen: false)
                      .searchBookedOrders(text);
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
                  // _refreshOrders(orderType);
                  Provider.of<BookProvider>(context, listen: false)
                      .clearSearchResults();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final bookProvider = Provider.of<BookProvider>(context);
    List<Order> orders = bookProvider.ordersBooked;

    int selectedCount = orders.where((order) => order.isSelected).length;

    // Update flag when orders are fetched
    if (orders.isNotEmpty) {
      areOrdersFetched = true; // Set flag to true when orders are available
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
          child: bookProvider.isLoadingBooked
              ? const Center(
                  child: LoadingAnimation(
                    icon: Icons.book_online,
                    beginColor: Color.fromRGBO(189, 189, 189, 1),
                    endColor: AppColors.primaryBlue,
                    size: 80.0,
                  ),
                )
              : orders.isEmpty
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
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            _buildOrderCard(orders[index]),
                            const Divider(thickness: 1, color: Colors.grey),
                          ],
                        );
                      },
                    ),
        ),
        if (areOrdersFetched)
          CustomPaginationFooter(
            currentPage: bookProvider.currentPageBooked,
            totalPages: bookProvider.totalPagesBooked,
            buttonSize: 30,
            pageController: _pageController,
            onFirstPage: () {
              bookProvider.fetchBookedOrders(1);
            },
            onLastPage: () {
              bookProvider.fetchBookedOrders(bookProvider.totalPagesBooked);
            },
            onNextPage: () {
              int currentPage = bookProvider.currentPageBooked;

              int totalPages = bookProvider.totalPagesBooked;

              if (currentPage < totalPages) {
                bookProvider.fetchBookedOrders(currentPage + 1);
              }
            },
            onPreviousPage: () {
              int currentPage = bookProvider.currentPageBooked;

              if (currentPage > 1) {
                bookProvider.fetchBookedOrders(currentPage - 1);
              }
            },
            onGoToPage: (int page) {
              int totalPages = bookProvider.totalPagesBooked;

              if (page > 0 && page <= totalPages) {
                bookProvider.fetchBookedOrders(page);
              } else {
                _showSnackbar(context,
                    'Please enter a valid page number between 1 and $totalPages.');
              }
            },
            onJumpToPage: () {
              final String pageText = _pageController.text;
              int? page = int.tryParse(pageText);
              int totalPages = bookProvider.totalPagesBooked;

              if (page == null || page < 1 || page > totalPages) {
                _showSnackbar(context,
                    'Please enter a valid page number between 1 and $totalPages.');
                return;
              }

              bookProvider.fetchBookedOrders(page);

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
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Consumer<MarketplaceProvider>(
              builder: (context, provider, child) {
                return PopupMenuButton<String>(
                  tooltip: 'Filter by Marketplace',
                  initialValue: 'All',
                  onSelected: (String value) {
                    if (value == 'All') {
                      bookProvider
                          .fetchBookedOrders(bookProvider.currentPageBooked);
                    } else {
                      bookProvider.fetchBookedOrdersByMarketplace(
                          value, bookProvider.currentPageBooked);
                    }
                    log('Selected: $value');
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    ...provider.marketplaces
                        .map((marketplace) => PopupMenuItem<String>(
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
            const SizedBox(width: 8),
            // _buildBookButton('Cancel', orderType, AppColors.cardsred),
            // const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardsred,
              ),
              onPressed: bookProvider.isCancel
                  ? null // Disable button while loading
                  : () async {
                      log("B2C");
                      final provider =
                          Provider.of<BookProvider>(context, listen: false);

                      // Collect selected order IDs
                      List<String> selectedOrderIds = provider.ordersB2B
                          .asMap()
                          .entries
                          .where(
                              (entry) => provider.selectedB2BItems[entry.key])
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(resultMessage),
                            backgroundColor: snackBarColor,
                          ),
                        );
                      }
                    },
              child: bookProvider.isCancel
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
              onPressed: bookProvider.isRefreshingOrders
                  ? null
                  : () async {
                      _refreshOrders();
                    },
              child: bookProvider.isRefreshingOrders
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
    final bookProvider = Provider.of<BookProvider>(context);
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
                  value: bookProvider.selectAllBooked,
                  onChanged: (value) {
                    bookProvider.toggleBookedSelectAll(value);
                  },
                ),
                Text("Select All ($selectedCount)"),
              ],
            ),
          ),
          buildHeader('ORDERS', flex: 7),
          buildHeader('Booked', flex: 2),
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
    final bookProvider = Provider.of<BookProvider>(context);
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
              bookProvider.handleRowCheckboxChangeBooked(
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
          flex: 14,
          child: BookedOrderCard(
            order: order,
            checkboxWidget: checkboxWidget,
          ),
        ),
        const SizedBox(width: 50),
        buildCell(order.isBooked, flex: 2),
        // buildCell(order['isBooked']['status'], flex: 2),
      ],
    );
  }

  Widget buildCell(bool isBooked, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        child: isBooked
            ? const Icon(
                Icons.check,
                size: 40,
                color: AppColors.green,
              )
            : const Icon(
                Icons.close,
                size: 40,
                color: AppColors.cardsred,
              ),
      ),
    );
  }

  void _showPicklistSourceDialog(BuildContext context) {
    final bookProvider = context.read<BookProvider>();
    showDialog(
      context: context,
      builder: (_) {
        // Add a state variable to track the selected option
        String? selectedMarketplace;

        return AlertDialog(
          title: const Text(
            'Select Marketplace',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.primaryBlue,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    contentPadding: const EdgeInsets.all(0),
                    title:
                        const Text('Website', style: TextStyle(fontSize: 16)),
                    value: 'website',
                    groupValue: selectedMarketplace,
                    onChanged: (value) {
                      setState(() {
                        selectedMarketplace = value; // Store selected option
                      });
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: const EdgeInsets.all(0),
                    title:
                        const Text('Offline', style: TextStyle(fontSize: 16)),
                    value: 'offline',
                    groupValue: selectedMarketplace,
                    onChanged: (value) {
                      setState(() {
                        selectedMarketplace = value; // Store selected option
                      });
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: const EdgeInsets.all(0),
                    title: const Text('All', style: TextStyle(fontSize: 16)),
                    value: 'all',
                    groupValue: selectedMarketplace,
                    onChanged: (value) {
                      setState(() {
                        selectedMarketplace = value; // Store selected option
                      });
                    },
                  ),
                ],
              );
            },
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedMarketplace != null) {
                  log('Selected Marketplace: $selectedMarketplace');

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Prevent dismissing the dialog
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 10),
                            Text("Generating picklist"),
                          ],
                        ),
                      );
                    },
                  ).then((_) {
                    // Close the marketplace selection dialog after loading dialog is dismissed
                    Navigator.of(context).pop();
                  });

                  // Fetch order picker data
                  bookProvider
                      .generatePicklist(context, selectedMarketplace!)
                      .then((_) {
                    Navigator.of(context).pop(); // Close loading dialog
                  });
                }
              },
              child: const Text(
                'Ok',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        );
      },
    );
  }
}
