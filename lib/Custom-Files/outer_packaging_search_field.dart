import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import '../model/outerpacking_model.dart';
import 'colors.dart';

class OuterPackagingSearchableTextField extends StatefulWidget {
  final bool isRequired;
  final void Function(OuterPackaging? outerPackaging)? onSelected;

  const OuterPackagingSearchableTextField({
    super.key,
    required this.isRequired,
    this.onSelected,
  });

  @override
  _OuterPackagingSearchableTextFieldState createState() => _OuterPackagingSearchableTextFieldState();
}

class _OuterPackagingSearchableTextFieldState extends State<OuterPackagingSearchableTextField> {
  final TextEditingController _typeAheadController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  List<OuterPackaging> _suggestions = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Future<List<OuterPackaging>> _fetchSuggestions(String query) async {
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
      final response = await searchOuterPackaging(query, page: _currentPage);
      if (response['success'] == true) {
        final List<OuterPackaging> newOuterPackagings =
        (response['boxsizes'] as List).map((b) => OuterPackaging.fromJson(b)).toList();

        setState(() {
          if (_currentPage == 1) {
            _suggestions = newOuterPackagings;
          } else {
            _suggestions.addAll(newOuterPackagings);
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
      debugPrint('Error fetching outer packagings: $e');
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
        return TypeAheadField<OuterPackaging>(
          controller: _typeAheadController,
          focusNode: _focusNode,
          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            decoration: InputDecoration(
              labelText: 'Outer Packaging${widget.isRequired ? ' *' : ''}',
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
              prefixIcon: const Icon(Icons.inventory_2),
              errorText: formFieldState.errorText,
            ),
            onChanged: (value) {
              formFieldState.didChange(value);
            },
          ),
          suggestionsCallback: (query) async {
            return await _fetchSuggestions(query);
          },
          itemBuilder: (context, outerPackaging) {
            return ListTile(
              title: Text(outerPackaging.outerPackageName),
              subtitle: Text(outerPackaging.outerPackageSku),
            );
          },
          onSelected: (outerPackaging) {
            _typeAheadController.text = '';
            // _typeAheadController.text = outerPackaging.outerPackageName;
            formFieldState.didChange(outerPackaging.outerPackageName);
            widget.onSelected?.call(outerPackaging);
            debugPrint('Selected Outer Packaging: ${outerPackaging.outerPackageName}');
          },
          emptyBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No outer packagings found.'),
          ),
          decorationBuilder: (context, child) => Material(
            type: MaterialType.card,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 250,
              ),
              child: child,
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

Future<Map<String, dynamic>> searchOuterPackaging(String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  String url;
  // Search by outerPackage_sku if query contains numbers, otherwise by outerPackage_name
  if (query.contains('-')) {
  // if (query.contains(RegExp(r'[0-9]'))) {
    url = '$baseUrl/boxsize?page=$page&outerPackage_sku=$query';
  } else {
    url = '$baseUrl/boxsize?page=$page&outerPackage_name=$query';
  }

  // outerPackage_name, occupied_weight, outerPackage_sku, outerPackage_type

  log("searchOuterPackaging url: $url");

  try {
    final token = await AuthProvider().getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found'};
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data.containsKey('data')) {
        return {
          'success': true,
          'boxsizes': data['data']['boxsizes'],
          'totalPages': data['data']['totalPages'],
          'currentPage': data['data']['currentPage'],
        };
      }
      return {'success': false, 'message': 'Unexpected response format'};
    }
    return {'success': false, 'message': 'Failed with status: ${response.statusCode}'};
  } catch (error) {
    debugPrint('Search error: $error');
    return {'success': false, 'message': 'Network error: $error'};
  }
}
