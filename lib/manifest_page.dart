import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/manifest_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';

class ManifestPage extends StatefulWidget {
  const ManifestPage({super.key});

  @override
  State<ManifestPage> createState() => _ManifestPageState();
}

class _ManifestPageState extends State<ManifestPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDate = 'Select Date';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ManifestProvider>(context, listen: false)
          .fetchOrdersWithStatus8();
    });
    Provider.of<ManifestProvider>(context, listen: false)
        .textEditingController
        .clear();
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<ManifestProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedCourier = 'All';
    return Consumer<ManifestProvider>(
      builder: (context, manifestProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(183, 6, 90, 216),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Search by Order ID',
                            hintStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color.fromARGB(183, 6, 90, 216),
                            ),
                          ),
                          onChanged: (query) {
                            // Trigger a rebuild to show/hide the search button
                            setState(() {
                              // Update search focus
                            });
                            if (query.isEmpty) {
                              // Reset to all orders if search is cleared
                              manifestProvider.fetchOrdersWithStatus8();
                            }
                          },
                          onTap: () {
                            setState(() {
                              // Mark the search field as focused
                            });
                          },
                          onSubmitted: (query) {
                            if (query.isNotEmpty) {
                              manifestProvider.searchOrders(query);
                            }
                          },
                          onEditingComplete: () {
                            // Mark it as not focused when done
                            FocusScope.of(context)
                                .unfocus(); // Dismiss the keyboard
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: _searchController.text.isNotEmpty
                          ? _onSearchButtonPressed
                          : null,
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    // ElevatedButton(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.cardsred,
                    //   ),
                    //   onPressed: manifestProvider.isCancel
                    //       ? null // Disable button while loading
                    //       : () async {
                    //           final provider = Provider.of<ManifestProvider>(
                    //               context,
                    //               listen: false);
                    //           // Collect selected order IDs
                    //           List<String> selectedOrderIds = provider.orders
                    //               .asMap()
                    //               .entries
                    //               .where((entry) =>
                    //                   provider.selectedProducts[entry.key])
                    //               .map((entry) => entry.value.orderId)
                    //               .toList();
                    //           if (selectedOrderIds.isEmpty) {
                    //             // Show an error message if no orders are selected
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               const SnackBar(
                    //                 content: Text('No orders selected'),
                    //                 backgroundColor: AppColors.cardsred,
                    //               ),
                    //             );
                    //           } else {
                    //             // Set loading status to true before starting the operation
                    //             provider.setCancelStatus(true);
                    //             // Call confirmOrders method with selected IDs
                    //             String resultMessage = await provider
                    //                 .cancelOrders(context, selectedOrderIds)
                    //             // Set loading status to false after operation completes
                    //             provider.setCancelStatus(false);
                    //             // Determine the background color based on the result
                    //             Color snackBarColor;
                    //             if (resultMessage.contains('success')) {
                    //               snackBarColor =
                    //                   AppColors.green; // Success: Green
                    //             } else if (resultMessage.contains('error') ||
                    //                 resultMessage.contains('failed')) {
                    //               snackBarColor =
                    //                   AppColors.cardsred; // Error: Red
                    //             } else {
                    //               snackBarColor =
                    //                   AppColors.orange; // Other: Orange
                    //             }
                    //             // Show feedback based on the result
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               SnackBar(
                    //                 content: Text(resultMessage),
                    //                 backgroundColor: snackBarColor,
                    //               ),
                    //             );
                    //           }
                    //         },
                    //   child: manifestProvider.isCancel
                    //       ? const SizedBox(
                    //           width: 20,
                    //           height: 20,
                    //           child: CircularProgressIndicator(
                    //               color: Colors.white),
                    //         )
                    //       : const Text(
                    //           'Cancel Orders',
                    //           style: TextStyle(color: Colors.white),
                    //         ),
                    // ),
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
                                String formattedDate =
                                    DateFormat('yyyy-MM-dd').format(picked);
                                setState(() {
                                  _selectedDate = formattedDate;
                                });

                                if (selectedCourier != 'All') {
                                  manifestProvider.fetchOrdersByBookingCourier(
                                    selectedCourier,
                                    manifestProvider.currentPage,
                                    date: picked,
                                  );
                                } else {
                                  manifestProvider.fetchOrdersWithStatus8(
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
                    // Refresh Button
                    StatefulBuilder(builder: (context, setState) {
                      return Column(
                        children: [
                          Text(
                            selectedCourier,
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Filter by Booking Courier',
                            onSelected: (String value) {
                              setState(() {
                                selectedCourier = value;
                              });
                              if (value == 'All') {
                                manifestProvider.fetchOrdersWithStatus8(
                                  date: _selectedDate == 'Select Date'
                                      ? null
                                      : DateTime.parse(_selectedDate),
                                );
                              } else {
                                selectedCourier = value;
                                manifestProvider.fetchOrdersByBookingCourier(
                                    value, manifestProvider.currentPage,
                                    date: _selectedDate == 'Select Date'
                                        ? null
                                        : DateTime.parse(_selectedDate));
                              }
                              log('Selected: $value');
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'Delhivery', // Hardcoded marketplace
                                child: Text('Delhivery'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Shiprocket', // Hardcoded marketplace
                                child: Text('Shiprocket'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Others', // Hardcoded marketplace
                                child: Text('Others'),
                              ),
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
                          ),
                        ],
                      );
                    }),
                    const SizedBox(
                      width: 8,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: manifestProvider.isCreatingManifest
                          ? null
                          : () async {
                              manifestProvider.createManifest(
                                  context, selectedCourier);
                            },
                      child: manifestProvider.isCreatingManifest
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Manifest',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: manifestProvider.isRefreshingOrders
                          ? null
                          : () async {
                              manifestProvider.fetchOrdersWithStatus8();
                            },
                      child: manifestProvider.isRefreshingOrders
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
              const SizedBox(height: 8), // Decreased space here
              _buildTableHeader(
                  manifestProvider.orders.length, manifestProvider),
              const SizedBox(height: 4), // New space for alignment
              Expanded(
                child: Stack(
                  children: [
                    if (manifestProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.star_border_outlined,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (manifestProvider.orders.isEmpty)
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
                    else
                      ListView.builder(
                        itemCount: manifestProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = manifestProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, manifestProvider),
                              const Divider(thickness: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              CustomPaginationFooter(
                currentPage:
                    manifestProvider.currentPage, // Ensure correct currentPage
                totalPages: manifestProvider.totalPages,
                buttonSize: 30,
                pageController: manifestProvider.textEditingController,
                onFirstPage: () {
                  manifestProvider.goToPage(1);
                },
                onLastPage: () {
                  manifestProvider.goToPage(manifestProvider.totalPages);
                },
                onNextPage: () {
                  if (manifestProvider.currentPage <
                      manifestProvider.totalPages) {
                    print(
                        'Navigating to page: ${manifestProvider.currentPage + 1}');
                    manifestProvider.goToPage(manifestProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (manifestProvider.currentPage > 1) {
                    print(
                        'Navigating to page: ${manifestProvider.currentPage - 1}');
                    manifestProvider.goToPage(manifestProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  manifestProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page =
                      int.tryParse(manifestProvider.textEditingController.text);
                  if (page != null &&
                      page > 0 &&
                      page <= manifestProvider.totalPages) {
                    manifestProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(int totalCount, ManifestProvider manifestProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: manifestProvider.selectAll,
              onChanged: (value) {
                manifestProvider.toggleSelectAll(value!);
              },
            ),
          ),
          Text(
            'Select All(${manifestProvider.selectedCount})',
          ),
          buildHeader('ORDERS', flex: 8), // Increased flex
          // buildHeader('DELIVERY PARTNER SIGNATURE',
          //     flex: 5), // Decreased flex for better alignment
          // buildHeader('CONFIRM', flex: 3),
        ],
      ),
    );
  }

  Widget buildHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      Order order, int index, ManifestProvider manifestProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 8.0), // Increased vertical space for order cards
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: manifestProvider.selectedProducts[index],
            onChanged: (isSelected) {
              manifestProvider.handleRowCheckboxChange(index, isSelected!);
            },
          ),
          Expanded(
            flex: 5, // Increased flex for wider order card
            child: OrderCard(order: order),
          ),
          // const SizedBox(
          //     width: 20), // Reduced space between order card and signature
          // buildCell(
          //   // Use the getOrderImage method to handle image display
          //   order.getOrderImage(),
          //   flex: 3,
          // ),
          // const SizedBox(width: 4),
          // buildCell(
          //   order.checkManifest!.approved
          //       ? const Icon(
          //           Icons.check_circle,
          //           color: Colors.green,
          //           size: 24,
          //         )
          //       : const SizedBox.shrink(),
          //   flex: 2,
          // ),
        ],
      ),
    );
  }

  Widget buildCell(Widget content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Center(child: content),
      ),
    );
  }
}
