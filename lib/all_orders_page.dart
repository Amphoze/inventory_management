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
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> with SingleTickerProviderStateMixin {

  final TextEditingController _pageController = TextEditingController();
  List<Map<String, String>> statuses = [];
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
      // selectedCourier = 'All';
      // selectedStatus = 'All';
      // _selectedDate = 'Select Date';
      // picked = null;
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
      body: Column(
        children: [

          Row(
            children: [
              Consumer<AllOrdersProvider>(
                builder: (context, provider, _) {

                  int selectedCount = provider.ordersBooked.where((order) => order.isSelected).length;

                  return SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: provider.selectAll,
                          onChanged: (value) {
                            provider.toggleSelectAll(value!);
                          },
                        ),
                        Text("Select All ($selectedCount)"),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              _searchBar(),

              const Spacer(),

              _buildConfirmButtons(),
            ],
          ),

          Expanded(
            child: Consumer<AllOrdersProvider>(
              builder: (context, provider, _) {
                return provider.isLoading
                    ?
                const Center(
                  child: LoadingAnimation(
                    icon: Icons.apps,
                    beginColor: Color.fromRGBO(189, 189, 189, 1),
                    endColor: AppColors.primaryBlue,
                    size: 80.0,
                  ),
                )
                    :
                provider.ordersBooked.isEmpty
                    ?
                const Center(
                  child: Text(
                    'No Orders Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
                    :
                ListView.builder(
                  itemCount: provider.ordersBooked.length,
                  itemBuilder: (context, index) {

                    final order = provider.ordersBooked[index];

                    String orderStatus = (order.orderStatusMap.isNotEmpty)
                        ? order.orderStatusMap.last.status
                        : 'Unknown Status';

                    return Card(
                      elevation: 2,
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [

                            Expanded(
                              flex: 7,
                              child: OrderComboCard(
                                order: order,
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                toShowBy: true,
                                toShowOrderDetails: true,
                                checkboxWidget:  SizedBox(
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
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  _buildOrderStatusCard(orderStatus),

                                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                                  // order.awbNumber == ''
                                  //     ?
                                  // const Text('Not Available')
                                  //     :
                                  // _buildTrackingStatus(order),

                                  _buildTrackingStatusCard(order),

                                  if (order.reverseOrder.isNotEmpty)
                                    _buildReverseOrderCard(order),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Consumer<AllOrdersProvider>(
            builder: (context, allOrdersProvider, _) {

              if (allOrdersProvider.isLoading) {
                return const SizedBox();
              }

              return CustomPaginationFooter(
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
              );
            },
          ),
        ],
      ),
    );
  }

  void _refreshOrders() {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context, listen: false);
    // setState(() {
    //   picked = null;
    //   selectedCourier = 'All';
    //   selectedStatus = 'All';
    //   _selectedDate = 'Select Date';
    // });
    allOrdersProvider.fetchAllOrders(page: allOrdersProvider.currentPage);
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
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
                    Provider.of<AllOrdersProvider>(context, listen: false).searchOrdersWithId(text.trim());
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
                          marketplace: selectedCourier
                      );
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
                backgroundColor: Colors.orange.shade300,
              ),
              onPressed: () {
                setState(() {
                  selectedCourier = 'All';
                  _selectedDate = 'Select Date';
                  selectedStatus = 'All';
                  picked = null;
                });
                _refreshOrders();
              },
              child: const Text('Reset Filters'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: allOrdersProvider.isRefreshingOrders
                  ? null
                  : () async {
                      log('refresh selectedCourier: $selectedCourier');
                      log('refresh _selectedDate: $_selectedDate');
                      log('refresh selectedStatus: $selectedStatus');
                      log('refresh picked: $picked');
                      final status = statuses.firstWhere((map) => map.containsKey(selectedStatus), orElse: () => {})[selectedStatus]!;

                      allOrdersProvider.fetchAllOrders(page: allOrdersProvider.currentPage, date: picked, status: status, marketplace: selectedCourier);
              },
              icon: allOrdersProvider.isRefreshingOrders
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(String orderStatus) {

    Color bgColor = Colors.blue.shade300;
    Color fgColor = Colors.blue;

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fgColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Order Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            orderStatus,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: bgColor,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrackingStatusCard(Order order) {

    bool isDelhivery = order.bookingCourier == 'Delhivery';
    String awbNumber = order.awbNumber;

    Color bgColor = Colors.green.shade300;
    Color fgColor = Colors.green;

    if (awbNumber.isNotEmpty) {
      _updateTrackingStatus(awbNumber, isDelhivery);
    }

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fgColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tracking Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),

          const SizedBox(height: 3),

          if (awbNumber.isNotEmpty)
            ValueListenableBuilder<String?>(
              valueListenable: _getTrackingNotifier(awbNumber, isDelhivery),
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
                  return Text(
                    status,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  );
                } else {
                  return Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: bgColor,
                    ),
                  );
                }
              },
            ),

          const SizedBox(height: 3),

          _buildReverseInfoRow(
            title: 'AWB',
            value: awbNumber.isEmpty ? 'Not Available' : awbNumber,
            isReverseDetailCard: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStatus(Order order) {

    bool isDelhivery = order.bookingCourier == 'Delhivery';

    return Center(
      child: Column(
        children: [
          Text(order.awbNumber),

          Builder(
            builder: (context) {
              _updateTrackingStatus(order.awbNumber, isDelhivery);

              return ValueListenableBuilder<String?>(
                valueListenable: _getTrackingNotifier(order.awbNumber, isDelhivery),
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
    );

    // return Expanded(
    //   flex: 1,
    //   child: Center(
    //     child: Column(
    //       children: [
    //         Text(order.awbNumber),
    //
    //         Builder(
    //           builder: (context) {
    //             _updateTrackingStatus(order.awbNumber, false);
    //
    //             return ValueListenableBuilder<String?>(
    //               valueListenable: _getTrackingNotifier(order.awbNumber, false),
    //               builder: (context, status, child) {
    //                 if (status == null) {
    //                   return const SizedBox(
    //                     width: 16,
    //                     height: 16,
    //                     child: CircularProgressIndicator(
    //                       color: AppColors.primaryBlue,
    //                       strokeWidth: 2,
    //                     ),
    //                   );
    //                 } else if (status.startsWith('Error:')) {
    //                   return Text(status);
    //                 } else {
    //                   return Text(
    //                     status ?? '',
    //                     style: const TextStyle(
    //                       fontWeight: FontWeight.bold,
    //                     ),
    //                   );
    //                 }
    //               },
    //             );
    //           },
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }

  Widget _buildReverseOrderCard(Order order) {
    
    final reverseOrder = order.reverseOrder.last;

    if (!reverseOrder.status) return const SizedBox();

    String timestamp = reverseOrder.timestamp;

    String date = 'NA';

    try {
      DateTime dateTime = DateTime.parse(timestamp);
      date = DateFormat('dd MMM, yyyy hh:mm:ss a').format(dateTime);
    } catch (e) {
      log('Cannot Parse Timestamp for Reverse Order :- $e');
    }

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              'Reversing Details',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 3),

            _buildReverseInfoRow(
              title: 'Reason',
              value: reverseOrder.reason,
            ),

            const SizedBox(height: 3),

            _buildReverseInfoRow(
              title: 'Reversed By',
              value: reverseOrder.reverseBy,
            ),

            const SizedBox(height: 3),

            _buildReverseInfoRow(
              title: 'Date',
              value: date,
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildReverseInfoRow({
    required String title,
    required String value,
    bool isReverseDetailCard = true,
  }) {
    return Text.rich(
        TextSpan(
            children: [
              TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isReverseDetailCard ? Colors.red : Colors.green,
                  )
              ),

              TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isReverseDetailCard ? Colors.red.shade400 : Colors.green.shade400,
                  )
              )
            ]
        )
    );
  }
}
