import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/utils.dart';

class BookedPage extends StatefulWidget {
  const BookedPage({super.key});

  @override
  _BookedPageState createState() => _BookedPageState();
}

class _BookedPageState extends State<BookedPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  bool areOrdersFetched = false;
  String selectedSearchType = 'Order ID';
  final TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  String selectedPicklist = '';
  List<String> picklistIds = ['W1', 'W2', 'W3', 'G1', 'G2', 'G3', 'E1', 'E2', 'E3'];
  bool isDownloading = false;
  late BookProvider bookProvider;

  // String _selectedDate = 'Select Date';
  // String selectedCourier = 'All';
  // DateTime? picked;

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
    bookProvider = Provider.of<BookProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.resetFilterData();
      bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
      context.read<MarketplaceProvider>().fetchMarketplaces();
      _fetchUserRole();
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, pro, child) => Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: _buildOrderList(),
        ),
      ),
    );
  }

  void _refreshOrders() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
    // bookProvider.resetFilterData();
  }

  Widget _searchBar() {
    final TextEditingController controller = _searchController;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 120,
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
                        Provider.of<BookProvider>(context, listen: false).clearSearchResults();
                        _refreshOrders();
                      } else {
                        Provider.of<BookProvider>(context, listen: false).searchBookedOrders(text, selectedSearchType);
                      }
                    },
                    onSubmitted: (text) {
                      bookProvider.resetFilterData();
                      if (text.isEmpty) {
                        _refreshOrders();
                      } else {
                        Provider.of<BookProvider>(context, listen: false).searchBookedOrders(text, selectedSearchType);
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
                      _refreshOrders();
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _searchBar(),
              const SizedBox(width: 10),
              _buildConfirmButtons(),
            ],
          ),
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
                _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
              }
            },
            onJumpToPage: () {
              final String pageText = _pageController.text;
              int? page = int.tryParse(pageText);
              int totalPages = bookProvider.totalPagesBooked;

              if (page == null || page < 1 || page > totalPages) {
                _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
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
    return Padding(
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

                      bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
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
                      bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
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
                      bookProvider.fetchBookedOrders(bookProvider.currentPageBooked);
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: bookProvider.isRebook
                ? null
                : () async {
                    log("B2C");
                    final provider = Provider.of<BookProvider>(context, listen: false);
                    List<String> selectedOrderIds =
                        provider.ordersBooked.where((order) => order.isSelected).map((order) => order.orderId).toList();

                    log("Selected Order IDs: $selectedOrderIds");

                    if (selectedOrderIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Please select at least one order'),
                            ],
                          ),
                          backgroundColor: AppColors.cardsred,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } else {
                      provider.setRebookingStatus(true);
                      String resultMessage = await provider.rebookOrders(selectedOrderIds);
                      provider.setRebookingStatus(false);

                      bool isSuccess = resultMessage.contains('success');

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            titlePadding: EdgeInsets.zero,
                            title: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSuccess ? AppColors.green.withValues(alpha: 0.1) : AppColors.cardsred.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSuccess ? Icons.check_circle : Icons.error_outline,
                                    color: isSuccess ? AppColors.green : AppColors.cardsred,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isSuccess ? 'Orders Rebooked Successfully' : 'Rebooking Status',
                                      style: TextStyle(
                                        color: isSuccess ? AppColors.green : AppColors.cardsred,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            content: Container(
                              width: double.maxFinite,
                              constraints: const BoxConstraints(maxHeight: 400),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resultMessage,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    if (isSuccess && selectedOrderIds.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rebooked Orders (${selectedOrderIds.length})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'These orders can be found in the confirm section:',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ...selectedOrderIds.map((orderId) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.circle, size: 8, color: Colors.grey[600]),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Order ID: $orderId',
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
            child: bookProvider.isRebook
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 8),
                      Text(
                        'Rebook Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              _showPicklistSourceDialog(context);
            },
            child: const Text(
              'Generate Picklist',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(builder: (BuildContext context, StateSetter dialogSetState) {
                    return AlertDialog(
                      title: const Text('Download Packlist'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: "Select Date",
                              suffixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true, // Prevent manual input
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );

                              if (picked != null) {
                                dialogSetState(() {
                                  _dateController.text = _dateFormat.format(picked);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          DropdownButton(
                            value: picklistIds.contains(selectedPicklist)
                                ? selectedPicklist
                                : null, // Only set value if it exists in the list
                            isExpanded: true,
                            hint: const Text('Select Picklist ID'),
                            items: picklistIds.map((id) {
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(id),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              dialogSetState(() {
                                // Update dialog state
                                if (newValue != null) {
                                  selectedPicklist = newValue;
                                }
                              });
                            },
                          )
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedPicklist.isEmpty) return;

                            dialogSetState(() {
                              isDownloading = true;
                            });

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text('Downloading'),
                                    ],
                                  ),
                                );
                              },
                            );

                            final res = await bookProvider.generatePacklist(context, _dateController.text, selectedPicklist);

                            Utils.showSnackBar(context, res['message']);

                            Navigator.pop(context);
                            Navigator.pop(context);

                            dialogSetState(() {
                              isDownloading = false;
                            });
                          },
                          child: const Text('Download'),
                        ),
                      ],
                    );
                  });
                },
              );
            },
            child: const Text('Download Packlist'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardsred,
            ),
            onPressed: bookProvider.isCancel
                ? null // Disable button while loading
                : () async {
                    log("B2C");
                    final provider = Provider.of<BookProvider>(context, listen: false);

                    // Collect selected order IDs
                    List<String> selectedOrderIds =
                        provider.ordersBooked.where((order) => order.isSelected).map((order) => order.orderId).toList();

                    log("Selected Order IDs: $selectedOrderIds");
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
              backgroundColor: Colors.orange.shade300,
            ),
            onPressed: () {
              bookProvider.resetFilterData();
              _refreshOrders();
            },
            child: const Text('Reset Filters'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh',
            onPressed: bookProvider.isRefreshingOrders
                ? null
                : () async {
                    bookProvider.searchController.clear();
                    _refreshOrders();
                  },
            icon: bookProvider.isRefreshingOrders
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      // color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
          flex: 7,
          child: OrderComboCard(
            order: order,
            toShowBy: true,
            isBookedPage: true,
            toShowOrderDetails: true,
            checkboxWidget: checkboxWidget,
            isAdmin: isAdmin ?? false,
            isSuperAdmin: isSuperAdmin ?? false,
          ),
        ),
        // const SizedBox(width: 50),
        buildCell(order.isBooked, flex: 1),
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
                    title: const Text('Website', style: TextStyle(fontSize: 16)),
                    subtitle: const Text('W1/W2/W3'),
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
                    title: const Text('Offline', style: TextStyle(fontSize: 16)),
                    subtitle: const Text('G1/G2/G3'),
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
                    title: const Text('Ecom', style: TextStyle(fontSize: 16)),
                    subtitle: const Text('E1/E2/E3'),
                    value: 'ecom',
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
              onPressed: () async {
                if (selectedMarketplace != null) {
                  log('Selected Marketplace: $selectedMarketplace');

                  showDialog(
                    context: context,
                    barrierDismissible: false,
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
                    Navigator.of(context).pop();
                  });

                  // Fetch order picker data
                  await bookProvider.generatePicklist(context, selectedMarketplace!).then((_) {
                    Navigator.of(context).pop();
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
