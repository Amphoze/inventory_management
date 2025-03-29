import 'dart:convert'; // For JSON encoding/decoding
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Api/inventory_api.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/data_table.dart';
import 'Custom-Files/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController searchController = TextEditingController();
  String? downloadUrl;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory(page: 1); // Start at page 1
      Provider.of<ComboProvider>(context, listen: false).fetchProducts();

      getDropValueForProduct();
      getDropValueForWarehouse();

      searchController.addListener(() {
        log("Search text: ${searchController.text}");
        context.read<ComboProvider>().addMoreProducts(searchController.text);
      });

      _getInventoryItems();
    });
    super.initState();
  }

  void _getInventoryItems() async {
    downloadUrl = await context.read<InventoryProvider>().getInventoryItems();
  }

  void getDropValueForProduct() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchProducts();
  }

  void getDropValueForWarehouse() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchWarehouses();
    List<DropdownMenuItem<String>> newItems = [];
    ComboProvider comboProvider = Provider.of<ComboProvider>(context, listen: false);

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
        Uri.parse('${await Constants.getBaseUrl()}/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Inventory created successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to create inventory"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save inventory"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving inventory: $e"),
          backgroundColor: Colors.red,
        ),
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

  bool isThresholdCsv = false;
  bool isSkuCsv = false;

  Future<void> downloadThresholdCsv() async {
    setState(() {
      isThresholdCsv = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final warehouseId = prefs.getString('warehouseId');

      String baseUrl = await Constants.getBaseUrl();

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Authorization token is missing or invalid'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        throw Exception('Authorization token is missing or invalid.');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/inventory/minimunThreshold?warehouseId=$warehouseId'),
        headers: headers,
      );

      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        log("jsonBody: $jsonBody");

        final downloadUrl = jsonBody['downloadUrl'];

        if (downloadUrl != null) {
          final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
          if (canLaunch) {
            await launchUrl(Uri.parse(downloadUrl));

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('CSV download started successfully'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            throw 'Could not launch $downloadUrl';
          }
        } else {
          throw Exception('No download URL found');
        }
      } else {
        throw Exception('Failed to load template: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      log('error: $error');
      log('Error during report generation: $error');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error downloading CSV: $error',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isThresholdCsv = false;
      });
    }
  }

  Future<void> downloadSkuCsv() async {
    setState(() {
      isSkuCsv = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      // final warehouseId = prefs.getString('warehouseId');

      String baseUrl = await Constants.getBaseUrl();

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Authorization token is missing or invalid'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        throw Exception('Authorization token is missing or invalid.');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/inventory/uploadQty?warehouseId=66fceb5163c6d5c106cfa809'),
        headers: headers,
      );

      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        log("jsonBody: $jsonBody");

        final downloadUrl = jsonBody['downloadUrl'];

        if (downloadUrl != null) {
          final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
          if (canLaunch) {
            await launchUrl(Uri.parse(downloadUrl));

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('CSV download started successfully'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            throw 'Could not launch $downloadUrl';
          }
        } else {
          throw Exception('No download URL found');
        }
      } else {
        throw Exception('Failed to load template: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      log('error: $error');
      log('Error during report generation: $error');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error downloading CSV',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isSkuCsv = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);
    final comboProvider = Provider.of<ComboProvider>(context);
    final paginatedData = provider.inventory;

    // log('rows: $paginatedData');

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
      'SKU QUANTITY',
      'THRESHOLD QUANTITY',
      'THRESHOLD',
      'LABEL SKU',
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          if (!comboProvider.isFormVisible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 120,
                  height: 34,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: provider.selectedSearchBy,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'productSku', child: Text('SKU')),
                      DropdownMenuItem(value: 'displayName', child: Text('Name')),
                    ],
                    onChanged: (value) {
                      Logger().e('$value');
                      setState(() {
                        if (value != null) {
                          provider.setSelectedSearchBy(value);
                        }
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: AppColors.primaryBlue),
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
                          borderSide: const BorderSide(color: AppColors.primaryBlue),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        prefixIcon: IconButton(
                          tooltip: 'Search',
                            icon: const Icon(Icons.search, color: AppColors.primaryBlue),
                            onPressed: () {
                              final value = _searchController.text.trim();
                              Logger().e('$value ${provider.selectedSearchBy}');
                              if (value.trim().isNotEmpty) {
                                provider.filterInventory(value.trim(), provider.selectedSearchBy); // Fetch filtered data
                              } else {
                                provider.fetchInventory();
                              }
                            }),
                        suffixIcon: IconButton(
                          tooltip: 'Clear',
                            icon: const Icon(Icons.close, color: AppColors.cardsred),
                            onPressed: () {
                              final searchTerm = _searchController.text.trim();
                              if (searchTerm.isNotEmpty) {
                                setState(() {
                                  _searchController.clear();
                                });
                                provider.fetchInventory();
                              }
                            }),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          provider.fetchInventory(); // Load all inventory
                        }
                      },
                      onSubmitted: (value) {
                        Logger().e('$value ${provider.selectedSearchBy}');
                        if (value.trim().isNotEmpty) {
                          provider.filterInventory(value.trim(), provider.selectedSearchBy); // Fetch filtered data
                        } else {
                          provider.fetchInventory();
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, color: AppColors.primaryBlue),
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.position.pixels + 200,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Download Product-SKU and Empty Qty.  CSV',
                  child: ElevatedButton(
                    onPressed: downloadSkuCsv,
                    child: isSkuCsv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('SKU CSV'),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Download Minimum Threshold Quantity CSV',
                  child: ElevatedButton(
                    onPressed: downloadThresholdCsv,
                    child: isThresholdCsv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Threshold CSV'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Fetching inventory sheet..."),
                            ],
                          ),
                        );
                      },
                    );

                    // Fetch the download URL
                    downloadUrl = await context.read<InventoryProvider>().getInventoryItems();

                    // Close loading dialog
                    if (context.mounted) {
                      Navigator.pop(context);
                    }

                    // Launch URL if available
                    if (downloadUrl != null) {
                      final Uri url = Uri.parse(downloadUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch download URL'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download URL not available'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Get Inventory Sheet'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    comboProvider.toggleFormVisibility();
                  },
                  child: const Text('Create Inventory'),
                ),
                const SizedBox(width: 10),
                Consumer<ComboProvider>(builder: (context, provider, child) {
                  return provider.isFormVisible
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            provider.toggleFormVisibility(); // Hide form
                          },
                          child: const Text('Cancel'),
                        )
                      : Container();
                }),
              ],
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (comboProvider.isFormVisible) ...[
                          const SizedBox(height: 16),
                          const Text("Manage Inventory", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),

                          const Text("Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),

                          DropdownSearch<String>(
                            items: comboProvider.products
                                .where(
                                    (product) => product.displayName?.toLowerCase().contains(searchController.text.toLowerCase()) ?? false)
                                .map((product) => '${product.sku}: ${product.displayName}' ?? 'Unknown')
                                .toList(),
                            onChanged: (String? newValue) {
                              final selectedProduct = comboProvider.products
                                  .firstWhere((product) => product.displayName == newValue || product.sku == newValue);
                              setState(() {
                                selectedProductId = selectedProduct.id;
                                selectedProductName = selectedProduct.displayName;
                              });
                            },
                            selectedItem: selectedProductName,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Search and Select Product',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            popupProps: PopupProps.dialog(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                controller: searchController,
                                decoration: const InputDecoration(
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                          subInventories[index]['warehouseId'] = newValue;
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
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (value) {
                                        setState(() {
                                          subInventories[index]['quantity'] = int.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          removeSubInventory(index);
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        label: const Text("Remove", style: TextStyle(color: Colors.red)),
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
                              backgroundColor: AppColors.primaryBlue,
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
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text("Please select a product"),
                                    ));
                                  } else {
                                    // Show loading dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false, // Prevent dismissing the dialog
                                      builder: (BuildContext context) {
                                        return const AlertDialog(
                                          content: Row(
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(width: 20),
                                              Text("Saving inventory..."),
                                            ],
                                          ),
                                        );
                                      },
                                    );

                                    await saveInventoryToApi(context);

                                    // Close the loading dialog after saving
                                    Navigator.of(context).pop();
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
                                      child: LoadingAnimation(
                                        icon: Icons.inventory_2,
                                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                                        endColor: AppColors.primaryBlue,
                                        size: 80.0,
                                      ),
                                    ),
                                  )
                                : paginatedData.isEmpty
                                    ? const Center(
                                        child: Text('No data found'),
                                      )
                                    : InventoryDataTable(
                                        columnNames: columnNames,
                                        rowsData: paginatedData,
                                        scrollController: _scrollController,
                                      ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!comboProvider.isFormVisible)
            CustomPaginationFooter(
              currentPage: provider.currentPage,
              totalPages: provider.totalPages,
              buttonSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
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
      ),
    );
  }
}
