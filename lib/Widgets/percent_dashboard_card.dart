import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    "readyToInvoice": "Ready to Invoice",
    "readyToBook": "Ready to Book",
    "readyToPick": "Ready to Pick",
    "readyToPack": "Ready to Pack",
    "checkWeight": "Ready to Check",
    "readyToRack": "Ready to Rack",
    "readyToManifest": "Ready to Manifest",
    "dispatch": "Dispatched",
    "cancelled": "Cancelled",
    "rto": "RTO",
    "merged": "Merged",
    "split": "Split",
    "inTransit": "In-Transit",
    "delivered": "Delivered",
    "rto_inTransit": "RTO, In-Transit",
  };

  void _fetchData(BuildContext context) {
    if (startDate != null && endDate != null && selectedStatuses.isNotEmpty && selectedSource != null) {
      final dateRange = "${startDate!.toIso8601String().split('T')[0]},${endDate!.toIso8601String().split('T')[0]}";
      Provider.of<DashboardProvider>(context, listen: false).fetchPercentageData(
        dateRange,
        selectedSource!,
        selectedStatuses.map((status) => status.toLowerCase()).toList(),
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
                          items: orderStatusMap.values.toList(),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Select Order Statuses",
                            ),
                          ),
                          onChanged: (List<String> values) {
                            setDialogState(() {
                              tempStatuses = values;
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
                            items: pro.marketplaces.map((market) {
                              return DropdownMenuItem<String>(
                                value: market.name,
                                child: Text(market.name, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
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
        int currentTotal = currentStatus.isNotEmpty ? provider.statusTotals[currentStatus] ?? 0 : 0;
        String currentPercentage = currentStatus.isNotEmpty ? provider.statusPercentages[currentStatus] ?? "0" : "0";
        double parsedPercentage = double.tryParse(currentPercentage) ?? 0;
        Color changeColor = parsedPercentage >= 0 ? Colors.green : Colors.red;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue.withValues(alpha: 0.9),
                        letterSpacing: -0.5,
                      ),
                    ),
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
                    Row(
                      children: [
                        Text(
                          provider.isPercentLoading ? '...' : provider.marketplace,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message: 'Set Filters',
                          child: InkWell(
                            child: const Icon(Icons.filter_alt_outlined, size: 20),
                            onTap: () => _showSettingsDialog(context),
                          ),
                        ),
                      ],
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  tooltip: 'Previous Status',
                                  icon: const Icon(Icons.arrow_left, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: currentStatusIndex > 0 ? () => setState(() => currentStatusIndex--) : null,
                                  color: currentStatusIndex > 0 ? AppColors.primaryBlue : Colors.grey,
                                ),
                                provider.isPercentLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : statusKeys.isNotEmpty
                                        ? Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${orderStatusMap[currentStatus] ?? currentStatus.toUpperCase()}: ",
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$currentTotal',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '(${parsedPercentage.toStringAsFixed(2)}%)',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w500,
                                                        color: changeColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        : const Center(
                                            child: Text(
                                              'No Status Selected',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                IconButton(
                                  tooltip: 'Next Status',
                                  icon: const Icon(Icons.arrow_right, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: currentStatusIndex < statusKeys.length - 1 ? () => setState(() => currentStatusIndex++) : null,
                                  color: currentStatusIndex < statusKeys.length - 1 ? AppColors.primaryBlue : Colors.grey,
                                ),
                              ],
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.grey.withValues(alpha: 0.1), width: 1),
                    ),
                  ),
                  child: Tooltip(
                    message: selectedStatuses.isEmpty
                        ? 'N/A'
                        : selectedStatuses.length == 17
                            ? 'All'
                            : selectedStatuses.map((s) => s.toUpperCase()).join(', '),
                    child: Text(
                      selectedStatuses.isEmpty
                          ? 'N/A'
                          : selectedStatuses.length == 17
                              ? 'All'
                              : selectedStatuses.map((s) => s.toUpperCase()).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey.withValues(alpha: 0.8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
