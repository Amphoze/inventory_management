import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/small_combo_card.dart';
import 'package:inventory_management/provider/dispatched_provider.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'model/orders_model.dart';

class DispatchedOrders extends StatefulWidget {
  const DispatchedOrders({super.key});

  @override
  State<DispatchedOrders> createState() => _DispatchedOrdersState();
}

class _DispatchedOrdersState extends State<DispatchedOrders> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DispatchedProvider>(context, listen: false)
          .fetchOrdersWithStatus9();
    });
  }

  void _onSearchButtonPressed(String query) {
    if (query.trim().isNotEmpty) {
      Provider.of<DispatchedProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DispatchedProvider>(
      builder: (context, dispatchProvider, child) {
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
                          if (query.isNotEmpty) {
                            dispatchProvider.searchOrders(query);
                          }
                        },
                      ),
                    ),
                    const Spacer(),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardsred,
                      ),
                      onPressed: dispatchProvider.isCancel
                          ? null // Disable button while loading
                          : () async {
                              final provider = Provider.of<DispatchedProvider>(
                                  context,
                                  listen: false);

                              // Collect selected order IDs
                              List<String> selectedOrderIds = provider.orders
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      provider.selectedProducts[entry.key])
                                  .map((entry) => entry.value.orderId)
                                  .toList();

                              if (selectedOrderIds.isEmpty) {
                                Utils.showSnackBar(context, 'No orders selected', isError: true);
                              } else {
                                String resultMessage = await provider
                                    .cancelOrders(context, selectedOrderIds);

                                Color snackBarColor;
                                if (resultMessage.contains('success')) {
                                  snackBarColor =
                                      AppColors.green; // Success: Green
                                } else if (resultMessage.contains('error') ||
                                    resultMessage.contains('failed')) {
                                  snackBarColor =
                                      AppColors.cardsred; // Error: Red
                                } else {
                                  snackBarColor =
                                      AppColors.orange; // Other: Orange
                                }

                                Utils.showSnackBar(context, resultMessage, color: snackBarColor, seconds: 5);
                              }
                            },
                      child: dispatchProvider.isCancel
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : const Text(
                              'Cancel Orders',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 8),

                    _buildDispatchButton(dispatchProvider),

                    const SizedBox(width: 8),
                    // Refresh Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: dispatchProvider.isRefreshingOrders
                          ? null
                          : () async {
                              dispatchProvider.fetchOrdersWithStatus9();
                            },
                      child: dispatchProvider.isRefreshingOrders
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
              _buildTableHeader(
                  dispatchProvider.orders.length, dispatchProvider),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (dispatchProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.find_replace,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (dispatchProvider.orders.isEmpty)
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
                        itemCount: dispatchProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = dispatchProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, dispatchProvider),
                              const Divider(thickness: 1, color: Colors.grey),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              Consumer<DispatchedProvider>(
                builder: (context, dispatchProvider, child) {
                  return CustomPaginationFooter(
                    currentPage: dispatchProvider.currentPage,
                    totalPages: dispatchProvider.totalPages,
                    totalCount: dispatchProvider.totalOrders,
                    buttonSize: 30,
                    pageController: dispatchProvider.textEditingController,
                    onFirstPage: () {
                      dispatchProvider.goToPage(1);
                    },
                    onLastPage: () {
                      dispatchProvider.goToPage(dispatchProvider.totalPages);
                    },
                    onNextPage: () {
                      if (dispatchProvider.currentPage <
                          dispatchProvider.totalPages) {
                        dispatchProvider.goToPage(dispatchProvider.currentPage + 1);
                      }
                    },
                    onPreviousPage: () {
                      if (dispatchProvider.currentPage > 1) {
                        dispatchProvider.goToPage(dispatchProvider.currentPage - 1);
                      }
                    },
                    onGoToPage: (page) {
                      dispatchProvider.goToPage(page);
                    },
                    onJumpToPage: () {
                      final page =
                          int.tryParse(dispatchProvider.textEditingController.text);
                      if (page != null &&
                          page > 0 &&
                          page <= dispatchProvider.totalPages) {
                        dispatchProvider.goToPage(page);
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

  Widget _buildOrderCard(
      Order order, int index, DispatchedProvider dispatchProvider) {
    // String? selectedStatus;
    // bool isSaved = order.trackingStatus != '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: dispatchProvider
                .selectedProducts[index], // Accessing selected products
            onChanged: (isSelected) {
              dispatchProvider.handleRowCheckboxChange(index, isSelected!);
            },
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Space between elements
              children: [
                Expanded(
                  child: SmallComboCard(
                      order: order), // Your existing OrderCard widget
                ),
                const SizedBox(width: 50),
                SizedBox(
                  width: 200,
                  child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      children: [
                        // PopupMenuButton<String>(
                        //   tooltip: 'Select tracking status',
                        //   onSelected: (String newStatus) {
                        //     setState(() {
                        //       selectedStatus = newStatus;
                        //       order.trackingStatus = newStatus;
                        //     });
                        //   },
                        //   itemBuilder: (BuildContext context) {
                        //     return <String>[
                        //       "Delivered",
                        //       "RTO",
                        //       "Disposed Off",
                        //       "Rack Up",
                        //       "Lost",
                        //       "In Transit",
                        //       "Damaged",
                        //       "Out For Delivery",
                        //       "Not Confirmed",
                        //       "Cancelled",
                        //       "Confirmed",
                        //       "Shipped",
                        //       "Destroyed",
                        //       "Discarded Entry",
                        //       "Attempted",
                        //       "Hold"
                        //     ].map<PopupMenuItem<String>>((String value) {
                        //       return PopupMenuItem<String>(
                        //         value: value,
                        //         child: Text(value),
                        //       );
                        //     }).toList();
                        //   },
                        //   child: isSaved == true
                        //       ? Text(
                        //           order.trackingStatus!,
                        //         )
                        //       : Text(
                        //           selectedStatus == null
                        //               ? "Select tracking status"
                        //               : selectedStatus!,
                        //           style: TextStyle(
                        //               color: selectedStatus == null
                        //                   ? AppColors.primaryBlue
                        //                   : Colors.black),
                        //         ),
                        // ),
                        Text(
                          order.trackingStatus?.toUpperCase() ?? '',
                        ),
                        // const SizedBox(
                        //   height: 8,
                        // ),
                        // if (selectedStatus != null)
                        //   ElevatedButton(
                        //     onPressed: () {
                        //       isSaved = true;
                        //       if (selectedStatus != null) {
                        //         dispatchProvider.updateOrderTrackingStatus(
                        //             context, order.id, selectedStatus!);
                        //       }
                        //       log("id: ${order.id}");
                        //       log("tracking: ${order.trackingStatus}");
                        //       log('Saving status: $selectedStatus');
                        //     },
                        //     child: const Text('Save'),
                        //   ),
                      ],
                    );
                  }),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // if (dispatchProvider.isDispatching)
          //   Center(
          //     child: CircularProgressIndicator(), // Loading indicator
          //   ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(int totalCount, DispatchedProvider returnprovider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            value: returnprovider.selectAll,
            onChanged: (value) {
              returnprovider.toggleSelectAll(value!);
            },
          ),
          Text(
            'Select All(${returnprovider.selectedCount})',
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

  Widget _buildDispatchButton(DispatchedProvider dispatchProvider) {
    return ElevatedButton(
      onPressed: dispatchProvider.selectedCount > 0
          ? () async {
              await dispatchProvider
                  .returnSelectedOrders(); // Call the return method
            }
          : null, // Disable the button if no orders are selected
      child: dispatchProvider.isDispatching
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Return Orders',
              style: TextStyle(color: Colors.white),
            ),
    );
  }
}
