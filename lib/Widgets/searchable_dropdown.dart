import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SearchableDropdown extends StatefulWidget {
  final String label;
  final Function(Map<String, String>?)? onChanged;
  final bool isCombo;

  const SearchableDropdown({
    super.key,
    required this.label,
    this.onChanged,
    this.isCombo = false,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  late final TextEditingController searchController;
  late final Logger logger;
  List<Map<String, dynamic>> products = [];
  String? selectedProductId;
  String? selectedProductName;
  int currentPage = 1;
  bool isLoading = false;
  bool isSearching = false;
  bool isDropdownOpen = false;
  bool hasMore = true;
  String? errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    logger = Logger();
    fetchProducts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts({String query = ''}) async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await getAllProducts(page: currentPage, search: query);
      if (response['success']) {
        setState(() {
          products.addAll(List<Map<String, dynamic>>.from(response['data']));
          currentPage++;
          hasMore = response['data'].length >= 10;
        });
      } else {
        setState(() => errorMessage = response['message']);
      }
    } catch (e) {
      setState(() => errorMessage = 'Error loading items: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleItemSelection(Map<String, dynamic> product) {
    logger.d('Item selected: ${product['displayName']}');
    final selectedData = {
      'id': product['id'].toString(),
      'name': product['displayName'].toString(),
      'sku': product['sku'].toString(),
    };

    widget.onChanged?.call(selectedData);

    setState(() {
      searchController.clear();
      selectedProductId = product['id'];
      selectedProductName = product['displayName'];
      isDropdownOpen = false;
      // searchController.text = '${product['sku']}: ${product['displayName']}';
    });
  }

  Future<Map<String, dynamic>> searchProduct(String query) async {
    final isCombo = widget.isCombo;
    final baseUrl = await Constants.getBaseUrl();
    final searchKey = query.contains('-') ? (isCombo ? 'comboSku' : 'sku') : (isCombo ? 'name' : 'displayName');
    final url = Uri.parse('$baseUrl${isCombo ? '/combo' : '/products'}?$searchKey=$query');

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('authToken') ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = isCombo ? data['combos'] : data['products'];

        if (items?.isNotEmpty ?? false) {
          return {
            'success': true,
            'data': (items as List)
                .map((item) => {
                      'id': item['_id'] ?? '',
                      'displayName': isCombo ? item['name'] : item['displayName'] ?? '',
                      'sku': isCombo ? item['comboSku'] : item['sku'] ?? '',
                    })
                .toList(),
          };
        }
      }
      return {
        'success': false,
        'message': 'No ${isCombo ? 'combos' : 'products'} found.',
      };
    } catch (error) {
      return {'success': false, 'message': 'Error: $error'};
    }
  }

  Future<Map<String, dynamic>> getAllProducts({
    required int page,
    int itemsPerPage = 10,
    String search = '',
  }) async {
    final isCombo = widget.isCombo;
    final baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl${isCombo ? '/combo' : '/products'}?page=$page&limit=$itemsPerPage');

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('authToken') ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = isCombo ? data['combos'] : data['products'];

        if (items != null) {
          return {
            'success': true,
            'data': (items as List)
                .map((item) => {
                      'id': item['_id'] ?? '',
                      'displayName': isCombo ? item['name'] : item['displayName'] ?? '',
                      'sku': isCombo ? item['comboSku'] : item['sku'] ?? '',
                    })
                .toList(),
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to load ${isCombo ? "combos" : "products"}',
      };
    } catch (error) {
      logger.e("Error in getAllProducts: $error");
      return {'success': false, 'message': 'Error fetching ${isCombo ? "combos" : "products"}'};
    }
  }

  void _toggleDropdown() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
      if (!isDropdownOpen) {
        _resetDropdown();
      }
    });
  }

  void _resetDropdown() {
    searchController.clear();
    products.clear();
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    fetchProducts();
  }

  void _debouncedSearch(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (value.isEmpty) {
        _resetDropdown();
      } else {
        _performSearch(value);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => isSearching = true);
    final response = await searchProduct(query);

    setState(() {
      if (response['success']) {
        products = List<Map<String, dynamic>>.from(response['data']);
        _showSnackBar(
          'Found ${widget.isCombo ? 'combo' : 'product'} with query: $query.',
          AppColors.green,
        );
      } else {
        _showSnackBar(
          'Search Error: ${response['message']} for query: $query.',
          AppColors.cardsred,
        );
      }
      isSearching = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: searchController,
          onTap: _toggleDropdown,
          onSubmitted: _performSearch,
          onChanged: (value) {
            setState(() => isDropdownOpen = true);
            _debouncedSearch(value.trim());
          },
          decoration: InputDecoration(
            hintText: widget.isCombo ? 'Search Combo by Name or SKU' : 'Search Product by Name or SKU',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            suffixIcon: Icon(
              isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ),
        ),
        if (isDropdownOpen)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  fetchProducts(query: searchController.text.trim());
                }
                return true;
              },
              child: ListView.builder(
                itemCount: products.length + (hasMore || errorMessage != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == products.length) {
                    if (errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final product = products[index];
                  return ListTile(
                    title: Text('${product['sku']}: ${product['displayName']}'),
                    onTap: () => _handleItemSelection(product),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:inventory_management/Custom-Files/colors.dart';
// import 'package:inventory_management/constants/constants.dart';
// import 'package:logger/logger.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class SearchableDropdown extends StatefulWidget {
//   final String label;
//   final Function(Map<String, String>?)? onChanged;
//   final bool isCombo;
//
//   const SearchableDropdown({
//     super.key,
//     required this.label,
//     this.onChanged,
//     this.isCombo = false,
//   });
//
//   @override
//   _SearchableDropdownState createState() => _SearchableDropdownState();
// }
//
// class _SearchableDropdownState extends State<SearchableDropdown> {
//   List<dynamic> products = [];
//   String? selectedProductId;
//   String? selectedProductName;
//   int currentPage = 1;
//   bool isLoading = false;
//   bool isSearching = false;
//   TextEditingController searchController = TextEditingController();
//   bool isDropdownOpen = false;
//   bool hasMore = true;
//   String? errorMessage;
//
//   @override
//   void initState() {
//     fetchProducts();
//     super.initState();
//   }
//
//   Future<void> fetchProducts({String query = ''}) async {
//     if (isLoading || !hasMore) return;
//
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       final response = await getAllProducts(page: currentPage, search: query);
//       if (response['success']) {
//         final newItems = response['data'];
//         setState(() {
//           products.addAll(newItems);
//           currentPage++;
//           hasMore = newItems.length >= 10;
//         });
//       } else {
//         setState(() {
//           errorMessage = response['message'];
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error loading items: $e';
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _handleItemSelection(Map<String, dynamic> product) {
//     Logger().d('Item selected: ${product['displayName']}');
//     if (widget.onChanged != null) {
//       final selectedData = {
//         'id': product['id'].toString(),
//         'name': product['displayName'].toString(),
//         'sku': product['sku'].toString(),
//       };
//       widget.onChanged!(selectedData);
//     }
//
//     setState(() {
//       selectedProductId = product['id'];
//       selectedProductName = product['displayName'];
//       isDropdownOpen = false;
//       searchController.text = '${product['sku']}: ${product['displayName']}';
//     });
//   }
//
//   // Search for a specific product by SKU
//   Future<Map<String, dynamic>> searchProduct(String query) async {
//     Uri url;
//     final isCombo = widget.isCombo;
//
//     Logger().e('isCombo: $isCombo');
//
//     if (isCombo) {
//       url = Uri.parse(
//           '${await Constants.getBaseUrl()}/combo?${query.contains('-') ? 'comboSku' : 'name'}=$query');
//     } else {
//       url = Uri.parse(
//           '${await Constants.getBaseUrl()}/products?${query.contains('-') ? 'sku' : 'displayName'}=$query');
//     }
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('authToken') ?? '';
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final items = isCombo ? data['combos'] : data['products'];
//
//         if (items != null && items.isNotEmpty) {
//           final itemList = items.map((item) {
//             return {
//               'id': item['_id'] ?? '',
//               'displayName': isCombo ? item['name'] : item['displayName'] ?? '',
//               'sku': isCombo ? item['comboSku'] : item['sku'] ?? '',
//             };
//           }).toList();
//
//           return {
//             'success': true,
//             'data': itemList,
//           };
//         }
//       }
//       return {
//         'success': false,
//         'message': 'No ${isCombo ? 'combos' : 'products'} found.',
//       };
//     } catch (error) {
//       return {'success': false, 'message': 'Error: $error'};
//     }
//   }
//
//   Future<Map<String, dynamic>> getAllProducts({
//     int page = 1,
//     int itemsPerPage = 10,
//     String search = '',
//   }) async {
//     final isCombo = widget.isCombo;
//     String baseUrl = await Constants.getBaseUrl();
//     final endpoint = isCombo ? '/combo' : '/products';
//     final url = Uri.parse('$baseUrl$endpoint?page=$page&limit=$itemsPerPage');
//
//     // Logger().e("isCombo: $isCombo");
//     // Logger().e("Fetching from URL: $url");
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('authToken') ?? '';
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       // Logger().e("Response status: ${response.statusCode}");
//       // Logger().e("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final items = isCombo ? data['combos'] : data['products'];
//
//         if (items != null) {
//           final itemList = items.map((item) {
//             return {
//               'id': item['_id'] ?? '',
//               'displayName': isCombo ? item['name'] : item['displayName'] ?? '',
//               'sku': isCombo ? item['comboSku'] : item['sku'] ?? '',
//             };
//           }).toList();
//
//           return {'success': true, 'data': itemList};
//         }
//       }
//       return {
//         'success': false,
//         'message': 'Failed to load ${isCombo ? "combos" : "products"}',
//       };
//     } catch (error) {
//       Logger().e("Error in getAllProducts: $error");
//       return {
//         'success': false,
//         'message': 'Error fetching ${isCombo ? "combos" : "products"}'
//       };
//     }
//   }
//
//   void _toggleDropdown() {
//     setState(() {
//       isDropdownOpen = !isDropdownOpen;
//       if (!isDropdownOpen) {
//         searchController.clear();
//         products.clear();
//         currentPage = 1;
//         hasMore = true;
//         errorMessage = null;
//         fetchProducts();
//       }
//     });
//   }
//
//   void _performSearch() async {
//     String query = searchController.text.trim();
//     if (query.isNotEmpty) {
//       setState(() {
//         isSearching = true;
//       });
//
//       final response = await searchProduct(query);
//       if (response['success']) {
//         setState(() {
//           products = response['data'];
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 'Found ${widget.isCombo ? 'combo' : 'product'} with query: $query.'),
//             backgroundColor: AppColors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content:
//                 Text('Search Error: ${response['message']} for query: $query.'),
//             backgroundColor: AppColors.cardsred,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//       setState(() {
//         isSearching = false;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               'Please enter a ${widget.isCombo ? 'combo name' : 'SKU'} to search.'),
//           backgroundColor: AppColors.cardsred,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         TextField(
//           controller: searchController,
//           onTap: _toggleDropdown,
//           onSubmitted: (_) => _performSearch(),
//           onChanged: (value) {
//             setState(() {
//               isDropdownOpen = true;
//               if (value == '') {
//                 fetchProducts();
//               }
//             });
//           },
//           decoration: InputDecoration(
//             hintText: widget.isCombo
//                 ? 'Search Combo by Name or SKU'
//                 : 'Search Product by Name or SKU',
//             border: const OutlineInputBorder(),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
//             suffixIcon: Icon(
//               isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
//               color: Colors.grey,
//             ),
//           ),
//         ),
//         if (isDropdownOpen) ...[
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade300),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             constraints: const BoxConstraints(maxHeight: 250),
//             child: NotificationListener<ScrollNotification>(
//               onNotification: (scrollInfo) {
//                 if (!isLoading &&
//                     scrollInfo.metrics.pixels ==
//                         scrollInfo.metrics.maxScrollExtent) {
//                   fetchProducts(query: searchController.text);
//                 }
//                 return true;
//               },
//               child: ListView.builder(
//                 itemCount: products.length + (hasMore ? 1 : 0),
//                 itemBuilder: (context, index) {
//                   if (index == products.length) {
//                     if (errorMessage != null) {
//                       return Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(
//                           errorMessage!,
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                       );
//                     }
//
//                     if (isLoading) {
//                       return const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(8.0),
//                           child: CircularProgressIndicator(),
//                         ),
//                       );
//                     }
//
//                     return const SizedBox();
//                   }
//
//                   final product = products[index];
//                   return ListTile(
//                     title: Text('${product['sku']}: ${product['displayName']}'),
//                     onTap: () => _handleItemSelection(product),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }
