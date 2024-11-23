import 'package:flutter/material.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/edit_order_page.dart';
import 'package:inventory_management/orders_page.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/loading_indicator.dart';
import 'Widgets/order_card.dart';
import 'model/orders_model.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountsProvider>(context, listen: false)
          .fetchOrdersWithStatus2();
    });
  }

  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Provider.of<AccountsProvider>(context, listen: false)
          .onSearchChanged(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountsProvider>(
      builder: (context, accountsProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                            setState(() {});
                            if (query.isEmpty) {
                              accountsProvider.fetchOrdersWithStatus2();
                            }
                          },
                          onTap: () {
                            setState(() {});
                          },
                          onSubmitted: (query) {
                            if (query.isNotEmpty) {
                              accountsProvider.searchOrders(query);
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
                      onPressed: _searchController.text.isNotEmpty
                          ? _onSearchButtonPressed
                          : null,
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    // Refresh Button
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: () async {
                            await accountsProvider.statusUpdate(context);
                          },
                          child: accountsProvider.isUpdatingOrder
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Confirm',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          onPressed: accountsProvider.isRefreshingOrders
                              ? null
                              : () async {
                                  await accountsProvider
                                      .fetchOrdersWithStatus2();
                                },
                          child: accountsProvider.isRefreshingOrders
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
              _buildTableHeader(
                  accountsProvider.orders.length, accountsProvider),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    if (accountsProvider.isLoading)
                      const Center(
                        child: LoadingAnimation(
                          icon: Icons.account_box_rounded,
                          beginColor: Color.fromRGBO(189, 189, 189, 1),
                          endColor: AppColors.primaryBlue,
                          size: 80.0,
                        ),
                      )
                    else if (accountsProvider.orders.isEmpty)
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
                        itemCount: accountsProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = accountsProvider.orders[index];

                          return Card(
                            surfaceTintColor: Colors.white,
                            color: const Color.fromARGB(255, 231, 230, 230),
                            elevation: 0.5,
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Checkbox(
                                        value: accountsProvider
                                            .selectedProducts[index],
                                        onChanged: (isSelected) {
                                          accountsProvider
                                              .handleRowCheckboxChange(
                                                  index, isSelected!);
                                        },
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Order ID: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Date: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            accountsProvider
                                                .formatDate(order.date!),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Amount: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Rs. ${order.totalAmount ?? ''}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Items: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${order.items.fold(0, (total, item) => total + item.qty!)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Weight: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${order.totalWeight ?? ''}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditOrderPage(
                                                order: order,
                                                isBookPage: false,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            Provider.of<AccountsProvider>(
                                                    context,
                                                    listen: false)
                                                .fetchOrdersWithStatus2();
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
                                    ],
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          child: const SizedBox(
                                            height: 50,
                                            width: 130,
                                            child: Text(
                                              'ORDER DETAILS:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Order Details:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditOrderDetailsDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow('Order Type',
                                                  order.orderType ?? ''),
                                              buildLabelValueRow(
                                                  'Marketplace',
                                                  order.marketplace?.name ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Transaction Number',
                                                  order.transactionNumber ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Calc Entry No.',
                                                  order.calcEntryNumber ?? ''),
                                              buildLabelValueRow(
                                                  'Micro Dealer Order',
                                                  order.microDealerOrder ?? ''),
                                              buildLabelValueRow(
                                                  'Fulfillment Type',
                                                  order.fulfillmentType ?? ''),
                                              buildLabelValueRow(
                                                  'Filter', order.filter ?? ''),
                                              const SizedBox(height: 7.0),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Payment Details:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditPaymentDetailsDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow('Payment Mode',
                                                  order.paymentMode ?? ''),
                                              buildLabelValueRow(
                                                  'Currency Code',
                                                  order.currencyCode ?? ''),
                                              buildLabelValueRow('Currency',
                                                  order.currency ?? ''),
                                              buildLabelValueRow(
                                                  'COD Amount',
                                                  order.codAmount?.toString() ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Prepaid Amount',
                                                  order.prepaidAmount
                                                          ?.toString() ??
                                                      ''),
                                              buildLabelValueRow('Payment Bank',
                                                  order.paymentBank ?? ''),
                                              buildLabelValueRow(
                                                'Payment Date Time',
                                                order.paymentDateTime != null
                                                    ? accountsProvider
                                                        .formatDateTime(order
                                                            .paymentDateTime!)
                                                    : '',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 35.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Delivery Details:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditDeliveryDetailsDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow('Courier Name',
                                                  order.courierName ?? ''),
                                              buildLabelValueRow(
                                                  'Tracking Status',
                                                  order.trackingStatus ?? ''),
                                              buildLabelValueRow(
                                                'Expected Delivery Date',
                                                order.expectedDeliveryDate !=
                                                        null
                                                    ? accountsProvider
                                                        .formatDate(order
                                                            .expectedDeliveryDate!)
                                                    : '',
                                              ),
                                              buildLabelValueRow(
                                                  'Preferred Courier',
                                                  order.preferredCourier ?? ''),
                                              buildLabelValueRow(
                                                  'Delivery Term',
                                                  order.deliveryTerm ?? ''),
                                              const SizedBox(height: 7.0),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Order Specification:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditOrderSpecificationDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow(
                                                  'Total Quantity',
                                                  order.totalQuantity
                                                          ?.toString() ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'No. of Boxes',
                                                  order.numberOfBoxes
                                                          ?.toString() ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'SKU Qty',
                                                  order.skuQty?.toString() ??
                                                      ''),
                                              const SizedBox(height: 7.0),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Order Dimention:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditDimensionsDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow(
                                                'Dimensions',
                                                '${order.length?.toString() ?? ''} x ${order.breadth?.toString() ?? ''} x ${order.height?.toString() ?? ''}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 26.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Discount Info:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditDiscountDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow(
                                                  'Discount Amount',
                                                  order.discountAmount
                                                          ?.toString() ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Discount Scheme',
                                                  order.discountScheme ?? ''),
                                              const SizedBox(height: 7.0),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Additional Info:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditAdditionalInfoDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow(
                                                  'Agent', order.agent ?? ''),
                                              buildLabelValueRow(
                                                  'Notes', order.notes ?? ''),
                                              buildLabelValueRow('Coin',
                                                  order.coin?.toString() ?? ''),
                                              buildLabelValueRow(
                                                  'Tax Percent',
                                                  order.taxPercent
                                                          ?.toString() ??
                                                      ''),
                                              const SizedBox(height: 7),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Customer Details:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Add spacing between the text and the icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    padding: EdgeInsets
                                                        .zero, // Remove extra padding
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditContactDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow(
                                                'Customer ID',
                                                order.customer?.customerId ??
                                                    '',
                                              ),
                                              buildLabelValueRow(
                                                  'Full Name',
                                                  order.customer?.firstName !=
                                                          order.customer
                                                              ?.lastName
                                                      ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'
                                                          .trim()
                                                      : order.customer
                                                              ?.firstName ??
                                                          ''),
                                              buildLabelValueRow(
                                                'Email',
                                                order.customer?.email ?? '',
                                              ),
                                              buildLabelValueRow(
                                                'Phone',
                                                order.customer?.phone
                                                        ?.toString() ??
                                                    '',
                                              ),
                                              buildLabelValueRow(
                                                'GSTIN',
                                                order.customer?.customerGstin ??
                                                    '',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 21.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(
                                                height: 7,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize
                                                    .min, // Adjust to fit content
                                                children: [
                                                  const Text(
                                                    'Shipping Address:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          4.0), // Adjust spacing between text and icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditShippingAddressDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              buildLabelValueRow(
                                                'Address',
                                                [
                                                  order.shippingAddress
                                                      ?.address1,
                                                  order.shippingAddress
                                                      ?.address2,
                                                  order.shippingAddress?.city,
                                                  order.shippingAddress?.state,
                                                  order
                                                      .shippingAddress?.country,
                                                  order.shippingAddress?.pincode
                                                      ?.toString(),
                                                ]
                                                    .where((element) =>
                                                        element != null &&
                                                        element.isNotEmpty)
                                                    .join(', '),
                                              ),
                                              buildLabelValueRow(
                                                'Name',
                                                order.shippingAddress
                                                            ?.firstName !=
                                                        order.shippingAddress
                                                            ?.lastName
                                                    ? '${order.shippingAddress?.firstName ?? ''} ${order.shippingAddress?.lastName ?? ''}'
                                                        .trim()
                                                    : order.shippingAddress
                                                            ?.firstName ??
                                                        '',
                                              ),
                                              buildLabelValueRow(
                                                'Phone',
                                                order.shippingAddress?.phone
                                                        ?.toString() ??
                                                    '',
                                              ),
                                              buildLabelValueRow(
                                                'Email',
                                                order.shippingAddress?.email ??
                                                    '',
                                              ),
                                              buildLabelValueRow(
                                                'Country Code',
                                                order.shippingAddress
                                                        ?.countryCode ??
                                                    '',
                                              ),
                                              buildLabelValueRow(
                                                'Pin Code',
                                                order.shippingAddress?.pincode
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 50.0),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Row to place 'Billing Address' and the edit icon side by side
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Billing Address:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12.0,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width:
                                                          8.0), // Add some space between the text and icon
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size:
                                                          16, // Smaller icon size
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(), // Remove size constraints
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            EditBillingAddressDialog(
                                                                order: order),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),

                                              // Build the other label-value rows
                                              buildLabelValueRow(
                                                'Address',
                                                [
                                                  order
                                                      .billingAddress?.address1,
                                                  order
                                                      .billingAddress?.address2,
                                                  order.billingAddress?.city,
                                                  order.billingAddress?.state,
                                                  order.billingAddress?.country,
                                                  order.billingAddress?.pincode
                                                      ?.toString(),
                                                ]
                                                    .where((element) =>
                                                        element != null &&
                                                        element.isNotEmpty)
                                                    .join(', '),
                                              ),
                                              buildLabelValueRow(
                                                'Name',
                                                order.billingAddress?.firstName !=
                                                        order.billingAddress
                                                            ?.lastName
                                                    ? '${order.billingAddress?.firstName ?? ''} ${order.billingAddress?.lastName ?? ''}'
                                                        .trim()
                                                    : order.billingAddress
                                                            ?.firstName ??
                                                        '',
                                              ),
                                              buildLabelValueRow(
                                                  'Phone',
                                                  order.billingAddress?.phone
                                                          ?.toString() ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Email',
                                                  order.billingAddress?.email ??
                                                      ''),
                                              buildLabelValueRow(
                                                  'Country Code',
                                                  order.billingAddress
                                                          ?.countryCode ??
                                                      ''),

                                              buildLabelValueRow(
                                                'Pin Code',
                                                order.shippingAddress?.pincode
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 1,
                                    color: AppColors.grey,
                                  ),
                                  // Nested cards for each item in the order
                                  const SizedBox(height: 6),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: order.items.length,
                                    itemBuilder: (context, itemIndex) {
                                      final item = order.items[itemIndex];

                                      return OrderItemCard(
                                        item: item,
                                        index: itemIndex,
                                        courierName: order.courierName,
                                        orderStatus:
                                            order.orderStatus.toString(),
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
                currentPage: accountsProvider.currentPage,
                totalPages: accountsProvider.totalPages,
                buttonSize: 30,
                pageController: accountsProvider.textEditingController,
                onFirstPage: () {
                  accountsProvider.goToPage(1);
                },
                onLastPage: () {
                  accountsProvider.goToPage(accountsProvider.totalPages);
                },
                onNextPage: () {
                  if (accountsProvider.currentPage <
                      accountsProvider.totalPages) {
                    accountsProvider.goToPage(accountsProvider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (accountsProvider.currentPage > 1) {
                    accountsProvider.goToPage(accountsProvider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  accountsProvider.goToPage(page);
                },
                onJumpToPage: () {
                  final page =
                      int.tryParse(accountsProvider.textEditingController.text);
                  if (page != null &&
                      page > 0 &&
                      page <= accountsProvider.totalPages) {
                    accountsProvider.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(
      Order order, int index, AccountsProvider accountsProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: accountsProvider
                .selectedProducts[index], // Accessing selected products
            onChanged: (isSelected) {
              accountsProvider.handleRowCheckboxChange(index, isSelected!);
            },
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Space between elements
              children: [
                Expanded(
                  child:
                      OrderCard(order: order), // Your existing OrderCard widget
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // if (returnProvider.isReturning)
          //   Center(
          //     child: CircularProgressIndicator(), // Loading indicator
          //   ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(int totalCount, AccountsProvider accountsProvider) {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: accountsProvider.selectAll,
              onChanged: (value) {
                accountsProvider.toggleSelectAll(value!);
              },
            ),
          ),
          Text(
            'Select All(${accountsProvider.selectedCount})',
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

Widget buildLabelValueRow(String label, String? value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label: ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
      Flexible(
        child: Text(
          value ?? '',
          softWrap: true,
          maxLines: null,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ),
    ],
  );
}
