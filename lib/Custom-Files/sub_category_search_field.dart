import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' show LogicalKeyboardKey;

import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import 'colors.dart';

// Define a SubCategory class to handle the API response
class SubCategory {
  final String id;
  final String name;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubCategory({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SubCategorySearchableTextField extends StatefulWidget {
  final bool isRequired;
  final void Function(SubCategory? subCategory)? onSelected;

  const SubCategorySearchableTextField({
    super.key,
    required this.isRequired,
    this.onSelected,
  });

  @override
  _SubCategorySearchableTextFieldState createState() => _SubCategorySearchableTextFieldState();
}

class _SubCategorySearchableTextFieldState extends State<SubCategorySearchableTextField> {
  final TextEditingController _typeAheadController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  List<SubCategory> _suggestions = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Future<List<SubCategory>> _fetchSuggestions(String query) async {
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
      final response = await searchSubCategories(query, page: _currentPage);
      if (response['success'] == true) {
        final List<SubCategory> newSubCategories =
        (response['subcategories'] as List).map((s) => SubCategory.fromJson(s)).toList();

        setState(() {
          if (_currentPage == 1) {
            _suggestions = newSubCategories;
          } else {
            _suggestions.addAll(newSubCategories);
          }
          _hasMore = response['currentPage'] < response['totalPages'];
          _isFetching = false;
          _lastQuery = query;
        });

        if (_hasMore && query == _lastQuery) _currentPage++;
        return _suggestions;
      }
      return _suggestions;
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      return _suggestions;
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        _hasMore &&
        !_isFetching) {
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
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: _validateInput,
      initialValue: _typeAheadController.text,
      builder: (FormFieldState<String> formFieldState) {
        return TypeAheadField<SubCategory>(
          controller: _typeAheadController,
          focusNode: _focusNode,
          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            decoration: InputDecoration(
              labelText: 'Subcategory${widget.isRequired ? ' *' : ''}',
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
              // prefixIcon: const Icon(Icons.category),
              errorText: formFieldState.errorText,
            ),
            onChanged: (value) {
              formFieldState.didChange(value);
            },
            // onSubmitted: (value) {
            //   final suggestionsController = SuggestionsController.of<SubCategory>(context);
            //   if (suggestionsController?.selected.value != null) {
            //     widget.onSelected?.call(suggestionsController!.selected.value);
            //   }
            // },
          ),
          suggestionsCallback: (query) async {
            return await _fetchSuggestions(query);
          },
          itemBuilder: (context, subCategory) {
            return ListTile(
              title: Text(subCategory.name),
            );
          },
          onSelected: (subCategory) {
            _typeAheadController.text = subCategory.name;
            formFieldState.didChange(subCategory.name);
            widget.onSelected?.call(subCategory);
            debugPrint('Selected Subcategory: ${subCategory.name}');
          },
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No subcategories found.'),
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
                    if (_isFetching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
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

Future<Map<String, dynamic>> searchSubCategories(String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  final url = Uri.parse('$baseUrl/subCategory?page=$page${query.isNotEmpty ? '&name=$query' : ''}');

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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'subcategories': data['subcategories'],
        'totalPages': data['totalPages'],
        'currentPage': data['currentPage'],
      };
    }
    return {'success': false, 'message': 'Failed with status: ${response.statusCode}'};
  } catch (error) {
    debugPrint('Search error: $error');
    return {'success': false, 'message': 'Network error: $error'};
  }
}