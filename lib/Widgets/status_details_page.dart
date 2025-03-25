import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:provider/provider.dart';
import '../Custom-Files/colors.dart';

class StatusDetailsPage extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedSource;
  final List<String> selectedStatuses;

  const StatusDetailsPage({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedSource,
    required this.selectedStatuses,
  });

  @override
  State<StatusDetailsPage> createState() => _StatusDetailsPageState();
}

class _StatusDetailsPageState extends State<StatusDetailsPage> {
  DateTime? startDate;
  DateTime? endDate;
  String? selectedSource;
  List<String> selectedStatuses = [];

  static const Map<String, String> orderStatusMap = {
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

  @override
  void initState() {
    super.initState();
    startDate = widget.startDate;
    endDate = widget.endDate;
    selectedSource = widget.selectedSource;
    selectedStatuses = List.from(widget.selectedStatuses);

    // Fetch data on initial load
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _fetchData(context);
    // });
  }

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
        options: statusKeys,
      );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date selection row
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
                              child: _buildDateField(
                                'Start Date',
                                tempStartDate,
                                (date) => setDialogState(() => tempStartDate = date),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                              child: _buildDateField(
                                'End Date',
                                tempEndDate,
                                (date) => setDialogState(() => tempEndDate = date),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Status selection
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: DropdownSearch<String>.multiSelection(
                          items: ['All', ...orderStatusMap.values],
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Select Status",
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          onChanged: (List<String> values) {
                            setDialogState(() {
                              if (values.contains('All')) {
                                tempStatuses = orderStatusMap.values.toList();
                              } else {
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
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Marketplace selection
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Consumer<MarketplaceProvider>(
                          builder: (context, pro, child) {
                            return DropdownButtonFormField<String>(
                              value: tempSource,
                              decoration: const InputDecoration(
                                labelText: 'Marketplace',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                              isExpanded: true,
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'all',
                                  child: Text('All', style: const TextStyle(fontSize: 14)),
                                ),
                                ...pro.marketplaces.map((market) {
                                  return DropdownMenuItem<String>(
                                    value: market.name,
                                    child: Text(market.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                              ],
                              onChanged: (newValue) {
                                setDialogState(() => tempSource = newValue);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime?) onDateSelected) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryBlue, size: 18),
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(
        text: value == null ? 'Select Date' : DateFormat('dd-MM-yyyy').format(value),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
    );
  }

  // String _truncateText(String text, int maxLength) {
  //   if (text.length <= maxLength) return text;
  //   return '${text.substring(0, maxLength)}...';
  // }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Status Details', style: TextStyle(fontSize: 18, color: Colors.white)),
          backgroundColor: AppColors.primaryBlue,
          elevation: 2,
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact Filter Summary Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, AppColors.primaryBlue.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Row(
                          children: [
                            Tooltip(
                              message: 'Apply filters',
                              child: InkWell(
                                onTap: () => _showSettingsDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.filter_alt, color: AppColors.primaryBlue, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${startDate != null ? DateFormat('dd-MM-yyyy').format(startDate!) : 'N/A'} - ${endDate != null ? DateFormat('dd-MM-yyyy').format(endDate!) : 'N/A'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.store, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        selectedSource == 'all' ? 'All Marketplaces' : (selectedSource ?? 'N/A'),
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        height: 12,
                                        width: 1,
                                        color: Colors.grey.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.list_alt, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          selectedStatuses.isEmpty
                                              ? 'No Status Selected'
                                              : selectedStatuses.length == orderStatusMap.length
                                                  ? 'All Statuses'
                                                  : selectedStatuses.join(', '),
                                          // : _truncateText(selectedStatuses.join(', '), 30),
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                          // overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Material(
                            //   color: Colors.transparent,
                            //   child: InkWell(
                            //     borderRadius: BorderRadius.circular(20),
                            //     child: Container(
                            //       padding: const EdgeInsets.all(8),
                            //       decoration: BoxDecoration(
                            //         color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            //         borderRadius: BorderRadius.circular(20),
                            //       ),
                            //       child: const Icon(Icons.tune, size: 18, color: AppColors.primaryBlue),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
      
                  // Status Summary
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text(
                      'Status Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
      
                  // Status Cards Grid
                  Expanded(
                    child: provider.isPercentLoading
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200, // Smaller card size
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.7, // Adjusted for compact cards
                            ),
                            itemCount: provider.statusTotals.length,
                            itemBuilder: (context, index) {
                              String statusKey = provider.statusTotals.keys.elementAt(index);
                              int total = provider.statusTotals[statusKey] ?? 0;
                              String percentage = provider.statusPercentages[statusKey] ?? "0";
                              int parsedPercentage = double.tryParse(percentage)?.round() ?? 0;
                              // Color changeColor = parsedPercentage >= 0 ? Colors.green : Colors.red;
                              String displayName = orderStatusMap[statusKey] ?? statusKey.toUpperCase();
      
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: parsedPercentage > 0
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : parsedPercentage < 0
                                            ? Colors.red.withValues(alpha: 0.3)
                                            : Colors.grey.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$total',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                parsedPercentage > 0
                                                    ? Icons.arrow_upward
                                                    : parsedPercentage < 0
                                                        ? Icons.arrow_downward
                                                        : Icons.remove,
                                                size: 14,
                                                color: _getStatusColor(statusKey),
                                              ),
                                              Text(
                                                '${parsedPercentage.abs().toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: _getStatusColor(statusKey),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // const SizedBox(height: 4),
                                      // Progress indicator
                                      // ClipRRect(
                                      //   borderRadius: BorderRadius.circular(4),
                                      //   child: LinearProgressIndicator(
                                      //     value: total / (provider.statusTotals.values.fold(0, (sum, count) => sum + count) * 1.2),
                                      //     backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                      //     color: _getStatusColor(statusKey),
                                      //     minHeight: 4,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'filter',
              onPressed: () => _showSettingsDialog(context),
              backgroundColor: AppColors.primaryBlue,
              mini: true,
              child: const Icon(Icons.filter_alt, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'refresh',
              onPressed: () => _fetchData(context),
              backgroundColor: AppColors.primaryBlue,
              mini: true,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to assign colors to different status types
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
