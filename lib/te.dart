import 'package:flutter/material.dart';
import 'package:inventory_management/Api/bin_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:provider/provider.dart';

class BinProductsPage extends StatefulWidget {
  const BinProductsPage({super.key, required this.binName});

  final String binName;

  @override
  State<BinProductsPage> createState() => _BinProductsPageState();
}

class _BinProductsPageState extends State<BinProductsPage> {
  @override
  void initState() {
    context.read<BinApi>().fetchBinProducts(
          widget.binName,
        );
    super.initState();
  }

  Widget _buildProductName(String name) {
    return Text(
      name ?? 'No Name',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BinApi>(
      builder: (context, b, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (b.isLoadingProducts)
                const Expanded(
                  child: Center(
                    child: LoadingAnimation(
                      icon: Icons.archive,
                      beginColor: Color.fromRGBO(189, 189, 189, 1),
                      endColor: AppColors.primaryBlue,
                      size: 80.0,
                    ),
                  ),
                )
              else if (b.products.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No Products Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: AppColors.primaryBlue),
                              onPressed: () => b.toggle(true),
                              tooltip: 'Back to bins list',
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Bin Name: ${widget.binName}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              "Qty: ${b.binQty}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: b.products.length,
                              itemBuilder: (context, itemIndex) {
                                final item = b.products[itemIndex];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(
                                        10), // Slightly smaller rounded corners
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                            0.08), // Lighter shadow for smaller card
                                        offset: const Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        10.0), // Reduced padding inside product card
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildProductName(
                                                  item['displayName']),
                                              const SizedBox(
                                                  height:
                                                      6.0), // Reduced spacing between text elements
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceBetween, // Space between widgets
                                                children: [
                                                  // SKU at the extreme left
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text: 'SKU: ',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.blueAccent,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                15, // Reduced font size
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              item['sku'] ?? 'N/A',
                                                          style: const TextStyle(
                                                            color: Colors.black87,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                13, // Reduced font size
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
                                                            color:
                                                                Colors.blueAccent,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                13, // Reduced font size
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: item['qty'] ?? '0',
                                                          style: const TextStyle(
                                                            color: Colors.black87,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize:
                                                                15, // Reduced font size
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
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              CustomPaginationFooter(
                currentPage: b.currentPage,
                totalPages: b.totalPages,
                buttonSize: 30,
                pageController: b.textEditingController,
                onFirstPage: () {
                  b.goToPage(1);
                },
                onLastPage: () {
                  b.goToPage(b.totalPages);
                },
                onNextPage: () {
                  if (b.currentPage < b.totalPages) {
                    b.goToPage(b.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (b.currentPage > 1) {
                    b.goToPage(b.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  b.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(b.textEditingController.text);
                  if (page != null && page > 0 && page <= b.totalPages) {
                    b.goToPage(page);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
