import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/utils.dart';

class InvoicedOrders extends StatefulWidget {
  const InvoicedOrders({super.key});

  @override
  _InvoicedOrdersState createState() => _InvoicedOrdersState();
}

class _InvoicedOrdersState extends State<InvoicedOrders> with SingleTickerProviderStateMixin {
  final TextEditingController _pageController = TextEditingController();
  bool areOrdersFetched = false;
  String selectedSearchType = 'Order ID'; // Default selection
  late AccountsProvider provider;

  bool? isSuperAdmin = false;
  bool? isAdmin = false;

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
      isAdmin = prefs.getBool('_isAdminAssigned');
    });
  }

  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (provider.invoiceSearch.text.trim().isEmpty) {
      _refreshBookedOrders();
      Provider.of<AccountsProvider>(context, listen: false).clearSearchResults();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      provider.searchInvoicedOrders(value, provider.selectedSearchType);
    });
  }

  @override
  void initState() {
    provider = context.read<AccountsProvider>();
    provider.invoiceSearch.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.resetFilterData();
      provider.fetchInvoicedOrders(provider.currentPage);
      // context.read<MarketplaceProvider>().fetchMarketplaces();
      _fetchUserRole();
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.resetFilterData();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsProvider>(
      builder: (context, pro, child) => Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: _buildOrderList(),
        ),
      ),
    );
  }

