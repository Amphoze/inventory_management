// ignore_for_file: avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:inventory_management/Api/combo_api.dart';
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

    // List<Map<String,String?> selectedProductIds =
    //     comboProvider.selectedProducts.map((product) => product.id).toList();
    List<Map<String, String>> selectedProductIds =
        comboProvider.selectedProducts.map((product) {
      return {'product': product.id ?? ''};
    }).toList();

    for (int i = 0; i < selectedProductIds.length; i++) {
      print("i am creating combo ${selectedProductIds[i]}");
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

    try {
      await comboApi.createCombo(
          combo, comboProvider.selectedImages, comboProvider.imageNames);
      // comboProvider.setCombo(combo);
      // comboProvider.addCombo(combo);
      _clearFormFields();
      comboProvider.toggleFormVisibility();
    } catch (e) {
      print('Failed to save combo: $e');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ComboProvider>(
          builder: (context, comboProvider, child) {
            if (comboProvider.products.isNotEmpty && items.isEmpty) {
              getDropValue(); // Generate the dropdown items
            }

            print(items);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    comboProvider.toggleFormVisibility();
                  },
                  child: const Text('Create Combo'),
                ),
                if (comboProvider.isFormVisible) ...[
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  items.isEmpty
                      ? const CircularProgressIndicator() // Show loading if items are not ready
                      : MultiDropdown<String>(
                          items: items,
                          controller: productController,
                          searchEnabled: true,
                          chipDecoration: const ChipDecoration(
                            backgroundColor: Colors.yellow,
                            wrap: true,
                            runSpacing: 2,
                            spacing: 10,
                          ),
                          fieldDecoration: FieldDecoration(
                            hintText: 'Select Products',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.black87),
                            ),
                          ),
                          dropdownDecoration: const DropdownDecoration(
                            maxHeight: 500,
                          ),
                          onSelectionChange: (selectedItems) {
                            debugPrint(
                                'Selected items (product IDs): $selectedItems');
                            comboProvider.selectProductsByIds(selectedItems);
                          },
                        ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _mrpController,
                    decoration: const InputDecoration(labelText: 'MRP'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _costController,
                    decoration: const InputDecoration(labelText: 'Cost'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: comboProvider.selectImages, // Pick images
                    child: const Text('Upload Images'),
                  ),
                  // Image Previews
                  comboProvider.selectedImages != null &&
                          comboProvider.selectedImages!.isNotEmpty
                      ? SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: comboProvider.selectedImages!.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Image.memory(
                                        comboProvider.selectedImages![index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comboProvider.imageNames[index],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : const Text('No images selected'),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => saveCombo(context),
                        child: const Text('Save Combo'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _clearFormFields();
                          comboProvider.toggleFormVisibility();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                ],

                // Do not touch this code - Begin - This is for getCombos
                if (!comboProvider.isFormVisible) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Existing Combos:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (comboProvider.loading)
                    const Center(child: CircularProgressIndicator()),
                  if (!comboProvider.loading &&
                      comboProvider.combosList.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: comboProvider.combosList.length,
                        itemBuilder: (context, index) {
                          final combo = comboProvider.combosList[index];
                          final images =
                              combo['images'] as List<dynamic>? ?? [];
                          final products =
                              combo['products'] as List<dynamic>? ?? [];

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        combo['name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'MRP: ₹${combo['mrp'] ?? 'N/A'}',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'Cost: ₹${combo['cost'] ?? 'N/A'}',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'SKU: ${combo['comboSku'] ?? 'N/A'}',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 16),
                                  if (images.isNotEmpty) ...[
                                    const Text(
                                      'Images:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: images.map((imageUrl) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.network(
                                                imageUrl,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                  if (products.isNotEmpty) ...[
                                    const Text(
                                      'Products:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: products.map((product) {
                                        return ListTile(
                                          title: Text(
                                            product['displayName']
                                                    ?.toString() ??
                                                'No Name Available',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                            'SKU: ${product['sku']?.toString() ?? 'No SKU Available'}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600]),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'No products available for this combo.',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else if (!comboProvider.loading &&
                      comboProvider.combosList.isEmpty) ...[
                    const Text(
                      'No combos available.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
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
                    )
                  ],
                ]

                // Do not touch this code - End
              ],
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Provider.of<ComboProvider>(context, listen: false).fetchCombos();
      //   },
      //   backgroundColor: Colors.blue,
      //   tooltip: 'Fetch Combos',
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }
}

class CustomDropdownItem<T> extends DropdownItem<T> {
  CustomDropdownItem({
    required String label,
    required T value,
    bool disabled = false,
    bool selected = false,
  }) : super(
          label: label,
          value: value,
          disabled: disabled,
          selected: selected,
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CustomDropdownItem<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
