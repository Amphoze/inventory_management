import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:logger/logger.dart';

// import 'package:inventory_management/Widgets/picker_order_card.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/picker_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Custom-Files/loading_indicator.dart';
import 'constants/constants.dart';
import 'package:http/http.dart' as http;

class PickerPage extends StatefulWidget {
  const PickerPage({super.key});

  @override
  State<PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends State<PickerPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  bool _isDownloading = false;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = _dateFormat.format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PickerProvider>(context, listen: false).fetchOrdersWithStatus4();
    });
    Provider.of<PickerProvider>(context, listen: false).textEditingController.clear();
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<PickerProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  void _showOrderIdsDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<String> orderIds = (order['orderIds'] as List).cast<String>();

        return StatefulBuilder(
          builder: (context, setState) {
            List<String> filteredIds = orderIds.where((id) => id.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return AlertDialog(
              title: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search Order IDs',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: filteredIds.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(filteredIds[index]),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PickerProvider>(builder: (context, pickerProvider, child) {
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
                            pickerProvider.fetchOrdersWithStatus4();
                          }
                        },
                        onTap: () {
                          setState(() {
                            // Mark the search field as focused
                          });
                        },
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            pickerProvider.searchOrders(query);
                          }
                        },
                        onEditingComplete: () {
                          // Mark it as not focused when done
                          FocusScope.of(context).unfocus(); // Dismiss the keyboard
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
                    onPressed: _searchController.text.isNotEmpty ? _onSearchButtonPressed : null,
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final TextEditingController dateController = TextEditingController();
                          final TextEditingController picklistIdController = TextEditingController();

                          return AlertDialog(
                            title: const Text('Download Picklist PDF'),
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
                                  onTap: () => _selectDate(context),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: picklistIdController,
                                  decoration: const InputDecoration(
                                    labelText: 'Picklist ID',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
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
                                  // Navigator.pop(context);
                                  setState(() {
                                    _isDownloading = true;
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

                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('authToken') ?? '';
                                  final date = _dateController.text;
                                  final id = picklistIdController.text.trim();
                                  String url = '${await Constants.getBaseUrl()}/order-picker/picklistCsv?date=$date&picklistId=$id';

                                  Logger().e('picklist url: $url');

                                  Map<String, dynamic>? data;

                                  try {
                                    final response = await http.get(
                                      Uri.parse(url),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Content-Type': 'application/json',
                                      },
                                    );

                                    if (response.statusCode == 200) {
                                      data = json.decode(response.body);
                                      final downloadUrl = data!['downloadUrl'];

                                      if (downloadUrl != null) {
                                        final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
                                        if (canLaunch) {
                                          await launchUrl(Uri.parse(downloadUrl));
                                        } else {
                                          log('Could not launch $downloadUrl');
                                        }
                                      } else {
                                        log('No download URL found');
                                        // throw Exception('No download URL found');
                                      }
                                    } else {
                                      // Handle non-success responses
                                    }
                                  } catch (e) {
                                    log('error aaya hai: $e');
                                  } finally {
                                    setState(() {
                                      _isDownloading = false;

                                      Navigator.pop(context);
                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(data!['message'] ?? ''),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    });
                                  }
                                },
                                child: const Text('Download'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Download Picklist PDF'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    onPressed: pickerProvider.isRefreshingOrders
                        ? null
                        : () async {
                            pickerProvider.fetchOrdersWithStatus4();
                          },
                    child: pickerProvider.isRefreshingOrders
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
            _buildTableHeader(pickerProvider.extractedOrders.length, pickerProvider),
            Expanded(
              child: Stack(
                children: [
                  if (pickerProvider.isLoading)
                    const Center(
                      child: LoadingAnimation(
                        icon: Icons.local_shipping,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryBlue,
                        size: 80.0,
                      ),
                    )
                  else if (pickerProvider.extractedOrders.isEmpty)
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
                      itemCount: pickerProvider.extractedOrders.length,
                      itemBuilder: (context, index) {
                        final extractedOrders = pickerProvider.extractedOrders[index];
                        return Column(
                          children: [
                            _buildOrderCard(extractedOrders),
                            const Divider(thickness: 1, color: Colors.grey),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            CustomPaginationFooter(
              currentPage: pickerProvider.currentPage,
              totalPages: pickerProvider.totalPages,
              buttonSize: 30,
              pageController: pickerProvider.textEditingController,
              onFirstPage: () {
                pickerProvider.goToPage(1);
                pickerProvider.textEditingController.clear(); // Reset the page number
              },
              onLastPage: () {
                pickerProvider.goToPage(pickerProvider.totalPages);
                pickerProvider.textEditingController.clear(); // Reset the page number
              },
              onNextPage: () {
                if (pickerProvider.currentPage < pickerProvider.totalPages) {
                  pickerProvider.goToPage(pickerProvider.currentPage + 1);
                  pickerProvider.textEditingController.clear(); // Reset the page number
                }
              },
              onPreviousPage: () {
                if (pickerProvider.currentPage > 1) {
                  pickerProvider.goToPage(pickerProvider.currentPage - 1);
                  pickerProvider.textEditingController.clear(); // Reset the page number
                }
              },
              onGoToPage: (page) {
                pickerProvider.goToPage(page);
                pickerProvider.textEditingController.clear(); // Reset the page number
              },
              onJumpToPage: () {
                final page = int.tryParse(pickerProvider.textEditingController.text);
                if (page != null && page > 0 && page <= pickerProvider.totalPages) {
                  pickerProvider.goToPage(page);
                  pickerProvider.textEditingController.clear(); // Reset the page number
                } else {
                  _showSnackbar(context, 'Please enter a valid page number between 1 and ${pickerProvider.totalPages}.');
                }
              },
            ),
          ],
        ),
      );
    });
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTableHeader(int totalCount, PickerProvider pickerProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          buildHeader('PRODUCTS', flex: 9),
          buildHeader('QUANTITY', flex: 2),
          // buildHeader('CUSTOMER', flex: 3),
          buildHeader('ID', flex: 2),
          // buildHeader('DATE', flex: 3),
          // buildHeader('TOTAL', flex: 2),
          // buildHeader('CONFIRM', flex: 2),
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
    Map<String, dynamic> order,
  ) {
    // order['items][index]['product_id'][]
    return Card(
      color: AppColors.white,
      elevation: 4, // Reduced elevation for less shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Slightly smaller rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add padding here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text.rich(
            //   TextSpan(
            //       text: "Updated on: ",
            //       children: [
            //         TextSpan(
            //             text: DateFormat('yyyy-MM-dd\',\' hh:mm a').format(
            //               DateTime.parse("${order['items'][index]['product_id']}"),
            //             ),
            //             style: const TextStyle(
            //               fontWeight: FontWeight.normal,
            //             )),
            //       ],
            //       style: const TextStyle(
            //         fontWeight: FontWeight.bold,
            //       )),
            // ),
            InkWell(
              onTap: () => _showOrderIdsDialog(order),
              child: Text.rich(
                TextSpan(
                    text: "Order ID: ",
                    children: [
                      TextSpan(
                        text: (order['orderIds'] as List).join(', '),
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: " (${order['orderIds'].length})",
                      ),
                    ],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 15,
                  child: SizedBox(
                    // height: 200, // Removed fixed height
                    child: ListView.builder(
                      shrinkWrap: true, // Allow ListView to take necessary height
                      itemCount: order['items'].length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(10), // Slightly smaller rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08), // Lighter shadow for smaller card
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0), // Reduced padding inside product card
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 60, // Smaller image size
                                        height: 60,
                                        child: order['items'][index]['product_id']['shopifyImage'] != null &&
                                                order['items'][index]['product_id']['shopifyImage'].isNotEmpty
                                            ? Image.network(
                                                '${order['items'][index]['product_id']['shopifyImage']}',
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 40, // Fallback icon size
                                                color: AppColors.grey,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0), // Reduced spacing between image and text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order['items'][index]['product_id']['displayName'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14, // Reduced font size
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6.0), // Reduced spacing between text elements
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'SKU: ',
                                                      style: TextStyle(
                                                        color: Colors.blueAccent,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13, // Reduced font size
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: order['items'][index]['product_id']['sku'],
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13, // Reduced font size
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Amount: ',
                                                      style: TextStyle(
                                                        color: Colors.blueAccent,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13, // Reduced font size
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: order['items'][index]['product_id']['mrp'].toString(),
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13, // Reduced font size
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(), // Ensures `qty` is aligned to the right end
                                    const Text(
                                      "X",
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Spacer(), // Ensures `qty` is aligned to the right end
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                                      child: Center(
                                        child: Text(
                                          "${order['items'][index]['product_id']['itemQty']}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 60,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                buildCell(
                  Text(
                    "${order['picklistId']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                  flex: 3,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                      text: "Created on: ",
                      children: [
                        TextSpan(
                          text: DateFormat('yyyy-MM-dd, hh:mm a').format(
                            DateTime.parse(order['createdAt']).toLocal(),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      )),
                ),
                // const Text('skjfbsfiab'),
                if (order['messages'] != null &&
                    order['messages']!['confirmerMessage'] != null &&
                    order['messages']!['confirmerMessage'].toString().isNotEmpty) ...[
                  Utils().showMessage(context, 'Confirmer Remark', order['messages']!['confirmerMessage'].toString())
                ],
                ///////////////////////////////////////////////////////////
                if (order['messages'] != null &&
                    order['messages']!['accountMessage'] != null &&
                    order['messages']!['accountMessage'].toString().isNotEmpty) ...[
                  Utils().showMessage(context, 'Account Remark', order['messages']!['accountMessage'].toString()),
                ],
                /////////////////////////////////////////////////////////
                if (order['messages'] != null &&
                    order['messages']!['bookerMessage'] != null &&
                    order['messages']!['bookerMessage'].toString().isNotEmpty) ...[
                  Utils().showMessage(context, 'Booker Remark', order['messages']!['bookerMessage'].toString())
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildOrderCard(Order order, int index, PickerProvider pickerProvider,
  //     String name, String sku, String amount, int qty) {
  //   return Card(
  //     color: AppColors.white,
  //     elevation: 4, // Reduced elevation for less shadow
  //     shape: RoundedRectangleBorder(
  //       borderRadius:
  //           BorderRadius.circular(12), // Slightly smaller rounded corners
  //     ),
  //     child: Column(
  //       children: [
  //         Text("Picklist ID: "),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: [
  //             Expanded(
  //               flex: 13,
  //               child: PickerOrderCard(
  //                   order: order, name: name, sku: sku, amount: amount, qty: qty),
  //             ),
  //             const SizedBox(width: 4),
  //             buildCell(
  //               const Text(
  //                 "1",
  //                 style: TextStyle(fontSize: 16),
  //               ),
  //               flex: 3,
  //             ),
  //             // const SizedBox(width: 4),
  //             // buildCell(
  //             //   Column(
  //             //     crossAxisAlignment: CrossAxisAlignment.center,
  //             //     children: [
  //             //       Text(
  //             //         _getCustomerFullName(order.customer),
  //             //         style: const TextStyle(fontSize: 16),
  //             //         textAlign: TextAlign.center,
  //             //       ),
  //             //       const SizedBox(height: 4),
  //             //       if (order.customer?.phone != null) ...[
  //             //         Row(
  //             //           mainAxisAlignment: MainAxisAlignment.center,
  //             //           children: [
  //             //             IconButton(
  //             //               onPressed: () {
  //             //                 // Add your phone action here
  //             //               },
  //             //               icon: const Icon(
  //             //                 Icons.phone,
  //             //                 color: AppColors.green,
  //             //                 size: 14,
  //             //               ),
  //             //             ),
  //             //             const SizedBox(width: 4),
  //             //             Text(
  //             //               _getCustomerPhoneNumber(order.customer?.phone),
  //             //               style: const TextStyle(
  //             //                 fontSize: 14,
  //             //                 color: Colors.orange,
  //             //                 fontWeight: FontWeight.bold,
  //             //               ),
  //             //               textAlign: TextAlign.center,
  //             //             ),
  //             //           ],
  //             //         ),
  //             //       ] else ...[
  //             //         const Text(
  //             //           'Phone not available',
  //             //           style: TextStyle(
  //             //             fontSize: 14,
  //             //             color: Colors.grey,
  //             //           ),
  //             //         ),
  //             //       ],
  //             //     ],
  //             //   ),
  //             //   flex: 3,
  //             // ),
  //             // const SizedBox(width: 4),
  //             // buildCell(
  //             //   Text(
  //             //     pickerProvider.formatDate(order.date!),
  //             //     style: const TextStyle(fontSize: 16),
  //             //   ),
  //             //   flex: 3,
  //             // ),
  //             // const SizedBox(width: 4),
  //             // buildCell(
  //             //   Text(
  //             //     'Rs.${order.totalAmount!}',
  //             //     style: const TextStyle(fontSize: 16),
  //             //   ),
  //             //   flex: 2,
  //             // ),
  //             // const SizedBox(width: 4),
  //             // buildCell(
  //             //   order.isPickerFullyScanned
  //             //       ? const Icon(
  //             //           Icons.check_circle,
  //             //           color: Colors.green,
  //             //           size: 24,
  //             //         )
  //             //       : const SizedBox.shrink(),
  //             //   flex: 2,
  //             // ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildProductCard(
  //     Order order, int index, PickerProvider pickerProvider) {
  //   final item = order.items[index];
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           flex: 9,
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color: AppColors.lightGrey,
  //               borderRadius: BorderRadius.circular(
  //                   10), // Slightly smaller rounded corners
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black
  //                       .withOpacity(0.08), // Lighter shadow for smaller card
  //                   offset: const Offset(0, 1),
  //                   blurRadius: 3,
  //                 ),
  //               ],
  //             ),
  //             margin: const EdgeInsets.symmetric(vertical: 4.0),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 _buildProductImage(item),
  //                 const SizedBox(
  //                     width: 8.0), // Reduced spacing between image and text
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       _buildProductName(item),
  //                       const SizedBox(
  //                           height:
  //                               6.0), // Reduced spacing between text elements
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment
  //                             .spaceBetween, // Space between widgets
  //                         children: [
  //                           // SKU at the extreme left
  //                           RichText(
  //                             text: TextSpan(
  //                               children: [
  //                                 const TextSpan(
  //                                   text: 'SKU: ',
  //                                   style: TextStyle(
  //                                     color: Colors.blueAccent,
  //                                     fontWeight: FontWeight.bold,
  //                                     fontSize: 13, // Reduced font size
  //                                   ),
  //                                 ),
  //                                 TextSpan(
  //                                   text: item.product?.sku ?? 'N/A',
  //                                   style: const TextStyle(
  //                                     color: Colors.black87,
  //                                     fontWeight: FontWeight.w500,
  //                                     fontSize: 13, // Reduced font size
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                           // Amount at the extreme right
  //                           RichText(
  //                             text: TextSpan(
  //                               children: [
  //                                 const TextSpan(
  //                                   text: 'Amount: ',
  //                                   style: TextStyle(
  //                                     color: Colors.blueAccent,
  //                                     fontWeight: FontWeight.bold,
  //                                     fontSize: 13, // Reduced font size
  //                                   ),
  //                                 ),
  //                                 TextSpan(
  //                                   text: 'Rs.${item.amount.toString()}',
  //                                   style: const TextStyle(
  //                                     color: Colors.black87,
  //                                     fontWeight: FontWeight.w500,
  //                                     fontSize: 13, // Reduced font size
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 4),
  //         buildCell(
  //           Text(
  //             order.items[index].qty.toString(),
  //             style: const TextStyle(fontSize: 16),
  //           ),
  //           flex: 3,
  //         ),
  //         const SizedBox(width: 4),
  //         buildCell(
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             children: [
  //               Text(
  //                 _getCustomerFullName(order.customer),
  //                 style: const TextStyle(fontSize: 16),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 4),
  //               if (order.customer?.phone != null) ...[
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     IconButton(
  //                       onPressed: () {
  //                         // Add your phone action here
  //                       },
  //                       icon: const Icon(
  //                         Icons.phone,
  //                         color: AppColors.green,
  //                         size: 14,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 4),
  //                     Text(
  //                       _getCustomerPhoneNumber(order.customer?.phone),
  //                       style: const TextStyle(
  //                         fontSize: 14,
  //                         color: Colors.orange,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ],
  //                 ),
  //               ] else ...[
  //                 const Text(
  //                   'Phone not available',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.grey,
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //           flex: 3,
  //         ),
  //         const SizedBox(width: 4),
  //         buildCell(
  //           Text(
  //             pickerProvider.formatDate(order.date!),
  //             style: const TextStyle(fontSize: 16),
  //           ),
  //           flex: 3,
  //         ),
  //         const SizedBox(width: 4),
  //         buildCell(
  //           Text(
  //             'Rs.${order.totalAmount!}',
  //             style: const TextStyle(fontSize: 16),
  //           ),
  //           flex: 2,
  //         ),
  //         const SizedBox(width: 4),
  //         buildCell(
  //           order.isPickerFullyScanned
  //               ? const Icon(
  //                   Icons.check_circle,
  //                   color: Colors.green,
  //                   size: 24,
  //                 )
  //               : const SizedBox.shrink(),
  //           flex: 2,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildProductImage(Item item) {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(6),
  //     child: SizedBox(
  //       width: 60, // Smaller image size
  //       height: 60,
  //       child: item.product?.shopifyImage != null &&
  //               item.product!.shopifyImage!.isNotEmpty
  //           ? Image.network(
  //               item.product!.shopifyImage!,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) {
  //                 return const Icon(
  //                   Icons.image_not_supported,
  //                   size: 40, // Smaller fallback icon size
  //                   color: AppColors.grey,
  //                 );
  //               },
  //             )
  //           : const Icon(
  //               Icons.image_not_supported,
  //               size: 40, // Smaller fallback icon size
  //               color: AppColors.grey,
  //             ),
  //     ),
  //   );
  // }

  // Widget _buildProductName(Item item) {
  //   return Text(
  //     item.product?.displayName ?? 'No Name',
  //     style: const TextStyle(
  //       fontWeight: FontWeight.w600,
  //       fontSize: 14, // Reduced font size
  //       color: Colors.black87,
  //     ),
  //     maxLines: 2,
  //     overflow: TextOverflow.ellipsis,
  //   );
  // }

  // String _getCustomerPhoneNumber(dynamic phoneNumber) {
  //   if (phoneNumber == null) return 'Unknown';
  //   // Convert to string if it's an int, otherwise return as is
  //   return phoneNumber.toString();
  // }

  // String _getCustomerFullName(Customer? customer) {
  //   if (customer == null) return 'Unknown';
  //   final firstName = customer.firstName ?? '';
  //   final lastName = customer.lastName ?? '';
  //   // Check if both first name and last name are empty
  //   if (firstName.isEmpty && lastName.isEmpty) {
  //     return 'Unknown';
  //   }
  //   return (firstName + (lastName.isNotEmpty ? ' $lastName' : '')).trim();
  // }

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
