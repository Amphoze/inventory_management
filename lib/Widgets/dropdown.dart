import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaginatedSearchDropdown extends StatefulWidget {
  final String hintText;
  final double dropdownWidth;
  final double dropdownMaxHeight;
  final bool isBoxSize;
  final bool isBrand;
  final bool isLabel;
  final Future<Map<String, dynamic>> Function(String searchKey, int page)
      fetchItems;
  final ValueChanged<String> onItemSelected;
  final bool returnId;
  final bool isParentSku;

  const PaginatedSearchDropdown({
    super.key,
    required this.hintText,
    required this.fetchItems,
    required this.onItemSelected,
    this.dropdownWidth = 250,
    this.dropdownMaxHeight = 250,
    this.isBoxSize = false,
    this.isLabel = false,
    this.isBrand = false,
    this.returnId = true,
    this.isParentSku = false,
  });

  @override
  _PaginatedSearchDropdownState createState() =>
      _PaginatedSearchDropdownState();
}

class _PaginatedSearchDropdownState extends State<PaginatedSearchDropdown> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> items = [];
  bool isLoading = false;
  bool isDropdownOpen = false;
  int currentPage = 1;
  String? selectedItemName;

  @override
  void initState() {
    super.initState();
    _fetchItems('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: searchController,
          onTap: () {
            setState(() {
              isDropdownOpen = !isDropdownOpen;
            });
          },
          onSubmitted: (query) => _onSearchChanged(query),
          onChanged: (query) {
            setState(() {
              isDropdownOpen = true;
              if (query == '') {
                _fetchItems('');
              }
            });
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            suffixIcon: Icon(
              isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ),
        ),
        if (isDropdownOpen) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: BoxConstraints(
              maxHeight: widget.dropdownMaxHeight,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _fetchItems(searchController.text);
                }
                return true;
              },
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: isLoading ? items.length + 1 : items.length,
                itemBuilder: (context, index) {
                  if (index == items.length && isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final item = items[index];
                  return ListTile(
                    title: Text(
                      widget.isParentSku
                          ? "${item['parentsku']}"
                          : widget.isLabel
                              ? "${item['labelSku']} : ${item['name']}"
                              : widget.isBoxSize
                                  ? item['outerPackage_name']
                                  : item['name'],
                    ),
                    onTap: () => _handleItemSelection(item),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _onSearchChanged(String query) {
    currentPage = 1;
    items.clear();
    _fetchItems(query);
  }

  Future<void> _fetchItems(String query) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final response = await widget.fetchItems(query, currentPage);

    if (response['success']) {
      setState(() {
        items.addAll(response['data']);
        currentPage++;
      });
    } else {
      print('Error fetching items: ${response['message']}');
    }

    setState(() {
      isLoading = false;
    });
  }

  void resetSelection() {
    setState(() {
      selectedItemName = null;
      searchController.clear();
    });
  }

  void _handleItemSelection(dynamic item) {
    setState(() {
      selectedItemName = widget.isParentSku
          ? item['parentsku']?.toString()
          : widget.isLabel
              ? item['labelSku']?.toString()
              : widget.isBoxSize
                  ? item['outerPackage_sku']?.toString()
                  : item['name']?.toString();
      searchController.text = selectedItemName ?? '';
      isDropdownOpen = false;
    });

    log("selectedItemName: $selectedItemName");

    if (selectedItemName != null) {
      if (widget.isBrand || widget.isParentSku) {
        if (widget.isParentSku) {
          return widget.onItemSelected(item['parentsku']?.toString() ?? '');
        }
        return widget.onItemSelected(item['_id']?.toString() ?? '');
      }
      return widget.onItemSelected(selectedItemName!);
    } else {
      log("Warning: Selected value is null");
      widget.onItemSelected('');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

Future<Map<String, dynamic>> fetchCategoryFromApi(
    String searchKey, int page) async {
  final url =
      Uri.parse('${await ApiUrls.getBaseUrl()}/category?name=$searchKey');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final categories = data['categories']; // Fetch categories

      log("categories: $categories");
      return {
        'success': true,
        'data': categories,
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to load categories',
      };
    }
  } catch (e) {
    print('Error: $e');
    return {
      'success': false,
      'message': 'Error fetching categories',
    };
  }
}

// DONE
Future<Map<String, dynamic>> fetchBrandsFromApi(String query, int page) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url = Uri.parse(
      '${await ApiUrls.getBaseUrl()}/brand?name=$query'); // Assume pagination and search parameters

  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final brands =
          data['brands']; // Assume 'brands' is the key containing the data
      log("brands: $brands");
      return {
        'success': true,
        'data': brands,
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to load data',
      };
    }
  } catch (e) {
    print('Error: $e');
    return {
      'success': false,
      'message': 'Error fetching data',
    };
  }
}

Future<Map<String, dynamic>> fetchLabelFromApi(String query, int page) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url = Uri.parse(
      '${await ApiUrls.getBaseUrl()}/label?labelSku=$query'); // Assume pagination and search parameters

  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final labels = data['data']['labels'];

      log("labels: $labels");
      return {
        'success': true,
        'data': labels,
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to load data',
      };
    }
  } catch (e) {
    log('Error: $e');
    return {
      'success': false,
      'message': 'Error fetching data',
    };
  }
}

Future<Map<String, dynamic>> fetchBoxSizeFromApi(String query, int page) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url = Uri.parse(
      '${await ApiUrls.getBaseUrl()}/boxsize?outerPackage_name=$query');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final boxSizes = data['data']['boxsizes'];

      log("boxSizes: $boxSizes");
      return {
        'success': true,
        'data': boxSizes,
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to load box sizes',
      };
    }
  } catch (e) {
    log('Error: $e');
    return {
      'success': false,
      'message': 'Error fetching box sizes',
    };
  }
}

Future<Map<String, dynamic>> fetchParentSkusFromApi(
    String query, int page) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url =
      Uri.parse('${await ApiUrls.getBaseUrl()}/products/fetch-products/$query');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final products = data['products'];
      return {
        'success': true,
        'data': products,
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to load products',
      };
    }
  } catch (e) {
    log('Error: $e');
    return {
      'success': false,
      'message': 'Error fetching products',
    };
  }
}
