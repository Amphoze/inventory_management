import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/dashboard.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/warehouses_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:shimmer/shimmer.dart';

class WarehousesPage extends StatefulWidget {
  const WarehousesPage({super.key});

  @override
  State<WarehousesPage> createState() => _WarehousesPageState();
}

class _WarehousesPageState extends State<WarehousesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    Future.microtask(() =>
        Provider.of<WarehousesProvider>(context, listen: false)
            .fetchWarehouses());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _storeWarehouseId(
      String warehouseId, String warehouseName, bool isPrimary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('warehouseId', warehouseId);
    await prefs.setString('warehouseName', warehouseName);
    await prefs.setBool('isPrimary', isPrimary);

    log('warehouseId: $warehouseId');
    log('warehouseName: $warehouseName');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully signed in to $warehouseName'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.primaryBlue,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            warehouseId: warehouseId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: DesktopTextSelectionControls(),
        child: Stack(
          children: [
            // Simplified background gradient
            // Container(
            //   decoration: const BoxDecoration(
            //     gradient: LinearGradient(
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //       colors: [
            //         AppColors.lightGrey,
            //         AppColors.greyBackground,
            //       ],
            //     ),
            //   ),
            // ),

            // Content
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Simplified header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: const Text(
                      'Warehouse Selection',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),

                  // Main content area
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          elevation: 8,
                          shadowColor: AppColors.shadowblack1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Table header
                              const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warehouse_rounded,
                                      size: 24,
                                      color: AppColors.primaryBlue,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Available Warehouses',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Updated table styles
                              Expanded(
                                child: Consumer<WarehousesProvider>(
                                  builder: (context, provider, child) {
                                    if (provider.isLoading) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: ListView.builder(
                                            itemCount:
                                                5, // Number of shimmer items
                                            itemBuilder: (context, index) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: Container(
                                                        height: 20,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Container(
                                                        height: 20,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Container(
                                                        height: 20,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Container(
                                                        height: 36,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }

                                    return Container(
                                      margin: const EdgeInsets.all(16),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SingleChildScrollView(
                                          child: Table(
                                            columnWidths: const {
                                              0: FlexColumnWidth(2),
                                              1: FlexColumnWidth(2),
                                              2: FlexColumnWidth(2),
                                              3: FlexColumnWidth(1),
                                            },
                                            children: [
                                              TableRow(
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primaryBlue,
                                                ),
                                                children: [
                                                  _buildHeaderCell('ID'),
                                                  _buildHeaderCell('Name'),
                                                  _buildHeaderCell(
                                                      'Warehouse Pincode'),
                                                  _buildHeaderCell('Actions'),
                                                ],
                                              ),
                                              ...provider.warehouses
                                                  .map((warehouse) {
                                                return TableRow(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors
                                                            .grey.shade200,
                                                      ),
                                                    ),
                                                  ),
                                                  children: [
                                                    _buildDataCell(
                                                        warehouse['id']),
                                                    _buildDataCell(
                                                        warehouse['name']),
                                                    _buildDataCell(warehouse[
                                                        'warehousePincode']),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: ElevatedButton(
                                                        onPressed: () =>
                                                            _storeWarehouseId(
                                                                warehouse['id'],
                                                                warehouse[
                                                                    'name'],
                                                                warehouse[
                                                                    'isPrimary']),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              AppColors
                                                                  .primaryBlue,
                                                          foregroundColor:
                                                              AppColors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                            'Sign In'),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simplified header cell
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.white,
        ),
      ),
    );
  }

  // Simplified data cell
  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 14,
        ),
      ),
    );
  }
}
