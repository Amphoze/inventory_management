import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/model/orders_model.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _b2bSearchController = TextEditingController();
  final TextEditingController _b2cSearchController = TextEditingController();
  final TextEditingController b2bPageController = TextEditingController();
  final TextEditingController b2cPageController = TextEditingController();
  bool areOrdersFetched = false;
  String selectedCourier = 'All';
  String _selectedDate = 'Select Date';
  String bookingCourier = 'bookingCourier';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Reload data when the tab changes
      if (_tabController.indexIsChanging) {
        _refreshOrders("B2B");
        _refreshOrders("B2C");
        _b2bSearchController.clear();
        _b2cSearchController.clear();
      }
    });
    // _b2bSearchController.addListener(() {
    //   if (_b2bSearchController.text.isEmpty) {
    //     _refreshOrders('B2B');
    //     Provider.of<BookProvider>(context, listen: false).clearSearchResults();
    //   }
    // });
    // _b2cSearchController.addListener(() {
    //   if (_b2cSearchController.text.isEmpty) {
    //     _refreshOrders('B2C');
    //     Provider.of<BookProvider>(context, listen: false).clearSearchResults();
    //   }
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
      bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);
    });

    context.read<MarketplaceProvider>().fetchMarketplaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _b2bSearchController.dispose();
    _b2cSearchController.dispose();
    b2bPageController.dispose();
    b2cPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _buildTabBar(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList('B2C'),
              _buildOrderList('B2B'),
            ],
          ),
        ),
      ),
    );
  }

