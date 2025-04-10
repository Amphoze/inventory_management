import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/create_location_form.dart';
import 'Custom-Files/custom_pagination.dart';
import 'provider/warehouse_provider.dart';
import 'Custom-Files/custom-button.dart';
import 'Custom-Files/colors.dart';
import 'Custom-Files/data_table.dart';
import 'Custom-Files/loading_indicator.dart';

class WarehouseMaster extends StatefulWidget {
  const WarehouseMaster({super.key});

  @override
  _WarehouseMasterState createState() => _WarehouseMasterState();
}

class _WarehouseMasterState extends State<WarehouseMaster> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(); // Call _refreshData on initial load
    });
  }

  void _refreshData() async {
    final locationProvider = Provider.of<WarehouseProvider>(context, listen: false);
    locationProvider.setLoading(true); // Start loading

    try {
      await locationProvider.fetchWarehouses(); // Fetch data
      print("Warehouses fetched successfully."); // Debugging
    } catch (error) {
      Utils.showSnackBar(context, 'Failed to refresh warehouses', isError: true);
    } finally {
      locationProvider.setLoading(false); // Ensure loading is stopped
    }
  }

  Future<void> _deleteWarehouse(BuildContext context, String warehouseId, String warehouseName) async {
    final locationProvider = Provider.of<WarehouseProvider>(context, listen: false);

    locationProvider.setLoading(true);
    bool isDeleted = await locationProvider.deleteWarehouse(context, warehouseId);

    if (isDeleted) {
      Utils.showSnackBar(context, '$warehouseName deleted successfully', color: AppColors.primaryBlue);
      _refreshData();
    } else {
      Utils.showSnackBar(context, 'Failed to delete $warehouseName', isError: true);
    }
    locationProvider.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<WarehouseProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // // Fixed sizes for large screens
    const fixedButtonWidth = 160.0;
    const fixedButtonHeight = 30.0;
    const fixedFontSize = 13.0;

    // Responsive sizes for smaller screens
    final buttonWidth = screenWidth < 600 ? screenWidth * 0.3 : fixedButtonWidth;
    final buttonHeight = screenWidth < 600 ? 30.0 : fixedButtonHeight;
    final fontSize = screenWidth < 600 ? 12.0 : fixedFontSize;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          if (!locationProvider.isCreatingNewLocation && !locationProvider.isEditingLocation)
            _buildButtonRow(locationProvider, context, buttonWidth, buttonHeight, fontSize),
          // const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  locationProvider.isEditingLocation
                      ? NewLocationForm(
                          isEditing: true,
                          warehouseData: locationProvider
                              .warehouseData, // If you want to pass this as a flag, ensure your form handles it
                        )
                      : locationProvider.isCreatingNewLocation
                          ? const NewLocationForm()
                          : _buildMainTable(context), // Display the main table or form
                ],
              ),
            ),
          ),
          if (!locationProvider.isCreatingNewLocation && !locationProvider.isEditingLocation)
            Consumer<WarehouseProvider>(
              builder: (context, locationProvider, child) {
                return CustomPaginationFooter(
                  currentPage: locationProvider.currentPage,
                  totalPages: locationProvider.totalPages,
                  totalCount: locationProvider.totalWarehouses,
                  buttonSize: 30,
                  pageController: locationProvider.textEditingController,
                  onFirstPage: () {
                    locationProvider.goToPage(1);
                  },
                  onLastPage: () {
                    locationProvider.goToPage(locationProvider.totalPages);
                  },
                  onNextPage: () {
                    if (locationProvider.currentPage < locationProvider.totalPages) {
                      locationProvider.goToPage(locationProvider.currentPage + 1);
                    }
                  },
                  onPreviousPage: () {
                    if (locationProvider.currentPage > 1) {
                      locationProvider.goToPage(locationProvider.currentPage - 1);
                    }
                  },
                  onGoToPage: (page) {
                    locationProvider.goToPage(page);
                  },
                  onJumpToPage: () {
                    final page = int.tryParse(locationProvider.textEditingController.text);
                    if (page != null && page > 0 && page <= locationProvider.totalPages) {
                      locationProvider.goToPage(page);
                    }
                  },
                );
              }
            )
        ],
      ),
    );
  }

  Widget _buildButtonRow(WarehouseProvider locationProvider, BuildContext context, double buttonWidth,
      double buttonHeight, double fontSize) {
    return Container(
      width: double.infinity,
      // height: 60,
      // color: AppColors.primaryBlue,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // const SizedBox(width: 16),
          // CustomButton(
          //   width: buttonWidth,
          //   height: buttonHeight,
          //   onTap: () {
          //     // Implement bulk locations upload functionality here
          //   },
          //   color: AppColors.white,
          //   textColor: AppColors.primaryBlue,
          //   fontSize: fontSize,
          //   text: 'Bulk Locations Upload',
          //   borderRadius: BorderRadius.circular(8),
          // ),
          SizedBox(
            width: 300,
            height: 35,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search Warehouse',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                locationProvider.filterWarehouses(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
          ),
          // CustomButton(
          //   width: buttonWidth * 0.75,
          //   height: buttonHeight,
          //   onTap: _refreshData,
          //   color: AppColors.white,
          //   textColor: AppColors.primaryBlue,
          //   fontSize: fontSize,
          //   text: 'Refresh',
          //   borderRadius: BorderRadius.circular(8),
          // ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => Provider.of<WarehouseProvider>(context, listen: false).toggleCreatingNewLocation(),
            child: const Text('Create Warehouse'),
          ),
          // CustomButton(
          //   width: 180,
          //   height: 30,
          //   onTap: () {},
          //   color: AppColors.white,
          //   textColor: AppColors.primaryBlue,
          //   fontSize: fontSize,
          //   text: 'Create New Warehouse',
          //   borderRadius: BorderRadius.circular(8),
          // ),
        ],
      ),
    );
  }

  Widget _buildMainTable(BuildContext context) {
    final locationProvider = Provider.of<WarehouseProvider>(context);

    // Column names including delete action
    final columnNames = [
      'Warehouse Name',
      'Warehouse Key',
      'Location',
      'Warehouse Pincode',
      'Pincodes',
      'Actions', // New column for delete and update actions
    ];

    // Rows data
    final rowsData = locationProvider.warehouses.map((warehouse) {
      String location;
      if (warehouse['location'] is String) {
        location = warehouse['location'];
      } else if (warehouse['location'] is Map) {
        // Extract from billingAddress
        final billingAddress = warehouse['location']['billingAddress'];
        final country = billingAddress['country'] ?? 'N/A';
        final state = billingAddress['state'] ?? 'N/A';
        final city = billingAddress['city'] ?? 'N/A';
        location = '$city, $state, $country';
      } else {
        location = 'N/A';
      }
      String pincodeList;
      if (warehouse['pincode'] is List) {
        pincodeList = warehouse['pincode'].join(', ');
      } else if (warehouse['pincode'] is String) {
        pincodeList = warehouse['pincode'];
      } else {
        pincodeList = 'N/A';
      }

      return {
        'Warehouse Name': warehouse['name'] ?? 'N/A',
        'Warehouse Key': warehouse['_id'] ?? 'N/A',
        'Location': location,
        'Warehouse Pincode': warehouse['warehousePincode'] ?? 'N/A',
        'Pincodes': pincodeList,
        'Actions': Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
              onPressed: () async {
                // Call the fetchWarehouse method using the warehouse ID
                await Provider.of<WarehouseProvider>(context, listen: false).fetchWarehouseById(warehouse['_id']);

                // Enable editing mode in LocationProvider
                Provider.of<WarehouseProvider>(context, listen: false).toggleEditingLocation();

                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.cardsred),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Warehouse'),
                        content: const Text('Are you sure you want to delete this warehouse?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteWarehouse(context, warehouse['_id'] ?? '', warehouse['name'] ?? '');
                              Navigator.pop(context);
                              setState(() {});
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
      };
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          locationProvider.isLoading
              ? const Center(
                  child: LoadingAnimation(
                    icon: Icons.warehouse_outlined,
                    beginColor: Color.fromRGBO(189, 189, 189, 1),
                    endColor: AppColors.primaryBlue,
                    size: 80.0,
                  ),
                )
              : CustomDataTable(
                  columnNames: columnNames,
                  rowsData: rowsData,
                ),
        ],
      ),
    );
  }
}
