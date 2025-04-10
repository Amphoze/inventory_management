import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/product_search_field.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:provider/provider.dart';

import 'provider/warehouse_provider.dart';

class CreateInventoryScreen extends StatefulWidget {
  const CreateInventoryScreen({super.key});

  @override
  State<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends State<CreateInventoryScreen> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().initCreateInventory();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: const Text('Create Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                ProductSearchableTextField(
                  isRequired: true,
                  onSelected: (product) {
                    if (product != null) {
                      provider.setSelectedProductId(product.id.toString());
                    }
                  },
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: provider.subInventories.length,
                    itemBuilder: (context, index) {
                  
                      final subInventory = provider.subInventories[index];
                  
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                            color: Colors.grey[100],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sub Inventory ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                  
                              const SizedBox(height: 15),
                  
                              Row(
                                children: [
                  
                                  Expanded(
                                    child: Consumer<WarehouseProvider>(
                                      builder: (context, pro, child) {
                                        return _buildDropdown(
                                          value: subInventory.warehouseName,
                                          label: 'Warehouse',
                                          items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                                          onChanged: (value) async {
                                            if (value != null) {
                                              final tempWarehouse = pro.warehouses.firstWhere((e) => e['name'] == value);
                                              final id = tempWarehouse['_id'].toString();
                                              provider.updateSubInventory(index: index, warehouseName: value, warehouseId: id);
                                              await provider.fetchBins(context, id, index);
                                            }
                                          },
                                          validator: (value) => value == null ? 'Please select a warehouse' : null,
                                        );
                                      },
                                    ),
                                  ),
                  
                                  const SizedBox(width: 8),
                  
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Threshold Quantity',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      onChanged: (value) {
                                        provider.updateSubInventory(index: index, thresholdQuantity: value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                  
                              const SizedBox(height: 16),
                  
                              provider.fetchingBins[index]
                                  ?
                              const CircularProgressIndicator()
                                  :
                              provider.bins[index].isEmpty
                                  ?
                              const Text(
                                'No Bin Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black
                                ),
                              )
                                  :
                              _buildDropdown(
                                value: subInventory.bin.binName,
                                label: 'Bin Name',
                                items: provider.bins[index],
                                onChanged: (value) {
                                  if (provider.bins.isEmpty) {
                                    return;
                                  }
                                  provider.updateSubInventory(index: index, bin: subInventory.bin.copyWith(binName: value));
                                },
                                validator: (value) => value == null || value.isEmpty ? 'Please select a bin' : null,
                              ),
                  
                              const SizedBox(height: 8),
                  
                              TextFormField(
                                onChanged: (value) {
                                  provider.updateSubInventory(index: index, bin: subInventory.bin.copyWith(binQuantity: value));
                                },
                                decoration: const InputDecoration(labelText: 'Bin Quantity'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter Bin Quantity';
                                  // if (int.tryParse(value) == null) return 'Please enter a valid number';
                                  return null;
                                },
                              ),
                  
                              const SizedBox(height: 16),
                  
                              if (provider.subInventories.length > 1)
                                TextButton.icon(
                                  onPressed: () {
                                    provider.removeCreateInventoryModel(index);
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text("Remove", style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        provider.addCreateInventoryModel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent
                      ),
                      child: const Text(
                        'Add Sub Inventory',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white
                        ),
                      ),
                    )
                  ]
                ),

                const SizedBox(height: 50),

                Center(
                  child: ElevatedButton(
                    onPressed: () async {

                      List<String> warehouses = [];

                      for (var inventory in provider.subInventories) {
                        if (inventory.warehouseId == null || inventory.warehouseName == null) {
                          Utils.showSnackBar(context, 'Please Select Warehouse for all Inventories..!');
                          return;
                        } else if (inventory.bin.binName == null || inventory.bin.binQuantity == null) {
                          Utils.showSnackBar(context, 'Please Enter Bin Name/Quantity for all Inventories..!');
                          return;
                        } else if (warehouses.contains(inventory.warehouseName)) {
                          Utils.showSnackBar(context, 'You cannot add same warehouse to inventory (${inventory.warehouseName})');
                          return;
                        } else {
                          warehouses.add(inventory.warehouseName.toString());
                        }
                      }

                      provider.setCreatingInventory(true);
                      await provider.createInventory(context);
                      provider.setCreatingInventory(false);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent
                    ),
                    child: const Text(
                      'Create Inventory',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    print('Building dropdown with value: $value, items: $items');
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        label: Text(label, style: const TextStyle(color: Colors.black)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
      hint: Text('Select $label'),
      isExpanded: true,
    );
  }
}
