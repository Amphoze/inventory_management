import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/chat_screen.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/provider/support_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Widgets/big_combo_card.dart';
import 'Widgets/order_card.dart';
import 'Widgets/order_info.dart';
import 'model/orders_model.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDate = 'Select Date';
  final remarkController = TextEditingController();
  late SupportProvider provider;

  String? email;
  String? role;

  void getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    role = prefs.getString('userPrimaryRole');
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<SupportProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return " ($date, $time)";
  }

  @override
  void initState() {
    super.initState();
    provider = Provider.of(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupportProvider>(context, listen: false).fetchSupportOrders();
      getUserData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    String selectedCourier = 'All';
    return Consumer<SupportProvider>(
      builder: (context, pro, child) {
        return Scaffold(
          endDrawer: const ChatScreen(),
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 250,
                      child: Container(
                        height: 35,
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
                            setState(() {});
                            if (query.isEmpty) {
                              pro.fetchSupportOrders();
                            }
                          },
                          onTap: () {
                            setState(() {});
                          },
                          onSubmitted: (query) {
                            if (query.isNotEmpty) {
                              pro.searchOrders(query);
                            }
                          },
                          onEditingComplete: () {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: pro.isRefreshingOrders
                              ? null
                              : () async {
                                  setState(() {
                                    selectedCourier = 'All';
                                    _selectedDate = 'Select Date';
                                  });
                                  await pro.fetchSupportOrders();
                                },
                          child: pro.isRefreshingOrders
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              _buildTableHeader(pro.orders.length, pro),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (pro.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.support_agent,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (pro.orders.isEmpty)
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
                        itemCount: pro.orders.length,
                        itemBuilder: (context, index) {
                          final order = pro.orders[index];

                          final Map<String, List<Item>> groupedComboItems = {};
                          for (var item in order.items) {
                            if (item.isCombo == true && item.comboSku != null) {
                              if (!groupedComboItems.containsKey(item.comboSku)) {
                                groupedComboItems[item.comboSku!] = [];
                              }
                              groupedComboItems[item.comboSku]!.add(item);
                            }
                          }
                          final List<List<Item>> comboItemGroups = groupedComboItems.values.where((items) => items.length > 1).toList();

                          Logger().e('comboItemGroups: $comboItemGroups');

                          final List<Item> remainingItems = order.items
                              .where((item) =>
                                  !(item.isCombo == true && item.comboSku != null && groupedComboItems[item.comboSku]!.length > 1))
                              .toList();

                          return Card(
                            surfaceTintColor: Colors.white,
                            color: pro.selectedProducts[index] ? Colors.grey[300] : Colors.grey[100],
                            // color: const Color.fromARGB(255, 231, 230, 230),
                            elevation: 2,
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Checkbox(
                                        value: pro.selectedProducts[index],
                                        onChanged: (isSelected) {
                                          pro.handleRowCheckboxChange(index, isSelected!);
                                        },
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Order ID: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            order.orderId ?? 'N/A',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Date: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            pro.formatDate(order.date!),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Amount: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Rs. ${order.totalAmount ?? ''}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Items: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${order.items.fold(0, (total, item) => total + item.qty!)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Weight: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${order.totalWeight ?? ''}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditOutboundPage(
                                                    order: order,
                                                    isBookPage: false,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                final searched = _searchController.text;
                                                pro.fetchSupportOrders();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: AppColors.white,
                                              backgroundColor: AppColors.orange,
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: const Text(
                                              'Edit Order',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              TextEditingController messageController = TextEditingController();

                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    titlePadding: EdgeInsets.zero,
                                                    title: Container(
                                                      padding: const EdgeInsets.all(20),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).primaryColor,
                                                        borderRadius: const BorderRadius.only(
                                                          topLeft: Radius.circular(16),
                                                          topRight: Radius.circular(16),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.bug_report_outlined, color: Colors.white, size: 24),
                                                          SizedBox(width: 12),
                                                          Text(
                                                            'Resolve issue',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    content: Container(
                                                      width: MediaQuery.of(context).size.width * 0.4,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            'Order Details',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 12),
                                                          TextField(
                                                            controller: TextEditingController(text: order.orderId),
                                                            readOnly: true,
                                                            decoration: InputDecoration(
                                                              labelText: 'Order ID',
                                                              prefixIcon: const Icon(Icons.shopping_cart_outlined),
                                                              filled: true,
                                                              fillColor: Colors.grey.shade100,
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                                              ),
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 24),
                                                          const Text(
                                                            'Your Message',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 12),
                                                          TextField(
                                                            controller: messageController,
                                                            maxLines: 4,
                                                            decoration: InputDecoration(
                                                              hintText: 'Please describe what you have resolved...',
                                                              prefixIcon: const Padding(
                                                                padding: EdgeInsets.only(bottom: 84),
                                                                child: Icon(Icons.message_outlined),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors.white,
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                                              ),
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton.icon(
                                                        onPressed: () => Navigator.pop(context),
                                                        label: const Text('Cancel'),
                                                        style: TextButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                        ),
                                                      ),
                                                      ElevatedButton.icon(
                                                        onPressed: () async {
                                                          if(messageController.text.trim().isEmpty ) {
                                                            Utils.showSnackBar(context, 'Please enter your message');
                                                            return;
                                                          }
                                                          
                                                          showDialog(
                                                            context: context,
                                                            barrierDismissible: false,
                                                            builder: (context) {
                                                              return const AlertDialog(
                                                                content: Row(
                                                                  children: [
                                                                    CircularProgressIndicator(),
                                                                    SizedBox(width: 20),
                                                                    Text('Processing...'),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                          bool result = await context
                                                              .read<SupportProvider>()
                                                              .support(context, order.orderId, messageController.text);

                                                          log('result: $result');

                                                          Navigator.pop(context);
                                                          Navigator.pop(context);

                                                          if (result) {
                                                            await provider.fetchSupportOrders();
                                                          }
                                                        },
                                                        label: const Text('Resolve'),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Theme.of(context).primaryColor,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: const Text('Resolve'),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Support Chat',
                                            icon: const Icon(Icons.message),
                                            onPressed: () {
                                              pro.setUserData(order.orderId, email!, role!);
                                              Scaffold.of(context).openEndDrawer();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
                                  OrderInfo(
                                    order: order,
                                    pro: pro,
                                  ),
                                  const SizedBox(height: 6),
                                  // Footer Information
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (order.confirmedBy!['status'] == true)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Text.rich(
                                              TextSpan(
                                                text: "Confirmed By: ",
                                                children: [
                                                  TextSpan(
                                                    text: "${order.confirmedBy!['confirmedBy'].toString().split('@')[0]} - ",
                                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                                  ),
                                                  TextSpan(
                                                    text: formatIsoDate(order.confirmedBy!['timestamp']),
                                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                                  ),
                                                ],
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text.rich(
                                              TextSpan(
                                                text: "Updated on: ",
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        DateFormat('yyyy-MM-dd\',\' hh:mm a').format(DateTime.parse("${order.updatedAt}")),
                                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                                  ),
                                                ],
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (order.messages?['confirmerMessage']?.toString().isNotEmpty ?? false)
                                              Utils()
                                                  .showMessage(context, 'Confirmer Remark', order.messages!['confirmerMessage'].toString()),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: 6),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: comboItemGroups.length,
                                    itemBuilder: (context, comboIndex) {
                                      final combo = comboItemGroups[comboIndex];
                                      return BigComboCard(
                                        items: combo,
                                        index: comboIndex,
                                        // courierName: order.courierName,
                                        // orderStatus:
                                        //     order.orderStatus.toString(),
                                      );
                                    },
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: remainingItems.length,
                                    itemBuilder: (context, itemIndex) {
                                      final item = remainingItems[itemIndex];
                                      print('Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                                      return ProductDetailsCard(
                                        item: item,
                                        index: itemIndex,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              CustomPaginationFooter(
                currentPage: pro.currentPage,
                totalPages: pro.totalPages,
                buttonSize: 30,
                pageController: pro.textEditingController,
                onFirstPage: () {
                  pro.goToPage(1);
                },
                onLastPage: () {
                  pro.goToPage(pro.totalPages);
                },
                onNextPage: () {
                  if (pro.currentPage < pro.totalPages) {
                    pro.goToPage(pro.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (pro.currentPage > 1) {
                    pro.goToPage(pro.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  pro.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(pro.textEditingController.text);
                  if (page != null && page > 0 && page <= pro.totalPages) {
                    pro.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, int index, SupportProvider pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: pro.selectedProducts[index],
            onChanged: (isSelected) {
              pro.handleRowCheckboxChange(index, isSelected!);
            },
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OrderCard(order: order),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildTableHeader(int totalCount, SupportProvider pro) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: pro.selectAll,
              onChanged: (value) {
                pro.toggleSelectAll(value!);
              },
            ),
          ),
          Text(
            'Select All(${pro.selectedCount})',
          ),
          buildHeader('ORDERS')
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

// Widget buildLabelValueRow(String label, String? value) {
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Text(
//         '$label: ',
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 12.0,
//         ),
//       ),
//       Flexible(
//         child: Tooltip(
//           message: value ?? '',
//           child: Text(
//             value ?? '',
//             overflow: TextOverflow.ellipsis,
//             maxLines: 1,
//             style: const TextStyle(
//               fontSize: 12.0,
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }
//
// Widget _buildInfoColumn(String title, List<Widget> children) {
//   return Expanded(
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 14.0,
//             color: AppColors.primaryBlue,
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...children,
//       ],
//     ),
//   );
// }
//
// // Helper method to build address cards
// Widget _buildAddressCard(
//   String title,
//   dynamic address,
//   String? firstName,
//   String? lastName,
//   dynamic pincode,
//   String? countryCode,
// ) {
//   return Card(
//     elevation: 2,
//     color: Colors.white,
//     child: Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 14.0,
//               color: AppColors.primaryBlue,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Address: ',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12.0,
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   [
//                     address?.address1,
//                     address?.address2,
//                     address?.city,
//                     address?.state,
//                     address?.country,
//                     address?.pincode?.toString(),
//                   ]
//                       .where((element) => element != null && element.isNotEmpty)
//                       .join(', ')
//                       .replaceAllMapped(RegExp('.{1,50}'), (match) => '${match.group(0)}\n'),
//                   softWrap: true,
//                   style: const TextStyle(fontSize: 12.0),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           buildLabelValueRow(
//             'Name',
//             firstName != lastName ? '$firstName $lastName'.trim() : firstName ?? '',
//           ),
//           buildLabelValueRow('Pincode', pincode?.toString() ?? ''),
//           buildLabelValueRow('Country Code', countryCode ?? ''),
//         ],
//       ),
//     ),
//   );
// }
