import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import 'colors.dart';

class LabelSearchableTextField extends StatefulWidget {
  final bool isRequired;
  final TextEditingController? controller;

  const LabelSearchableTextField({super.key, required this.isRequired, this.controller});

  @override
  _LabelSearchableTextFieldState createState() => _LabelSearchableTextFieldState();
}

class _LabelSearchableTextFieldState extends State<LabelSearchableTextField> {
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
    return FormField<String>(
      validator: _validateInput,
      initialValue: _typeAheadController.text,
      builder: (FormFieldState<String> formFieldState) {
        return TypeAheadField<Map<String, dynamic>>(
          controller: _typeAheadController,
          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            decoration: InputDecoration(
              labelText: 'Label${widget.isRequired ? ' *' : ''}',
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
              title: Text(suggestion['labelSku'] ?? ''),
              subtitle: Text(suggestion['name'] ?? ''),
            );
          },
          onSelected: (suggestion) {
            _typeAheadController.text = suggestion['labelSku'] ?? '';
            formFieldState.didChange(_typeAheadController.text); // Update form state
            debugPrint('Selected: ${suggestion['labelSku']}');
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
    );
  }
}

Future<Map<String, dynamic>> searchByLabel(String query, {int page = 1}) async {
  String baseUrl = await Constants.getBaseUrl();
  String url;

  // Check if query contains numbers to determine if searching by labelSku
  if (query.contains(RegExp(r'[0-9]'))) {
    url = '$baseUrl/label?page=$page&labelSku=$query';
  } else {
    url = '$baseUrl/label?page=$page&name=$query';
  }

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
      if (data.containsKey('data')) {
        final labels = List<Map<String, dynamic>>.from(data["data"]['labels']);
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