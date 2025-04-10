import 'package:flutter/material.dart';
import 'package:inventory_management/provider/rto_provider.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Widgets/order_card.dart';
import 'model/orders_model.dart';

class RTOOrders extends StatefulWidget {
  const RTOOrders({super.key});

  @override
  State<RTOOrders> createState() => _RTOOrdersState();
}

class _RTOOrdersState extends State<RTOOrders> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RtoProvider>(context, listen: false).fetchOrdersWithStatus11();
    });
  }

  void _onSearchButtonPressed(String query) {
    if (query.trim().isNotEmpty) {
      Provider.of<RtoProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RtoProvider>(
      builder: (context, returnProvider, child) {
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
                        onTap: () {
                          setState(() {
                            // Mark the search field as focused
                          });
                        },
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            returnProvider.searchOrders(query);
                          }
                        },
                        onEditingComplete: () {
                          // Mark it as not focused when done
                          FocusScope.of(context).unfocus(); // Dismiss the keyboard
                        },
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: returnProvider.isRefreshingOrders
                          ? null
                          : () async {
                              returnProvider.fetchOrdersWithStatus11();
                            },
                      child: returnProvider.isRefreshingOrders
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
              _buildTableHeader(returnProvider.orders.length),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (returnProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.find_replace,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (returnProvider.orders.isEmpty)
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
                        itemCount: returnProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = returnProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, returnProvider),
                              const Divider(thickness: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              Consumer<RtoProvider>(
                builder: (context, returnProvider, child) {
                  return CustomPaginationFooter(
                    currentPage: returnProvider.currentPage,
                    totalPages: returnProvider.totalPages,
                    totalCount: returnProvider.totalOrders,
                    buttonSize: 30,
                    pageController: returnProvider.textEditingController,
                    onFirstPage: () {
                      returnProvider.goToPage(1);
                    },
                    onLastPage: () {
                      returnProvider.goToPage(returnProvider.totalPages);
                    },
                    onNextPage: () {
                      if (returnProvider.currentPage < returnProvider.totalPages) {
                        returnProvider.goToPage(returnProvider.currentPage + 1);
                      }
                    },
                    onPreviousPage: () {
                      if (returnProvider.currentPage > 1) {
                        returnProvider.goToPage(returnProvider.currentPage - 1);
                      }
                    },
                    onGoToPage: (page) {
                      returnProvider.goToPage(page);
                    },
                    onJumpToPage: () {
                      final page = int.tryParse(returnProvider.textEditingController.text);
                      if (page != null && page > 0 && page <= returnProvider.totalPages) {
                        returnProvider.goToPage(page);
                      }
                    },
                  );
                }
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, int index, RtoProvider returnProvider) {
    if (index >= returnProvider.selectedProducts.length) {
      returnProvider.selectedProducts = List<bool>.filled(returnProvider.orders.length, false);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: returnProvider.selectedProducts[index], // Accessing selected products
            onChanged: (isSelected) {
              returnProvider.handleRowCheckboxChange(index, isSelected!);
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
                  '${order.trackingStatus?.isEmpty ?? true ? "NA" : order.trackingStatus}', // Display "NA" if null or empty
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
          // if (returnProvider.isReturning)
          //   Center(
          //     child: CircularProgressIndicator(), // Loading indicator
          //   ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(int totalCount) {
    final returnProvider = Provider.of<RtoProvider>(context);

    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            value: returnProvider.selectAll,
            onChanged: (value) {
              returnProvider.toggleSelectAll(value!);
            },
          ),
          Text(
            'Select All(${returnProvider.selectedCount})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          buildHeader('ORDERS', flex: 8),
          buildHeader('Tracking Status', flex: 3),
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
}
