import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ReorderingPage extends StatefulWidget {
  const ReorderingPage({super.key});

  @override
  State<ReorderingPage> createState() => _ReorderingPageState();
}

class _ReorderingPageState extends State<ReorderingPage> {
  String? _selectedValue;
  DateTime? _startDate;
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  final List<String> _options = [
    'Today',
    'Last 5 days',
    'Last 15 days',
    'Last 30 days',
    'Custom range'
  ];

  void _updateDatesBasedOnSelection(String? value) {
    if (value == null) return;

    final now = DateTime.now();
    _endDate = now;

    if (value == 'Today') {
      _startDate = now;
    } else if (value == 'Last 5 days') {
      _startDate = now.subtract(const Duration(days: 5));
    } else if (value == 'Last 15 days') {
      _startDate = now.subtract(const Duration(days: 15));
    } else if (value == 'Last 30 days') {
      _startDate = now.subtract(const Duration(days: 30));
    } else {
      // For custom range, initialize start date if null
      _startDate ??= now.subtract(const Duration(days: 7));
    }
    setState(() {});
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      String baseUrl = await Constants.getBaseUrl();

      final startDate = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endDate = DateFormat('yyyy-MM-dd').format(_endDate);

      if (token == null || token.isEmpty) {
        throw Exception('Authorization token is missing or invalid.');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(
            '$baseUrl/orders/reOrdering?startDate=$startDate&endDate=$endDate'),
        headers: headers,
      );

      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        log("jsonBody: $jsonBody");

        final downloadUrl = jsonBody['downloadUrl'];

        if (downloadUrl != null) {
          final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
          if (canLaunch) {
            await launchUrl(Uri.parse(downloadUrl));
          } else {
            throw 'Could not launch $downloadUrl';
          }
        } else {
          throw Exception('No download URL found');
        }
      } else {
        throw Exception(
            'Failed to load template: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
      log('Error during report generation: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _canGenerate {
    if (_selectedValue == null) return false;
    if (_selectedValue == 'Custom range') {
      return _startDate != null;
    }
    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 40,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 16),
              Text(
                'Reordering Report',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Product Quantity Sold Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedValue,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                        labelText: 'Select Period',
                        labelStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_month,
                          color: AppColors.primaryBlue,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedValue = newValue;
                          _updateDatesBasedOnSelection(newValue);
                        });
                      },
                      items: _options.map((String option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedValue != null) ...[
                      if (_selectedValue == 'Custom range') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final DateTime? pickedStart =
                                          await showDatePicker(
                                        context: context,
                                        initialDate:
                                            _startDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: _endDate,
                                      );
                                      if (pickedStart != null) {
                                        setState(
                                            () => _startDate = pickedStart);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.calendar_today),
                                    label: const Text('Select Start Date'),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.date_range,
                                          size: 20,
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Start: ${_formatDate(_startDate)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final DateTime? pickedEnd =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: _endDate,
                                        firstDate: _startDate ?? DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (pickedEnd != null) {
                                        setState(() => _endDate = pickedEnd);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.calendar_today),
                                    label: const Text('Select End Date'),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.date_range,
                                          size: 20,
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'End: ${_formatDate(_endDate)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Selected Period: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canGenerate && !_isLoading
                            ? _generateReport
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Generate Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
