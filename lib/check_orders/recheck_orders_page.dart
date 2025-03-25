import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/check_orders/provider/check_orders_provider.dart';
import 'package:inventory_management/check_orders/widgets/recheck_order_card.dart';

class RecheckOrdersPage extends StatefulWidget {
  const RecheckOrdersPage({super.key});

  @override
  State<RecheckOrdersPage> createState() => _RecheckOrdersPageState();
}

class _RecheckOrdersPageState extends State<RecheckOrdersPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckOrdersProvider>(context, listen: false).getRecheckOrders();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recheck Orders'),
      ),
      body: Consumer<CheckOrdersProvider>(
        builder: (context, provider, child) {
          if (provider.isRecheckOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.recheckOrders.isEmpty) {
            return const Center(child: Text('No recheck orders found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.recheckOrders.length,
            itemBuilder: (context, index) {
              final order = provider.recheckOrders[index];
              return RecheckOrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}
