import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:provider/provider.dart';

import '../Api/auth_provider.dart';
import '../provider/warehouse_provider.dart';

class SwitchWarehouse extends StatefulWidget {
  const SwitchWarehouse({super.key});

  @override
  State<SwitchWarehouse> createState() => _SwitchWarehouseState();
}

class _SwitchWarehouseState extends State<SwitchWarehouse> {
  String? selectedWarehouse;
  bool _isSaving = false;

  Future<String?> getWarehouse() async {
    final authProvider = context.read<AuthProvider>();
    final warehouseName = await authProvider.getWarehouseName();
    return warehouseName?.isNotEmpty == true ? warehouseName : null;
  }

  void _showWarehouseSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer<WarehouseProvider>(builder: (context, pro, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Select Warehouse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pro.warehouses.length,
                    itemBuilder: (context, index) {
                      final warehouse = pro.warehouses[index];
                      final isSelected = warehouse['name'] == selectedWarehouse;

                      return InkWell(
                        onTap: _isSaving
                            ? null
                            : () async {
                                Navigator.pop(context);
                                final newWarehouseName = warehouse['name'] ?? '';
                                final oldWarehouseName = selectedWarehouse;
                                setState(() {
                                  selectedWarehouse = newWarehouseName;
                                  _isSaving = true;
                                });
                                try {
                                  await pro.saveWarehouseData(
                                    context,
                                    warehouse['_id'] ?? '',
                                    newWarehouseName,
                                    warehouse['isPrimary'] ?? false,
                                  );
                                  log('Warehouse ID: ${warehouse['_id']}');
                                } catch (e) {
                                  setState(() {
                                    selectedWarehouse = oldWarehouseName; // Rollback on error
                                  });
                                  Utils.showSnackBar(context, 'Failed to save warehouse: $e', isError: true);
                                } finally {
                                  setState(() {
                                    _isSaving = false;
                                  });
                                }
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      warehouse['name'] ?? '',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    if (warehouse['isPrimary'] ?? false)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Primary',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                CustomPaginationFooter(
                  toShowGoToPageField: false,
                  currentPage: pro.currentPage,
                  totalPages: pro.totalPages,
                  buttonSize: 30,
                  totalCount: pro.totalWarehouses,
                  pageController: pro.textEditingController,
                  onFirstPage: () => pro.goToPage(1),
                  onLastPage: () => pro.goToPage(pro.totalPages),
                  onNextPage: () => pro.currentPage < pro.totalPages ? pro.goToPage(pro.currentPage + 1) : null,
                  onPreviousPage: () => pro.currentPage > 1 ? pro.goToPage(pro.currentPage - 1) : null,
                  onGoToPage: (page) => pro.goToPage(page),
                  onJumpToPage: () {
                    final page = int.tryParse(pro.textEditingController.text);
                    if (page != null && page > 0 && page <= pro.totalPages) {
                      pro.goToPage(page);
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getWarehouse(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          log('Error fetching warehouse: ${snapshot.error}');
          selectedWarehouse = null;
        } else {
          selectedWarehouse = snapshot.data;
        }
        return SizedBox(
          width: 200,
          child: Tooltip(
            message: 'Switch Warehouse',
            child: InkWell(
              onTap: _isSaving ? null : () => _showWarehouseSelector(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedWarehouse ?? 'Select Warehouse',
                        style: TextStyle(
                          color: selectedWarehouse != null ? Colors.black87 : Colors.black54,
                          fontWeight: selectedWarehouse != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.business,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
