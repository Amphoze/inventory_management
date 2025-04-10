import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/model/picker_model.dart';
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
  late PickerProvider pickerProvider;
  bool? isSuperAdmin = false;
  bool? isAdmin = false;

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
      isAdmin = prefs.getBool('_isAdminAssigned');
    });
  }

  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      pickerProvider.fetchOrdersWithStatus4();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      pickerProvider.searchOrders(value);
    });
  }

  @override
  void initState() {
    super.initState();
    pickerProvider = Provider.of<PickerProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pickerProvider.fetchOrdersWithStatus4();
      _fetchUserRole();
    });
    pickerProvider.textEditingController.clear();
  }

  void _showOrderIdsDialog(Picklist picklist) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String searchQuery = '';
        List<String> orderIds = (picklist.orderIds as List).cast<String>();

        return StatefulBuilder(
          builder: (context, setState) {
            List<String> filteredIds =
                orderIds.where((id) => id.toLowerCase().contains(searchQuery.toLowerCase())).toList();

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
                                    content: Text(
                                        'Are you sure you want to revert ${filteredIds[index]} to READY TO CONFIRM'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
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

                                            final res = await authPro.reverseOrder(filteredIds[index], '', '');

                                            Navigator.pop(context);

                                            if (res['success'] == true) {
                                              Utils.showInfoDialog(context,
                                                  "${res['message']}\nNew Order ID: ${res['newOrderId']}", true);
                                            } else {
                                              Utils.showInfoDialog(context, res['message'], false);
                                            }
                                          } catch (e) {
                                            Utils.showInfoDialog(context, 'An error occurred: $e', false);
                                          } finally {
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
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
                      onChanged: _onSearchChanged,
                      onSubmitted: (query) {
                        if (query.trim().isNotEmpty) {
                          pickerProvider.searchOrders(query);
                        } else {
                          pickerProvider.fetchOrdersWithStatus4();
                        }
                      },
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
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
                                    readOnly: true,
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
                                    value: picklistIds.contains(selectedPicklist) ? selectedPicklist : null,
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

                                    final res = await pickerProvider.downloadPicklist(
                                        context, _dateController.text, selectedPicklist);

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
                    onPressed: pickerProvider.isPicklistLoading
                        ? null
                        : () async {
                            pickerProvider.fetchOrdersWithStatus4();
                          },
                    child: pickerProvider.isPicklistLoading
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
            _buildTableHeader(pickerProvider.picklists.length, pickerProvider),
            if (_searchController.text.trim().isEmpty)
              Expanded(
                child: (pickerProvider.isPicklistLoading)
                    ? const Center(
                        child: LoadingAnimation(
                          icon: Icons.local_shipping,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    : (pickerProvider.picklists.isEmpty)
                        ? const Center(
                            child: Text(
                              'No Orders Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pickerProvider.picklists.length,
                            itemBuilder: (context, index) {
                              final picklist = pickerProvider.picklists[index];
                              return Column(
                                children: [
                                  _buildPicklistCard(picklist),
                                  const Divider(thickness: 1, color: Colors.grey),
                                ],
                              );
                            },
                          ),
              )
            else
              Expanded(
                child: (pickerProvider.isOrderLoading)
                    ? const Center(
                        child: LoadingAnimation(
                          icon: Icons.local_shipping,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    : (pickerProvider.orders.isEmpty)
                        ? const Center(
                            child: Text(
                              'No Orders Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pickerProvider.orders.length,
                            itemBuilder: (context, index) {
                              final order = pickerProvider.orders[index];
                              return Column(
                                children: [
                                  _buildPickerOrderCard(order),
                                  const Divider(thickness: 1, color: Colors.grey),
                                ],
                              );
                            },
                          ),
              ),
            CustomPaginationFooter(
              currentPage: pickerProvider.currentPage,
              totalPages: pickerProvider.totalPages,
              buttonSize: 30,
              pageController: pickerProvider.textEditingController,
              onFirstPage: () {
                pickerProvider.goToPage(1);
                pickerProvider.textEditingController.clear();
              },
              onLastPage: () {
                pickerProvider.goToPage(pickerProvider.totalPages);
                pickerProvider.textEditingController.clear();
              },
              onNextPage: () {
                if (pickerProvider.currentPage < pickerProvider.totalPages) {
                  pickerProvider.goToPage(pickerProvider.currentPage + 1);
                  pickerProvider.textEditingController.clear();
                }
              },
              onPreviousPage: () {
                if (pickerProvider.currentPage > 1) {
                  pickerProvider.goToPage(pickerProvider.currentPage - 1);
                  pickerProvider.textEditingController.clear();
                }
              },
              onGoToPage: (page) {
                pickerProvider.goToPage(page);
                pickerProvider.textEditingController.clear();
              },
              onJumpToPage: () {
                final page = int.tryParse(pickerProvider.textEditingController.text);
                if (page != null && page > 0 && page <= pickerProvider.totalPages) {
                  pickerProvider.goToPage(page);
                  pickerProvider.textEditingController.clear();
                } else {
                  _showSnackbar(
                      context, 'Please enter a valid page number between 1 and ${pickerProvider.totalPages}.');
                }
              },
            ),
          ],
        ),
      );
    });
  }

  void _showSnackbar(BuildContext context, String message) {
    Utils.showSnackBar(context, message);
  }

  Widget _buildTableHeader(int totalCount, PickerProvider pickerProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          buildHeader('PRODUCTS', flex: 8),
          buildHeader('QUANTITY', flex: 1),
          buildHeader('ID', flex: 2),
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

  Widget _buildPicklistCard(Picklist picklist) {
    final items = picklist.items;

    return Card(
      color: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: 'Click to view all Order IDs',
              child: InkWell(
                onTap: () => _showOrderIdsDialog(picklist),
                child: Text.rich(
                  TextSpan(
                      text: "Order ID: ",
                      children: [
                        TextSpan(
                          text: (picklist.orderIds).join(', '),
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: " (${picklist.orderIds.length})",
                        ),
                      ],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      )),
                  maxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: (items[index].productId.shopifyImage.isNotEmpty ?? false)
                                            ? Image.network(
                                                items[index].productId.shopifyImage,
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: AppColors.grey,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            items[index].productId.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6.0),
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
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: items[index].productId.sku,
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
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
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: items[index].productId.mrp.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
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
                                    const Spacer(),
                                    const Text(
                                      "X",
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                                      child: Center(
                                        child: Text(
                                          "${items[index].productId.itemQty}",
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
                // const SizedBox(width: 4),
                buildCell(
                  flex: 1,
                  Text(
                    picklist.picklistId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
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
                            DateTime.parse(picklist.createdAt).toLocal(),
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
                // if (picklist['messages']!['confirmerMessage'].toString().isNotEmpty) ...[
                //   Utils().showMessage(context, 'Confirmer Remark', picklist['messages']!['confirmerMessage'].toString())
                // ],
                // if (picklist['messages'] != null &&
                //     picklist['messages']!['accountMessage'] != null &&
                //     picklist['messages']!['accountMessage'].toString().isNotEmpty) ...[
                //   Utils().showMessage(context, 'Account Remark', picklist['messages']!['accountMessage'].toString()),
                // ],
                // if (picklist['messages'] != null &&
                //     picklist['messages']!['bookerMessage'] != null &&
                //     picklist['messages']!['bookerMessage'].toString().isNotEmpty) ...[
                //   Utils().showMessage(context, 'Booker Remark', picklist['messages']!['bookerMessage'].toString())
                // ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOrderCard(Order order) {
    final items = order.items;

    return Card(
      color: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                  text: "Order ID: ",
                  children: [
                    TextSpan(
                      text: order.orderId,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  )),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: (items[index].product?.shopifyImage?.isNotEmpty ?? false)
                                            ? Image.network(
                                                items[index].product!.shopifyImage!,
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: AppColors.grey,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            items[index].product?.displayName ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6.0),
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
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: items[index].product?.sku ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
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
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: items[index].product?.mrp.toString() ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
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
                                    const Spacer(),
                                    const Text(
                                      "X",
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                                      child: Center(
                                        child: Text(
                                          "${items[index].qty}",
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
                // const SizedBox(width: 4),
                buildCell(
                  flex: 1,
                  Text(
                    order.picklistId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.createdAt != null)
                  Text.rich(
                    TextSpan(
                        text: "Created on: ",
                        children: [
                          TextSpan(
                            text: DateFormat('yyyy-MM-dd, hh:mm a').format(
                              order.createdAt!.toLocal(),
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
                // if (picklist['messages']!['confirmerMessage'].toString().isNotEmpty) ...[
                //   Utils().showMessage(context, 'Confirmer Remark', picklist['messages']!['confirmerMessage'].toString())
                // ],
                // if (picklist['messages'] != null &&
                //     picklist['messages']!['accountMessage'] != null &&
                //     picklist['messages']!['accountMessage'].toString().isNotEmpty) ...[
                //   Utils().showMessage(context, 'Account Remark', picklist['messages']!['accountMessage'].toString()),
                // ],
                // if (picklist['messages'] != null &&
                //     picklist['messages']!['bookerMessage'] != null &&
                //     picklist['messages']!['bookerMessage'].toString().isNotEmpty) ...[
                //   Utils().showMessage(context, 'Booker Remark', picklist['messages']!['bookerMessage'].toString())
                // ],
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