// Refresh orders for both B2B and B2C
  void _refreshOrders(String orderType) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    if (orderType == 'B2B') {
      bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
    } else {
      bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);
    }
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'B2C'),
          Tab(text: 'B2B'),
        ],
        indicatorColor: Colors.blue,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorWeight: 3,
      ),
    );
  }

  String selectedSearchType = 'Order ID'; // Default selection

  Widget _searchBar(String orderType) {
    final TextEditingController controller = orderType == 'B2B' ? _b2bSearchController : _b2cSearchController;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 34,
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButtonFormField<String>(
              value: selectedSearchType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
              items: const [
                DropdownMenuItem(value: 'Order ID', child: Text('Order ID')),
                DropdownMenuItem(value: 'AWB No.', child: Text('AWB No.')),
              ],
              onChanged: (value) {
                log(value!);
                setState(() {
                  selectedSearchType = value;
                });
              },
            ),
          ),
          Container(
            width: 150,
            height: 34,
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
                        orderType == 'B2B' ? _refreshOrders('B2B') : _refreshOrders('B2C');
                      } else {
                        if (orderType == 'B2B') {
                          Provider.of<BookProvider>(context, listen: false).searchB2BOrders(text, selectedSearchType);
                        } else {
                          Provider.of<BookProvider>(context, listen: false).searchB2COrders(text, selectedSearchType);
                        }
                      }
                    },
                    onSubmitted: (text) {
                      if (orderType == 'B2B') {
                        Provider.of<BookProvider>(context, listen: false).searchB2BOrders(text, selectedSearchType);
                      } else {
                        Provider.of<BookProvider>(context, listen: false).searchB2COrders(text, selectedSearchType);
                      }
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
                      _refreshOrders(orderType);
                      Provider.of<BookProvider>(context, listen: false).clearSearchResults();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String orderType) {
    final bookProvider = Provider.of<BookProvider>(context);
    List<Order> orders = orderType == 'B2B' ? bookProvider.ordersB2B : bookProvider.ordersB2C;

    int selectedCount = orders.where((order) => order.isSelected).length;

    // Update flag when orders are fetched
    if (orders.isNotEmpty) {
      areOrdersFetched = true; // Set flag to true when orders are available
    }

    return Column(
      children: [
        Row(
          children: [
            _searchBar(orderType),
            // const SizedBox(width: 8),
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primaryBlue,
            //   ),
            //   onPressed: () {
            //     _showPicklistSourceDialog(context);
            //   },
            //   child: const Text(
            //     'Generate Picklist',
            //     style: TextStyle(color: Colors.white),
            //   ),
            // ),
            const Spacer(),
            // Add the Confirm button here
            _buildConfirmButtons(orderType),
          ],
        ),
        _buildTableHeader(orderType, selectedCount),
        Expanded(
          child: bookProvider.isLoadingB2B || bookProvider.isLoadingB2C
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
                            _buildOrderCard(orders[index], orderType),
                            const Divider(thickness: 1, color: Colors.grey),
                          ],
                        );
                      },
                    ),
        ),
        if (areOrdersFetched)
          CustomPaginationFooter(
            currentPage: orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C,
            totalPages: orderType == 'B2B' ? bookProvider.totalPagesB2B : bookProvider.totalPagesB2C,
            buttonSize: 30,
            pageController: orderType == 'B2B' ? b2bPageController : b2cPageController,
            onFirstPage: () {
              if (orderType == 'B2B') {
                bookProvider.fetchPaginatedOrdersB2B(1);
              } else {
                bookProvider.fetchPaginatedOrdersB2C(1);
              }
            },
            onLastPage: () {
              if (orderType == 'B2B') {
                bookProvider.fetchPaginatedOrdersB2B(bookProvider.totalPagesB2B);
              } else {
                bookProvider.fetchPaginatedOrdersB2C(bookProvider.totalPagesB2C);
              }
            },
            onNextPage: () {
              int currentPage = orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C;

              int totalPages = orderType == 'B2B' ? bookProvider.totalPagesB2B : bookProvider.totalPagesB2C;

              if (currentPage < totalPages) {
                if (orderType == 'B2B') {
                  bookProvider.fetchPaginatedOrdersB2B(currentPage + 1);
                } else {
                  bookProvider.fetchPaginatedOrdersB2C(currentPage + 1);
                }
              }
            },
            onPreviousPage: () {
              int currentPage = orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C;

              if (currentPage > 1) {
                if (orderType == 'B2B') {
                  bookProvider.fetchPaginatedOrdersB2B(currentPage - 1);
                } else {
                  bookProvider.fetchPaginatedOrdersB2C(currentPage - 1);
                }
              }
            },
            onGoToPage: (int page) {
              int totalPages = orderType == 'B2B' ? bookProvider.totalPagesB2B : bookProvider.totalPagesB2C;

              if (page > 0 && page <= totalPages) {
                if (orderType == 'B2B') {
                  bookProvider.fetchPaginatedOrdersB2B(page);
                } else {
                  bookProvider.fetchPaginatedOrdersB2C(page);
                }
              } else {
                _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
              }
            },
            onJumpToPage: () {
              final String pageText = (orderType == 'B2B' ? b2bPageController : b2cPageController).text;
              int? page = int.tryParse(pageText);
              int totalPages = orderType == 'B2B' ? bookProvider.totalPagesB2B : bookProvider.totalPagesB2C;

              if (page == null || page < 1 || page > totalPages) {
                _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
                return;
              }

              if (orderType == 'B2B') {
                bookProvider.fetchPaginatedOrdersB2B(page);
              } else {
                bookProvider.fetchPaginatedOrdersB2C(page);
              }

              (orderType == 'B2B' ? b2bPageController : b2cPageController).clear();
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

  Widget _buildConfirmButtons(String orderType) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
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
                    color: _selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
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
                        String formattedDate = DateFormat('dd-MM-yyyy').format(picked);
                        setState(() {
                          _selectedDate = formattedDate;
                        });

                        if (selectedCourier != 'All') {
                          bookProvider.fetchOrdersByMarketplace(
                            selectedCourier,
                            orderType,
                            bookProvider.currentPageB2B,
                            date: picked,
                          );
                        } else {
                          bookProvider.fetchOrders(
                            orderType,
                            bookProvider.currentPageB2B,
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
                      initialValue: 'All',
                      onSelected: (String value) {
                        setState(() {
                          selectedCourier = value;
                        });
                        if (value == 'All') {
                          bookProvider.fetchOrders(orderType, bookProvider.currentPageB2B,
                              date: _selectedDate == 'Select Date' ? null : DateTime.parse(_selectedDate));
                        } else {
                          bookProvider.fetchOrdersByMarketplace(
                              value, orderType, orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C,
                              date: _selectedDate == 'Select Date' ? null : DateTime.parse(_selectedDate));
                        }
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
            ),
            const SizedBox(width: 8),
            _buildBookButton('Delhivery', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _buildBookButton('Shiprocket', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _buildBookButton('Others', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            // _buildBookButton('Cancel', orderType, AppColors.cardsred),
            // const SizedBox(width: 8),
            orderType == 'B2B'
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardsred,
                    ),
                    onPressed: bookProvider.isCancel
                        ? null // Disable button while loading
                        : () async {
                            log("B2C");
                            final provider = Provider.of<BookProvider>(context, listen: false);

                            // Collect selected order IDs
                            List<String> selectedOrderIds = provider.ordersB2B
                                .asMap()
                                .entries
                                .where((entry) => provider.selectedB2BItems[entry.key])
                                .map((entry) => entry.value.orderId)
                                .toList();

                            if (selectedOrderIds.isEmpty) {
                              // Show an error message if no orders are selected
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardsred,
                    ),
                    onPressed: bookProvider.isCancel
                        ? null // Disable button while loading
                        : () async {
                            log("B2C");
                            final provider = Provider.of<BookProvider>(context, listen: false);

                            // Collect selected order IDs
                            List<String> selectedOrderIds = provider.ordersB2C
                                .asMap()
                                .entries
                                .where((entry) => provider.selectedB2CItems[entry.key])
                                .map((entry) => entry.value.orderId)
                                .toList();

                            if (selectedOrderIds.isEmpty) {
                              // Show an error message if no orders are selected
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
                      setState(() {
                        selectedCourier = 'All';
                        _selectedDate = 'Select Date';
                      });
                      _refreshOrders(orderType);
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

  Widget _buildBookButton(
    String courier,
    String orderType,
    Color color,
  ) {
    final bookProvider = Provider.of<BookProvider>(context);

    bool isLoading;
    switch (courier) {
      case 'Delhivery':
        isLoading = bookProvider.isDelhiveryLoading;
        break;
      case 'Shiprocket':
        isLoading = bookProvider.isShiprocketLoading;
        break;
      case 'Others':
        isLoading = bookProvider.isOthersLoading;
        break;
      default:
        isLoading = false;
    }
    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              await _handleBooking(courier, orderType);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(courier),
    );
  }

  Future<void> _handleBooking(String courier, String orderType) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    List<Map<String, String>> selectedOrderIds = [];

    // Collect selected order IDs based on the order type
    if (orderType == 'B2B') {
      selectedOrderIds = bookProvider.ordersB2B
          .where((order) => order.isSelected)
          .map((order) => {'orderId': order.orderId, 'courierId': order.selectedCourierId!, 'selectedCourier': order.selectedCourier!})
          .toList();
    } else {
      selectedOrderIds = bookProvider.ordersB2C
          .where((order) => order.isSelected)
          .map((order) => {'orderId': order.orderId, 'courierId': order.selectedCourierId!, 'selectedCourier': order.selectedCourier!})
          .toList();
    }

    // If no orders are selected, show a message
    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders selected'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    log('Selected Orders: $selectedOrderIds');

    // Confirm the selected orders using the new API
    try {
      String responseMessage =
          await bookProvider.bookOrders(context, selectedOrderIds, courier.toLowerCase(), courier); ////////////////////
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseMessage),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Refresh the orders after booking
      await bookProvider.fetchOrders(
        orderType,
        orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book orders with $courier: $e'),
          backgroundColor: AppColors.cardsred,
        ),
      );
    }
  }

  Widget _buildTableHeader(String orderType, int selectedCount) {
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
                  value: orderType == 'B2B' ? bookProvider.selectAllB2B : bookProvider.selectAllB2C,
                  onChanged: (value) {
                    bookProvider.toggleSelectAll(orderType == 'B2B', value);
                  },
                ),
                Text("Select All ($selectedCount)"),
              ],
            ),
          ),
          buildHeader('ORDERS', flex: 5),
          buildHeader('DELHIVERY', flex: 1),
          buildHeader('SHIPROCKET', flex: 2),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, String orderType) {
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
              setState(() {
                if (value == false) {
                  order.selectedCourier = null;
                }
              });
              // order.isSelected = false;
              bookProvider.handleRowCheckboxChange(
                order.orderId,
                value!,
                orderType == 'B2B',
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
            toShowBy: true,
            toShowOrderDetails: true,
            checkboxWidget: checkboxWidget,
            isBookPage: true,
          ),
        ),
        // const SizedBox(width: 20),
        order.freightCharge == null
            ? const Text('No freight charge found')
            : buildCell(order.freightCharge?.delhivery!, order.totalAmount!, flex: 1),

        order.availableCouriers!.isEmpty || order.availableCouriers == null
            ? const Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Not Available',
                  ),
                ),
              )
            : Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardsred),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.cardsred,
                          size: 20,
                        ),
                        label: const Text(
                          'Clear Selection',
                          style: TextStyle(
                            color: AppColors.cardsred,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          backgroundColor: AppColors.cardsred.withOpacity(0.1),
                        ),
                        onPressed: () {
                          setState(() {
                            order.selectedCourier = null;
                            order.isSelected = false;
                            order.selectedCourierId = null;
                          });
                        },
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: order.availableCouriers!.length,
                      itemBuilder: (context, index) {
                        var courier = order.availableCouriers![index];
                        var freightCharge = courier['freight_charge'];
                        var courierCompanyId = courier['courier_company_id'];

                        // Logger().e(courier);

                        var total = order.totalAmount!;
                        final percent = double.parse(((freightCharge! / total) * 100).toStringAsFixed(2));
                        return RadioListTile(
                          title: Text(
                            courier['name'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              courierCompanyId != null
                                  ? Text.rich(
                                      TextSpan(
                                        text: 'Courier ID: ',
                                        children: [
                                          TextSpan(
                                            text: courierCompanyId.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    )
                                  : const SizedBox(),
                              Row(
                                children: [
                                  Text(
                                    "Rs. $freightCharge",
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    percent > 20 ? "($percent %)" : "($percent %)",
                                    style: TextStyle(
                                      color: percent > 20 ? AppColors.cardsred : AppColors.primaryGreen,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          value: courier['name'],
                          groupValue: order.selectedCourier,
                          onChanged: (value) {
                            setState(() {
                              order.isSelected = true;
                              order.selectedCourier = value;
                              order.selectedCourierId = courierCompanyId;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              )
      ],
    );
  }

  Widget buildCell(double? freightCharge, double total, {int flex = 1}) {
    final percent = double.parse(((freightCharge! / total) * 100).toStringAsFixed(2));
    return Expanded(
      flex: flex,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Rs. $freightCharge",
            style: const TextStyle(
              color: AppColors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            percent > 20 ? "($percent %)" : "($percent %)",
            style: TextStyle(
              color: percent > 20 ? AppColors.cardsred : AppColors.primaryGreen,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

// void _showPicklistSourceDialog(BuildContext context) {
//   final bookProvider = context.read<BookProvider>();
//   showDialog(
//     context: context,
//     builder: (_) {
//       // Add a state variable to track the selected option
//       String? selectedMarketplace;

//       return AlertDialog(
//         title: const Text(
//           'Select Marketplace',
//           style: TextStyle(
//             fontWeight: FontWeight.w500,
//             color: AppColors.primaryBlue,
//           ),
//         ),
//         content: StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 RadioListTile<String>(
//                   contentPadding: const EdgeInsets.all(0),
//                   title: const Text('Website', style: TextStyle(fontSize: 16)),
//                   value: 'website',
//                   groupValue: selectedMarketplace,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedMarketplace = value; // Store selected option
//                     });
//                   },
//                 ),
//                 RadioListTile<String>(
//                   contentPadding: const EdgeInsets.all(0),
//                   title: const Text('Offline', style: TextStyle(fontSize: 16)),
//                   value: 'offline',
//                   groupValue: selectedMarketplace,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedMarketplace = value; // Store selected option
//                     });
//                   },
//                 ),
//                 RadioListTile<String>(
//                   contentPadding: const EdgeInsets.all(0),
//                   title: const Text('All', style: TextStyle(fontSize: 16)),
//                   value: 'all',
//                   groupValue: selectedMarketplace,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedMarketplace = value; // Store selected option
//                     });
//                   },
//                 ),
//               ],
//             );
//           },
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         backgroundColor: Colors.white,
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Close the dialog
//             },
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               if (selectedMarketplace != null) {
//                 log('Selected Marketplace: $selectedMarketplace');

//                 // Show loading dialog
//                 showDialog(
//                   context: context,
//                   barrierDismissible: false, // Prevent dismissing the dialog
//                   builder: (BuildContext context) {
//                     return const AlertDialog(
//                       content: Row(
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(width: 10),
//                           Text("Generating picklist"),
//                         ],
//                       ),
//                     );
//                   },
//                 ).then((_) {
//                   // Close the marketplace selection dialog after loading dialog is dismissed
//                   Navigator.of(context).pop();
//                 });

//                 // Fetch order picker data
//                 bookProvider.generatePicklist(context, selectedMarketplace!).then((_) {
//                   Navigator.of(context).pop(); // Close loading dialog
//                 });
//               }
//             },
//             child: const Text(
//               'Ok',
//               style: TextStyle(color: AppColors.primaryBlue),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }
}
