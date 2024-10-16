import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'Api/inventory_api.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/data_table.dart';
import 'Custom-Files/loading_indicator.dart';

class ManageInventoryPage extends StatefulWidget {
  const ManageInventoryPage({
    super.key,
  });

  @override
  _ManageInventoryPageState createState() => _ManageInventoryPageState();
}

class _ManageInventoryPageState extends State<ManageInventoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  List<Map<String, dynamic>> subInventories = [];
  List<DropdownMenuItem<String>> dropdownItemsForWarehouses = [];
  String? selectedProductId;
  String? selectedProductName;
  int curentPage = 1;
  bool isloading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false)
          .fetchInventory(page: 1); // Start at page 1
      Provider.of<ComboProvider>(context, listen: false).fetchProducts();

      getDropValueForProduct();
      getDropValueForWarehouse(); // Fetch warehouse dropdown values
    });
  }

  void getDropValueForProduct() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchProducts();
    setState(() {});
  }

  void getDropValueForWarehouse() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchWarehouses();
    List<DropdownMenuItem<String>> newItems = [];
    ComboProvider comboProvider =
        Provider.of<ComboProvider>(context, listen: false);

    for (var warehouse in comboProvider.warehouses) {
      newItems.add(DropdownMenuItem<String>(
        value: warehouse['_id'],
        child: Text(warehouse['name'] ?? 'Unknown'),
      ));
    }

    setState(() {
      dropdownItemsForWarehouses = newItems;
      subInventories.add({'warehouseId': null, 'quantity': null});
    });
  }

  void addSubInventory() {
    setState(() {
      subInventories.add({'warehouseId': null, 'quantity': null});
    });
  }

  // Remove SubInventory entry
  void removeSubInventory(int index) {
    setState(() {
      subInventories.removeAt(index);
    });
  }

  void cancelForm() {
    final comboProvider = Provider.of<ComboProvider>(context, listen: false);
    comboProvider.toggleFormVisibility(); // Hide the form
  }

  Future<void> saveInventoryToApi(BuildContext context) async {
    if (selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select a product"),
      ));
      return;
    }

    final Map<String, dynamic> requestData = {
      "product_id": selectedProductId,
      "subInventory": subInventories.map((subInventory) {
        return {
          "warehouseId": subInventory['warehouseId'],
          "quantity": subInventory['quantity'],
        };
      }).toList(),
    };

    //print("Data to send: $requestData");

    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(
            'https://inventory-management-backend-s37u.onrender.com/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inventory created successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inventory created successfully!")),
          );
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //   content: Text("Failed to create inventory: ${responseData['message'] ?? 'Unknown error'}"),
          // ));
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: Text("Failed to save inventory: ${response.body}"),
        // ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving inventory: $e")),
      );
    }
  }

  void _goToPage(int page) {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    if (page >= 1 && page <= provider.totalPages) {
      provider.goToPage(page);
    }
  }

  void _jumpToPage() {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    int page = int.tryParse(_pageController.text) ?? 1;
    if (page >= 1 && page <= provider.totalPages) {
      _goToPage(page - 1); // Go to the user-input page
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);
    final comboProvider = Provider.of<ComboProvider>(context);
    final paginatedData = provider.inventory;
    List<String> columnNames = [
      'COMPANY NAME',
      'CATEGORY',
      'IMAGE',
      'BRAND',
      'SKU',
      'PRODUCT NAME',
      'MRP',
      'BOXSIZE',
      'QUANTITY',
      'ACTIONS',
      'FLIPKART',
      'SNAPDEAL',
      'AMAZON.IN',
    ];

    // final paginatedData = provider.getPaginatedData();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left,
                            color: AppColors.primaryGreen),
                        onPressed: () {
                          _scrollController.animateTo(
                            _scrollController.position.pixels - 200,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryGreen),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              suffixIcon: IconButton(
                                  icon: const Icon(Icons.search,
                                      color: AppColors.primaryGreen),
                                  onPressed: () {
                                    final searchTerm =
                                        _searchController.text.trim();
                                    if (searchTerm.isNotEmpty) {
                                      provider.filterInventory(
                                          searchTerm); // Fetch filtered data
                                    } else {
                                      provider.fetchInventory();
                                    }
                                  }),
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
<<<<<<< HEAD
                                provider.fetchInventory(); // Load all inventory
                              } else {
                                provider.filterInventory(value); // Fetch filtered data
=======
                                provider.fetchInventory();
                              } else {
                                provider.filterInventory(value);
>>>>>>> 748a9e1 (order page)
                              }
                            },
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.arrow_right,
                            color: AppColors.primaryGreen),
                        onPressed: () {
                          _scrollController.animateTo(
                            _scrollController.position.pixels + 200,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          comboProvider.toggleFormVisibility();
                        },
                        child: const Text('Create Inventory'),
                      ),
                      const SizedBox(width: 10),
                      Consumer<ComboProvider>(
                          builder: (context, provider, child) {
                        return provider.isFormVisible
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () {
                                  provider.toggleFormVisibility(); // Hide form
                                },
                                child: const Text('Cancel'),
                              )
                            : Container();
                      }),
                    ],
                  ),

                  if (comboProvider.isFormVisible) ...[
                    const SizedBox(height: 16),
                    const Text("Manage Inventory",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    const Text("Product",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    DropdownSearch<String>(
                      items: comboProvider.products
                          .map((product) => product.displayName ?? 'Unknown')
                          .toList(),
                      onChanged: (String? newValue) {
                        final selectedProduct = comboProvider.products
                            .firstWhere(
                                (product) => product.displayName == newValue);
                        setState(() {
                          selectedProductId = selectedProduct.id;
                          selectedProductName = selectedProduct.displayName;
                        });
                      },
                      selectedItem: selectedProductName,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Search and Select Product',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: const PopupProps.dialog(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Search Product',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SubInventory List
                    ...List.generate(subInventories.length, (index) {
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
                                'SubInventory ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 16),

                              // Warehouse Dropdown
                              DropdownButtonFormField<String>(
                                hint: const Text('Select Warehouse'),
                                isExpanded: true,
                                value: subInventories[index]['warehouseId'],
                                items: dropdownItemsForWarehouses,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    subInventories[index]['warehouseId'] =
                                        newValue;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Warehouse',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Quantity Input
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    subInventories[index]['quantity'] =
                                        int.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    removeSubInventory(index);
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text("Remove",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: addSubInventory,
                      icon: const Icon(Icons.add),
                      label: const Text("Add SubInventory"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Save button
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedProductId == null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Please select a product"),
                              ));
                            } else {
                              await saveInventoryToApi(context);
                            }
                          },
                          child: const Text('Save Inventory'),
                        ),
                        const SizedBox(width: 16),

                        // Cancel button
                        ElevatedButton(
                          onPressed: cancelForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Table and pagination
                  if (!comboProvider.isFormVisible) ...[
                    SingleChildScrollView(
                      child: provider.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 100, // Set appropriate width
                                height: 500, // Set appropriate height
                                child: InventoryLoadingAnimation(),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  InventoryDataTable(
                                    columnNames: columnNames,
                                    rowsData: paginatedData,
                                    scrollController: _scrollController,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    CustomPaginationFooter(
                      currentPage: provider.currentPage,
<<<<<<< HEAD
                      totalPages: provider.totalPages ,
=======
                      totalPages: provider.totalPages,
>>>>>>> 748a9e1 (order page)
                      buttonSize:
                          MediaQuery.of(context).size.width > 600 ? 32 : 24,
                      pageController: _pageController,
                      onFirstPage: () => _goToPage(1),
                      onLastPage: () => _goToPage(provider.totalPages),
                      onNextPage: () {
                        if (provider.currentPage - 1 < provider.totalPages) {
                          _goToPage(provider.currentPage + 1);
                        }
                      },
                      onPreviousPage: () {
                        if (provider.currentPage > 1) {
                          _goToPage(provider.currentPage - 1);
                        }
                      },
                      onGoToPage: _goToPage,
                      onJumpToPage: _jumpToPage,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
