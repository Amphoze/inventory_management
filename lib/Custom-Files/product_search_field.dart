import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_management/model/orders_model.dart';

import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import 'colors.dart';

class ProductSearchableTextField extends StatefulWidget {
  final bool isRequired;
  final void Function(Product? product)? onSelected;

  const ProductSearchableTextField({
    super.key,
    required this.isRequired,
    this.onSelected,
  });

  @override
  _ProductSearchableTextFieldState createState() => _ProductSearchableTextFieldState();
}

class _ProductSearchableTextFieldState extends State<ProductSearchableTextField> {
  final TextEditingController _typeAheadController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  List<Product> _suggestions = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Future<List<Product>> _fetchSuggestions(String query) async {
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
      final response = await search(query, page: _currentPage);
      if (response['success'] == true) {
        final List<Product> newProducts = (response['products'] as List).map((v) => Product.fromJson(v)).toList();

        setState(() {
          if (_currentPage == 1) {
            _suggestions = newProducts;
          } else {
            _suggestions.addAll(newProducts);
          }
          _hasMore = newProducts.isNotEmpty;
          _isFetching = false;
          _lastQuery = query;
        });

        if (_hasMore && query == _lastQuery) _currentPage++;
        return _suggestions;
      }
      return _suggestions;
    } catch (e) {
      debugPrint('Error fetching products: $e');
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
      return 'Please select a product';
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
        return TypeAheadField<Product>(
          controller: _typeAheadController,
          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            decoration: InputDecoration(
              labelText: 'Product${widget.isRequired ? ' *' : ''}',
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
          itemBuilder: (context, product) {
            return ListTile(
              title: Text(product.sku ?? ''),
              subtitle: Text(product.displayName),
            );
          },
          onSelected: (product) {
            _typeAheadController.text = product.sku ?? '';
            formFieldState.didChange(product.displayName);
            widget.onSelected?.call(product);
            debugPrint('Selected product: ${product.displayName}');
          },
          loadingBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No products found.'),
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

Future<Map<String, dynamic>> search(String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  final url = Uri.parse(
    '$baseUrl/products${query.contains('-') ? '?sku=$query' : '?displayName=$query'}',
  );
  log('search url: $url');

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
    log('search body: ${response.body}');

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      if (data.containsKey('products')) {
        return {
          'success': true,
          'products': data['products'],
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
