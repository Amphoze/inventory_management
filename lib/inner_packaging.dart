import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/create_inner.dart';
import 'package:inventory_management/provider/inner_provider.dart';
import 'package:provider/provider.dart';

class ManageInner extends StatefulWidget {
  const ManageInner({super.key});

  @override
  State<ManageInner> createState() => _ManageInnerState();
}

class _ManageInnerState extends State<ManageInner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InnerPackagingProvider>(context, listen: false).fetchAllInnerPackings();
    });
  }

  TextEditingController searchController = TextEditingController();

  final TextEditingController _pageController = TextEditingController();

  void _goToPage(int page) {
    final provider = Provider.of<InnerPackagingProvider>(context, listen: false);
    if (page >= 1 && page <= provider.totalPages) {
      provider.goToPage(page);
    }
  }

  void _jumpToPage() {
    final provider = Provider.of<InnerPackagingProvider>(context, listen: false);
    int page = int.tryParse(_pageController.text) ?? 1;
    if (page >= 1 && page <= provider.totalPages) {
      _goToPage(page - 1); // Go to the user-input page
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = ['SKU', 'Name', 'Quantity', 'Product SKU'];
    return Consumer<InnerPackagingProvider>(
      builder: (context, provider, child) => Scaffold(
        backgroundColor: Colors.white,
        body: provider.innerPackings.isNotEmpty && !provider.isLoading
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            provider.fetchAllInnerPackings();
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            provider.toggleFormVisibility();
                          },
                          child: Text(
                            provider.showInnerPackForm ? 'Back' : 'Create Inner Packing',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (provider.showInnerPackForm) const InnerPackingForm(),
                  const SizedBox(height: 10),
                  if (!provider.showInnerPackForm) ...[
                    Expanded(
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.grey.shade200,
                                  dataTableTheme: DataTableThemeData(
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 15,
                                    ),
                                    dataTextStyle: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.85,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.resolveWith(
                                      (states) => Colors.blue.withValues(alpha: 0.1),
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    columns: columns.map((name) {
                                      return DataColumn(
                                        label: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    rows: provider.innerPackings.map((inner) {
                                      return DataRow(
                                        color: WidgetStateProperty.resolveWith(
                                          (states) => states.contains(WidgetState.hovered) ? Colors.blue.withValues(alpha: 0.05) : null,
                                        ),
                                        cells: [
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Text(
                                                inner['innerPackingSku'] ?? 'N/A',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Text(
                                                inner['name'] ?? 'N/A',
                                                style: TextStyle(
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    inner['quantity']?.toString() ?? '0',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  TextButton(
                                                    onPressed: () => _showDetailsDialog(context, inner),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                                    ),
                                                    child: const Text(
                                                      'View Details',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 8.0,
                                                horizontal: 4.0,
                                              ),
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.2,
                                              ),
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: inner['products'].map<Widget>((product) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.grey.shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      product['productSku'].toString(),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    headingRowHeight: 60,
                                    dataRowHeight: 100,
                                    columnSpacing: 24,
                                    horizontalMargin: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    CustomPaginationFooter(
                      currentPage: provider.currentPage,
                      totalPages: provider.totalPages,
                      totalCount: provider.totalInnerPacking,
                      buttonSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
                      pageController: _pageController,
                      onFirstPage: () => _goToPage(1),
                      onLastPage: () => _goToPage(provider.totalPages),
                      onNextPage: () {
                        if (provider.currentPage - 1 < provider.totalPages) {
                          _goToPage(provider.currentPage + 1);
                        }
                      },
                      onPreviousPage: () {
                        if (provider.currentPage > 1) {
                          _goToPage(provider.currentPage - 1);
                        }
                      },
                      onGoToPage: _goToPage,
                      onJumpToPage: _jumpToPage,
                    ),
                  ],
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) async {
    List<dynamic> labelLogs = data['InnerPackingLog'] ?? [];

    log('labelLogs: $labelLogs');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Updated Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['name']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.grey[100],
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300], thickness: 1.5),
                const SizedBox(height: 16),

                // Enhanced Content Section
                Expanded(
                  child: labelLogs.isNotEmpty
                      ? ListView.builder(
                          itemCount: labelLogs.length,
                          itemBuilder: (context, index) {
                            final log = labelLogs[index];
                            final (icon, iconColor) = _getIconProperties(log['changeType']);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      iconColor.withValues(alpha: 0.05),
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Enhanced Icon Section
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: iconColor.withValues(alpha: 0.15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: iconColor.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        icon,
                                        color: iconColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Enhanced Log Details Section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildEnhancedDetailRow(
                                            'Quantity Changed',
                                            '${log['quantityChanged']}',
                                            Colors.black87,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Previous Quantity',
                                            '${log['previousQuantity']}',
                                            Colors.grey[600]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'New Quantity',
                                            '${log['newQuantity']}',
                                            Colors.blue[700]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Updated By',
                                            '${log['updatedBy']}',
                                            Colors.grey[700]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Source',
                                            '${log['source']}',
                                            Colors.grey[600]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Timestamp',
                                            '${log['timestamp']}',
                                            Colors.grey[500]!,
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
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No label logs available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Enhanced Footer Section
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
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
        );
      },
    );
  }

  (IconData, Color) _getIconProperties(String changeType) {
    switch (changeType) {
      case 'Addition':
        return (Icons.add_circle_outline, Colors.green);
      case 'Subtraction':
        return (Icons.remove_circle_outline, Colors.red);
      default:
        return (Icons.info_outline, Colors.blue);
    }
  }

// Enhanced detail row builder
  Widget _buildEnhancedDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
