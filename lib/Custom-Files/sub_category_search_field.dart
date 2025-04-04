import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import 'colors.dart';

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
  final String? categoryName;
  final void Function(SubCategory? subCategory)? onSelected;

  const SubCategorySearchableTextField({
    super.key,
    required this.isRequired,
    this.categoryName,
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
    if (widget.categoryName != null) {
      _fetchSuggestions('');
    }
  }

  @override
  void didUpdateWidget(SubCategorySearchableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryName != oldWidget.categoryName) {
      debugPrint('Category changed from ${oldWidget.categoryName} to ${widget.categoryName}');
      setState(() {
        _suggestions.clear();
        _typeAheadController.clear();
        _currentPage = 1;
        _hasMore = true;
        _lastQuery = '';
      });
      if (widget.categoryName != null) {
        debugPrint('Triggering fetch for new category: ${widget.categoryName}');
        _fetchSuggestions('');
      } else {
        debugPrint('No category provided, clearing suggestions');
      }
    }
  }

  Future<List<SubCategory>> _fetchSuggestions(String query) async {
    if (_isFetching && query == _lastQuery) {
      debugPrint('Skipping fetch: already fetching for query "$query"');
      return _suggestions;
    }
    if (widget.categoryName == null) {
      debugPrint('No categoryName, returning empty suggestions');
      return [];
    }

    setState(() {
      if (query != _lastQuery) {
        _currentPage = 1;
        _hasMore = true;
        _suggestions.clear();
      }
      _isFetching = true;
    });

    try {
      debugPrint('Fetching subcategories for category: ${widget.categoryName}, query: $query, page: $_currentPage');
      final response = await searchSubCategories(widget.categoryName!, query, page: _currentPage);
      if (response['success'] == true) {
        final List<SubCategory> newSubCategories =
        (response['subcategories'] as List).map((s) => SubCategory.fromJson(s)).toList();

        setState(() {
          if (_currentPage == 1) {
            _suggestions = newSubCategories;
          } else {
            _suggestions.addAll(newSubCategories);
          }
          _hasMore = newSubCategories.isNotEmpty;
          _isFetching = false;
          _lastQuery = query;
          debugPrint('Updated suggestions: ${_suggestions.map((s) => s.name).toList()}');
        });

        if (_hasMore && query == _lastQuery) _currentPage++;
        return _suggestions;
      } else {
        debugPrint('Fetch failed: ${response['message']}');
        return _suggestions;
      }
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
          key: ValueKey(widget.categoryName), // Force rebuild when category changes
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
              errorText: formFieldState.errorText,
            ),
            onChanged: (value) {
              formFieldState.didChange(value);
            },
          ),
          suggestionsCallback: (query) async {
            final suggestions = await _fetchSuggestions(query);
            debugPrint('Suggestions callback triggered with query "$query", returning ${suggestions.length} items');
            return suggestions;
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

Future<Map<String, dynamic>> searchSubCategories(String categoryName, String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  final url = Uri.parse('$baseUrl/subCategory/fetch/subcategory?categoryName=$categoryName${query.isNotEmpty ? '&name=$query' : ''}');

  try {
    final token = await AuthProvider().getToken();
    if (token == null) {
      debugPrint('No token found');
      return {'success': false, 'message': 'Authentication token not found'};
    }

    debugPrint('Making API call to: $url');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('API Response Status: ${response.statusCode}');
    debugPrint('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'subcategories': data['subcategories'],
        'totalPages': 1, // Update if pagination is supported
        'currentPage': 1,
      };
    }
    return {'success': false, 'message': 'Failed with status: ${response.statusCode}'};
  } catch (error) {
    debugPrint('Search error: $error');
    return {'success': false, 'message': 'Network error: $error'};
  }
}