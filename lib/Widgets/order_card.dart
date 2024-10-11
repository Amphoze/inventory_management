import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart'; // Adjust the import based on your project structure
import 'package:inventory_management/model/orders_model.dart'; // Adjust the import based on your project structure

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({
    Key? key,
    required this.order,
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
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Total Amount: ',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Reduced font size
                        ),
                      ),
                      TextSpan(
                        text: 'Rs.${order.totalAmount?.toString() ?? 0}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14, // Reduced font size
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
