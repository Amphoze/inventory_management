import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/outerbox_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/inventory_provider.dart';

class CustomDataTable extends StatelessWidget {
  final List<String> columnNames;
  final List<Map<String, dynamic>> rowsData;

  const CustomDataTable({
    super.key,
    required this.columnNames,
    required this.rowsData,
  });

  @override
  Widget build(BuildContext context) {
    List<DataColumn> columns = columnNames.map((name) {
      return DataColumn(
        label: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      );
    }).toList();

    // Create DataRow list from rowsData
    List<DataRow> rows = rowsData.map((data) {
      return DataRow(
        cells: columnNames.map((columnName) {
          var cellData = data[columnName];
          if (cellData is Widget) {
            return DataCell(cellData);
          } else {
            return DataCell(Text(cellData?.toString() ?? 'N/A'));
          }
        }).toList(),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
            (states) => AppColors.green.withValues(alpha: 0.2),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class InventoryDataTable extends StatefulWidget {
  final List<String> columnNames;
  final List<Map<String, dynamic>> rowsData;
  final ScrollController scrollController;

  const InventoryDataTable({
    super.key,
    required this.columnNames,
    required this.rowsData,
    required this.scrollController,
    // required this.inventoryId,
  });

  @override
  State<InventoryDataTable> createState() => _InventoryDataTableState();
}

class _InventoryDataTableState extends State<InventoryDataTable> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: widget.scrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
            (states) => AppColors.blueAccent.withValues(alpha: 0.2),
          ),
          columns: widget.columnNames.map((name) {
            return DataColumn(
              label: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            );
          }).toList(),
          rows: widget.rowsData.map((data) {
            return DataRow(
              cells: widget.columnNames.map((columnName) {
                var cellData = data[columnName];

                if (columnName == 'IMAGE') {
                  return DataCell(
                    Image.network(
                      cellData,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 40,
                        );
                      },
                      fit: BoxFit.cover,
                    ),
                  );
                } else if (columnName == 'QUANTITY') {
                  return DataCell(
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cellData?.toString() ?? '0', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () {
                                  _showUpdateQuantityDialog(context, data);
                                },
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              final inventoryId = data['inventoryId'];
                              if (inventoryId != null) {
                                _showDetailsDialog(context, data);
                              } else {
                                print('Inventory ID not found for the selected item.');
                              }
                            },
                            child: const Text(
                              'View Details',
                              style: TextStyle(color: AppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (columnName == 'SKU QUANTITY') {
                  List<dynamic> thresholds = data['SKU QUANTITY'] ?? []; // Get the list of thresholds

                  return DataCell(
                    Container(
                      constraints: const BoxConstraints(), // Prevent excessive width
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: thresholds.map<Widget>((threshold) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (threshold['warehouseName'].toString().isNotEmpty) ...[
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warehouse,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              threshold['warehouseName'] ?? 'N/A',
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        threshold['quantity']?.toString() ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  if (threshold['binName'].toString().isNotEmpty) ...[
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.inventory,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              threshold['binName'] ?? 'N/A',
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        threshold['binQty']?.toString() ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                } else if (columnName == 'THRESHOLD QUANTITY') {
                  return DataCell(
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cellData?.toString() ?? '0', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () {
                                  _showQuantityDialog(context, data);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (cellData is Widget) {
                  return DataCell(cellData);
                } else if (columnName == 'THRESHOLD') {
                  // Logger().e('data: ${data['THRESHOLD']}');

                  List<dynamic> thresholds = data['THRESHOLD'] ?? []; // Get the list of thresholds

                  return DataCell(
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300), // Prevent excessive width
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: thresholds.map<Widget>((threshold) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warehouse,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            threshold['warehouseName'] ?? 'N/A',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      threshold['thresholdQuantity']?.toString() ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                } else {
                  return DataCell(Text(cellData?.toString() ?? 'N/A'));
                }
              }).toList(),
            );
          }).toList(),
          headingRowHeight: 80,
          dataRowHeight: 100,
          columnSpacing: 55,
          horizontalMargin: 16,
          dataTextStyle: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _showUpdateQuantityDialog(BuildContext context, Map<String, dynamic> data) {
    TextEditingController quantityController = TextEditingController();
    TextEditingController reasonController = TextEditingController();

    quantityController.text = data['QUANTITY'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'New Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(
              width: 5,
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                String newQuantity = quantityController.text;
                String reason = reasonController.text;

                int? parsedQuantity = int.tryParse(newQuantity);
                if (parsedQuantity == null) {
                  print('Invalid quantity entered');
                  return;
                }

                final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

                final prefs = await SharedPreferences.getInstance();
                final warehouseId = prefs.getString('warehouseId') ?? '';

                await inventoryProvider.updateInventoryQuantity(
                  data['inventoryId'],
                  parsedQuantity, // Parsednteger quantity
                  warehouseId, // Warehouse ID (hardcoded)
                  reason, // Reason for the update
                );

                inventoryProvider.notifyListeners(); // This will rebuild the relevant widgets

                data['QUANTITY'] = parsedQuantity;

                print('Updated quantity for ${data['PRODUCT NAME']}: $newQuantity');
                if (reason.isNotEmpty) {
                  print('Reason: $reason');
                }

                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showQuantityDialog(BuildContext context, Map<String, dynamic> data) {
    TextEditingController quantityController = TextEditingController();

    quantityController.text = data['THRESHOLD QUANTITY'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Threshold Qty.'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'New Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(
              width: 5,
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                Navigator.of(context).pop();
                String newQuantity = quantityController.text;

                int? parsedQuantity = int.tryParse(newQuantity);
                if (parsedQuantity == null) {
                  print('Invalid quantity entered');
                  return;
                }

                final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

                await inventoryProvider.updateThresholdQuantity(
                  data['SKU'],
                  parsedQuantity,
                );

                inventoryProvider.notifyListeners(); // This will rebuild the relevant widgets

                data['THRESHOLD QUANTITY'] = parsedQuantity;

                // Close the dialog
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

// Helper Methods
  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildQuantitySection({
    required dynamic previousTotal,
    required dynamic quantityChanged,
    required dynamic newTotal,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildQuantityBox(
            'Previous',
            previousTotal.toString(),
            Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuantityBox(
            'Changed',
            quantityChanged.toString(),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuantityBox(
            'New Total',
            newTotal.toString(),
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required String updatedBy,
    required String source,
    String? reason,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(Icons.person_outline, 'Updated by', updatedBy),
        const SizedBox(height: 8),
        _buildDetailItem(Icons.source_outlined, 'Source', source),
        if (reason != null) ...[
          const SizedBox(height: 8),
          _buildDetailItem(Icons.info_outline, 'Reason', reason),
        ],
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseSection(Map<String, dynamic> warehouse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Warehouse Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          Icons.warehouse_outlined,
          'Warehouse ID',
          warehouse['warehouseId'].toString(),
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          Icons.history,
          'Previous Quantity',
          warehouse['previousQuantity'].toString(),
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          Icons.update,
          'Updated Quantity',
          warehouse['updatedQuantity'].toString(),
        ),
      ],
    );
  }

  (IconData, Color) _getLogTypeDetails(String changeType) {
    switch (changeType) {
      case 'Addition':
        return (Icons.add_circle_outline, Colors.green);
      case 'Subtraction':
        return (Icons.remove_circle_outline, Colors.red);
      default:
        return (Icons.info_outline, Colors.grey.shade700);
    }
  }

  String _formatTimestamp(String timestamp) {
    // Add your timestamp formatting logic here
    return timestamp;
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) async {
    List<dynamic> inventoryLogs = (data['inventoryLogs'] as List?)?.reversed.toList() ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.primaryBlue.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Updated Details\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '${data['PRODUCT NAME']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: inventoryLogs.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: inventoryLogs.length,
                          itemBuilder: (context, index) {
                            final log = inventoryLogs[index];
                            final (icon, iconColor) = _getLogTypeDetails(log['changeType']);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with icon and change type
                                    Row(
                                      children: [
                                        _buildIconBadge(icon, iconColor),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log['changeType'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: iconColor,
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(log['timestamp']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // Quantity changes section
                                    _buildQuantitySection(
                                      previousTotal: log['previousTotal'],
                                      quantityChanged: log['quantityChanged'],
                                      newTotal: log['newTotal'],
                                    ),
                                    const SizedBox(height: 16),

                                    // Details section
                                    _buildDetailsSection(
                                      updatedBy: log['updatedBy'],
                                      source: log['source'],
                                      reason: log['additionalInfo']?['reason'] ?? '',
                                    ),

                                    // Warehouse section if available
                                    if (log['affectedWarehouse'] != null) ...[
                                      const Divider(height: 24),
                                      _buildWarehouseSection(log['affectedWarehouse']),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No inventory logs available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Footer Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 16),
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

class OuterboxDataTable extends StatefulWidget {
  final List<String> columnNames;
  final List<Map<String, dynamic>> rowsData;
  final ScrollController scrollController;

  const OuterboxDataTable({
    super.key,
    required this.columnNames,
    required this.rowsData,
    required this.scrollController,
    // required this.inventoryId,
  });

  @override
  State<OuterboxDataTable> createState() => _OuterboxDataTableState();
}

class _OuterboxDataTableState extends State<OuterboxDataTable> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: widget.scrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
            (states) => AppColors.blueAccent.withValues(alpha: 0.2),
          ),
          columns: widget.columnNames.map((name) {
            return DataColumn(
              label: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            );
          }).toList(),
          rows: widget.rowsData.map((data) {
            // data = boxsize
            return DataRow(
              cells: widget.columnNames.map((columnName) {
                var cellData = data[columnName];

                if (columnName == 'QUANTITY') {
                  return DataCell(
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cellData?.toString() ?? '0', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () {
                                  _showUpdateQuantityDialog(context, data);
                                },
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              final id = data['ID'];
                              if (id != null) {
                                _showDetailsDialog(context, data);
                              } else {
                                log('Outerbox ID not found for the selected item.');
                              }
                            },
                            child: const Text(
                              'View Details',
                              style: TextStyle(color: AppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (columnName == 'DIMENSION') {
                  return DataCell(
                    Text('${cellData['length'] ?? ''} x ${cellData['breadth'] ?? ''} x ${cellData['height'] ?? ''}'),
                  );
                } else if (cellData is Widget) {
                  return DataCell(cellData);
                } else {
                  return DataCell(Text(cellData?.toString() ?? 'N/A'));
                }
              }).toList(),
            );
          }).toList(),
          headingRowHeight: 80,
          dataRowMaxHeight: 100,
          columnSpacing: 100,
          horizontalMargin: 16,
          dataTextStyle: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _showUpdateQuantityDialog(BuildContext context, Map<String, dynamic> data) {
    TextEditingController quantityController = TextEditingController();
    TextEditingController reasonController = TextEditingController();

    quantityController.text = data['QUANTITY'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'New Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              // const SizedBox(height: 16.0),
              // TextField(
              //   controller: reasonController,
              //   decoration: InputDecoration(
              //     labelText: 'Reason',
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8.0),
              //     ),
              //   ),
              //   keyboardType: TextInputType.multiline,
              //   minLines: 2,
              //   maxLines: 3,
              // ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(
              width: 5,
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                String newQuantity = quantityController.text;
                String reason = reasonController.text;

                int? parsedQuantity = int.tryParse(newQuantity);
                if (parsedQuantity == null) {
                  print('Invalid quantity entered');
                  return;
                }

                final pro = Provider.of<OuterboxProvider>(context, listen: false);

                await pro.updateBoxsizeQuantity(
                  data['_id'],
                  parsedQuantity,
                  reason, // Reason for the update
                );

                pro.notifyListeners(); // This will rebuild the relevant widgets

                data['outerPackage_quantity'] = parsedQuantity;

                // print(
                //     'Updated quantity for ${data['PRODUCT NAME']}: $newQuantity');

                Navigator.of(context).pop();
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

// Helper Methods
  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildQuantitySection({
    required dynamic previousTotal,
    required dynamic quantityChanged,
    required dynamic newTotal,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildQuantityBox(
            'Previous',
            previousTotal.toString(),
            Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuantityBox(
            'Changed',
            quantityChanged.toString(),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuantityBox(
            'New Total',
            newTotal.toString(),
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required String updatedBy,
    required String source,
    String? reason,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(Icons.person_outline, 'Updated by', updatedBy),
        const SizedBox(height: 8),
        _buildDetailItem(Icons.source_outlined, 'Source', source),
        if (reason != null) ...[
          const SizedBox(height: 8),
          _buildDetailItem(Icons.info_outline, 'Reason', reason),
        ],
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outerbox Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          Icons.warehouse_outlined,
          'Outerbox ID',
          data['_id'].toString(),
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          Icons.history,
          'Previous Quantity',
          data['previousQuantity'].toString(),
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          Icons.update,
          'New Quantity',
          data['newQuantity'].toString(),
        ),
      ],
    );
  }

  (IconData, Color) _getLogTypeDetails(String changeType) {
    switch (changeType) {
      case 'Addition':
        return (Icons.add_circle_outline, Colors.green);
      case 'Subtraction':
        return (Icons.remove_circle_outline, Colors.red);
      default:
        return (Icons.info_outline, Colors.grey.shade700);
    }
  }

  String _formatTimestamp(String timestamp) {
    // Add your timestamp formatting logic here
    return timestamp;
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) async {
    List<dynamic> logs = (data['LOGS'] as List?)?.reversed.toList() ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.primaryBlue.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Updated Details\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '${data['NAME']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: logs.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final (icon, iconColor) = _getLogTypeDetails(log['changeType']);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with icon and change type
                                    Row(
                                      children: [
                                        _buildIconBadge(icon, iconColor),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log['changeType'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: iconColor,
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(log['timestamp']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),

                                    // Quantity changes section
                                    _buildQuantitySection(
                                      previousTotal: log['previousQuantity'],
                                      quantityChanged: log['quantityChanged'],
                                      newTotal: log['newQuantity'],
                                    ),
                                    const SizedBox(height: 16),

                                    // Details section
                                    _buildDetailsSection(
                                      updatedBy: log['updatedBy'],
                                      source: log['source'],
                                      reason: log['reason']?['reason'],
                                    ),

                                    // Warehouse section if available
                                    // if (log['affectedWarehouse'] != null) ...[
                                    //   const Divider(height: 24),
                                    //   _buildWarehouseSection(
                                    //       log['affectedWarehouse']),
                                    // ],
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No outerbox logs available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Footer Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 16),
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

class LabelValueText extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;

  const LabelValueText({
    super.key,
    required this.label,
    required this.value,
    this.fontSize = 20.0, // Default font size
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: Colors.black, // Customize color as needed
        ),
        children: <TextSpan>[
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: fontSize,
              color: Colors.black, // Customize color as needed
            ),
          ),
        ],
      ),
    );
  }
}
