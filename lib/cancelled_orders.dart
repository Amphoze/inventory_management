import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventory_management/provider/cancelled_provider.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Widgets/order_card.dart';
import 'model/orders_model.dart';

class CancelledOrders extends StatefulWidget {
  const CancelledOrders({super.key});

  @override
  State<CancelledOrders> createState() => _CancelledOrdersState();
}

class _CancelledOrdersState extends State<CancelledOrders> {
  final TextEditingController _searchController = TextEditingController();
  late CancelledProvider cancelledProvider;

  @override
  void initState() {
    super.initState();
    cancelledProvider = context.read<CancelledProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cancelledProvider.fetchOrdersWithStatus10();
    });
  }

  void _onSearchButtonPressed(String query) {
    if (query.trim().isNotEmpty) {
      cancelledProvider.onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CancelledProvider>(
      builder: (context, cancelProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 35,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(183, 6, 90, 216),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Search by Order ID',
                            hintStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                          onChanged: _onSearchButtonPressed,
                          onSubmitted: (query) {
                            if (query.trim().isNotEmpty) {
                              cancelProvider.searchOrders(query);
                            } else {
                              cancelProvider.fetchOrdersWithStatus10();
                            }
                          }),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: cancelProvider.isRefreshingOrders
                          ? null
                          : () async {
                              cancelProvider.fetchOrdersWithStatus10();
                            },
                      child: cancelProvider.isRefreshingOrders
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
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              _buildTableHeader(cancelProvider.orders.length, cancelProvider),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (cancelProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.find_replace,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (cancelProvider.orders.isEmpty)
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
                        itemCount: cancelProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = cancelProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, cancelProvider),
                              const Divider(thickness: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              Consumer<CancelledProvider>(builder: (context, cancelProvider, child) {
                return CustomPaginationFooter(
                  currentPage: cancelProvider.currentPage,
                  totalPages: cancelProvider.totalPages,
                  totalCount: cancelProvider.totalOrders,
                  buttonSize: 30,
                  pageController: cancelProvider.textEditingController,
                  onFirstPage: () {
                    cancelProvider.goToPage(1);
                  },
                  onLastPage: () {
                    cancelProvider.goToPage(cancelProvider.totalPages);
                  },
                  onNextPage: () {
                    if (cancelProvider.currentPage < cancelProvider.totalPages) {
                      cancelProvider.goToPage(cancelProvider.currentPage + 1);
                    }
                  },
                  onPreviousPage: () {
                    if (cancelProvider.currentPage > 1) {
                      cancelProvider.goToPage(cancelProvider.currentPage - 1);
                    }
                  },
                  onGoToPage: (page) {
                    cancelProvider.goToPage(page);
                  },
                  onJumpToPage: () {
                    final page = int.tryParse(cancelProvider.textEditingController.text);
                    if (page != null && page > 0 && page <= cancelProvider.totalPages) {
                      cancelProvider.goToPage(page);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, int index, CancelledProvider cancelProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: cancelProvider.selectedProducts[index], // Accessing selected products
            onChanged: (isSelected) {
              cancelProvider.handleRowCheckboxChange(index, isSelected!);
            },
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between elements
              children: [
                Expanded(
                  child: OrderCard(order: order), // Your existing OrderCard widget
                ),
                const SizedBox(width: 200), // Add some spacing between the elements

                Text(
                  '${(order.trackingStatus?.isEmpty ?? true) ? "NA" : order.trackingStatus}', // Display "NA" if null or empty
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: order.trackingStatus == 'return' ? Colors.green : Colors.black,
                  ),
                ),

                const SizedBox(width: 100),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // if (cancelProvider.isReturning)
          //   Center(
          //     child: CircularProgressIndicator(), // Loading indicator
          //   ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(int totalCount, CancelledProvider cancelProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            value: cancelProvider.selectAll,
            onChanged: (value) {
              cancelProvider.toggleSelectAll(value!);
            },
          ),
          Text(
            'Select All(${cancelProvider.selectedCount})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          buildHeader('ORDERS', flex: 3),
          buildHeader('Tracking Status', flex: 1),
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

  Widget buildCell(Widget content, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Center(child: content),
      ),
    );
  }

  // Widget _buildReturnButton(CancelledProvider cancelProvider) {
  //   return ElevatedButton(
  //     onPressed: cancelProvider.selectedCount > 0
  //         ? () async {
  //             await cancelProvider
  //                 .returnSelectedOrders(); // Call the return method
  //           }
  //         : null, // Disable the button if no orders are selected
  //     child: cancelProvider.isCancelling
  //         ? const SizedBox(
  //             width: 24,
  //             height: 24,
  //             child: CircularProgressIndicator(
  //               color: Colors.white,
  //               strokeWidth: 3,
  //             ),
  //           )
  //         : const Text(
  //             'Cancel',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //   );
  // }
}
