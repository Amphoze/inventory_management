import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:provider/provider.dart';
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
            (states) => AppColors.green.withOpacity(0.2),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

// Inventory Data Table
class InventoryDataTable extends StatefulWidget {
  final List<String> columnNames;
  final List<Map<String, dynamic>> rowsData;
  final ScrollController scrollController;
  // final String inventoryId;

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
            (states) => AppColors.green.withOpacity(0.2),
          ),
          columns: widget.columnNames.map((name) {
            if (name == 'ACTIONS') {
              return DataColumn(
                label: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        print('Save All clicked');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text('Save All'),
                    ),
                  ],
                ),
              );
            } else {
              return DataColumn(
                label: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              );
            }
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
                } else if (columnName == 'ACTIONS') {
                  return DataCell(
                    ElevatedButton(
                      onPressed: () {
                        print('Save clicked for: ${data['PRODUCT NAME']}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text('Save'),
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
                              Text(cellData?.toString() ?? '0',
                                  style: const TextStyle(fontSize: 16)),
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
                                // Check if inventoryId exists

                                _showDetailsDialog(context, data);
                                //_showDetailsDialog(context, inventoryId);
                              } else {
                                print(
                                    'Inventory ID not found for the selected item.');
                              }
                            },
                            child: const Text(
                              'View Details',
                              style: TextStyle(color: AppColors.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
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
          dataRowHeight: 100,
          columnSpacing: 55,
          horizontalMargin: 16,
          dataTextStyle: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _showUpdateQuantityDialog(
      BuildContext context, Map<String, dynamic> data) {
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
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
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

                final inventoryProvider =
                    Provider.of<InventoryProvider>(context, listen: false);

                await inventoryProvider.updateInventoryQuantity(
                  data['inventoryId'],
                  parsedQuantity, // Parsednteger quantity
                  '66fceb5163c6d5c106cfa809', // Warehouse ID (hardcoded)
                  reason, // Reason for the update
                );

                inventoryProvider
                    .notifyListeners(); // This will rebuild the relevant widgets

                data['QUANTITY'] = parsedQuantity;

                print(
                    'Updated quantity for ${data['PRODUCT NAME']}: $newQuantity');
                if (reason.isNotEmpty) {
                  print('Reason: $reason');
                }

                // Close the dialog
                Navigator.of(context).pop();
              },
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDetailsDialog(
      BuildContext context, Map<String, dynamic> data) async {
    List<dynamic> inventoryLogs = data['inventoryLogs'] ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // Wider dialog
            height: MediaQuery.of(context).size.height * 0.7, // Taller dialog
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Updated Details: ',
                              // style: TextStyle(
                              //   color: AppColors.primaryBlue,
                              // ),
                            ),
                            TextSpan(
                              text: '${data['PRODUCT NAME']}',
                              style: const TextStyle(
                                  // color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.normal),
                            )
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // child: Text(
                      //   'Updated Details: ${data['PRODUCT NAME']}',
                      //   style: const TextStyle(
                      //     fontSize: 22,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),

                // Content Section
                Expanded(
                  child: inventoryLogs.isNotEmpty
                      ? ListView.builder(
                          itemCount: inventoryLogs.length,
                          itemBuilder: (context, index) {
                            final log = inventoryLogs[index];
                            IconData icon;
                            Color iconColor;

                            if (log['changeType'] == 'Addition') {
                              icon = Icons.add;
                              iconColor = Colors.green;
                            } else if (log['changeType'] == 'Subtraction') {
                              icon = Icons.remove;
                              iconColor = Colors.red;
                            } else {
                              icon = Icons.info;
                              iconColor = Colors.grey;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Icon Section
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: iconColor.withOpacity(0.2),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        icon,
                                        color: iconColor,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Log Details Section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                            'Quantity Changed:',
                                            '${log['quantityChanged']}',
                                          ),
                                          _buildDetailRow(
                                            'Previous Total:',
                                            '${log['previousTotal']}',
                                          ),
                                          _buildDetailRow(
                                            'New Total:',
                                            '${log['newTotal']}',
                                          ),
                                          _buildDetailRow(
                                            'Updated By:',
                                            '${log['updatedBy']}',
                                          ),
                                          _buildDetailRow(
                                            'Source:',
                                            '${log['source']}',
                                          ),
                                          _buildDetailRow(
                                            'Timestamp:',
                                            '${log['timestamp']}',
                                          ),
                                          if (log['additionalInfo'] != null &&
                                              log['additionalInfo']['reason'] !=
                                                  null)
                                            _buildDetailRow(
                                              'Reason:',
                                              '${log['additionalInfo']['reason']}',
                                            ),
                                          if (log['affectedWarehouse'] != null)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Affected Warehouse:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                _buildDetailRow(
                                                  'Warehouse ID:',
                                                  '${log['affectedWarehouse']['warehouseId']}',
                                                ),
                                                _buildDetailRow(
                                                  'Previous Quantity:',
                                                  '${log['affectedWarehouse']['previousQuantity']}',
                                                ),
                                                _buildDetailRow(
                                                  'Updated Quantity:',
                                                  '${log['affectedWarehouse']['updatedQuantity']}',
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'No inventory logs available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),

                // Footer Section
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

// Helper Widget for Detail Rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _showDetailsDialog(BuildContext context, String inventoryId) async {
  //   final inventoryProvider = Provider.of<InventoryProvider>(context,listen: false);
  //
  //   await inventoryProvider.fetchInventoryById(inventoryId);
  //   inventoryProvider
  //       .notifyListeners();
  //
  //   final item = inventoryProvider.inventory.firstWhere(
  //         (element) => element['inventoryId'] == inventoryId,
  //     //orElse: () => null,
  //   );
  //
  //   if (item == null) {
  //     print('Inventory item not found');
  //     return;  // Exit if no item found
  //   }
  //
  //   // Extract and cast inventory logs
  //   List<dynamic> inventoryLogs = [];
  //   if (item['inventoryLogs'] is List) {
  //     inventoryLogs = item['inventoryLogs'] as List<dynamic>;  // Safe cast
  //   }
  //
  //
  //   // Display data in dialog
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Column(
  //           children: [
  //             Container(
  //               height: 30,
  //               width: 100,
  //               child: Text(
  //                 'Updated Details ${item['PRODUCT NAME'] ?? 'Unknown Product'}',
  //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Container(
  //           width: 500,  // Set width to maximum available
  //           constraints: BoxConstraints(
  //             maxHeight: MediaQuery.of(context).size.height * 0.4,  // Max height of 40% of screen
  //           ),
  //           child: SingleChildScrollView(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Inventory Logs:',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 10),
  //
  //                 // Check if there are any logs and render them
  //                 if (inventoryLogs.isNotEmpty)
  //                   Column(
  //                     children: inventoryLogs.map((log) {
  //                       // Handle log display here
  //                       IconData icon;
  //                       Color iconColor;
  //                       double size = 30;
  //
  //                       if (log['changeType'] == 'Addition') {
  //                         icon = Icons.add;
  //                         iconColor = Colors.green;
  //                       } else if (log['changeType'] == 'Subtraction') {
  //                         icon = Icons.remove;
  //                         iconColor = Colors.red;
  //                       } else {
  //                         icon = Icons.info;
  //                         iconColor = Colors.grey;
  //                       }
  //
  //                       return Card(
  //                         margin: const EdgeInsets.symmetric(vertical: 8),
  //                         elevation: 2,
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(8.0),
  //                           child: Row(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     LabelValueText(
  //                                       label: 'Quantity Changed: ',
  //                                       value: '${log['quantityChanged']}',
  //                                     ),
  //                                     // Additional fields
  //                                   ],
  //                                 ),
  //                               ),
  //                               Icon(icon, color: iconColor, size: size),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }).toList(),
  //                   )
  //                 else
  //                   const Center(child: Text('No inventory logs available')),
  //               ],
  //             ),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('Close', style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
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
