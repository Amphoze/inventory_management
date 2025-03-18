import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/order_combo_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/packer_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';

import 'Custom-Files/utils.dart';

class PackerPage extends StatefulWidget {
  const PackerPage({super.key});

  @override
  State<PackerPage> createState() => _PackerPageState();
}

class _PackerPageState extends State<PackerPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  String selectedPicklist = '';
  List<String> picklistIds = ['W1', 'W2', 'W3', 'G1', 'G2', 'G3', 'E1', 'E2', 'E3'];
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PackerProvider>(context, listen: false)
          .fetchOrdersWithStatus5();
    });
    Provider.of<PackerProvider>(context, listen: false)
        .textEditingController
        .clear();
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12.0),
                        ),
                        onChanged: (query) {
                          // Trigger a rebuild to show/hide the search button
                          setState(() {
                            // Update search focus
                          });
                          if (query.isEmpty) {
                            // Reset to all orders if search is cleared
                            packerProvider.fetchOrdersWithStatus5();
                          }
                        },
                        onTap: () {
                          setState(() {
                            // Mark the search field as focused
                          });
                        },
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            packerProvider.searchOrders(query);
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
                    //   ElevatedButton(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.cardsred,
                    //   ),
                    //   onPressed: packerProvider.isCancel
                    //       ? null // Disable button while loading
                    //       : () async {
                    //           final provider = Provider.of<PackerProvider>(
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
                    //   child: packerProvider.isCancel
                    //       ? const SizedBox(
                    //           width: 20,
                    //           height: 20,
                    //           child:
                    //               CircularProgressIndicator(color: Colors.white),
                    //         )
                    //       : const Text(
                    //           'Cancel Orders',
                    //           style: TextStyle(color: Colors.white),
                    //         ),
                    // ),
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

                                      final res = await context.read<BookProvider>().generatePacklist(context, _dateController.text, selectedPicklist);

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
                    // Refresh Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: packerProvider.isRefreshingOrders
                          ? null
                          : () async {
                              packerProvider.fetchOrdersWithStatus5();
                            },
                      child: packerProvider.isRefreshingOrders
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
              _buildTableHeader(packerProvider.orders.length, packerProvider),
              Expanded(
                child: Stack(
                  children: [
                    if (packerProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.backpack_rounded,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
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
          buildHeader('PACKAGE NAME', flex: 2),
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
            child: OrderComboCard(
              toShowBy: false,
              order: order,
              toShowOrderDetails: false,
              isPacked: true,
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
          // buildCell(
          //   Text(
          //     order.boxSize,
          //     style: const TextStyle(fontSize: 16),
          //   ),
          //   flex: 2,
          // ),
          buildCell(
            Text(
              order.outerPackage.replaceAll('[', '').replaceAll(']', '') ?? '',
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
