import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart'; // Adjust the import based on your project structure
import 'package:inventory_management/model/orders_model.dart';
// import 'package:inventory_management/edit_order_page.dart';
// import 'package:provider/provider.dart';
// import '../provider/orders_provider.dart'; // Adjust the import based on your project structure
import 'dart:developer';

class PickerProductCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isBookPage;
  final Widget? checkboxWidget;
  final String? name;
  final String? sku;
  final String? amount;
  int? qty;

  PickerProductCard({
    super.key,
    required this.order,
    this.isBookPage = false,
    this.checkboxWidget,
    this.name,
    this.amount,
    this.sku,
    this.qty,
  });

  @override
  Widget build(BuildContext context) {
    // final provider = Provider.of<OrdersProvider>(context, listen: false);
    // log('Building OrderCard for Order ID: ${order.id}');
    return Padding(
      padding: const EdgeInsets.all(12.0), // Reduced padding for a smaller card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6.0),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order['items'].length,
            itemBuilder: (context, itemIndex) {
              final item = order['items'][itemIndex];
              // log('Item $itemIndex: ${item.product?.displayName.toString() ?? ''}, Quantity: ${item.qty ?? 0}');
              return _buildProductDetails(item);
            },
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const SizedBox(
                width: 60, // Smaller image size
                height: 60,
                child: Icon(
                  Icons.image,
                  size: 40, // Smaller fallback icon size
                  color: AppColors.grey,
                ),
              ),
            ),
            const SizedBox(
                width: 8.0), // Reduced spacing between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14, // Reduced font size
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                      height: 6.0), // Reduced spacing between text elements
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
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: sku,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Reduced font size
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
                                fontSize: 13, // Reduced font size
                              ),
                            ),
                            TextSpan(
                              text: amount,
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
            const Spacer(), // Ensures `qty` is aligned to the right end
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
              child: Center(
                child: Text(
                  qty!.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget buildLabelValueRow(
  //   String label,
  //   String? value, {
  //   Color labelColor = Colors.black,
  //   Color valueColor = AppColors.primaryBlue,
  //   double fontSize = 10,
  // }) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         '$label: ',
  //         style: TextStyle(
  //           fontSize: fontSize,
  //           color: labelColor,
  //         ),
  //       ),
  //       Flexible(
  //         child: Text(
  //           value ?? '',
  //           softWrap: true,
  //           maxLines: null,
  //           style: TextStyle(
  //             fontSize: fontSize,
  //             color: valueColor,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildProductImage(Item item) {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(6),
  //     child: SizedBox(
  //       width: 60, // Smaller image size
  //       height: 60,
  //       child: item.product?.shopifyImage != null &&
  //               item.product!.shopifyImage!.isNotEmpty
  //           ? Image.network(
  //               item.product!.shopifyImage!,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) {
  //                 return const Icon(
  //                   Icons.image_not_supported,
  //                   size: 40, // Smaller fallback icon size
  //                   color: AppColors.grey,
  //                 );
  //               },
  //             )
  //           : const Icon(
  //               Icons.image_not_supported,
  //               size: 40, // Smaller fallback icon size
  //               color: AppColors.grey,
  //             ),
  //     ),
  //   );
  // }

  // Widget _buildProductName(Item item) {
  //   return Text(
  //     item.product?.displayName ?? 'No Name',
  //     style: const TextStyle(
  //       fontWeight: FontWeight.w600,
  //       fontSize: 14, // Reduced font size
  //       color: Colors.black87,
  //     ),
  //     maxLines: 2,
  //     overflow: TextOverflow.ellipsis,
  //   );
  // }
}
