import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/check_orders/provider/supervisor_provider.dart';
import 'package:inventory_management/check_orders/recheck_orders_page.dart';
import 'package:inventory_management/check_orders/widgets/check_order_card.dart';

import '../Custom-Files/colors.dart';

class SupervisorPage extends StatefulWidget {
  const SupervisorPage({super.key});

  @override
  State<SupervisorPage> createState() => _SupervisorPageState();
}

class _SupervisorPageState extends State<SupervisorPage> {
  final TextEditingController _searchController = TextEditingController();
  late SupervisorProvider supervisorProvider;
  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      supervisorProvider.getCheckOrders();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      supervisorProvider.searchCheckOrders(value);
    });
  }
  @override
  void initState() {
    super.initState();
    supervisorProvider = Provider.of<SupervisorProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      supervisorProvider.getCheckOrders();
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
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search by Order ID',
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(117, 117, 117, 1),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        Provider.of<SupervisorProvider>(context, listen: false).searchCheckOrders(value.trim());
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
                    Provider.of<SupervisorProvider>(context, listen: false).getCheckOrders();
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
              child: Consumer<SupervisorProvider>(
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
