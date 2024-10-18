import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart'; // Adjust the import based on your project structure
import 'package:inventory_management/edit_order_page.dart';
import 'package:inventory_management/model/orders_model.dart'; // Adjust the import based on your project structure

class OrderCard extends StatelessWidget {
  final Order order;
  final bool isBookPage;

  const OrderCard({
    Key? key,
    required this.order,
    this.isBookPage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building OrderCard for Order ID: ${order.id}');
    return Card(
      color: AppColors.white,
      elevation: 4, // Reduced elevation for less shadow
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12), // Slightly smaller rounded corners
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Padding(
        padding:
            const EdgeInsets.all(12.0), // Reduced padding for a smaller card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Reduced font size
                    color: Colors.blueAccent,
                  ),
                ),
                if (isBookPage)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditOrderPage(
                            order: order,
                            isBookPage: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.orange,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    child: const Text(
                      'Edit Order',
                    ),
                  ),

                //Text('Tracking Status: ${order.trackingStatus}'),
              ],
            ),

            const SizedBox(height: 6.0),
            // New Row for Billing Address
            _buildAddressRow('Billing Address:', order.billingAddress),
            const SizedBox(height: 6.0),
            // New Row for Shipping Address
            _buildAddressRow('Shipping Address:', order.shippingAddress),
            const SizedBox(height: 6.0), // Smaller spacing between elements
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, itemIndex) {
                final item = order.items[itemIndex];
                print(
                    'Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
                return _buildProductDetails(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius:
            BorderRadius.circular(10), // Slightly smaller rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.08), // Lighter shadow for smaller card
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding:
            const EdgeInsets.all(10.0), // Reduced padding inside product card
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(item),
            const SizedBox(
                width: 8.0), // Reduced spacing between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductName(item),
                  const SizedBox(
                      height: 6.0), // Reduced spacing between text elements
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Space between widgets
                    children: [
                      // SKU at the extreme left
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
                              text: item.product?.sku ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Qty in the center
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Qty: ',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: item.qty?.toString() ?? '0',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Amount at the extreme right
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
                              text: 'Rs.${item.amount.toString()}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(String title, Address? address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8.0),
        Flexible(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              children: [
                TextSpan(
                  text: [
                    address?.address1,
                    address?.address2,
                    address?.city,
                    address?.state,
                    address?.country,
                    address?.pincode?.toString(),
                  ]
                      .where((element) => element != null && element.isNotEmpty)
                      .join(', '),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(Item item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 60, // Smaller image size
        height: 60,
        child: item.product?.shopifyImage != null &&
                item.product!.shopifyImage!.isNotEmpty
            ? Image.network(
                item.product!.shopifyImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 40, // Smaller fallback icon size
                    color: AppColors.grey,
                  );
                },
              )
            : const Icon(
                Icons.image_not_supported,
                size: 40, // Smaller fallback icon size
                color: AppColors.grey,
              ),
      ),
    );
  }

  Widget _buildProductName(Item item) {
    return Text(
      item.product?.displayName ?? 'No Name',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14, // Reduced font size
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
