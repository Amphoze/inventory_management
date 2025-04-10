import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Api/combo_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
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
  late ComboProvider comboProvider;
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _weightController = TextEditingController();
  final _mrpController = TextEditingController();
  final _costController = TextEditingController();

  Timer? _debounce;

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      comboProvider.fetchCombos();
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      comboProvider.searchCombos(value);
    });
  }

  late final MultiSelectController<String> productController;
  List<DropdownItem<String>> items = [];

  void _clearFormFields() {
    _idController.clear();
    _nameController.clear();
    _weightController.clear();
    _mrpController.clear();
    _costController.clear();
    _skuController.clear();
    productController.selectedItems.clear();
  }

  void saveCombo(BuildContext context) async {
    ComboProvider comboProvider = Provider.of<ComboProvider>(context, listen: false);

    // Map selected products to IDs
    List<Map<String, String>> selectedProductIds = selectedProducts.map((product) {
      return {'product': product['sku'] ?? ''};
    }).toList();

    for (int i = 0; i < selectedProductIds.length; i++) {
      print("Creating combo with product ID: ${selectedProductIds[i]['product']}");
    }

    final combo = Combo(
      id: _idController.text,
      products: selectedProductIds,
      name: _nameController.text,
      comboWeight: double.tryParse(_weightController.text.trim()),
      mrp: _mrpController.text,
      cost: _costController.text,
      comboSku: _skuController.text,
    );

    final comboApi = ComboApi();

    Utils.showSnackBar(context, 'Saving combo...');

    try {
      await comboApi.createCombo(combo, comboProvider.selectedImages, comboProvider.imageNames);
      refreshCombos();

      _clearFormFields();
      comboProvider.toggleFormVisibility();

      Utils.showSnackBar(context, 'Combo saved successfully', color: AppColors.cardsgreen);
    } catch (e) {
      print('Failed to save combo: $e');
      Utils.showSnackBar(context, 'Failed to save combo', isError: true, details: e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    comboProvider = Provider.of<ComboProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      comboProvider.fetchCombos(page: currentPage, limit: 10);
      productController = MultiSelectController<String>();
      getDropValue();
    });
  }

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

  void refreshCombos() {
    currentPage = 1;
    loadCombos();
  }

  void getDropValue() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchProducts();
    print("getDropValue");

    List<DropdownItem<String>> newItems = [];
    ComboProvider comboProvider = Provider.of<ComboProvider>(context, listen: false);

    for (int i = 0; i < comboProvider.products.length; i++) {
      newItems.add(DropdownItem<String>(
        label: '$i: ${comboProvider.products[i].displayName ?? 'Unknown'}',
        value: comboProvider.products[i].id,
      ));
    }

    setState(() {
      items = newItems;
    });
  }

  final TextEditingController _searchController = TextEditingController();

  final Map<String, ValueNotifier<int?>> _quantityNotifiers = {};

  ValueNotifier<int?> getQuantityNotifier(String sku) {
    if (!_quantityNotifiers.containsKey(sku)) {
      _quantityNotifiers[sku] = ValueNotifier<int?>(null);
      context.read<ComboProvider>().fetchQuantityBySku(sku).then((value) {
        _quantityNotifiers[sku]?.value = value;
      });
    }
    return _quantityNotifiers[sku]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<ComboProvider>(
          builder: (context, pro, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!pro.isFormVisible)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Existing Combos',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Row(
                        children: [
                          Utils.richText('Total: ', pro.totalCombos.toString()),
                          const SizedBox(width: 8),
                          Container(
                            width: 200,
                            height: 34,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryBlue,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search Combos',
                                hintStyle: const TextStyle(
                                  color: Color.fromRGBO(117, 117, 117, 1),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(10),
                              ),
                              style: const TextStyle(color: AppColors.black),
                              onChanged: _onSearchChanged,
                              onSubmitted: (text) {
                                if (_searchController.text.isEmpty) {
                                  pro.fetchCombos();
                                } else {
                                  pro.searchCombos(_searchController.text.trim());
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                              onPressed: () {
                                pro.toggleFormVisibility();
                              },
                              child: const Text('Create Combo')),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            onPressed: pro.isRefreshingOrders
                                ? null
                                : () async {
                                    refreshCombos();
                                  },
                            child: pro.isRefreshingOrders
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
                if (pro.isFormVisible)
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
                            pro.clearSelectedImages();
                            pro.toggleFormVisibility();
                          },
                          child: const Text('Cancel')),
                    ],
                  ),
                if (pro.isFormVisible)
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
                              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
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
                                    !selectedProducts.any((product) => product['sku'] == selected['sku'])) {
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
                              runSpacing: 8.0,
                              // alignment: WrapAlignment.center,
                              children: selectedProducts.map((product) {
                                return Chip(
                                  label: Text(
                                    '${product['sku']}: ${product['name']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.primaryBlue,
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
                                    side: const BorderSide(color: Colors.yellow),
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
                            Row(
                              children: [
                                Flexible(
                                  child: TextFormField(
                                    controller: _weightController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration:
                                        const InputDecoration(labelText: 'Weight', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter combo weight';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: TextFormField(
                                    controller: _mrpController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: const InputDecoration(labelText: 'MRP', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter MRP';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Flexible(
                                  child: TextFormField(
                                    controller: _costController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: const InputDecoration(labelText: 'Cost', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter Cost';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: TextFormField(
                                    controller: _skuController,
                                    decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter SKU';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: pro.selectImages, // Pick images
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Upload Images'),
                            ),
                            pro.selectedImages != null && pro.selectedImages!.isNotEmpty
                                ? SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: pro.selectedImages!.length,
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
                                                      pro.selectedImages![index],
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    pro.imageNames[index],
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: -8,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.red),
                                                  onPressed: () {
                                                    pro.removeSelectedImage(index);
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
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Do not touch this code - Begin - This is for getCombos
                if (!pro.isFormVisible) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: pro.loading
                        ? const Center(
                            child: LoadingAnimation(
                              icon: Icons.collections,
                              beginColor: Color.fromRGBO(189, 189, 189, 1),
                              endColor: AppColors.primaryBlue,
                              size: 80.0,
                            ),
                          )
                        : pro.combosList.isNotEmpty
                            ? ListView.builder(
                                itemCount: pro.combosList.length,
                                itemBuilder: (context, index) {
                                  final combo = pro.combosList[index];
                                  final images = combo['images'] as List<dynamic>? ?? [];
                                  final products = combo['products'] as List<dynamic>? ?? [];

                                  print("combo hai: $combo");

                                  return Card(
                                    color: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Tooltip(
                                                  message: combo['name'] ?? 'N/A',
                                                  child: Text(
                                                    combo['name'] ?? 'N/A',
                                                    maxLines: 2,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                        overflow: TextOverflow.ellipsis),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  _buildCompactInfo(
                                                      label: 'Weight', value: '${combo['comboWeight'] ?? 'N/A'} Kg'),
                                                  _buildCompactInfo(label: 'MRP', value: '₹${combo['mrp'] ?? 'N/A'}'),
                                                  _buildCompactInfo(label: 'Cost', value: '₹${combo['cost'] ?? 'N/A'}'),
                                                  _buildCompactInfo(label: 'SKU', value: combo['comboSku'] ?? 'N/A'),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8.0),
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final nameController =
                                                            TextEditingController(text: combo['name'] ?? '');
                                                        final weightController = TextEditingController(
                                                            text: combo['comboWeight']?.toString() ?? '');

                                                        try {
                                                          await showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) => AlertDialog(
                                                              title: const Text('Edit Combo'),
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  TextFormField(
                                                                    controller: nameController,
                                                                    decoration: const InputDecoration(
                                                                      labelText: 'Name',
                                                                      hintText: 'Enter combo name',
                                                                    ),
                                                                    textInputAction: TextInputAction.next,
                                                                    validator: (value) => value?.isEmpty ?? true
                                                                        ? 'Name is required'
                                                                        : null,
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  TextFormField(
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter.allow(
                                                                          RegExp(r'^\d*\.?\d*')),
                                                                    ],
                                                                    controller: weightController,
                                                                    decoration: const InputDecoration(
                                                                      labelText: 'Weight',
                                                                      hintText: 'Enter weight',
                                                                    ),
                                                                    keyboardType: const TextInputType.numberWithOptions(
                                                                        decimal: true),
                                                                    textInputAction: TextInputAction.done,
                                                                    validator: (value) {
                                                                      if (value?.isEmpty ?? true)
                                                                        return 'Weight is required';
                                                                      if (double.tryParse(value!) == null)
                                                                        return 'Invalid weight';
                                                                      return null;
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                  child: const Text('Cancel'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () async {
                                                                    if (nameController.text.isEmpty ||
                                                                        weightController.text.isEmpty) {
                                                                      Utils.showSnackBar(
                                                                          context, 'Please fill all fields',
                                                                          isError: true);
                                                                      return;
                                                                    }

                                                                    try {
                                                                      // Show loading dialog
                                                                      showDialog(
                                                                        context: context,
                                                                        barrierDismissible: false,
                                                                        builder: (context) => const Dialog(
                                                                          child: Padding(
                                                                            padding: EdgeInsets.symmetric(
                                                                                vertical: 20, horizontal: 24),
                                                                            child: Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                CircularProgressIndicator(),
                                                                                SizedBox(width: 16),
                                                                                Text('Updating...'),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );

                                                                      // Perform update
                                                                      final res = await pro.updateCombo(
                                                                        combo['_id'],
                                                                        nameController.text.trim(),
                                                                        weightController.text.trim(),
                                                                      );

                                                                      // Close loading dialog
                                                                      if (context.mounted) Navigator.of(context).pop();

                                                                      // Show result dialog
                                                                      if (context.mounted) {
                                                                        await showDialog(
                                                                          context: context,
                                                                          builder: (context) => AlertDialog(
                                                                            content: Text(res),
                                                                            actions: [
                                                                              TextButton(
                                                                                onPressed: () =>
                                                                                    Navigator.of(context).pop(),
                                                                                child: const Text('OK'),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      }

                                                                      // Close edit dialog
                                                                      if (context.mounted) Navigator.of(context).pop();
                                                                      pro.fetchCombos();
                                                                    } catch (e) {
                                                                      // Close loading dialog if open
                                                                      if (context.mounted) Navigator.of(context).pop();

                                                                      // Show error dialog
                                                                      if (context.mounted) {
                                                                        await showDialog(
                                                                          context: context,
                                                                          builder: (context) => AlertDialog(
                                                                            title: const Text('Error'),
                                                                            content: Text(
                                                                                'Failed to update: ${e.toString()}'),
                                                                            actions: [
                                                                              TextButton(
                                                                                onPressed: () =>
                                                                                    Navigator.of(context).pop(),
                                                                                child: const Text('OK'),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  },
                                                                  child: const Text('Submit'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        } finally {
                                                          nameController.dispose();
                                                          weightController.dispose();
                                                        }
                                                      },
                                                      child: const Text('Edit'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    scrollDirection: Axis.horizontal,
                                                    itemCount: images.length,
                                                    itemBuilder: (context, index) {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(right: 8.0),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(8.0),
                                                          child: Image.network(
                                                            images[index],
                                                            width: 80,
                                                            height: 80,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Container(
                                                                width: 80,
                                                                height: 80,
                                                                color: Colors.grey[200],
                                                                child: const Icon(
                                                                  Icons.broken_image,
                                                                  color: Colors.red,
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
                                                  children: products.map((product) {
                                                    // String? qty = pro.fetchQuantityBySku(product['sku']).toString() ?? '0';
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(12),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.grey.withValues(alpha: 0.1),
                                                              spreadRadius: 1,
                                                              blurRadius: 4,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                          border: Border.all(color: Colors.grey.shade200),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              flex: 2,
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    product['displayName']?.toString() ??
                                                                        'No Name Available',
                                                                    style: const TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: Colors.black87,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Text(
                                                                    'SKU: ${product['sku']?.toString() ?? 'N/A'}',
                                                                    style: TextStyle(
                                                                      fontSize: 14,
                                                                      color: Colors.grey[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                  horizontal: 12, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: Colors.blue.shade50,
                                                                borderRadius: BorderRadius.circular(20),
                                                              ),
                                                              child: ValueListenableBuilder<int?>(
                                                                valueListenable: getQuantityNotifier(product['sku']),
                                                                builder: (context, quantity, child) {
                                                                  String quantityText;
                                                                  Color textColor;

                                                                  if (quantity == null) {
                                                                    quantityText = 'Loading...';
                                                                    textColor = Colors.grey;
                                                                  } else {
                                                                    quantityText = quantity.toString();
                                                                    textColor = Colors.blue.shade700;
                                                                  }

                                                                  return Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.inventory_2_outlined,
                                                                        size: 16,
                                                                        color: textColor,
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        quantityText,
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: textColor,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                )
                                              ] else ...[
                                                const SizedBox(height: 8),
                                                const Text(
                                                  '*No products available for this combo.',
                                                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                  ),
                  // Pagination Controls
                  if (!pro.loading && pro.combosList.isNotEmpty) ...[
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
                                    loadCombos();
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
      color: Colors.white.withValues(alpha: 0.7),
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
