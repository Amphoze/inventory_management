import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import 'colors.dart';

// Define a Vendor class to better handle the data
class Vendor {
  final String name;
  final String address;
  final int phone;
  final String email;
  final String shopName;

  Vendor({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.shopName,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      name: json['Name'] ?? '',
      address: json['Address'] ?? '',
      phone: json['Phone'] ?? 0,
      email: json['Email'] ?? '',
      shopName: json['shopName'] ?? '',
    );
  }
}

class VendorSearchableTextField extends StatefulWidget {
  final bool isRequired;
  final void Function(Vendor? vendor)? onSelected; // Callback for selected vendor

  const VendorSearchableTextField({
    super.key,
    required this.isRequired,
    this.onSelected,
  });

  @override
  _VendorSearchableTextFieldState createState() => _VendorSearchableTextFieldState();
}

class _VendorSearchableTextFieldState extends State<VendorSearchableTextField> {
  final TextEditingController _typeAheadController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  List<Vendor> _suggestions = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Future<List<Vendor>> _fetchSuggestions(String query) async {
    if (_isFetching && query == _lastQuery) return _suggestions;

    setState(() {
      if (query != _lastQuery) {
        _currentPage = 1;
        _hasMore = true;
        _suggestions.clear();
      }
      _isFetching = true;
    });

    try {
      final response = await searchByVendor(query, page: _currentPage);
      if (response['success'] == true) {
        final List<Vendor> newVendors = (response['vendors'] as List).map((v) => Vendor.fromJson(v)).toList();

        setState(() {
          if (_currentPage == 1) {
            _suggestions = newVendors;
          } else {
            _suggestions.addAll(newVendors);
          }
          _hasMore = newVendors.isNotEmpty;
          _isFetching = false;
          _lastQuery = query;
        });

        if (_hasMore && query == _lastQuery) _currentPage++;
        return _suggestions;
      }
      return _suggestions;
    } catch (e) {
      debugPrint('Error fetching vendors: $e');
      return _suggestions;
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && _hasMore && !_isFetching) {
      _fetchSuggestions(_typeAheadController.text);
    }
  }

  String? _validateInput(String? value) {
    if (widget.isRequired && (value == null || value.isEmpty)) {
      return 'This field is required';
    }
    return null;
  }

  @override
  void dispose() {
    _typeAheadController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: _validateInput,
      initialValue: _typeAheadController.text,
      builder: (FormFieldState<String> formFieldState) {
        return TypeAheadField<Vendor>(
          controller: _typeAheadController,
          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            decoration: InputDecoration(
              labelText: 'Vendor${widget.isRequired ? ' *' : ''}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: const Icon(Icons.store),
              errorText: formFieldState.errorText,
            ),
            onChanged: (value) {
              formFieldState.didChange(value);
            },
          ),
          suggestionsCallback: (query) async {
            return await _fetchSuggestions(query);
          },
          itemBuilder: (context, vendor) {
            return ListTile(
              title: Text(vendor.name),
              subtitle: Text(vendor.shopName.isNotEmpty ? vendor.shopName : vendor.email),
            );
          },
          onSelected: (vendor) {
            _typeAheadController.text = vendor.name;
            formFieldState.didChange(vendor.name);
            widget.onSelected?.call(vendor); // Pass the full Vendor object
            debugPrint('Selected Vendor: ${vendor.name}');
          },
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No vendors found.'),
          ),
          decorationBuilder: (context, child) => Material(
            type: MaterialType.card,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 250,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child,
                    // if (_isFetching)
                    //   const Padding(
                    //     padding: EdgeInsets.all(8.0),
                    //     child: CircularProgressIndicator(),
                    //   ),
                  ],
                ),
              ),
            ),
          ),
          debounceDuration: const Duration(milliseconds: 300),
          hideOnEmpty: false,
          hideOnLoading: false,
          hideOnError: false,
          retainOnLoading: true,
          hideOnSelect: true,
        );
      },
    );
  }
}

Future<Map<String, dynamic>> searchByVendor(String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  final url = Uri.parse(
    '$baseUrl/label/getVendor/vendor${query.isNotEmpty ? '?name=$query' : ''}',
  );
  log('searchByVendor url: $url');

  try {
    final token = await AuthProvider().getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found'};
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    log('searchByVendor body: ${response.body}');

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      if (data['success'] == true && data.containsKey('vendors')) {
        return {
          'success': true,
          'vendors': data['vendors'],
        };
      }
      return {'success': false, 'message': 'Unexpected response format'};
    }
    return {'success': false, 'message': 'Failed with status: ${response.statusCode}'};
  } catch (error) {
    log('Search error: $error');
    return {'success': false, 'message': 'Network error: $error'};
  }
}
