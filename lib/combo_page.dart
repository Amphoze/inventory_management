// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inventory_management/Api/combo_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Widgets/searchable_dropdown.dart';
import 'package:inventory_management/model/combo_model.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:provider/provider.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

class ComboPage extends StatefulWidget {
  const ComboPage({super.key});

  @override
  _ComboPageState createState() => _ComboPageState();
}

class _ComboPageState extends State<ComboPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Map<String, String>> selectedProducts = [];
  int currentPage = 1;
  int totalCombos = 0;

  Product? product;
  ComboProvider? comboProvider;
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _mrpController = TextEditingController();
  final _costController = TextEditingController();

  //final productController = MultiSelectController<String>();

  late final MultiSelectController<String> productController;
  List<DropdownItem<String>> items = [];

  void _clearFormFields() {
    _idController.clear();
    _nameController.clear();
    _mrpController.clear();
    _costController.clear();
    _skuController.clear();
    productController.selectedItems.clear();
  }

  void saveCombo(BuildContext context) async {
    ComboProvider comboProvider =
        Provider.of<ComboProvider>(context, listen: false);

    // Map selected products to IDs
    List<Map<String, String>> selectedProductIds =
        selectedProducts.map((product) {
      return {'product': product['id'] ?? ''};
    }).toList();

    for (int i = 0; i < selectedProductIds.length; i++) {
      print(
          "Creating combo with product ID: ${selectedProductIds[i]['product']}");
    }

    final combo = Combo(
      id: _idController.text,
      products: selectedProductIds,
      name: _nameController.text,
      mrp: _mrpController.text,
      cost: _costController.text,
      comboSku: _skuController.text,
    );

    final comboApi = ComboApi();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving combo...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await comboApi.createCombo(
          combo, comboProvider.selectedImages, comboProvider.imageNames);
      refreshCombos();

      _clearFormFields();
      comboProvider.toggleFormVisibility();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Combo saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Failed to save combo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save combo!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final comboProvider = Provider.of<ComboProvider>(context, listen: false);
      comboProvider.fetchCombos(page: currentPage, limit: 10);
      //comboProvider.fetchProducts();
      productController = MultiSelectController<String>();
      getDropValue();
      // print(1);
    });
  }

  // Function to load more combos
  void loadMoreCombos() async {
    currentPage++;
    final comboProvider = Provider.of<ComboProvider>(context, listen: false);
    await comboProvider.fetchCombos(page: currentPage, limit: 10);
  }

  // Function to load combos
  void loadCombos() async {
    final comboProvider = Provider.of<ComboProvider>(context, listen: false);
    await comboProvider.fetchCombos(page: currentPage, limit: 10);
  }

  // Function to refresh combos
  void refreshCombos() {
    currentPage = 1;
    loadCombos();
  }

  void getDropValue() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchProducts();
    print("getDropValue");

    List<DropdownItem<String>> newItems = [];
    ComboProvider comboProvider =
        Provider.of<ComboProvider>(context, listen: false);

    for (int i = 0; i < comboProvider.products.length; i++) {
      newItems.add(DropdownItem<String>(
        label: '$i: ${comboProvider.products[i].displayName ?? 'Unknown'}',
        value: comboProvider.products[i].id,
      ));
    }

    //print("items in drop down: $newItems");

    setState(() {
      items = newItems;
    });
  }

  // void getDropValue() async {
  //   await comboProvider!.fetchCombos();
  //   await comboProvider!.fetchProducts();
  //   print("new style");
  //   for (int i = 0; i < comboProvider!.products.length; i++) {
  //     print("heello i am divyansh");
  //     comboProvider!.addItem('$i:${comboProvider!.products[i].displayName}', comboProvider!.products[i].id);
  //     // items.add(DropdownItem<String>(
  //     //   label: '$i:${comboProvider!.products[i].displayName}',
  //     //   value: comboProvider!.products[i].id,
  //     // ));
  //   }

  //   print("length of it is here ${comboProvider!.item.length}");
  //   // setState(() {

  //   // });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ComboProvider>(
          builder: (context, comboProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!comboProvider.isFormVisible)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Existing Combos',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                comboProvider.toggleFormVisibility();
                              },
                              child: const Text('Create Combo')),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            onPressed: comboProvider.isRefreshingOrders
                                ? null
                                : () async {
                                    refreshCombos();
                                  },
                            child: comboProvider.isRefreshingOrders
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
                if (comboProvider.isFormVisible)
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              saveCombo(context);
                            }
                          },
                          child: const Text('Save Combo')),
                      const SizedBox(width: 8),
                      TextButton(
                          onPressed: () {
                            _clearFormFields();
                            comboProvider.clearSelectedImages();
                            comboProvider.toggleFormVisibility();
                          },
                          child: const Text('Cancel')),
                    ],
                  ),
                if (comboProvider.isFormVisible)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Combo Name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SearchableDropdown(
                              label: "Add Products",
                              onChanged: (selected) {
                                if (selected != null &&
                                    !selectedProducts.any((product) =>
                                        product['sku'] == selected['sku'])) {
                                  setState(() {
                                    selectedProducts.add({
                                      'sku': selected['sku'] ?? '',
                                      'name': selected['name'] ?? '',
                                      'id': selected['id'] ?? '',
                                    });
                                  });
                                  print('Selected Product: $selected');
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8.0,
                              children: selectedProducts.map((product) {
                                return Chip(
                                  label: Text(
                                    '${product['sku']}: ${product['name']}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.yellow,
                                  deleteIcon: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side:
                                        const BorderSide(color: Colors.yellow),
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      selectedProducts.remove(product);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mrpController,
                              decoration:
                                  const InputDecoration(labelText: 'MRP'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter MRP';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _costController,
                              decoration:
                                  const InputDecoration(labelText: 'Cost'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Cost';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _skuController,
                              decoration:
                                  const InputDecoration(labelText: 'SKU'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter SKU';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  comboProvider.selectImages, // Pick images
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Upload Images'),
                            ),
                            comboProvider.selectedImages != null &&
                                    comboProvider.selectedImages!.isNotEmpty
                                ? SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          comboProvider.selectedImages!.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Column(
                                                children: [
                                                  Expanded(
                                                    child: Image.memory(
                                                      comboProvider
                                                              .selectedImages![
                                                          index],
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    comboProvider
                                                        .imageNames[index],
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: -8,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    comboProvider
                                                        .removeSelectedImage(
                                                            index);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Text(
                                    'No Images Selected.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Do not touch this code - Begin - This is for getCombos
                if (!comboProvider.isFormVisible) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: comboProvider.loading
                        ? const Center(
                            child: LoadingAnimation(
                              icon: Icons.collections,
                              beginColor: Color.fromRGBO(189, 189, 189, 1),
                              endColor: AppColors.primaryBlue,
                              size: 80.0,
                            ),
                          )
                        : comboProvider.combosList.isNotEmpty
                            ? ListView.builder(
                                itemCount: comboProvider.combosList.length,
                                itemBuilder: (context, index) {
                                  final combo = comboProvider.combosList[index];
                                  final images =
                                      combo['images'] as List<dynamic>? ?? [];
                                  final products =
                                      combo['products'] as List<dynamic>? ?? [];

                                  return Card(
                                    color: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 7, horizontal: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(15)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  combo['name'] ?? 'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  _buildCompactInfo(
                                                      label: 'MRP',
                                                      value:
                                                          '₹${combo['mrp'] ?? 'N/A'}'),
                                                  _buildCompactInfo(
                                                      label: 'Cost',
                                                      value:
                                                          '₹${combo['cost'] ?? 'N/A'}'),
                                                  _buildCompactInfo(
                                                      label: 'SKU',
                                                      value:
                                                          combo['comboSku'] ??
                                                              'N/A'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (images.isNotEmpty) ...[
                                                const Text(
                                                  'Images:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  height: 80,
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: images.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 8.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          child: Image.network(
                                                            images[index],
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Container(
                                                                width: 80,
                                                                height: 80,
                                                                color: Colors
                                                                    .grey[200],
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 40,
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                              if (products.isNotEmpty) ...[
                                                const Text(
                                                  'Products:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Column(
                                                  children:
                                                      products.map((product) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4.0),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[200],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Flexible(
                                                              child:
                                                                  SingleChildScrollView(
                                                                scrollDirection:
                                                                    Axis.horizontal,
                                                                child: Text(
                                                                  'SKU: ${product['sku']?.toString() ?? 'N/A'}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Flexible(
                                                              child:
                                                                  SingleChildScrollView(
                                                                scrollDirection:
                                                                    Axis.horizontal,
                                                                child: Text(
                                                                  product['displayName']
                                                                          ?.toString() ??
                                                                      'No Name Available',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                            .grey[
                                                                        800],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ] else ...[
                                                const SizedBox(height: 8),
                                                const Text(
                                                  '*No products available for this combo.',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  'No combos available.',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                  ),
                  // Pagination Controls
                  if (!comboProvider.loading &&
                      comboProvider.combosList.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: ElevatedButton(
                            onPressed: currentPage > 1
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                    loadMoreCombos();
                                  }
                                : null,
                            child: const Text('Previous'),
                          ),
                        ),
                        Text('Page $currentPage'),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ElevatedButton(
                            onPressed: () {
                              loadMoreCombos();
                            },
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]

                // Do not touch this code - End
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _buildCompactInfo({required String label, required String value}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
