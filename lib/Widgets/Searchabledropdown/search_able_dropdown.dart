import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../Api/auth_provider.dart';
import '../../Custom-Files/colors.dart';
import '../../constants/constants.dart';



class searchabletestfeild extends StatefulWidget {
  final bool isRequired;
  final TextEditingController? controller;
  final TextEditingController? nameController;
  final bool isEditProduct;
  final String lable;
  const searchabletestfeild({super.key, required this.isRequired, this.controller, this.nameController, this.isEditProduct = false, required this.lable});

  @override
  State<searchabletestfeild> createState() => _searchabletestfeildState();
}

class _searchabletestfeildState extends State<searchabletestfeild> {
  late TextEditingController _typeAheadController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isFetching = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _suggestions = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _typeAheadController = widget.controller ?? TextEditingController();
    _scrollController.addListener(_onScroll);
  }

  Future<List<Map<String, dynamic>>> _fetchSuggestions(String query) async {
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
      final response = await searchByLabel(query, page: _currentPage);
      if (response['success'] == true) {
        final List<Map<String, dynamic>> newLabels =
        List<Map<String, dynamic>>.from(response['data']);

        setState(() {
          if (_currentPage == 1) {
            _suggestions = newLabels;
          } else {
            _suggestions.addAll(newLabels);
          }
          _hasMore = newLabels.isNotEmpty;
          _isFetching = false;
          _lastQuery = query;
        });

        if (_hasMore && query == _lastQuery) _currentPage++;
        return _suggestions;
      }
      return _suggestions;
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
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
    if (widget.controller == null) _typeAheadController.dispose(); // Only dispose if we created it
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:  widget.isEditProduct ?
      BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ) : null,
      child: FormField<String>(
        validator: _validateInput,
        initialValue: _typeAheadController.text,
        builder: (FormFieldState<String> formFieldState) {
          return TypeAheadField<Map<String, dynamic>>(
            controller: _typeAheadController,
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              decoration:  InputDecoration(

                labelText: '${widget.lable} ${widget.isRequired ? ' *' : ''}',
                border: widget.isEditProduct ? InputBorder.none  : OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder:  widget.isEditProduct ? InputBorder.none  : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: widget.isEditProduct ? InputBorder.none  : OutlineInputBorder(
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
                prefixIcon: const Icon(Icons.label),
                errorText: formFieldState.errorText, // Display validation error
              ),
              onChanged: (value) {
                formFieldState.didChange(value); // Update form field state
              },
            ),
            suggestionsCallback: (query) async {
              return await _fetchSuggestions(query);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion['outerPackage_sku'] ?? ''),
                subtitle: Text(suggestion['outerPackage_name'] ?? ''),
              );
            },
            onSelected: (suggestion) {

              log('Selected data:  ${suggestion}');


              _typeAheadController.text =
              "${suggestion['outerPackage_sku'] ?? ''} (${suggestion['outerPackage_name'] ?? ''})";
              formFieldState.didChange(_typeAheadController.text);
              debugPrint('Selected: ${suggestion['outerPackage_sku']}');

              // if (widget.nameController != null) {
              //   widget.nameController!.text = suggestion['outerPackage_name'] ?? '';
              // }
            },
            loadingBuilder: (context) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            emptyBuilder: (context) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No items found.'),
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
      ),
    );
  }
}

Future<Map<String, dynamic>> searchByLabel(String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  String url;

  if (query.contains(RegExp(r'[0-9]'))) {
    url = '$baseUrl/boxsize?page=$page&labelSku=$query';
  } else {
    url = '$baseUrl/boxsize?page=$page&outerPackage_name=$query';
  }

  try {
    final token = await AuthProvider().getToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found'};
    }

    log('response---> and Url --> $url and $token');


    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('data')) {
        final labels = List<Map<String, dynamic>>.from(data["data"]['boxsizes']);
        return {
          'success': true,
          'data': labels,
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