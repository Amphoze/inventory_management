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
  final TextEditingController b2bPageController = TextEditingController();
  final TextEditingController b2cPageController = TextEditingController();
  bool areOrdersFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
      bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          title: _buildAppBarTitle(),
          bottom: _buildTabBar(),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList('B2B'),
              _buildOrderList('B2C'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: _buildSearchBar(),
        ),
        const Spacer(),
        _buildFilterButton(),
        _buildSortDropdown(),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _refreshOrders();
          },
          color: Colors.black,
        ),
      ],
    );
  }

// Refresh orders for both B2B and B2C
  void _refreshOrders() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
    bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);

    // Show a message to indicate reloading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content refreshed'),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<BookProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(183, 6, 90, 216),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: provider.searchController,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search Orders',
              hintStyle: TextStyle(color: Colors.white),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              prefixIcon: Icon(Icons.search, color: Colors.white),
            ),
            onChanged: (value) {
              provider.onSearchChanged();
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterButton() {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () {
        print('Filter button pressed');
      },
      color: Colors.black,
    );
  }

  Widget _buildSortDropdown() {
    return Consumer<BookProvider>(
      builder: (context, provider, child) {
        return CustomDropdown<String>(
          items: const ['Date', 'Amount'],
          selectedItem: provider.sortOption,
          hint: 'Sort by',
          onChanged: (value) {
            provider.setSortOption(value);
          },
          hintStyle: const TextStyle(color: Colors.black54),
          itemStyle: const TextStyle(color: Colors.black),
          borderColor: Colors.grey,
          borderWidth: 1.0,
        );
      },
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'B2B'),
          Tab(text: 'B2C'),
        ],
        indicatorColor: Colors.blue,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorWeight: 3,
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
        // Add the Confirm button here
        _buildConfirmButton(orderType),
        _buildTableHeader(orderType, selectedCount),
        Expanded(
          child: bookProvider.isLoadingB2B || bookProvider.isLoadingB2C
              ? const Center(child: BookLoadingAnimation())
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

  Widget _buildConfirmButton(String orderType) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton(
          onPressed: () async {
            final bookProvider =
                Provider.of<BookProvider>(context, listen: false);
            List<String> selectedOrderIds = [];

            // Collect selected order IDs based on the order type
            if (orderType == 'B2B') {
              selectedOrderIds = bookProvider.ordersB2B
                  .where((order) => order.isSelected)
                  .map((order) => order.orderId!)
                  .toList();
            } else {
              selectedOrderIds = bookProvider.ordersB2C
                  .where((order) => order.isSelected)
                  .map((order) => order.orderId!)
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
              String responseMessage =
                  await bookProvider.bookOrders(context, selectedOrderIds);
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
                      : bookProvider.currentPageB2C);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to book orders: $e'),
                  backgroundColor: AppColors.cardsred,
                ),
              );
            }
          },
          child: const Text('Shiprocket'),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String orderType, int selectedCount) {
    final bookProvider = Provider.of<BookProvider>(context);
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 200,
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
          buildHeader('PRODUCTS', flex: 7),
          buildHeader('DELHIVERY', flex: 2),
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
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, String orderType) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
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
          const SizedBox(width: 150),
          Expanded(
            flex: 7,
            child: OrderCard(
              order: order,
            ),
          ),
          const SizedBox(width: 40),
          buildCell(order.freightCharge?.delhivery?.toString() ?? '', flex: 2),
          const SizedBox(width: 40),
          buildCell(order.freightCharge?.shiprocket?.toString() ?? '', flex: 2),
        ],
      ),
    );
  }

  Widget buildCell(String content, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Rs. $content",
              style: const TextStyle(
                color: AppColors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
