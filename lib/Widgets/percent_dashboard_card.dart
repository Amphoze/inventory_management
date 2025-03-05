import 'package:flutter/material.dart';
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
  String? selectedOption;
  String? selectedSource;

  final List<String> options = ['RTO', 'Delivered'];

  void _fetchData(BuildContext context) {
    if (startDate != null && endDate != null && selectedOption != null && selectedSource != null) {
      final dateRange = "${startDate!.toIso8601String().split('T')[0]},${endDate!.toIso8601String().split('T')[0]}";
      Provider.of<DashboardProvider>(context, listen: false).fetchPercentageData(dateRange, selectedSource!, selectedOption!.toLowerCase());
    }
  }

  void _showSettingsDialog(BuildContext context) {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;
    String? tempOption = selectedOption;
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
                    // Start Date
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          labelStyle: TextStyle(color: Colors.grey),
                          // border: OutlineInputBorder(
                          //   borderRadius: BorderRadius.circular(8.0),
                          // ),
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        controller: TextEditingController(
                          text: tempStartDate == null ? 'Select' : tempStartDate!.toString().split(' ')[0],
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

                    // End Date
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          labelStyle: TextStyle(color: Colors.grey),
                          // border: OutlineInputBorder(
                          //   borderRadius: BorderRadius.circular(8.0),
                          // ),
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        controller: TextEditingController(
                          text: tempEndDate == null ? 'Select' : tempEndDate!.toString().split(' ')[0],
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

                    // Option Dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: tempOption,
                        decoration: const InputDecoration(
                          labelText: 'Option',
                          labelStyle: TextStyle(color: Colors.grey),
                          // border: OutlineInputBorder(
                          //   borderRadius: BorderRadius.circular(8.0),
                          // ),
                        ),
                        hint: const Text('Select from RTO or Delivered', style: TextStyle(fontSize: 14)),
                        items: options.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() {
                            tempOption = newValue;
                          });
                        },
                      ),
                    ),

                    // Source Dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Consumer<MarketplaceProvider>(
                        builder: (context, pro, child) {
                          return DropdownButtonFormField<String>(
                            value: tempSource,
                            decoration: const InputDecoration(
                              labelText: 'Marketplace',
                              labelStyle: TextStyle(color: Colors.grey),
                              // border: OutlineInputBorder(
                              //   borderRadius: BorderRadius.circular(8.0),
                              // ),
                            ),
                            hint: const Text('Select', style: TextStyle(fontSize: 14)),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  startDate = tempStartDate;
                  endDate = tempEndDate;
                  selectedOption = tempOption;
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
        // Determine the percentage and color based on selectedOption
        String percentage = selectedOption == 'Delivered' ? provider.deliveredPercentage : provider.rtoPercentage;
        Color changeColor = double.parse(percentage) >= 0 ? Colors.green : Colors.red;

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                  blurRadius: 10,
                ),
              ],
              border: Border.all(
                color: AppColors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section with Button
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'RTO/Delivered',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue.withOpacity(0.9),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        message: 'Set Filters',
                        child: InkWell(
                          child: const Icon(Icons.filter_alt_outlined, size: 20),
                          onTap: () => _showSettingsDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Value Section
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: provider.isPercentLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          selectedOption == 'RTO' ? provider.totalRto.toString() : provider.totalDelivered.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                ),

                const Spacer(),

                // Bottom Info Section
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedOption?.toUpperCase() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: changeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              double.parse(percentage) >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 14,
                              color: changeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: changeColor,
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
          ),
        );
      },
    );
  }
}
