import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
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
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketplaceProvider>(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.isFormVisible
                  ? AppColors.cardsred
                  : AppColors.primaryBlue,
            ),
            onPressed: () {
              provider.toggleForm(); // Toggle the form visibility
            },
            child: provider.isFormVisible
                ? const Text('Cancel')
                : const Text('Create Marketplace'),
          ),
          const SizedBox(height: 8),
          if (provider.isFormVisible) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Marketplace',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: provider.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SKU Map:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Consumer<MarketplaceProvider>(
                    builder: (context, provider, child) {
                      // Prepare the options for CustomDropdown
                      List<Map<String, dynamic>> options = provider.products
                          .map((product) => {
                                'name': product.displayName ?? 'Unknown',
                                'product': product,
                              })
                          .toList();

                      return Column(
                        children: provider.skuMaps.map((skuMap) {
                          int index = provider.skuMaps.indexOf(skuMap);
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                      text: skuMap.mktpSku),
                                  decoration: const InputDecoration(
                                    labelText: 'SKU',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    provider.updateSkuMap(
                                        index, value, skuMap.product);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomDropdown(
                                  option: options,
                                  selectedIndex: skuMap.product != null
                                      ? options.indexWhere((option) =>
                                          option['product'] == skuMap.product)
                                      : 0,
                                  onSelectedChanged: (selectedIndex) {
                                    final selectedProduct = options.isNotEmpty
                                        ? options[selectedIndex]['product']
                                        : null;
                                    provider.updateSkuMap(
                                        index, skuMap.mktpSku, selectedProduct);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () {
                                  provider.removeSkuMapRow(index);
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      provider
                          .addSkuMapRow(); // Adds a new empty row for SKU Map
                    },
                    child: const Text('Add New Row'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.isSaving
                        ? null // Disable button while saving
                        : () async {
                            await provider
                                .saveMarketplace(); // Save marketplace
                          },
                    child: provider.isSaving
                        ? const CircularProgressIndicator(
                            color: Colors
                                .purple, // Show progress indicator while saving
                          )
                        : const Text(
                            'Save Marketplace'), // Normal text when not saving
                  ),
                ],
              ),
            ),
          ],
          if (!provider.isFormVisible) ...[
            const SizedBox(height: 16),
            const Text(
              'Existing Marketplaces:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<MarketplaceProvider>(
                builder: (context, provider, child) {
                  if (provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.marketplaces.isEmpty) {
                    return const Center(child: Text('No marketplaces found.'));
                  }

                  return ListView.builder(
                    itemCount: provider.marketplaces.length,
                    itemBuilder: (context, index) {
                      final marketplace = provider.marketplaces[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        elevation:
                            6, // Enhanced shadow for better card visibility
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Marketplace title with delete option
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    marketplace.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.blueGrey),
                                    onPressed: () {
                                      // Confirm deletion dialog
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                                'Delete Marketplace'),
                                            content: const Text(
                                                'Are you sure you want to delete this marketplace?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  provider.deleteMarketplace(
                                                      marketplace.id!);
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
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

                              // Products within the marketplace
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: marketplace.skuMap.map((skuMap) {
                                    final product = skuMap.product;

                                    // Fetch the product image if it exists
                                    final imageUrl =
                                        (product?.images as List<dynamic>?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? product!.images![0]
                                            : null;

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Card(
                                        elevation: 3,
                                        margin: const EdgeInsets.only(top: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Display product image or a placeholder icon if no image is found
                                              imageUrl != null
                                                  ? Image.network(
                                                      imageUrl,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(Icons.image,
                                                              size: 80,
                                                              color: Colors.grey),
                                                    )
                                                  : const Icon(Icons.image,
                                                      size: 80,
                                                      color: Colors.grey),

                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                      color: product != null
                                                          ? Colors.black87
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Product SKU: ${product?.sku ?? 'N/A'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: product != null
                                                          ? Colors.black54
                                                          : Colors.grey,
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
                              const SizedBox(
                                width: 8,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call the method to fetch marketplaces
          Provider.of<MarketplaceProvider>(context, listen: false)
              .fetchMarketplaces();
        },
        backgroundColor: Colors.blue,
        tooltip: 'Fetch Marketplaces',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
