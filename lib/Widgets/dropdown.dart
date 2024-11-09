import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaginatedSearchDropdown extends StatefulWidget {
  final String hintText;
  final double dropdownWidth;
  final double dropdownMaxHeight;
  final Future<Map<String, dynamic>> Function(String searchKey, int page)
      fetchItems;
  final ValueChanged<String> onItemSelected;

  PaginatedSearchDropdown({
    required this.hintText,
    required this.fetchItems,
    required this.onItemSelected,
    this.dropdownWidth = 250,
    this.dropdownMaxHeight = 250,
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
  OverlayEntry? _overlayEntry;
  GlobalKey _key =
      GlobalKey(); // Added a GlobalKey to track widget position and size

  @override
  void initState() {
    super.initState();
    _fetchItems('');
  }

  void _toggleDropdown() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
      if (isDropdownOpen) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    final RenderBox renderBox =
        _key.currentContext?.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + renderBox.size.height,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: widget.dropdownWidth,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  onChanged: (query) => _onSearchChanged(query),
                ),
                ConstrainedBox(
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
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final item = items[index];
                        return ListTile(
                          title: Text(item['name']),
                          onTap: () {
                            widget.onItemSelected(item['id']);
                            _removeOverlay();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    setState(() {
      isDropdownOpen = false;
    });
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
        currentPage++; // Increment page number
      });
    } else {
      print('Error fetching items: ${response['message']}');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        key: _key,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.hintText,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Icon(
              isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> fetchCategoryFromApi(
    String searchKey, int page) async {
  final url = Uri.parse(
      'https://inventory-management-backend-s37u.onrender.com/category?page=$page&search=$searchKey');
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

// Fetch items from the provided API URL
Future<Map<String, dynamic>> fetchBrandsFromApi(
    String searchKey, int page) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url = Uri.parse(
      'https://inventory-management-backend-s37u.onrender.com/brand?page=$page&search=$searchKey'); // Assume pagination and search parameters

  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(response.body);
      final brands =
          data['brands']; // Assume 'brands' is the key containing the data
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
