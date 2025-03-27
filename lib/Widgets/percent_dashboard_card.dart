import 'package:carousel_slider/carousel_slider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Widgets/status_details_page.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import '../Custom-Files/colors.dart';

class PercentDashboardCard extends StatefulWidget {
  final double width;
  final double height;

  const PercentDashboardCard({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<PercentDashboardCard> createState() => _PercentDashboardCardState();
}

class _PercentDashboardCardState extends State<PercentDashboardCard> {
  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedStatuses = [];
  String? selectedSource;
  int currentStatusIndex = 0;

  final Map<String, String> orderStatusMap = {
    "failed": "Failed",
    "confirmed": "Ready to Confirm",
    "readytoinvoice": "Ready to Invoice",
    "readytobook": "Ready to Book",
    "readytopick": "Ready to Pick",
    "readytopack": "Ready to Pack",
    "checkweight": "Ready to Check",
    "readytorack": "Ready to Rack",
    "readytomanifest": "Ready to Manifest",
    "dispatch": "Dispatched",
    "cancelled": "Cancelled",
    "rto": "RTO",
    "merged": "Merged",
    "split": "Split",
    "intransit": "In-Transit",
    "delivered": "Delivered",
    "rto_intransit": "RTO, In-Transit",
  };

  void _fetchData(BuildContext context) {
    if (startDate != null && endDate != null && selectedStatuses.isNotEmpty && selectedSource != null) {
      final dateRange = "${startDate!.toIso8601String().split('T')[0]},${endDate!.toIso8601String().split('T')[0]}";

      final statusKeys = selectedStatuses.map((status) {
        return orderStatusMap.keys.firstWhere(
          (key) => orderStatusMap[key] == status,
          orElse: () => status.toLowerCase(),
        );
      }).toList();

      Provider.of<DashboardProvider>(context, listen: false).fetchPercentageData(
        dateRange: dateRange,
        marketplace: selectedSource!,
        options: statusKeys, // Pass the keys instead of the values
      );
      setState(() {
        currentStatusIndex = 0;
      });
    }
  }

  void _showSettingsDialog(BuildContext context) {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;
    List<String> tempStatuses = List.from(selectedStatuses);
    String? tempSource = selectedSource;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: const Text(
            'Set Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          contentPadding: const EdgeInsets.all(16.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          labelStyle: TextStyle(color: Colors.grey),
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        controller: TextEditingController(
                          text: tempStartDate == null ? 'Select Start Date' : DateFormat('dd-MM-yyyy').format(tempStartDate!).toString(),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              tempStartDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          labelStyle: TextStyle(color: Colors.grey),
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        controller: TextEditingController(
                          text: tempEndDate == null ? 'Select End Date' : DateFormat('dd-MM-yyyy').format(tempEndDate!).toString(),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              tempEndDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500, minWidth: 300),
                        child: DropdownSearch<String>.multiSelection(
                          items: ['All', ...orderStatusMap.values],
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Select Order Statuses",
                            ),
                          ),
                          onChanged: (List<String> values) {
                            setDialogState(() {
                              if (values.contains('All')) {
                                // If 'All' is selected, add all statuses
                                tempStatuses = orderStatusMap.values.toList();
                              } else {
                                // Remove 'All' from the selection if present and use the selected values
                                tempStatuses = values.where((item) => item != 'All').toList();
                              }
                            });
                          },
                          selectedItems: tempStatuses,
                          popupProps: PopupPropsMultiSelection.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                labelText: "Search Status",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Consumer<MarketplaceProvider>(
                        builder: (context, pro, child) {
                          return DropdownButtonFormField<String>(
                            value: tempSource,
                            decoration: const InputDecoration(
                              labelText: 'Marketplace',
                              labelStyle: TextStyle(color: Colors.grey),
                            ),
                            hint: const Text('Select Marketplace', style: TextStyle(fontSize: 14)),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('All', style: TextStyle(fontSize: 14)),
                              ),
                              ...pro.marketplaces.map((market) {
                                return DropdownMenuItem<String>(
                                  value: market.name,
                                  child: Text(market.name, style: const TextStyle(fontSize: 14)),
                                );
                              })
                            ],
                            onChanged: (newValue) {
                              setDialogState(() {
                                tempSource = newValue;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  startDate = tempStartDate;
                  endDate = tempEndDate;
                  selectedStatuses = tempStatuses;
                  selectedSource = tempSource;
                  _fetchData(context);
                });
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    startDate = DateTime.now().subtract(const Duration(days: 15));
    endDate = DateTime.now();
    selectedSource = 'all';
    selectedStatuses = orderStatusMap.values.toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(context);
    });
    // Optionally call _fetchData here if other required fields are also initialized
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final statusKeys = selectedStatuses
            .map((s) => orderStatusMap.keys.firstWhere(
                  (k) => orderStatusMap[k] == s,
                  orElse: () => s.toLowerCase(),
                ))
            .toList();

        String currentStatus = statusKeys.isNotEmpty && currentStatusIndex < statusKeys.length ? statusKeys[currentStatusIndex] : '';
        // int currentTotal = currentStatus.isNotEmpty ? provider.statusTotals[currentStatus] ?? 0 : 0;
        String currentPercentage = currentStatus.isNotEmpty ? provider.statusPercentages[currentStatus] ?? "0" : "0";
        double parsedPercentage = double.tryParse(currentPercentage) ?? 0;
        // Color changeColor = parsedPercentage >= 0 ? Colors.green : Colors.red;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                  blurRadius: 10,
                ),
              ],
              border: Border.all(
                color: AppColors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue.withValues(alpha: 0.9),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    if (startDate != null && endDate != null)
                      RichText(
                        text: TextSpan(
                          text: DateFormat('dd-MM-yyyy').format(startDate!),
                          children: [
                            const TextSpan(
                              text: ' | ',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: DateFormat('dd-MM-yyyy').format(endDate!),
                            ),
                          ],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    text: 'Total: ',
                    children: [
                      TextSpan(
                        text: '${provider.isPercentLoading ? '...' : provider.totalOrders}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: provider.isPercentLoading
                      ? const Center(child: CircularProgressIndicator())
                      : statusKeys.isNotEmpty
                          ? CarouselSlider(
                              options: CarouselOptions(
                                height: widget.height * 0.6, // Adjust height as needed
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 3),
                                enlargeCenterPage: true,
                                viewportFraction: 0.9,
                              ),
                              items: statusKeys.map((status) {
                                int currentTotal = provider.statusTotals[status] ?? 0;
                                String currentPercentage = provider.statusPercentages[status] ?? "0";
                                double parsedPercentage = double.tryParse(currentPercentage) ?? 0;
                                // Color changeColor = parsedPercentage >= 0 ? Colors.green : Colors.red;

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${orderStatusMap[status] ?? status.toUpperCase()}: ",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '$currentTotal (${parsedPercentage.toStringAsFixed(2)}%)',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          : const Text(
                              'Select Statuses to View',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                ),
                // Divider(height: 8, color: AppColors.grey.withValues(alpha: 0.1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Text(
                            selectedStatuses.isEmpty
                                ? 'N/A'
                                : selectedStatuses.length == 17
                                    ? 'All Statuses | '
                                    : selectedStatuses.map((s) => s.toUpperCase()).join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey.withValues(alpha: 0.8),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            provider.isPercentLoading ? '...' : provider.marketplace,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StatusDetailsPage(
                                    startDate: startDate,
                                    endDate: endDate,
                                    selectedSource: selectedSource,
                                    selectedStatuses: selectedStatuses)));
                      },
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (["delivered", "dispatch"].contains(status)) {
      return Colors.green;
    } else if (["failed", "cancelled", "rto", "rto_intransit"].contains(status)) {
      return Colors.red;
    } else if (["confirmed", "readytoinvoice", "readytobook"].contains(status)) {
      return Colors.orange;
    } else if (["readytopick", "readytopack", "checkweight", "readytorack", "readytomanifest"].contains(status)) {
      return Colors.blue;
    } else if (["intransit"].contains(status)) {
      return Colors.purple;
    } else if (["merged", "split"].contains(status)) {
      return Colors.teal;
    }
    return AppColors.primaryBlue;
  }
}
