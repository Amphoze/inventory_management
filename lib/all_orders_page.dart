import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/provider/all_orders_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/model/orders_model.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  _AllOrdersPageState createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> with SingleTickerProviderStateMixin {
  final TextEditingController _pageController = TextEditingController();
  List<Map<String, String>> statuses = [];
  bool areOrdersFetched = false;
  String selectedCourier = 'All';
  String selectedStatus = 'All';
  DateTime? picked;
  String _selectedDate = 'Select Date';
  late AllOrdersProvider allOrdersProvider;

  final Map<String, ValueNotifier<String?>> delhiveryTrackingStatuses = {};
  final Map<String, ValueNotifier<String?>> shiprocketTrackingStatuses = {};

  @override
  void initState() {
    super.initState();
    allOrdersProvider = Provider.of<AllOrdersProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedCourier = 'All';
      selectedStatus = 'All';
      _selectedDate = 'Select Date';
      picked = null;
      allOrdersProvider.fetchAllOrders(page: allOrdersProvider.currentPage);
      context.read<MarketplaceProvider>().fetchMarketplaces();
      fetchStatuses();
    });
  }

  void fetchStatuses() async {
    List<Map<String, String>> fetchedStatuses = await allOrdersProvider.getTrackingStatuses();
    log('fetchedStatuses: $fetchedStatuses');

    fetchedStatuses.insert(0, {'All': 'all'});

    setState(() {
      statuses = fetchedStatuses;
    });
  }

  @override
  void dispose() {
    // allOrdersProvider.searchController.dispose();
    _pageController.dispose();
    for (var notifier in delhiveryTrackingStatuses.values) {
      notifier.dispose();
    }
    for (var notifier in shiprocketTrackingStatuses.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  // Helper method to get or create ValueNotifier for tracking status
  ValueNotifier<String?> _getTrackingNotifier(String awbNumber, bool isDelhivery) {
    if (isDelhivery) {
      return delhiveryTrackingStatuses.putIfAbsent(awbNumber, () => ValueNotifier<String?>(null));
    } else {
      return shiprocketTrackingStatuses.putIfAbsent(awbNumber, () => ValueNotifier<String?>(null));
    }
  }

  // Method to fetch and update tracking status
  void _updateTrackingStatus(String awbNumber, bool isDelhivery) async {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context, listen: false);
    final notifier = _getTrackingNotifier(awbNumber, isDelhivery);

    try {
      final status = isDelhivery
          ? await allOrdersProvider.fetchDelhiveryTrackingStatus(awbNumber)
          : await allOrdersProvider.fetchShiprocketTrackingStatus(awbNumber);
      notifier.value = status;
    } catch (error) {
      notifier.value = 'Error: $error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 3.0),
        child: _buildOrderList(),
      ),
    );
  }

  void _refreshOrders() {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context, listen: false);
    setState(() {
      picked = null;
      selectedCourier = 'All';
      selectedStatus = 'All';
      _selectedDate = 'Select Date';
    });
    allOrdersProvider.fetchAllOrders(page: allOrdersProvider.currentPage);
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
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
                controller: allOrdersProvider.searchController,
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
                onChanged: (text) {
                  if (text.isEmpty) {
                    setState(() {
                      _selectedDate = 'Select Date';
                      picked = null;
                      selectedCourier = 'All';
                      selectedStatus = 'All';
                    });
                    context.read<AllOrdersProvider>().fetchAllOrders();
                  }
                },
                onSubmitted: (text) {
                  setState(() {
                    _selectedDate = 'Select Date';
                    picked = null;
                    selectedCourier = 'All';
                    selectedStatus = 'All';
                  });
                  if (text.trim().isEmpty) {
                    context.read<AllOrdersProvider>().fetchAllOrders();
                  } else {
                    Provider.of<AllOrdersProvider>(context, listen: false).searchOrders(text.trim());
                  }
                },
              ),
            ),
            if (allOrdersProvider.searchController.text.isNotEmpty)
              InkWell(
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                ),
                onTap: () {
                  allOrdersProvider.searchController.clear();
                  setState(() {
                    _selectedDate = 'Select Date';
                    picked = null;
                    selectedCourier = 'All';
                    selectedStatus = 'All';
                  });
                  Provider.of<AllOrdersProvider>(context, listen: false).clearSearchResults();
                  Provider.of<AllOrdersProvider>(context, listen: false).fetchAllOrders();
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

    if (ordersBooked.isNotEmpty) {
      areOrdersFetched = true;
    }

    return Column(
      children: [
        Row(
          children: [
            _searchBar(),
            const Spacer(),
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
              allOrdersProvider.goToPage(1, date: picked, status: selectedStatus, marketplace: selectedCourier);
            },
            onLastPage: () {
              allOrdersProvider.goToPage(allOrdersProvider.totalPages, date: picked, status: selectedStatus, marketplace: selectedCourier);
            },
            onNextPage: () {
              int currentPage = allOrdersProvider.currentPage;
              int totalPages = allOrdersProvider.totalPages;
              if (currentPage < totalPages) {
                allOrdersProvider.goToPage(allOrdersProvider.currentPage + 1,
                    date: picked, status: selectedStatus, marketplace: selectedCourier);
              }
            },
            onPreviousPage: () {
              int currentPage = allOrdersProvider.currentPage;
              if (currentPage > 1) {
                allOrdersProvider.goToPage(allOrdersProvider.currentPage - 1,
                    date: picked, status: selectedStatus, marketplace: selectedCourier);
              }
            },
            onGoToPage: (int page) {
              int totalPages = allOrdersProvider.totalPages;
              if (page > 0 && page <= totalPages) {
                allOrdersProvider.goToPage(page, date: picked, status: selectedStatus, marketplace: selectedCourier);
              } else {
                _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
              }
            },
            onJumpToPage: () {
              final String pageText = _pageController.text;
              int? page = int.tryParse(pageText);
              int totalPages = allOrdersProvider.totalPages;

              if (page == null || page < 1 || page > totalPages) {
                _showSnackbar(context, 'Please enter a valid page number between 1 and $totalPages.');
                return;
              }

              allOrdersProvider.goToPage(page, date: picked, status: selectedStatus, marketplace: selectedCourier);
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
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context, listen: false);

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
                IconButton(
                  tooltip: 'Filter by date',
                  onPressed: () async {
                    picked = await showDatePicker(
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
                      String formattedDate = DateFormat('yyyy-MM-dd').format(picked!);
                      setState(() {
                        _selectedDate = formattedDate;
                      });

                      allOrdersProvider.fetchAllOrders(
                          page: allOrdersProvider.currentPage,
                          date: picked,
                          status: statuses.firstWhere((map) => map.containsKey(selectedStatus), orElse: () => {})[selectedStatus]!,
                          marketplace: selectedCourier);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                ),
                if (_selectedDate != 'Select Date')
                  Tooltip(
                    message: 'Clear selected Date',
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedDate = 'Select Date';
                          picked = null;
                        });
                        allOrdersProvider.fetchAllOrders();
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
            const SizedBox(width: 16),
            Column(
              children: [
                Text(selectedStatus),
                Consumer<AllOrdersProvider>(
                  builder: (context, provider, child) {
                    return PopupMenuButton<String>(
                      tooltip: 'Filter by Status',
                      initialValue: selectedStatus,
                      onSelected: (String value) {
                        setState(() {
                          selectedStatus = value;
                        });
                        final status = statuses.firstWhere((map) => map.containsKey(value), orElse: () => {})[value]!;
                        Logger().e('status is: $status');
                        allOrdersProvider.fetchAllOrders(
                            page: allOrdersProvider.currentPage, date: picked, status: status, marketplace: selectedCourier);
                      },
                      itemBuilder: (BuildContext context) {
                        List<String> temp = statuses.map((item) => item.keys.first).toList();
                        return <PopupMenuEntry<String>>[
                          ...temp.map((status) => PopupMenuItem<String>(
                                value: status.toString(),
                                child: Text(status.toString()),
                              )),
                          // const PopupMenuItem<String>(
                          //   value: 'All',
                          //   child: Text('All'),
                          // ),
                        ];
                      },
                      child: IconButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        icon: const Icon(Icons.hourglass_empty, size: 30),
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
                  builder: (context, marketPro, child) {
                    return PopupMenuButton<String>(
                      tooltip: 'Filter by Marketplace',
                      onSelected: (String value) {
                        final status = statuses.firstWhere((map) => map.containsKey(selectedStatus), orElse: () => {})[selectedStatus]!;
                        log('marketplace value: $value');
                        log('date value: $picked');
                        log('status value: $status');
                        setState(() {
                          selectedCourier = value;
                        });
                        allOrdersProvider.fetchAllOrders(
                            page: allOrdersProvider.currentPage, date: picked, status: status, marketplace: value);
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
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardsred,
              ),
              onPressed: allOrdersProvider.isCancel
                  ? null
                  : () async {
                      log("B2C");
                      final provider = Provider.of<AllOrdersProvider>(context, listen: false);

                      List<String> selectedOrderIds = provider.ordersBooked
                          .asMap()
                          .entries
                          .where((entry) => provider.selectedProducts[entry.key])
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
                      setState(() {
                        selectedCourier = 'All';
                        _selectedDate = 'Select Date';
                        picked = null;
                      });
                      _refreshOrders();
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context);
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
            toShowBy: true,
            toShowOrderDetails: true,
            checkboxWidget: checkboxWidget,
          ),
        ),
        buildCell((order.orderStatusMap?.isNotEmpty ?? false) ? order.orderStatusMap!.last.status : 'Unknown Status', flex: 1),
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
                    Builder(
                      builder: (context) {
                        _updateTrackingStatus(order.awbNumber, true);

                        return ValueListenableBuilder<String?>(
                          valueListenable: _getTrackingNotifier(order.awbNumber, true),
                          builder: (context, status, child) {
                            if (status == null) {
                              return const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                  strokeWidth: 2,
                                ),
                              );
                            } else if (status.startsWith('Error:')) {
                              return Text(status);
                            } else {
                              return Text(
                                status,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                          },
                        );
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
                    Builder(
                      builder: (context) {
                        _updateTrackingStatus(order.awbNumber, false);

                        return ValueListenableBuilder<String?>(
                          valueListenable: _getTrackingNotifier(order.awbNumber, false),
                          builder: (context, status, child) {
                            if (status == null) {
                              return const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                  strokeWidth: 2,
                                ),
                              );
                            } else if (status.startsWith('Error:')) {
                              return Text(status);
                            } else {
                              return Text(
                                status ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            )
        ],
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
