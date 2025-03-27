import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/all_orders_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadOrders extends StatefulWidget {
  const DownloadOrders({super.key});

  @override
  State<DownloadOrders> createState() => _DownloadOrdersState();
}

class _DownloadOrdersState extends State<DownloadOrders> {
  String? _selectedValue;
  String _selectedStatus = 'all';
  // final String _marketplace = '';
  DateTime? _startDate;
  DateTime _endDate = DateTime.now();
  bool _isDownloading = false;
  String? _error;
  List<Map<String, String>> statuses = [];

  final List<String> _options = ['Today', 'Last 5 days', 'Last 15 days', 'Last 30 days', 'Custom range'];

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
      _startDate ??= now.subtract(const Duration(days: 7));
    }
    setState(() {});
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

  List<String> selectedMarketplaces = [];
  List<String> temp = [];

  void _openMultiSelectDialog(BuildContext context, List<String> marketplaces) {
    showDialog(
      context: context,
      builder: (context) {
        // Create a copy of the current selected marketplaces to allow cancellation
        List<String> tempSelectedMarketplaces = List.from(selectedMarketplaces);
        bool isAllSelected = tempSelectedMarketplaces.isEmpty || tempSelectedMarketplaces.length == marketplaces.length;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Marketplaces"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Add "All" option at the top
                    CheckboxListTile(
                      title: const Text("All"),
                      value: isAllSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            // For "All" selection, we'll use an empty list to represent "all"
                            tempSelectedMarketplaces.clear();
                            isAllSelected = true;
                          } else {
                            // Deselect all marketplaces
                            tempSelectedMarketplaces.clear();
                            isAllSelected = false;
                          }
                        });
                      },
                    ),
                    const Divider(), // Add a visual separator
                    ...marketplaces.map((marketplace) {
                      final isSelected = tempSelectedMarketplaces.contains(marketplace);
                      return CheckboxListTile(
                        title: Text(marketplace),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              tempSelectedMarketplaces.add(marketplace);
                            } else {
                              tempSelectedMarketplaces.remove(marketplace);
                            }
                            // Update "All" checkbox state
                            isAllSelected = tempSelectedMarketplaces.length == marketplaces.length;
                            if (isAllSelected) {
                              // If all are selected individually, switch to "All" mode
                              tempSelectedMarketplaces.clear();
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the parent widget's state
                    this.setState(() {
                      selectedMarketplaces = tempSelectedMarketplaces;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void fetchStatuses() async {
    final allOrdersProvider = Provider.of<AllOrdersProvider>(context, listen: false);
    List<Map<String, String>> fetchedStatuses = await allOrdersProvider.getTrackingStatuses();
    fetchedStatuses.insert(0, {'All': 'all'});

    log('fetchedStatuses: $fetchedStatuses');

    setState(() {
      statuses = fetchedStatuses;
      // Ensure a default value is set only after statuses are loaded
      // _selectedStatus = fetchedStatuses.isNotEmpty ? fetchedStatuses.first.keys.first : 'all';
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 28,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All Orders Report',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.close),
                        //   onPressed: () => Navigator.of(context).pop(),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<dynamic>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                        labelText: 'Select Status',
                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        prefixIcon: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                      items: [
                        ...statuses.map<DropdownMenuItem<dynamic>>((Map<String, dynamic> status) {
                          String key = status.keys.first;
                          dynamic value = status[key]; // Get the corresponding value from the map

                          return DropdownMenuItem<dynamic>(
                            value: value, // Use the value from the map
                            child: Text(key), // Display the key in the dropdown
                          );
                        }),
                        // const DropdownMenuItem<String>(
                        //   value: 'all',
                        //   child: Text('All'),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Consumer<MarketplaceProvider>(
                      builder: (context, provider, child) {
                        return GestureDetector(
                          onTap: () {
                            _openMultiSelectDialog(
                              context,
                              provider.marketplaces.map((e) => e.name).toList(),
                            );
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              ),
                              labelText: 'Select Marketplaces',
                              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              prefixIcon: const Icon(Icons.shopping_cart, color: AppColors.primaryBlue),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            child: Text(
                              selectedMarketplaces.isEmpty ? 'All' : selectedMarketplaces.join(', '),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      },
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
                      items: _options.map<DropdownMenuItem<String>>((String option) {
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
                                      final DateTime? pickedStart = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: _endDate ?? DateTime.now(),
                                      );
                                      if (pickedStart != null) {
                                        setState(() => _startDate = pickedStart);
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final DateTime? pickedEnd = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? DateTime.now(),
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
                              Expanded(
                                child: Text(
                                  'Selected Period: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_canGenerate && !_isDownloading) {
                            setState(() {
                              _isDownloading = true;
                            });

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              // Prevent dismissing the dialog by tapping outside
                              builder: (_) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                  content: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      // Adjust to create horizontal spacing
                                      Text(
                                        'Downloading',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );

                            Map<String, dynamic>? jsonBody;

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

                              // setState(() {
                              //   if (_selectedStatus != 'all') {
                              //     _selectedStatus =
                              //         statuses.firstWhere((map) => map.containsKey(_selectedStatus), orElse: () => {})[_selectedStatus]!;
                              //   }
                              // });
                              Logger().e('_selectedStatus: $_selectedStatus');

                              String marketplacesParam =
                                  selectedMarketplaces.isEmpty ? 'marketplace=all' : 'marketplace=${selectedMarketplaces.join(',')}';

                              String url =
                                  '$baseUrl/orders/download?startDate=$startDate&endDate=$endDate&order_status=$_selectedStatus&$marketplacesParam';

                              // String url = '$baseUrl/orders/download?startDate=$startDate&endDate=$endDate&order_status=$_selectedStatus&marketplace=$_marketplace';

                              Logger().e('url: $url');

                              final response = await http.get(
                                Uri.parse(url),
                                headers: headers,
                              );

                              log('Response body: ${response.body}');
                              jsonBody = json.decode(response.body);

                              if (response.statusCode == 200) {
                                log("jsonBody: $jsonBody");

                                final downloadUrl = jsonBody!['downloadUrl'];

                                if (downloadUrl != null) {
                                  final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
                                  if (canLaunch) {
                                    await launchUrl(Uri.parse(downloadUrl));
                                  } else {
                                    // throw 'Could not launch $downloadUrl';
                                    log('Could not launch $downloadUrl');
                                  }
                                } else {
                                  log('No download URL found');
                                  // throw Exception('No download URL found');
                                }
                              } else {
                                log('Failed to load template: ${response.statusCode} ${response.body}');
                                // throw Exception('Failed to load template: ${response.statusCode} ${response.body}');
                              }
                            } catch (error) {
                              setState(() {
                                _error = error.toString();
                              });
                              log('Error during report generation: $error');
                            } finally {
                              setState(() {
                                _isDownloading = false;
                                // _selectedStatus = 'all';
                              });
                              // Navigator.pop(context);
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(jsonBody!['message'] ?? jsonBody['error']),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child:
                            // _isDownloading
                            //     ? const SizedBox(
                            //         height: 24,
                            //         width: 24,
                            //         child: CircularProgressIndicator(
                            //           strokeWidth: 2,
                            //           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            //         ),
                            //       )
                            //     :
                            const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Download Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
