import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/checker_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';

class CheckerPage extends StatefulWidget {
  const CheckerPage({super.key});

  @override
  State<CheckerPage> createState() => _CheckerPageState();
}

class _CheckerPageState extends State<CheckerPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckerProvider>(context, listen: false)
          .fetchOrdersWithStatus5();
    });
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<CheckerProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckerProvider>(
      builder: (context, checkerProvider, child) {
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
                              checkerProvider.fetchOrdersWithStatus5();
                            }
                          },
                          onTap: () {
                            setState(() {
                              // Mark the search field as focused
                            });
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
                    // Refresh Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: () {
                        checkerProvider.fetchOrdersWithStatus5();
                      },
                      child: const Text(
                        'Refresh',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildTableHeader(checkerProvider.orders.length, checkerProvider),
              Expanded(
                child: Stack(
                  children: [
                    if (checkerProvider.isLoading)
                      const Center(child: CheckerLoadingAnimation())
                    else if (checkerProvider.orders.isEmpty)
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
                        itemCount: checkerProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = checkerProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, checkerProvider),
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
                    checkerProvider.currentPage, // Ensure correct currentPage
                totalPages: checkerProvider.totalPages,
                buttonSize: 30,
                pageController: checkerProvider.textEditingController,
                onFirstPage: () {
                  checkerProvider.goToPage(1);
                },
                onLastPage: () {
                  checkerProvider.goToPage(checkerProvider.totalPages);
                },
                onNextPage: () {
                  if (checkerProvider.currentPage <
                      checkerProvider.totalPages) {
                    print(
                        'Navigating to page: ${checkerProvider.currentPage + 1}');
                    checkerProvider.goToPage(checkerProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (checkerProvider.currentPage > 1) {
                    print(
                        'Navigating to page: ${checkerProvider.currentPage - 1}');
                    checkerProvider.goToPage(checkerProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  checkerProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page =
                      int.tryParse(checkerProvider.textEditingController.text);
                  if (page != null &&
                      page > 0 &&
                      page <= checkerProvider.totalPages) {
                    checkerProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(int totalCount, CheckerProvider checkerProvider) {
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
      Order order, int index, CheckerProvider checkerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 9,
            child: OrderCard(order: order),
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
              checkerProvider.formatDate(order.date!),
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
            order.checker!.approved
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

  String _getCustomerPhoneNumber(dynamic phoneNumber) {
    if (phoneNumber == null) return 'Unknown';

    // Convert to string if it's an int, otherwise return as is
    return phoneNumber.toString();
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
