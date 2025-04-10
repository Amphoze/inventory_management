import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventory_management/Api/bin_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:provider/provider.dart';

class BinProductsPage extends StatefulWidget {
  const BinProductsPage({super.key, required this.binName});

  final String binName;

  @override
  State<BinProductsPage> createState() => _BinProductsPageState();
}

class _BinProductsPageState extends State<BinProductsPage> {
  final _searchController = TextEditingController();
  late BinProvider pro;

  @override
  void initState() {
    pro = context.read<BinProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pro.fetchBinProducts(widget.binName);
      pro.setBinName(widget.binName);
    });
    super.initState();
  }

  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      pro.fetchBinProducts(widget.binName);
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      pro.searchProducts(widget.binName, value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BinProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // Back button with hover effect
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => provider.toggle(true),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.primaryBlue,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Back',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Bin name with ellipsis overflow handling
                    Expanded(child: Utils.richText('Bin: ', widget.binName, fontSize: 20)),
                    // Expanded(
                    //   child: Text(
                    //     "Bin: ${widget.binName}",
                    //     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    //           fontWeight: FontWeight.w600,
                    //           color: Colors.black87,
                    //         ),
                    //     overflow: TextOverflow.ellipsis,
                    //   ),
                    // ),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Product',
                                hintStyle: TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  provider.searchProducts(widget.binName, value);
                                } else {
                                  provider.fetchBinProducts(widget.binName);
                                }
                              },
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            InkWell(
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              onTap: () {
                                _searchController.clear();
                                provider.fetchBinProducts(widget.binName);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quantity indicator with custom container
                    Container(
                      // padding: const EdgeInsets.symmetric(
                      //     horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${provider.binQty ?? 0}",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.isLoadingProducts)
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
              else if (provider.products.isEmpty)
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
                  child: SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.products.length,
                      itemBuilder: (context, itemIndex) {
                        final item = provider.products[itemIndex];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.lightGrey,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Handle item tap
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Name
                                    Text(
                                      item['displayName'],
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            height: 1.2,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    // SKU and Quantity Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // SKU Container
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.lightGrey.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'SKU:',
                                                style: TextStyle(
                                                  color: Colors.blueAccent.shade700,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['sku'] ?? 'N/A',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quantity Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 16,
                                                color: Colors.blueAccent.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['qty'].toString(),
                                                style: TextStyle(
                                                  color: Colors.blueAccent.shade700,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              CustomPaginationFooter(
                currentPage: provider.currentPage,
                totalPages: provider.totalPages,
                buttonSize: 30,
                pageController: provider.textEditingController,
                onFirstPage: () {
                  provider.goToPage(1);
                },
                onLastPage: () {
                  provider.goToPage(provider.totalPages);
                },
                onNextPage: () {
                  if (provider.currentPage < provider.totalPages) {
                    provider.goToPage(provider.currentPage + 1);
                  }
                },
                onPreviousPage: () {
                  if (provider.currentPage > 1) {
                    provider.goToPage(provider.currentPage - 1);
                  }
                },
                onGoToPage: (page) {
                  provider.goToPage(page);
                },
                onJumpToPage: () {
                  final page = int.tryParse(provider.textEditingController.text);
                  if (page != null && page > 0 && page <= provider.totalPages) {
                    provider.goToPage(page);
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
