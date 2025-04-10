import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/racked_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';

class RackedPage extends StatefulWidget {
  const RackedPage({super.key});

  @override
  State<RackedPage> createState() => _RackedPageState();
}

class _RackedPageState extends State<RackedPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RackedProvider>(context, listen: false)
          .fetchOrdersWithStatus7();
    });
    Provider.of<RackedProvider>(context, listen: false)
        .textEditingController
        .clear();
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<RackedProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RackedProvider>(
      builder: (context, rackedProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Search TextField
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
                        onChanged: (query) {
                          // Trigger a rebuild to show/hide the search button
                          setState(() {
                            // Update search focus
                          });
                          if (query.isEmpty) {
                            // Reset to all orders if search is cleared
                            rackedProvider.fetchOrdersWithStatus7();
                          }
                        },
                        onTap: () {
                          setState(() {
                            // Mark the search field as focused
                          });
                        },
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            rackedProvider.searchOrders(query);
                          }
                        },
                        onEditingComplete: () {
                          // Mark it as not focused when done
                          FocusScope.of(context)
                              .unfocus(); // Dismiss the keyboard
                        },
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
                    //   onPressed: rackedProvider.isCancel
                    //       ? null // Disable button while loading
                    //       : () async {
                    //           final provider = Provider.of<RackedProvider>(
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
                    //                 .cancelOrders(context, selectedOrderIds);

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
                    //   child: rackedProvider.isCancel
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
                    // const SizedBox(width: 8),
                    // Refresh Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: rackedProvider.isRefreshingOrders
                          ? null
                          : () async {
                              rackedProvider.fetchOrdersWithStatus7();
                            },
                      child: rackedProvider.isRefreshingOrders
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
              _buildTableHeader(rackedProvider.orders.length, rackedProvider),
              Expanded(
                child: Stack(
                  children: [
                    if (rackedProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.shelves,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (rackedProvider.orders.isEmpty)
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
                        itemCount: rackedProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = rackedProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, rackedProvider),
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
                    rackedProvider.currentPage, // Ensure correct currentPage
                totalPages: rackedProvider.totalPages,
                buttonSize: 30,
                pageController: rackedProvider.textEditingController,
                onFirstPage: () {
                  rackedProvider.goToPage(1);
                },
                onLastPage: () {
                  rackedProvider.goToPage(rackedProvider.totalPages);
                },
                onNextPage: () {
                  if (rackedProvider.currentPage < rackedProvider.totalPages) {
                    print(
                        'Navigating to page: ${rackedProvider.currentPage + 1}');
                    rackedProvider.goToPage(rackedProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (rackedProvider.currentPage > 1) {
                    print(
                        'Navigating to page: ${rackedProvider.currentPage - 1}');
                    rackedProvider.goToPage(rackedProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  rackedProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page =
                      int.tryParse(rackedProvider.textEditingController.text);
                  if (page != null &&
                      page > 0 &&
                      page <= rackedProvider.totalPages) {
                    rackedProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(int totalCount, RackedProvider rackedProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          buildHeader('ORDERS', flex: 9),
          buildHeader('CUSTOMER', flex: 3),
          buildHeader('DATE', flex: 3),
          buildHeader('TOTAL', flex: 2),
          buildHeader('WEIGHT', flex: 2),
          buildHeader('CONFIRM', flex: 2),
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
      Order order, int index, RackedProvider rackedProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 9,
            child: OrderComboCard(
              order: order,
              toShowBy: false,
              toShowOrderDetails: false,
            ),
          ),
          const SizedBox(width: 4),
          buildCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _getCustomerFullName(order.customer),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (order.customer?.phone != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Add your phone action here
                        },
                        icon: const Icon(
                          Icons.phone,
                          color: AppColors.green,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCustomerPhoneNumber(order.customer?.phone),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Phone not available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            flex: 3,
          ),
          const SizedBox(width: 4),
          buildCell(
            Text(
              rackedProvider.formatDate(order.date!),
              style: const TextStyle(fontSize: 16),
            ),
            flex: 3,
          ),
          const SizedBox(width: 4),
          buildCell(
            Text(
              'Rs.${order.totalAmount!}',
              style: const TextStyle(fontSize: 16),
            ),
            flex: 2,
          ),
          const SizedBox(width: 4),
          buildCell(
            Text(
              '${order.totalWeight}',
              style: const TextStyle(fontSize: 16),
            ),
            flex: 2,
          ),
          const SizedBox(width: 4),
          buildCell(
            order.racker!.approved
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  )
                : const SizedBox.shrink(),
            flex: 2,
          ),
        ],
      ),
    );
  }

  static String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  String _getCustomerPhoneNumber(dynamic phoneNumber) {
    if (phoneNumber == null) return 'Unknown';

    // Convert to string if it's an int, otherwise return as is
    return maskPhoneNumber(phoneNumber.toString());
  }

  String _getCustomerFullName(Customer? customer) {
    if (customer == null) return 'Unknown';

    final firstName = customer.firstName ?? '';
    final lastName = customer.lastName ?? '';

    // Check if both first name and last name are empty
    if (firstName.isEmpty && lastName.isEmpty) {
      return 'Unknown';
    }

    return (firstName + (lastName.isNotEmpty ? ' $lastName' : '')).trim();
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
