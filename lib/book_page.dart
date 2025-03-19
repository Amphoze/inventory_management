import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/chat_screen.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController b2bPageController = TextEditingController();
  final TextEditingController b2cPageController = TextEditingController();
  bool areOrdersFetched = false;
  late BookProvider bookProvider;

  bool? isSuperAdmin = false;
  bool? isAdmin = false;

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
      isAdmin = prefs.getBool('_isAdminAssigned');
    });
  }

  @override
  void initState() {
    super.initState();
    bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.b2bSearchController.clear();
    bookProvider.b2cSearchController.clear();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _refreshOrders("B2B");
        _refreshOrders("B2C");
        bookProvider.resetFilterData();
        bookProvider.b2bSearchController.clear();
        bookProvider.b2cSearchController.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.resetFilterData();
      bookProvider.fetchOrders('B2B', bookProvider.currentPageB2B);
      bookProvider.fetchOrders('B2C', bookProvider.currentPageB2C);
      context.read<MarketplaceProvider>().fetchMarketplaces();
      context.read<LocationProvider>().fetchWarehouses();
      _fetchUserRole();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // bookProvider.b2bSearchController.dispose();
    // bookProvider.b2cSearchController.dispose();
    b2bPageController.dispose();
    b2cPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(builder: (context, pro, child) {
      return Scaffold(
        key: pro.scaffoldKey,
        endDrawer: const ChatScreen(),
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
      );
    });
  }

  void _refreshOrders(String orderType) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.resetFilterData();
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
          Tab(text: 'Business-to-Consumer (B2C)'),
          Tab(text: 'Business-to-Business (B2B)'),
        ],
        indicatorColor: Colors.blue,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  // String selectedSearchType = 'Order ID';

  Widget _searchBar(String orderType) {
    final TextEditingController controller = orderType == 'B2B' ? bookProvider.b2bSearchController : bookProvider.b2cSearchController;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButtonFormField<String>(
              value: bookProvider.searchType,
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
                  bookProvider.searchType = value;
                });
              },
            ),
          ),
          Container(
            width: 200,
            height: 40,
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
                    decoration: const InputDecoration(
                      hintText: 'Search Orders',
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(117, 117, 117, 1),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                    ),
                    style: const TextStyle(color: AppColors.black),
                    onChanged: (text) {
                      if (text.isEmpty) {
                        bookProvider.resetFilterData();
                        orderType == 'B2B' ? _refreshOrders('B2B') : _refreshOrders('B2C');
                      } else {
                        if (orderType == 'B2B') {
                          Provider.of<BookProvider>(context, listen: false).searchB2BOrders(text);
                        } else {
                          Provider.of<BookProvider>(context, listen: false).searchB2COrders(text);
                        }
                      }
                    },
                    onSubmitted: (text) {
                      bookProvider.resetFilterData();
                      if (text.trim().isEmpty) {
                        orderType == 'B2B' ? _refreshOrders('B2B') : _refreshOrders('B2C');
                        return;
                      }

                      if (orderType == 'B2B') {
                        Provider.of<BookProvider>(context, listen: false).searchB2BOrders(text);
                        return;
                      } else {
                        Provider.of<BookProvider>(context, listen: false).searchB2COrders(text);
                        return;
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

    if (orders.isNotEmpty) {
      areOrdersFetched = true;
    }

    return Column(
      children: [
        Row(
          children: [
            _searchBar(orderType),
            const Spacer(),
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
    final page = orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C;
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
                  bookProvider.selectedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: bookProvider.selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                  ),
                ),
                Tooltip(
                  message: 'Filter by Date',
                  child: IconButton(
                    onPressed: () async {
                      bookProvider.picked = await showDatePicker(
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

                      if (bookProvider.picked != null) {
                        String formattedDate = DateFormat('dd-MM-yyyy').format(bookProvider.picked!);
                        setState(() {
                          bookProvider.selectedDate = formattedDate;
                        });

                        bookProvider.fetchOrders(orderType, page);
                      }
                    },
                    icon: const Icon(
                      Icons.calendar_today,
                      size: 30,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                if (bookProvider.selectedDate != 'Select Date')
                  Tooltip(
                    message: 'Clear selected Date',
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          bookProvider.selectedDate = 'Select Date';
                          bookProvider.picked = null;
                        });
                        bookProvider.fetchOrders(orderType, page);
                      },
                      child: const Icon(
                        Icons.clear,
                        size: 12,
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
                  bookProvider.selectedCourier,
                ),
                Consumer<MarketplaceProvider>(
                  builder: (context, provider, child) {
                    return PopupMenuButton<String>(
                      tooltip: 'Filter by Marketplace',
                      onSelected: (String value) {
                        setState(() {
                          bookProvider.selectedCourier = value;
                        });
                        bookProvider.fetchOrders(orderType, page);
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
              onPressed: bookProvider.isCloning
                  ? null
                  : () async {
                      List<Order> orders = orderType == 'B2B' ? bookProvider.ordersB2B : bookProvider.ordersB2C;
                      List<bool> selectedOrders = orderType == 'B2B' ? bookProvider.selectedB2BItems : bookProvider.selectedB2CItems;
                      int page = orderType == 'B2B' ? bookProvider.currentPageB2B : bookProvider.currentPageB2C;

                      List<String> selectedOrderIds =
                          orders.asMap().entries.where((entry) => selectedOrders[entry.key]).map((entry) => entry.value.orderId).toList();

                      if (selectedOrderIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No orders selected'),
                            backgroundColor: AppColors.cardsred,
                          ),
                        );
                      } else {
                        String resultMessage = await bookProvider.cloneOrders(context, orderType, page, selectedOrderIds);
                        Color snackBarColor;
                        if (resultMessage.contains('success')) {
                          snackBarColor = AppColors.green;
                        } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                          snackBarColor = AppColors.cardsred;
                        } else {
                          snackBarColor = AppColors.orange;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(resultMessage),
                            backgroundColor: snackBarColor,
                          ),
                        );
                      }
                    },
              child: bookProvider.isCloning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text(
                      'Clone',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            const SizedBox(width: 8),
            _buildBookButton('Delhivery', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _buildBookButton('Shiprocket', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            _buildBookButton('Others', orderType, AppColors.primaryBlue),
            const SizedBox(width: 8),
            orderType == 'B2B'
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardsred,
                    ),
                    onPressed: bookProvider.isCancel
                        ? null
                        : () async {
                            log("B2C");
                            final provider = Provider.of<BookProvider>(context, listen: false);

                            List<String> selectedOrderIds = provider.ordersB2B
                                .asMap()
                                .entries
                                .where((entry) => provider.selectedB2BItems[entry.key])
                                .map((entry) => entry.value.orderId)
                                .toList();

                            if (selectedOrderIds.isEmpty) {
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No orders selected'),
                                  backgroundColor: AppColors.cardsred,
                                ),
                              );
                            } else {
                              provider.setCancelStatus(true);

                              String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

                              provider.setCancelStatus(false);

                              Color snackBarColor;
                              if (resultMessage.contains('success')) {
                                snackBarColor = AppColors.green;
                              } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                snackBarColor = AppColors.cardsred;
                              } else {
                                snackBarColor = AppColors.orange;
                              }

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
                        ? null
                        : () async {
                            log("B2C");
                            final provider = Provider.of<BookProvider>(context, listen: false);

                            List<String> selectedOrderIds = provider.ordersB2C
                                .asMap()
                                .entries
                                .where((entry) => provider.selectedB2CItems[entry.key])
                                .map((entry) => entry.value.orderId)
                                .toList();

                            if (selectedOrderIds.isEmpty) {
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No orders selected'),
                                  backgroundColor: AppColors.cardsred,
                                ),
                              );
                            } else {
                              provider.setCancelStatus(true);

                              String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

                              provider.setCancelStatus(false);

                              Color snackBarColor;
                              if (resultMessage.contains('success')) {
                                snackBarColor = AppColors.green;
                              } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                                snackBarColor = AppColors.cardsred;
                              } else {
                                snackBarColor = AppColors.orange;
                              }

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
                      bookProvider.b2bSearchController.clear();
                      bookProvider.b2cSearchController.clear();
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

  bool isLoading = false;

  Widget _buildBookButton(
    String courier,
    String orderType,
    Color color,
  ) {
    final bookProvider = Provider.of<BookProvider>(context);

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

    setState(() {
      selectedOrderIds = (orderType == 'B2B' ? bookProvider.ordersB2B : bookProvider.ordersB2C)
          .where((order) => order.isSelected)
          .map((order) =>
              {'orderId': order.orderId, 'courierId': order.selectedCourierId ?? '', 'selectedCourier': order.selectedCourier ?? ''})
          .toList();
    });

    if (courier == 'Shiprocket' &&
        selectedOrderIds.every((order) => (order['courierId']?.isEmpty ?? false) || (order['selectedCourier']?.isEmpty ?? false))) {
      Utils.showSnackBar(context, 'Selected Delivery Courier', color: Colors.red);
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders selected'),
          backgroundColor: AppColors.orange,
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    log('Selected Orders: $selectedOrderIds');

    try {
      String responseMessage = await bookProvider.bookOrders(context, selectedOrderIds, courier);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseMessage),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 5),
        ),
      );

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: OrderComboCard(
            order: order,
            toShowBy: true,
            toShowOrderDetails: true,
            checkboxWidget: checkboxWidget,
            isBookPage: true,
            isAdmin: isAdmin ?? false,
            isSuperAdmin: isSuperAdmin ?? false,
          ),
        ),
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
                          backgroundColor: AppColors.cardsred.withValues(alpha: 0.1),
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
}
