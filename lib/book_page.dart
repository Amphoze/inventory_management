import 'package:flutter/material.dart';
import 'package:inventory_management/Api/orders_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/dropdown.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Widgets/order_card.dart';
import 'package:inventory_management/Api/orders_api.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _b2bSearchController = TextEditingController();
  final TextEditingController _b2cSearchController = TextEditingController();
  final TextEditingController b2bPageController = TextEditingController();
  final TextEditingController b2cPageController = TextEditingController();
  bool areOrdersFetched = false;

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
    _b2bSearchController.addListener(() {
      if (_b2bSearchController.text.isEmpty) {
        _refreshOrders('B2B');
        Provider.of<BookProvider>(context, listen: false).clearSearchResults();
      }
    });
    _b2cSearchController.addListener(() {
      if (_b2cSearchController.text.isEmpty) {
        _refreshOrders('B2C');
        Provider.of<BookProvider>(context, listen: false).clearSearchResults();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
      bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);
    });
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

  Widget _searchBar(String orderType) {
    final TextEditingController controller =
        orderType == 'B2B' ? _b2bSearchController : _b2cSearchController;

    return Padding(
      padding: EdgeInsets.all(8.0),
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
                  if (orderType == 'B2B') {
                    Provider.of<BookProvider>(context, listen: false)
                        .searchB2BOrders(text);
                  } else {
                    Provider.of<BookProvider>(context, listen: false)
                        .searchB2COrders(text);
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

  Widget _buildOrderList(String orderType) {
    final bookProvider = Provider.of<BookProvider>(context);
    List<Order> orders =
        orderType == 'B2B' ? bookProvider.ordersB2B : bookProvider.ordersB2C;

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
            currentPage: orderType == 'B2B'
                ? bookProvider.currentPageB2B
                : bookProvider.currentPageB2C,
            totalPages: orderType == 'B2B'
                ? bookProvider.totalPagesB2B
                : bookProvider.totalPagesB2C,
            buttonSize: 30,
            pageController:
                orderType == 'B2B' ? b2bPageController : b2cPageController,
            onFirstPage: () {
              if (orderType == 'B2B') {
                bookProvider.fetchPaginatedOrdersB2B(1);
              } else {
                bookProvider.fetchPaginatedOrdersB2C(1);
              }
            },
            onLastPage: () {
              if (orderType == 'B2B') {
                bookProvider
                    .fetchPaginatedOrdersB2B(bookProvider.totalPagesB2B);
              } else {
                bookProvider
                    .fetchPaginatedOrdersB2C(bookProvider.totalPagesB2C);
              }
            },
            onNextPage: () {
              int currentPage = orderType == 'B2B'
                  ? bookProvider.currentPageB2B
                  : bookProvider.currentPageB2C;

              int totalPages = orderType == 'B2B'
                  ? bookProvider.totalPagesB2B
                  : bookProvider.totalPagesB2C;

              if (currentPage < totalPages) {
                if (orderType == 'B2B') {
                  bookProvider.fetchPaginatedOrdersB2B(currentPage + 1);
                } else {
                  bookProvider.fetchPaginatedOrdersB2C(currentPage + 1);
                }
              }
            },
            onPreviousPage: () {
              int currentPage = orderType == 'B2B'
                  ? bookProvider.currentPageB2B
                  : bookProvider.currentPageB2C;

              if (currentPage > 1) {
                if (orderType == 'B2B') {
                  bookProvider.fetchPaginatedOrdersB2B(currentPage - 1);
                } else {
                  bookProvider.fetchPaginatedOrdersB2C(currentPage - 1);
                }
              }
            },
            onGoToPage: (int page) {
              int totalPages = orderType == 'B2B'
                  ? bookProvider.totalPagesB2B
                  : bookProvider.totalPagesB2C;

              if (page > 0 && page <= totalPages) {
                if (orderType == 'B2B') {
                  bookProvider.fetchPaginatedOrdersB2B(page);
                } else {
                  bookProvider.fetchPaginatedOrdersB2C(page);
                }
              } else {
                _showSnackbar(context,
                    'Please enter a valid page number between 1 and $totalPages.');
              }
            },
            onJumpToPage: () {
              final String pageText =
                  (orderType == 'B2B' ? b2bPageController : b2cPageController)
                      .text;
              int? page = int.tryParse(pageText);
              int totalPages = orderType == 'B2B'
                  ? bookProvider.totalPagesB2B
                  : bookProvider.totalPagesB2C;

              if (page == null || page < 1 || page > totalPages) {
                _showSnackbar(context,
                    'Please enter a valid page number between 1 and $totalPages.');
                return;
              }

              if (orderType == 'B2B') {
                bookProvider.fetchPaginatedOrdersB2B(page);
              } else {
                bookProvider.fetchPaginatedOrdersB2C(page);
              }

              (orderType == 'B2B' ? b2bPageController : b2cPageController)
                  .clear();
            },
          ),
      ],
    );
  }

  void _showSnackbar(BuildContext context, String message) {
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
            _buildBookButton('Delhivery', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _buildBookButton('Shiprocket', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _buildBookButton('Others', orderType, AppColors.primaryBlue),
            const SizedBox(
              width: 8,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              onPressed: bookProvider.isRefreshingOrders
                  ? null
                  : () async {
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

  Widget _buildBookButton(String provider, String orderType, Color color) {
    final bookProvider = Provider.of<BookProvider>(context);

    bool isLoading;
    switch (provider) {
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
              await _handleBooking(provider, orderType);
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
          : Text(provider),
    );
  }

  Future<void> _handleBooking(String provider, String orderType) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    List<String> selectedOrderIds = [];

    // Collect selected order IDs based on the order type
    if (orderType == 'B2B') {
      selectedOrderIds = bookProvider.ordersB2B
          .where((order) => order.isSelected)
          .map((order) => order.orderId)
          .toList();
    } else {
      selectedOrderIds = bookProvider.ordersB2C
          .where((order) => order.isSelected)
          .map((order) => order.orderId)
          .toList();
    }

    // If no orders are selected, show a message
    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders selected'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    // Confirm the selected orders using the new API
    try {
      String responseMessage = await bookProvider.bookOrders(
          context, selectedOrderIds, provider.toLowerCase(), provider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseMessage),
          backgroundColor: AppColors.green,
        ),
      );

      // Refresh the orders after booking
      await bookProvider.fetchOrders(
        orderType,
        orderType == 'B2B'
            ? bookProvider.currentPageB2B
            : bookProvider.currentPageB2C,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book orders with $provider: $e'),
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
                  value: orderType == 'B2B'
                      ? bookProvider.selectAllB2B
                      : bookProvider.selectAllB2C,
                  onChanged: (value) {
                    bookProvider.toggleSelectAll(orderType == 'B2B', value);
                  },
                ),
                Text("Select All ($selectedCount)"),
              ],
            ),
          ),
          buildHeader('ORDERS', flex: 7),
          buildHeader('DELHIVERY', flex: 1),
          buildHeader('SHIPROCKET', flex: 1),
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
          flex: 9,
          child: OrderCard(
            order: order,
            isBookPage: true,
            checkboxWidget: checkboxWidget,
          ),
        ),
        const SizedBox(width: 20),
        buildCell(order.freightCharge?.delhivery?.toString() ?? '', flex: 1),
        const SizedBox(width: 10),
        buildCell(order.freightCharge?.shiprocket?.toString() ?? '', flex: 1),
      ],
    );
  }

  Widget buildCell(String content, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Rs. $content",
              style: const TextStyle(
                color: AppColors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
