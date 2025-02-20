import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/Widgets/big_combo_card.dart';
import 'package:inventory_management/Widgets/order_info.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_outbound_page.dart';
import 'package:inventory_management/provider/ba_approve_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/return_entry_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Widgets/order_card.dart';
import 'model/orders_model.dart';

class ReturnEntry extends StatefulWidget {
  const ReturnEntry({super.key});

  @override
  State<ReturnEntry> createState() => _ReturnEntryState();
}

class _ReturnEntryState extends State<ReturnEntry> {
  final TextEditingController _searchController = TextEditingController();

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<ReturnEntryProvider>(context, listen: false).onSearchChanged(query);
    }
  }

  String formatIsoDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toUtc().add(const Duration(hours: 5, minutes: 30));
    final date = DateFormat('yyyy-MM-dd').format(dateTime);
    final time = DateFormat('hh:mm:ss a').format(dateTime);
    return " ($date, $time)";
  }

  @override
  void dispose() {
    _searchController.dispose();
    // remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReturnEntryProvider>(
      builder: (context, pro, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    searchBar(pro),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    if (pro.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.keyboard_return,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (pro.orders.isEmpty)
                      const Center(
                        child: Text(
                          'Search for orders',
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

                          final List<Item> remainingItems = order.items
                              .where((item) =>
                                  !(item.isCombo == true && item.comboSku != null && groupedComboItems[item.comboSku]!.length > 1))
                              .toList();

                          return Card(
                            surfaceTintColor: Colors.white,
                            color: Colors.grey[100],
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
                                    ],
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: 6),
                                  if (comboItemGroups.isEmpty && remainingItems.isEmpty)
                                    const Center(
                                        child: Text(
                                      'No Products/Combos found in this order',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ))
                                  else if (comboItemGroups.isNotEmpty)
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: comboItemGroups.length,
                                      itemBuilder: (context, comboIndex) {
                                        final combo = comboItemGroups[comboIndex];
                                        return Row(
                                          children: [
                                            BigComboCard(
                                              items: combo,
                                              index: comboIndex,
                                            ),
                                            const SizedBox(width: 16),
                                            editQuantityWidget(order.orderId, combo[index].comboSku ?? '', combo[index].qty ?? 0, pro)
                                          ],
                                        );
                                      },
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: remainingItems.length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = remainingItems[itemIndex];
                                        print('Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                                        return Row(
                                          children: [
                                            ProductDetailsCard(
                                              item: item,
                                              index: itemIndex,
                                            ),
                                            const SizedBox(width: 16),
                                            editQuantityWidget(order.orderId, item.sku ?? '', item.qty ?? 0, pro)
                                          ],
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
            ],
          ),
        );
      },
    );
  }

  Widget editQuantityWidget(String orderId, String sku, int qty, ReturnEntryProvider pro) {
    final TextEditingController _goodQuantityController = TextEditingController();
    final TextEditingController _badQuantityController = TextEditingController();

    return IconButton(
      icon: Icon(Icons.fact_check_outlined, color: Colors.grey.shade500),
      onPressed: () {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sku),
                    Text(
                      'Total Quantity: $qty',
                      style: TextStyle(fontSize: 12),
                    )
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _goodQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Good Quantity',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _badQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Bad Quantity',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(
                    child: const Text('Submit'),
                    onPressed: () async {
                      final goodQuantity = int.tryParse(_goodQuantityController.text) ?? 0;
                      final badQuantity = int.tryParse(_badQuantityController.text) ?? 0;

                      if ((goodQuantity + badQuantity) > qty) {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                content: const Text('Total quantity exceeded!!'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok'))],
                              );
                            });
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (_) {
                          return const AlertDialog(
                            content: Row(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text('Updating')
                              ],
                            ),
                          );
                        },
                      );

                      List<Map<String, dynamic>> qualityCheckResults = [];

                      // Create a map to group quantities by SKU and condition
                      Map<String, Map<String, int>> skuConditionMap = {};

                      if (skuConditionMap.containsKey(sku)) {
                        skuConditionMap[sku]!['good'] = goodQuantity;
                        skuConditionMap[sku]!['bad'] = badQuantity;
                      } else {
                        skuConditionMap[sku] = {'good': goodQuantity, 'bad': badQuantity};
                      }

                      skuConditionMap.forEach((sku, conditions) {
                        qualityCheckResults.add({"productSku": sku, "condition": "good", "goodQty": conditions['good']});
                        qualityCheckResults.add({"productSku": sku, "condition": "bad", "goodQty": conditions['bad']});
                      });

                      final res = await pro.qualityCheck(orderId, qualityCheckResults);
                      Navigator.pop(context);
                      if (res) {
                        Navigator.pop(context);
                        pro.showSnackBar(context, 'Success', Colors.green);
                      } else {
                        pro.showSnackBar(context, 'Failed', Colors.red);
                      }
                    },
                  ),
                ],
              );
            });
      },
    );
  }

  Widget searchBar(ReturnEntryProvider pro) {
    return Container(
      width: 280,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          hintText: 'Search by Order ID',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.blue.shade500,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: Colors.grey.shade500,
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,
          ),
        ),
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            pro.searchOrders(query.trim());
          }
        },
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
