import 'dart:convert'; // For JSON encoding/decoding
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/create_outerbox.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:inventory_management/provider/outerbox_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Api/inventory_api.dart';
import 'Custom-Files/custom_pagination.dart';
import 'Custom-Files/data_table.dart';
import 'Custom-Files/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageOuterbox extends StatefulWidget {
  const ManageOuterbox({
    super.key,
  });

  @override
  _ManageOuterboxState createState() => _ManageOuterboxState();
}

class _ManageOuterboxState extends State<ManageOuterbox> {
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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OuterboxProvider>(context, listen: false).fetchBoxsizes(); // Start at page 1
      Provider.of<ComboProvider>(context, listen: false).fetchProducts();

      getDropValueForProduct();
      getDropValueForWarehouse(); // Fetch warehouse dropdown values
    });

    searchController.addListener(() {
      log("Search text: ${searchController.text}");
      context.read<ComboProvider>().addMoreProducts(searchController.text);
    });

    _getInventoryItems();
  }

  void _getInventoryItems() async {
    downloadUrl = await context.read<InventoryProvider>().getInventoryItems();
  }

  void getDropValueForProduct() async {
    await Provider.of<ComboProvider>(context, listen: false).fetchProducts();
    setState(() {});
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
      subInventories.add({
        'warehouseId': null,
        'quantity': null
      });
    });
  }

  void addSubInventory() {
    setState(() {
      subInventories.add({
        'warehouseId': null,
        'quantity': null
      });
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
    final provider = Provider.of<OuterboxProvider>(context, listen: false);
    if (page >= 1 && page <= provider.totalPages) {
      provider.goToPage(page);
    }
  }

  void _jumpToPage() {
    final provider = Provider.of<OuterboxProvider>(context, listen: false);
    int page = int.tryParse(_pageController.text) ?? 1;
    if (page >= 1 && page <= provider.totalPages) {
      _goToPage(page - 1); // Go to the user-input page
    }
  }

  bool withQtyCsv = false;
  bool withoutQtyCsv = false;

  Future<void> downloadWithQtyCsv() async {
    setState(() {
      withQtyCsv = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

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
        Uri.parse('$baseUrl/boxsize/download?quantity=true'),
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
        withQtyCsv = false;
      });
    }
  }

  Future<void> downloadWithoutCsv() async {
    setState(() {
      withoutQtyCsv = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

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
        Uri.parse('$baseUrl/boxsize/download?quantity=false'),
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
        withoutQtyCsv = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OuterboxProvider>(context);
    final paginatedData = provider.boxsizes;

    // log('rows: $paginatedData');

    List<String> columnNames = [
      'SKU',
      'NAME',
      'DIMENSION',
      'TYPE',
      'QUANTITY',
      'WEIGHT',
    ];

    // final paginatedData = provider.getPaginatedData();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          if (!provider.isFormVisible)
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
                      DropdownMenuItem(value: 'outerPackage_name', child: Text('Name')),
                      DropdownMenuItem(value: 'occupied_weight', child: Text('Weight')),
                      DropdownMenuItem(value: 'outerPackage_sku', child: Text('SKU')),
                      DropdownMenuItem(value: 'outerPackage_type', child: Text('Type')),
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
                const SizedBox(width: 8),
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
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: AppColors.primaryBlue),
                            onPressed: () {
                              final searchTerm = _searchController.text.trim();
                              if (searchTerm.isNotEmpty) {
                                provider.filterBoxsize(searchTerm); // Fetch filtered data
                              } else {
                                provider.fetchBoxsizes();
                              }
                            }),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          provider.fetchBoxsizes(); // Load all inventory
                        }
                      },
                      onSubmitted: (value) {
                        Logger().e('Submitted: $value');
                        if (value.isEmpty) {
                          provider.fetchBoxsizes(); // Load all inventory
                        } else {
                          provider.filterBoxsize(value); // Fetch filtered data
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
                  message: 'Download Filled Quantity CSV',
                  child: ElevatedButton(
                    onPressed: downloadWithQtyCsv,
                    child: withQtyCsv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Filled Qty. CSV'),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Download Empty Quantity CSV',
                  child: ElevatedButton(
                    onPressed: downloadWithoutCsv,
                    child: withoutQtyCsv
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Empty Qty. CSV'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    provider.toggleFormVisibility();
                  },
                  child: const Text('Create Outerbox'),
                ),
              ],
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.isFormVisible) ...[
                      const SizedBox(height: 16),
                      provider.isFormVisible
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                provider.toggleFormVisibility(); // Hide form
                              },
                              child: const Text('Cancel'),
                            )
                          : Container(),
                      const Text("Create Outerbox", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const OuterPackageForm(),
                    ],

                    const SizedBox(height: 30),
                    // Table and pagination
                    if (!provider.isFormVisible) ...[
                      SingleChildScrollView(
                        child: provider.isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 100, // Set appropriate width
                                  height: 500, // Set appropriate height
                                  child: LoadingAnimation(
                                    icon: Icons.outbox,
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
                                : OuterboxDataTable(
                                    columnNames: columnNames,
                                    rowsData: paginatedData,
                                    scrollController: _scrollController,
                                  ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!provider.isFormVisible)
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
