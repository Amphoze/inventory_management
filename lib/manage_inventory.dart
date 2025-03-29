import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/product_search_field.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/create_inventory_screen.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Api/auth_provider.dart';
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
  List<Map<String, dynamic>> subInventories = [
    {
      'warehouseId': null,
      'thresholdQuantity': null,
      "bin": [
        {"binName": null, "binQty": null, "binPriority": 1}
      ]
    }
  ];
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
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory(page: 1);
      Provider.of<ComboProvider>(context, listen: false).fetchProducts();

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

  void addSubInventory() {
    setState(() {
      warehouse.add(null);
      subInventories.add({
        'warehouseId': null,
        'thresholdQuantity': null,
        "bin": [
          {"binName": null, "binQty": null, "binPriority": 1}
        ]
      });
    });
  }

  void removeSubInventory(int index) {
    setState(() {
      warehouse.removeAt(index);
      subInventories.removeAt(index);
    });
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
          "thresholdQuantity": subInventory['thresholdQuantity'],
          "bin": subInventory['bin'],
        };
      }).toList(),
    };

    final payload = jsonEncode(requestData);

    log('Payload is: $payload');

    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          Utils.showSnackBar(context, 'Inventory created successfully!', color: Colors.green);
          return;
        }
      }

      final message = responseData['error'] ?? 'Failed to create inventory..!';
      final details = responseData['details'] ?? 'Status Code: ${response.statusCode}';

      Utils.showSnackBar(context, message, details: details, color: Colors.red);
    } catch (e) {
      Utils.showSnackBar(context, 'Error occured while creating inventory..!', details: e.toString(), color: Colors.red);
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
      _goToPage(page - 1);
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
                                provider.filterInventory(value.trim(), provider.selectedSearchBy);
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
                          provider.fetchInventory();
                        }
                      },
                      onSubmitted: (value) {
                        Logger().e('$value ${provider.selectedSearchBy}');
                        if (value.trim().isNotEmpty) {
                          provider.filterInventory(value.trim(), provider.selectedSearchBy);
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

                    downloadUrl = await context.read<InventoryProvider>().getInventoryItems();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }

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
                    // comboProvider.toggleFormVisibility();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInventoryScreen()));
                  },
                  child: const Text('Create Inventory'),
                ),
                const SizedBox(width: 10),
                Consumer<ComboProvider>(builder: (context, provider, child) {
                  return provider.isFormVisible
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            provider.toggleFormVisibility();
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
                          const Text("Create Inventory", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text("Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          ProductSearchableTextField(
                            isRequired: true,
                            onSelected: (product) {
                              if (product != null) {
                                setState(() {
                                  selectedProductId = product.id;
                                  selectedProductName = product.displayName;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Consumer<LocationProvider>(
                                            builder: (context, pro, child) {
                                              return _buildDropdown(
                                                value: warehouse[index],
                                                label: 'Warehouse',
                                                items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                                                onChanged: (value) async {
                                                  if (value != null) {
                                                    final tempWarehouse = pro.warehouses.firstWhere((e) => e['name'] == value);
                                                    final id = tempWarehouse['_id'].toString();
                                                    setState(() {
                                                      warehouse[index] = value;
                                                      subInventories[index]['warehouseId'] = id;
                                                    });

                                                    log('ID: $id');
                                                    log('Warehouse ID: ${subInventories[index]['warehouseId']}');

                                                    await _fetchBins(id);
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
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            onChanged: (value) {
                                              setState(() {
                                                subInventories[index]['thresholdQuantity'] = int.tryParse(value) ?? 0;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    isLoadingBins
                                        ? const CircularProgressIndicator()
                                        : _buildDropdown(
                                            value: subInventories[index]['bin'][0]['binName'],
                                            label: 'Bin Name',
                                            items: bins.isEmpty ? ['No bins available'] : bins,
                                            onChanged: bins.isEmpty
                                                ? null
                                                : (value) {
                                                    log("1. Sub Inventory at $index is $subInventories $value");
                                                    log("value type 1: ${value.runtimeType}");
                                                    try {
                                                      setState(() {
                                                        subInventories[index]['bin'][0]['binName'] = value;
                                                      });
                                                    } catch (e, s) {
                                                      log("Error while selecting bin name: $e $s");
                                                    }
                                                    log("value type 2: ${subInventories[index]['bin'][0]['binName'].runtimeType}");
                                                    log("2. Sub Inventory at $index is ${subInventories[index]}");
                                                  },
                                            validator: (value) => value == null || value.isEmpty ? 'Please select a bin' : null,
                                          ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      onChanged: (value) {
                                        setState(() {
                                          subInventories[index]['bin'][0]['binQty'] = value.trim();
                                        });
                                      },
                                      decoration: const InputDecoration(labelText: 'Bin Quantity'),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter Bin Quantity';

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
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
                              ElevatedButton(
                                onPressed: () async {
                                  if (selectedProductId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text("Please select a product"),
                                    ));
                                  } else {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
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

                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Save Inventory'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: comboProvider.toggleFormVisibility,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 30),
                        if (!comboProvider.isFormVisible) ...[
                          SingleChildScrollView(
                            child: provider.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 100,
                                      height: 500,
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

  List<String> bins = [];
  List<String?> warehouse = [null];
  bool isLoadingBins = false;

  Future<void> _fetchBins(String warehouseId) async {
    setState(() => isLoadingBins = true);
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/bin/$warehouseId');

    try {
      final token = await Provider.of<AuthProvider>(context, listen: false).getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final res = json.decode(response.body);
      if (response.statusCode == 200 && res.containsKey('bins')) {
        setState(() {
          bins = List<String>.from(res['bins'].map((bin) => bin['binName'].toString()));

          log('Fetched bins: $bins');
        });
      } else {
        print('No bins key in response');
        setState(() => bins = []);
      }
    } catch (error) {
      print('Error fetching bins: $error');

      setState(() => bins = []);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch bins: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoadingBins = false);
    }
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
