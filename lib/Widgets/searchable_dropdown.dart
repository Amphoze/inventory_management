import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Custom-Files/colors.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchableDropdown extends StatefulWidget {
  final String label;
  final Function(Map<String, String>?)? onChanged;

  const SearchableDropdown({
    Key? key,
    required this.label,
    this.onChanged,
  }) : super(key: key);

  @override
  _SearchableDropdownState createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  List<dynamic> products = [];
  String? selectedProductId;
  String? selectedProductName;
  int currentPage = 1;
  bool isLoading = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts({String query = ''}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final response = await getAllProducts(page: currentPage, search: query);
    if (response['success']) {
      setState(() {
        products.addAll(response['data']);
        currentPage++;
      });
    } else {
      print(response['message']);
    }

    setState(() {
      isLoading = false;
    });
  }

  // Search for a specific product by SKU
  Future<Map<String, dynamic>> searchProductBySku(String sku) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/products?sku=$sku');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final products = json.decode(response.body)['products'];

        if (products.isNotEmpty) {
          final productList = products.map((product) {
            return {
              'id': product['_id'] ?? '',
              'displayName': product['displayName'] ?? '',
              'sku': product['sku'] ?? '',
            };
          }).toList();

          return {
            'success': true,
            'data': productList,
          };
        } else {
          return {
            'success': false,
            'message': 'No products found for the provided SKU.',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch product. Status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error: $error'};
    }
  }

  Future<Map<String, dynamic>> getAllProducts({
    int page = 1,
    int itemsPerPage = 10,
    String search = '',
  }) async {
    final url = Uri.parse(
        'https://inventory-management-backend-s37u.onrender.com/products?page=$page&limit=$itemsPerPage&search=$search');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['products'];
        final products = data.map((product) {
          return {
            'id': product['_id'] ?? '',
            'displayName': product['displayName'] ?? '',
            'sku': product['sku'] ?? ''
          };
        }).toList();

        return {'success': true, 'data': products};
      } else {
        return {
          'success': false,
          'message':
              'Failed to load products. Status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error fetching products'};
    }
  }

  void _toggleDropdown() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
      if (!isDropdownOpen) {
        searchController.clear();
        products.clear();
        currentPage = 1;
        fetchProducts();
      }
    });
  }

  // void _addNewProduct(String name) {
  //   setState(() {
  //     products.insert(0, {'displayName': name, 'id': 'new'});
  //     selectedProductId = 'new';
  //     selectedProductName = name;
  //     isDropdownOpen = false;
  //   });

  //   if (widget.onChanged != null) {
  //     widget
  //         .onChanged!({'id': selectedProductId!, 'name': selectedProductName!});
  //   }

  //   searchController.clear();
  // }

  void _performSearch() async {
    String sku = searchController.text.trim();
    if (sku.isNotEmpty) {
      setState(() {
        isSearching = true;
      });

      final response = await searchProductBySku(sku);
      if (response['success']) {
        setState(() {
          products = response['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // content: Text('Found ${response['data'].length} product(s) for SKU: $sku.'),
            content: Text('Found product with SKU: $sku.'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Search Error: ${response['message']} for SKU: $sku.'),
            backgroundColor: AppColors.cardsred,
            duration: const Duration(seconds: 2),
          ),
        );
        print('Search Error: ${response['message']}');
      }
      setState(() {
        isSearching = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a SKU to search.'),
          backgroundColor: AppColors.cardsred,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ],
            ),
            if (isDropdownOpen) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by SKU',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  isSearching
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.green),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _performSearch,
                        ),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!isLoading &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                      fetchProducts();
                    }
                    return true;
                  },
                  child: ListView.builder(
                    itemCount:
                        isLoading ? products.length + 1 : products.length,
                    itemBuilder: (context, index) {
                      if (index == products.length && isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final product = products[index];
                      return ListTile(
                        title: Text(
                            '${product['sku']}: ${product['displayName']}'),
                        onTap: () {
                          setState(() {
                            selectedProductId = product['id'];
                            selectedProductName = product['displayName'];
                            isDropdownOpen = false;
                          });
                          if (widget.onChanged != null) {
                            widget.onChanged!({
                              'id': selectedProductId!,
                              'name': selectedProductName!,
                              'sku': product['sku']!,
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
