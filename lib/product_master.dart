import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/product_master_card.dart';
import 'package:inventory_management/create_product.dart';
import 'package:provider/provider.dart';
import 'Custom-Files/colors.dart';
import 'provider/product_master_provider.dart';

class ProductMasterPage extends StatefulWidget {
  const ProductMasterPage({super.key});

  @override
  State<ProductMasterPage> createState() => _ProductMasterPageState();
}

class _ProductMasterPageState extends State<ProductMasterPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductMasterProvider>(context, listen: false).loadMoreProducts(context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<ProductMasterProvider>(
                      builder: (context, provider, _) =>
                          !provider.showCreateProduct ? _buildProductList(context, provider) : const CreateProduct(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<ProductMasterProvider>(
      builder: (context, provider, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButtons(context, provider),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductMasterProvider provider) {
    return Row(
      children: [
        if (provider.selectedSearchOption != 'Show All Products') _buildConditionalSearchBar(context, provider),
        const SizedBox(width: 300),
        if (!provider.showCreateProduct) Text('Total Products: ${provider.totalProductsCount}', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 20),
        CustomButton(
          width: 150,
          height: 37,
          onTap: () => provider.toggleCreateProduct(),
          color: AppColors.primaryBlue,
          textColor: Colors.white,
          fontSize: 16,
          text: provider.showCreateProduct ? 'Back' : 'Create Products',
          borderRadius: BorderRadius.circular(8.0),
        ),
      ],
    );
  }

  Widget _buildConditionalSearchBar(BuildContext context, ProductMasterProvider provider) {
    return SizedBox(
      width: 420,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: provider.searchbarController,
              decoration: InputDecoration(
                hintText: 'Search by SKU or Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.orange, width: 2.0),
                ),
              ),
              onChanged: (value) {
                if(value.trim().isEmpty) {
                  provider.loadMoreProducts();
                }
              },
              onSubmitted: (_) => provider.performSearch(context),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.performSearch(context),
            child: const Text('Search'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: provider.refreshPage,
            child: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, ProductMasterProvider provider) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!provider.isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          provider.loadMoreProducts(context);
        }
        return false;
      },
      child: provider.products.isEmpty
          ? const Center(
              child: LoadingAnimation(
                icon: Icons.production_quantity_limits_rounded,
                beginColor: Color.fromRGBO(189, 189, 189, 1),
                endColor: AppColors.primaryBlue,
                size: 80.0,
              ),
            )
          : ListView.builder(
              itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.products.length) {
                  return const Center(
                    child: LoadingAnimation(
                      icon: Icons.production_quantity_limits_rounded,
                      beginColor: Color.fromRGBO(189, 189, 189, 1),
                      endColor: AppColors.primaryBlue,
                      size: 80.0,
                    ),
                  );
                }
                return ProductMasterCard(product: provider.products[index]);
              },
            ),
    );
  }
}
