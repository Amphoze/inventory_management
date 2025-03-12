import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/picker_provider.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Api/auth_provider.dart';
import 'Custom-Files/loading_indicator.dart';

class PickerPage extends StatefulWidget {
  const PickerPage({super.key});

  @override
  State<PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends State<PickerPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  String selectedPicklist = '';
  List<String> picklistIds = ['W1', 'W2', 'W3', 'G1', 'G2', 'G3', 'E1', 'E2', 'E3'];
  bool isDownloading = false;

  bool? isSuperAdmin = false;
  bool? isAdmin = false;

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
      isAdmin = prefs.getBool('_isAdminAssigned');
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PickerProvider>(context, listen: false).fetchOrdersWithStatus4();
      _fetchUserRole();
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
      builder: (BuildContext dialogContext) {
        // Use a unique context for the outer dialog
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
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredIds.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(filteredIds[index]),
                        if ((isSuperAdmin ?? false) || (isAdmin ?? false))
                          IconButton(
                            tooltip: 'Revert Order',
                            icon: const Icon(Icons.undo),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Revert Order'),
                                    content: Text('Are you sure you want to revert ${filteredIds[index]} to READY TO CONFIRM'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          Navigator.pop(context);

                                          showDialog(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (context) {
                                              return const AlertDialog(
                                                content: Row(
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    SizedBox(width: 8),
                                                    Text('Reversing'),
                                                  ],
                                                ),
                                              );
                                            },
                                          );

                                          try {
                                            final authPro = context.read<AuthProvider>();
                                            final res = await authPro.reverseOrder(filteredIds[index]);

                                            Navigator.pop(context);

                                            if (res['success'] == true) {
                                              Utils.showInfoDialog(context, "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                                            } else {
                                              Utils.showInfoDialog(context, res['message'], false);
                                            }
                                          } catch (e) {
                                            Navigator.pop(context);
                                            Utils.showInfoDialog(context, 'An error occurred: $e', false);
                                          }
                                        },
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
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
                          return StatefulBuilder(builder: (BuildContext context, StateSetter dialogSetState) {
                            return AlertDialog(
                              title: const Text('Download Picklist'),
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
                                    log('picklist id is: $selectedPicklist');
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

                                    final res = await pickerProvider.generatePicklist(context, _dateController.text, selectedPicklist);

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

  String status = '1';

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
                      overflow: TextOverflow.ellipsis,
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
                                color: Colors.black.withValues(alpha: 0.08), // Lighter shadow for smaller card
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
