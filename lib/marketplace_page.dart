import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';

import 'model/combo_model.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      provider.fetchProducts();
      provider.fetchMarketplaces();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketplaceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isFormVisible ? AppColors.cardsred : AppColors.primaryBlue,
                ),
                onPressed: () {
                  provider.toggleForm();
                  FocusScope.of(context).unfocus();
                },
                child: provider.isFormVisible ? const Text('Cancel') : const Text('Create Marketplace'),
              ),
              if (!provider.isFormVisible)
                Row(
                  children: [
                    Utils.richText('Total: ', provider.totalMarketplace.toString()),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () {
                        Provider.of<MarketplaceProvider>(context, listen: false).fetchMarketplaces();
                      },
                      icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 200,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                hintText: 'Search Marketplaces',
                                hintStyle: TextStyle(color: Color.fromRGBO(117, 117, 117, 1), fontSize: 16),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onSubmitted: (value) => provider.updateSearchQuery(value),
                              onChanged: (value) => provider.updateSearchQuery(value),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _searchController.clear();
                                provider.updateSearchQuery('');
                              },
                              child: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.isFormVisible) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Marketplace', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: provider.nameController,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('SKU Map:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Consumer<MarketplaceProvider>(
                    builder: (context, provider, child) {
                      List<Map<String, dynamic>> options = provider.products
                          .map((product) => {
                                'name': product.displayName ?? 'Unknown',
                                'product': product,
                              })
                          .toList();

                      return Column(
                        children: provider.skuMaps.asMap().entries.map((entry) {
                          int index = entry.key;
                          var skuMap = entry.value;
                          return SkuMapRow(
                            key: ValueKey(index), // Ensure unique keys for each row
                            index: index,
                            initialSku: skuMap.mktpSku,
                            initialProduct: skuMap.product,
                            options: options,
                            onRemove: () => provider.removeSkuMapRow(index),
                            onUpdate: (sku, product) => provider.updateSkuMap(index, sku, product),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: provider.addSkuMapRow,
                    child: const Text('Add New Row'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.isSaving
                        ? null
                        : () async {
                            await provider.saveMarketplace();
                          },
                    child: provider.isSaving
                        ? const CircularProgressIndicator(color: Colors.purple)
                        : const Text('Save Marketplace'),
                  ),
                ],
              ),
            ),
          ],
          if (!provider.isFormVisible) ...[
            Expanded(
              child: Consumer<MarketplaceProvider>(
                builder: (context, provider, child) {
                  if (provider.loading) return const Center(child: CircularProgressIndicator());
                  if (provider.marketplaces.isEmpty) return const Center(child: Text('No marketplaces found.'));

                  return ListView.builder(
                    itemCount: provider.filteredMarketplaces.length,
                    itemBuilder: (context, index) {
                      final marketplace = provider.filteredMarketplaces[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    marketplace.name,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.blueGrey),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Delete Marketplace'),
                                            content: const Text('Are you sure you want to delete this marketplace?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  provider.deleteMarketplace(marketplace.id!);
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: marketplace.skuMap.map((skuMap) {
                                    final product = skuMap.product;
                                    final imageUrl = (product?.images as List<dynamic>?)?.isNotEmpty == true
                                        ? product!.images![0]
                                        : null;

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Card(
                                        elevation: 3,
                                        margin: const EdgeInsets.only(top: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              imageUrl != null
                                                  ? Image.network(
                                                      imageUrl,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          const Icon(Icons.image, size: 80, color: Colors.grey),
                                                    )
                                                  : const Icon(Icons.image, size: 80, color: Colors.grey),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'SKU: ${skuMap.mktpSku}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Product Name: ${product?.displayName ?? 'Unknown'}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: product != null ? Colors.black87 : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Product SKU: ${product?.sku ?? 'N/A'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: product != null ? Colors.black54 : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Stateful widget for each SKU map row
class SkuMapRow extends StatefulWidget {
  final int index;
  final String initialSku;
  final Product? initialProduct;
  final List<Map<String, dynamic>> options;
  final VoidCallback onRemove;
  final void Function(String, Product?) onUpdate;

  const SkuMapRow({
    super.key,
    required this.index,
    required this.initialSku,
    required this.initialProduct,
    required this.options,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  _SkuMapRowState createState() => _SkuMapRowState();
}

class _SkuMapRowState extends State<SkuMapRow> {
  late TextEditingController _skuController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.initialSku);
    _selectedIndex = widget.initialProduct != null
        ? widget.options.indexWhere((option) => option['product'] == widget.initialProduct)
        : 0;
  }

  @override
  void dispose() {
    _skuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _skuController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'SKU',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                widget.onUpdate(value, widget.options[_selectedIndex]['product']);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomDropdown(
              option: widget.options,
              selectedIndex: _selectedIndex,
              onSelectedChanged: (selectedIndex) {
                setState(() {
                  _selectedIndex = selectedIndex;
                });
                widget.onUpdate(_skuController.text, widget.options[selectedIndex]['product']);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