// Refresh ordersBooked for both B2B and B2C
  void _refreshBookedOrders({bool removeFilter = true}) {
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
    accountsProvider.fetchInvoicedOrders(accountsProvider.currentPage);
    if (removeFilter) {
      accountsProvider.resetFilterData();
    }
    accountsProvider.invoiceSearch.clear();
  }

  Widget _searchBar() {
    // final TextEditingController controller = provider.invoiceSearch;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButtonFormField<String>(
              value: selectedSearchType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
              items: const [
                DropdownMenuItem(value: 'Order ID', child: Text('Order ID')),
                DropdownMenuItem(value: 'Transaction No.', child: Text('Transaction No.')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSearchType = value!;
                });
              },
            ),
          ),
          Container(
            width: 220,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: provider.invoiceSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search Orders',
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(117, 117, 117, 1),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                    ),
                    style: const TextStyle(color: AppColors.black),
                    onChanged: _onSearchChanged,
                    onSubmitted: (text) {
                      provider.resetFilterData();
                      if (text.isEmpty) {
                        _refreshBookedOrders();
                      } else {
                        Provider.of<AccountsProvider>(context, listen: false)
                            .searchInvoicedOrders(text, selectedSearchType);
                      }
                    },
                  ),
                ),
                if (provider.invoiceSearch.text.isNotEmpty)
                  InkWell(
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                    ),
                    onTap: () {
                      setState(() {
                        provider.invoiceSearch.clear();
                      });
                      _refreshBookedOrders();
                      Provider.of<AccountsProvider>(context, listen: false).clearSearchResults();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    final accountsProvider = Provider.of<AccountsProvider>(context);
    List<Order> ordersBooked = accountsProvider.ordersBooked;

    int selectedCount = ordersBooked.where((order) => order.isSelected).length;

    // Update flag when ordersBooked are fetched
    if (ordersBooked.isNotEmpty) {
      areOrdersFetched = true; // Set flag to true when ordersBooked are available
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
          child: accountsProvider.isLoadingBooked
              ? const Center(
                  child: LoadingAnimation(
                    icon: Icons.book_online,
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
          Consumer<AccountsProvider>(
            builder: (context, accountsProvider, child) {
              return CustomPaginationFooter(
                currentPage: accountsProvider.currentPageBooked,
                totalPages: accountsProvider.totalPages,
                buttonSize: 30,
                totalCount: accountsProvider.totalOrdersInvoiced,
                pageController: _pageController,
                onFirstPage: () {
                  goToBookedPage(1);
                },
                onLastPage: () {
                  goToBookedPage(accountsProvider.totalPagesBooked);
                },
                onNextPage: () {
                  int currentPage = accountsProvider.currentPageBooked;

                  int totalPages = accountsProvider.totalPagesBooked;

                  if (currentPage < totalPages) {
                    goToBookedPage(accountsProvider.currentPageBooked + 1);
                  }
                },
                onPreviousPage: () {
                  int currentPage = accountsProvider.currentPageBooked;

                  if (currentPage > 1) {
                    goToBookedPage(accountsProvider.currentPageBooked - 1);
                  }
                },
                onGoToPage: (int page) {
                  int totalPages = accountsProvider.totalPages;

                  if (page > 0 && page <= totalPages) {
                    goToBookedPage(page);
                  } else {
                    _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
                  }
                },
                onJumpToPage: () {
                  final String pageText = _pageController.text;
                  int? page = int.tryParse(pageText);
                  int totalPages = accountsProvider.totalPages;

                  if (page == null || page < 1 || page > totalPages) {
                    _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
                    return;
                  }

                  goToBookedPage(page);

                  _pageController.clear();
                },
              );
            }
          ),
      ],
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    Utils.showSnackBar(context, message);
  }

  Widget _buildConfirmButtons() {
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              children: [
                Text(provider.selectedPaymentMode ?? ''),
                PopupMenuButton<String>(
                  tooltip: 'Filter by Payment Mode',
                  onSelected: (String value) {
                    if (value != '') {
                      setState(() {
                        provider.selectedPaymentMode = value;
                      });
                      // if (selectedCourier == 'All') {
                      //   accountsProvider.fetchOrdersByMarketplace(selectedCourier, 2, accountsProvider.currentPageBooked,
                      //       date: picked, mode: selectedPaymentMode);
                      // }
                      accountsProvider.fetchInvoicedOrders(accountsProvider.currentPageBooked);
                    }

                    log('Selected: $value');
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    ...[
                      'COD',
                      'Prepaid',
                      'Partial Payment',
                    ].map(
                      (paymentMode) => PopupMenuItem<String>(
                        value: paymentMode,
                        child: Text(paymentMode),
                      ),
                    ),
                  ],
                  child: const IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.payment,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  provider.selectedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: provider.selectedDate == 'Select Date' ? Colors.grey : AppColors.primaryBlue,
                  ),
                ),
                Tooltip(
                  message: 'Filter by Date',
                  child: IconButton(
                    onPressed: () async {
                      provider.picked = await showDatePicker(
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

                      if (provider.picked != null) {
                        String formattedDate = DateFormat('dd-MM-yyyy').format(provider.picked!);
                        setState(() {
                          provider.selectedDate = formattedDate;
                        });

                        // if (selectedCourier != 'All') {
                        //   accountsProvider.fetchBookedOrdersByMarketplace(selectedCourier, accountsProvider.currentPageBooked,
                        //       date: picked, mode: selectedPaymentMode);
                        // } else {
                        accountsProvider.fetchInvoicedOrders(accountsProvider.currentPageBooked);
                        // }
                      }
                    },
                    icon: const Icon(
                      Icons.calendar_today,
                      size: 30,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                if (accountsProvider.selectedDate != 'Select Date')
                  Tooltip(
                    message: 'Clear selected Date',
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          accountsProvider.selectedDate = 'Select Date';
                          accountsProvider.picked = null;
                        });
                        accountsProvider.fetchInvoicedOrders(accountsProvider.currentPageBooked);
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
            // Refresh Button
            Column(
              children: [
                Text(
                  provider.selectedCourier,
                ),
                Consumer<MarketplaceProvider>(
                  builder: (context, marketPro, child) {
                    return PopupMenuButton<String>(
                      tooltip: 'Filter by Marketplace',
                      onSelected: (String value) {
                        setState(() {
                          provider.selectedCourier = value;
                        });
                        accountsProvider.fetchInvoicedOrders(accountsProvider.currentPageBooked);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        ...marketPro.marketplaces.map((marketplace) => PopupMenuItem<String>(
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
            // _buildBookButton('Cancel', orderType, AppColors.cardsred),
            // const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardsred,
              ),
              onPressed: accountsProvider.isCancel
                  ? null // Disable button while loading
                  : () async {
                      log("B2C");
                      final provider = Provider.of<AccountsProvider>(context, listen: false);

                      // Collect selected order IDs
                      List<String> selectedOrderIds = provider.ordersBooked
                          .asMap()
                          .entries
                          .where((entry) => provider.selectedAccounts[entry.key])
                          .map((entry) => entry.value.orderId)
                          .toList();

                      if (selectedOrderIds.isEmpty) {
                        Utils.showSnackBar(context, 'No orders selected', isError: true, toRemoveCurr: true);
                      } else {
                        String resultMessage = await provider.cancelOrders(context, selectedOrderIds);

                        Color snackBarColor;
                        if (resultMessage.contains('success')) {
                          await accountsProvider.fetchInvoicedOrders(accountsProvider.currentPageBooked);

                          snackBarColor = AppColors.green; // Success: Green
                        } else if (resultMessage.contains('error') || resultMessage.contains('failed')) {
                          snackBarColor = AppColors.cardsred; // Error: Red
                        } else {
                          snackBarColor = AppColors.orange; // Other: Orange
                        }

                        Utils.showSnackBar(context, resultMessage, color: snackBarColor, seconds: 5);
                      }
                    },
              child: accountsProvider.isCancel
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
                backgroundColor: Colors.orange.shade300,
              ),
              onPressed: () async {
                _refreshBookedOrders();
              },
              child: const Text('Reset Filters'),
            ),

            const SizedBox(width: 8),

            IconButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: () async {
                  _refreshBookedOrders(removeFilter: false);
                },
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.primaryBlue,
                )),

            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primaryBlue,
            //   ),
            //   onPressed: accountsProvider.isLoadingBooked
            //       ? null
            //       : () async {
            //           _refreshBookedOrders();
            //         },
            //   child: accountsProvider.isLoadingBooked
            //       ? const SizedBox(
            //           width: 16,
            //           height: 16,
            //           child: CircularProgressIndicator(
            //             color: Colors.white,
            //             strokeWidth: 2,
            //           ),
            //         )
            //       : const Text(
            //           'Refresh',
            //           style: TextStyle(color: Colors.white),
            //         ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(int selectedCount) {
    return Consumer<AccountsProvider>(builder: (context, accountsProvider, child) {
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
                    value: accountsProvider.allSelectedInvoiced,
                    onChanged: (value) {
                      accountsProvider.toggleBookedSelectAll(value!);
                    },
                  ),
                  Text("Select All ($selectedCount)"),
                ],
              ),
            ),
            buildHeader('ORDERS', flex: 7),
            buildHeader('Invoice', flex: 2),
          ],
        ),
      );
    });
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

  Widget _buildOrderCard(Order order) {
    final accountsProvider = Provider.of<AccountsProvider>(context);
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
              accountsProvider.toggleOrderSelectionBooked(
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
          child: OrderComboCard(
            order: order,
            toShowBy: true,
            toShowOrderDetails: true,
            isAccountSection: true,
            checkboxWidget: checkboxWidget,
            isAdmin: isAdmin ?? false,
            isSuperAdmin: isSuperAdmin ?? false,
          ),
        ),
        const SizedBox(width: 50),
        buildCell(order.checkInvoice, flex: 2),
        // buildCell(order['isBooked']['status'], flex: 2),
      ],
    );
  }

  Widget buildCell(bool checkInvoice, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        child: checkInvoice
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

  void goToBookedPage(int page) {
    if (page < 1 || page > provider.totalPagesBooked) return;
    provider.setCurrentPage(page);
    provider.fetchInvoicedOrders(page);
  }
}
