import 'package:flutter/material.dart';
import '../Custom-Files/colors.dart';
import '../model/orders_model.dart';

class OrderInfo extends StatelessWidget {
  final Order order;
  final pro;
  const OrderInfo({super.key, required this.order, required this.pro});

  String maskPhoneNumber(dynamic phone) {
    if (phone == null) return '';
    String phoneStr = phone.toString();
    if (phoneStr.length < 4) return phoneStr;
    return '${'*' * (phoneStr.length - 4)}${phoneStr.substring(phoneStr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Information Grid
        Card(
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoColumn(
                  'Payment Details',
                  [
                    buildLabelValueRow('Payment Mode', order.paymentMode ?? ''),
                    buildLabelValueRow('Currency Code', order.currencyCode ?? ''),
                    buildLabelValueRow('COD Amount', order.codAmount.toString() ?? ''),
                    buildLabelValueRow('Prepaid Amount', order.prepaidAmount.toString() ?? ''),
                    buildLabelValueRow('Coin', order.coin.toString() ?? ''),
                    buildLabelValueRow('Tax Percent', order.taxPercent.toString() ?? ''),
                    buildLabelValueRow('Courier Name', order.courierName ?? ''),
                    buildLabelValueRow('Order Type', order.orderType ?? ''),
                    buildLabelValueRow('Payment Bank', order.paymentBank ?? ''),
                  ],
                ),
                const SizedBox(width: 16),
                _buildInfoColumn(
                  'Order Details',
                  [
                    buildLabelValueRow('Discount Amount', order.discountAmount.toString() ?? ''),
                    buildLabelValueRow('Discount Scheme', order.discountScheme ?? ''),
                    buildLabelValueRow('Agent', order.agent ?? ''),
                    buildLabelValueRow('Notes', order.notes ?? ''),
                    buildLabelValueRow('Marketplace', order.marketplace?.name ?? ''),
                    buildLabelValueRow('Source', order.source ?? ''),
                    buildLabelValueRow('Filter', order.filter ?? ''),
                    buildLabelValueRow(
                      'Expected Delivery Date',
                      order.expectedDeliveryDate != null ? pro.formatDate(order.expectedDeliveryDate!) : '',
                    ),
                    buildLabelValueRow('Preferred Courier', order.preferredCourier ?? ''),
                    buildLabelValueRow(
                      'Payment Date Time',
                      order.paymentDateTime != null ? pro.formatDateTime(order.paymentDateTime!) : '',
                    ),
                    buildLabelValueRow(
                      'Dimensions',
                      '${order.length.toString() ?? ''} x ${order.breadth.toString() ?? ''} x ${order.height.toString() ?? ''}',
                    ),
                    buildLabelValueRow('Tracking Status', order.trackingStatus ?? ''),
                  ],
                ),
                const SizedBox(width: 16),
                _buildInfoColumn(
                  'Shipment Details',
                  [
                    buildLabelValueRow('Delivery Term', order.deliveryTerm ?? ''),
                    buildLabelValueRow('Transaction Number', order.transactionNumber ?? ''),
                    buildLabelValueRow('Micro Dealer Order', order.microDealerOrder ?? ''),
                    buildLabelValueRow('Fulfillment Type', order.fulfillmentType ?? ''),
                    buildLabelValueRow('No. of Boxes', order.numberOfBoxes.toString() ?? ''),
                    buildLabelValueRow('Total Quantity', order.totalQuantity.toString() ?? ''),
                    buildLabelValueRow('SKU Qty', order.skuQty.toString() ?? ''),
                    buildLabelValueRow('Calc Entry No.', order.calcEntryNumber ?? ''),
                    buildLabelValueRow('Currency', order.currency ?? ''),
                  ],
                ),
                const SizedBox(width: 16),
                _buildInfoColumn(
                  'Customer Information',
                  [
                    buildLabelValueRow('Customer ID', order.customer?.customerId ?? ''),
                    buildLabelValueRow(
                        'Full Name',
                        order.customer?.firstName != order.customer?.lastName
                            ? '${order.customer?.firstName ?? ''} ${order.customer?.lastName ?? ''}'.trim()
                            : order.customer?.firstName ?? ''),
                    buildLabelValueRow('Email', order.customer?.email ?? ''),
                    buildLabelValueRow('Phone', maskPhoneNumber(order.customer?.phone?.toString()) ?? ''),
                    buildLabelValueRow('GSTIN', order.customer?.customerGstin ?? ''),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Address Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAddressCard(
                'Shipping Address',
                order.shippingAddress,
                order.shippingAddress?.firstName,
                order.shippingAddress?.lastName,
                order.shippingAddress?.pincode,
                order.shippingAddress?.zipcode,
                order.shippingAddress?.countryCode,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAddressCard(
                'Billing Address',
                order.billingAddress,
                order.billingAddress?.firstName,
                order.billingAddress?.lastName,
                order.billingAddress?.pincode,
                order.billingAddress?.zipcode,
                order.billingAddress?.countryCode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildLabelValueRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
          ),
        ),
        Flexible(
          child: Tooltip(
            message: value ?? '',
            child: Text(
              value ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(String title, List<Widget> children) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

// Helper method to build address cards
  Widget _buildAddressCard(
    String title,
    dynamic address,
    String? firstName,
    String? lastName,
    dynamic pincode,
    dynamic zipcode,
    String? countryCode,
  ) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Address: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
                Expanded(
                  child: Text(
                    [
                      address?.address1,
                      address?.address2,
                      address?.city,
                      address?.state,
                      address?.country,
                      address?.pincode?.toString(),
                    ]
                        .where((element) => element != null && element.isNotEmpty)
                        .join(', ')
                        .replaceAllMapped(RegExp('.{1,50}'), (match) => '${match.group(0)}\n'),
                    softWrap: true,
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            buildLabelValueRow(
              'Name',
              firstName != lastName ? '$firstName $lastName'.trim() : firstName ?? '',
            ),
            if (pincode?.toString() != '0')buildLabelValueRow('Pincode', pincode?.toString() ?? ''),
            if (zipcode?.toString().isNotEmpty ?? false) buildLabelValueRow('Zipcode', zipcode?.toString() ?? ''),
            buildLabelValueRow('Country Code', countryCode ?? ''),
          ],
        ),
      ),
    );
  }
}
