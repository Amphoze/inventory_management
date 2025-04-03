import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/check_orders/provider/check_orders_provider.dart';
import 'package:inventory_management/check_orders/recheck_orders_page.dart';
import 'package:inventory_management/check_orders/widgets/check_order_card.dart';

import '../Custom-Files/colors.dart';

class CheckOrdersPage extends StatefulWidget {
  const CheckOrdersPage({super.key});

  @override
  State<CheckOrdersPage> createState() => _CheckOrdersPageState();
}

class _CheckOrdersPageState extends State<CheckOrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckOrdersProvider>(context, listen: false).getCheckOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Check Orders', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                Container(
                  width: 180,
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        Provider.of<CheckOrdersProvider>(context, listen: false).getCheckOrders();
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search Orders',
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(117, 117, 117, 1),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        Provider.of<CheckOrdersProvider>(context, listen: false).searchCheckOrders(value.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    Provider.of<CheckOrdersProvider>(context, listen: false).getCheckOrders();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Recheck'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecheckOrdersPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<CheckOrdersProvider>(
                builder: (context, provider, child) {
                  if (provider.isCheckOrdersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.checkOrders.isEmpty) {
                    return const Center(child: Text('No orders found'));
                  }

                  return ListView.builder(
                    itemCount: provider.checkOrders.length,
                    itemBuilder: (context, index) {
                      final order = provider.checkOrders[index];
                      return CheckOrderCard(
                        orderId: order.orderId,
                        items: order.items,
                        orderPics: order.orderPics,
                        pickListId: order.pickListId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
