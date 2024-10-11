import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/packer_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';

class PackerPage extends StatefulWidget {
  const PackerPage({super.key});

  @override
  State<PackerPage> createState() => _PackerPageState();
}

class _PackerPageState extends State<PackerPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PackerProvider>(context, listen: false)
          .fetchOrdersWithStatus4();
    });
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<PackerProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PackerProvider>(
      builder: (context, packerProvider, child) {
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
                              packerProvider.fetchOrdersWithStatus4();
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
                        packerProvider.fetchOrdersWithStatus4();
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
              _buildTableHeader(packerProvider.orders.length, packerProvider),
              Expanded(
                child: Stack(
                  children: [
                    if (packerProvider.isLoading)
                      const Center(child: PackerLoadingAnimation())
                    else if (packerProvider.orders.isEmpty)
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
                        itemCount: packerProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = packerProvider.orders[index];
                          return Column(
                            children: [
                              _buildOrderCard(order, index, packerProvider),
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
                    packerProvider.currentPage, // Ensure correct currentPage
                totalPages: packerProvider.totalPages,
                buttonSize: 30,
                pageController: packerProvider.textEditingController,
                onFirstPage: () {
                  packerProvider.goToPage(1);
                },
                onLastPage: () {
                  packerProvider.goToPage(packerProvider.totalPages);
                },
                onNextPage: () {
                  if (packerProvider.currentPage < packerProvider.totalPages) {
                    print(
                        'Navigating to page: ${packerProvider.currentPage + 1}');
                    packerProvider.goToPage(packerProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (packerProvider.currentPage > 1) {
                    print(
                        'Navigating to page: ${packerProvider.currentPage - 1}');
                    packerProvider.goToPage(packerProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  packerProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page =
                      int.tryParse(packerProvider.textEditingController.text);
                  if (page != null &&
                      page > 0 &&
                      page <= packerProvider.totalPages) {
                    packerProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(int totalCount, PackerProvider packerProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          buildHeader('ORDERS', flex: 9),
          buildHeader('CUSTOMER', flex: 3),
          buildHeader('DATE', flex: 3),
          buildHeader('TOTAL', flex: 2),
          buildHeader('BOX SIZE', flex: 2),
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
      Order order, int index, PackerProvider packerProvider) {
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
              packerProvider.formatDate(order.date!),
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
              '${order.boxSize}',
              style: const TextStyle(fontSize: 16),
            ),
            flex: 2,
          ),
          const SizedBox(width: 4),
          buildCell(
            order.isPackerFullyScanned
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
