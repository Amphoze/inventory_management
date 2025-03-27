import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/create_location_form.dart';
import 'Custom-Files/custom_pagination.dart';
import 'provider/location_provider.dart';
import 'Custom-Files/custom-button.dart';
import 'Custom-Files/colors.dart';
import 'Custom-Files/data_table.dart';
import 'Custom-Files/loading_indicator.dart';

class LocationMaster extends StatefulWidget {
  const LocationMaster({super.key});

  @override
  _LocationMasterState createState() => _LocationMasterState();
}

class _LocationMasterState extends State<LocationMaster> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(); // Call _refreshData on initial load
    });
  }

  void _refreshData() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.setLoading(true); // Start loading

    try {
      await locationProvider.fetchWarehouses(); // Fetch data
      print("Warehouses fetched successfully."); // Debugging
    } catch (error) {
      // Handle errors during fetch
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh warehouses'),
          backgroundColor: AppColors.cardsred,
        ),
      );
    } finally {
      locationProvider.setLoading(false); // Ensure loading is stopped
    }
  }

  // Future<void> _deleteWarehouse(
  //     BuildContext context, String warehouseId) async {
  //   final locationProvider =
  //       Provider.of<LocationProvider>(context, listen: false);

  //   locationProvider.setLoading(true);
  //   bool isDeleted =
  //       await locationProvider.deleteWarehouse(context, warehouseId);

  //   if (isDeleted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Warehouse deleted successfully'),
  //         backgroundColor: AppColors.primaryGreen,
  //       ),
  //     );
  //     _refreshData();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Failed to delete warehouse'),
  //         backgroundColor: AppColors.cardsred,
  //       ),
  //     );
  //   }
  //   locationProvider.setLoading(false);
  // }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Fixed sizes for large screens
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
                          warehouseData: locationProvider.warehouseData, // If you want to pass this as a flag, ensure your form handles it
                        )
                      : locationProvider.isCreatingNewLocation
                          ? const NewLocationForm()
                          : _buildMainTable(context), // Display the main table or form
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomPaginationFooter(
        currentPage: locationProvider.currentPage,
        totalPages: locationProvider.totalPages,
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
      ),
    );
  }

  Widget _buildButtonRow(LocationProvider locationProvider, BuildContext context, double buttonWidth, double buttonHeight, double fontSize) {
    return Container(
      width: double.infinity,
      height: 60,
      color: AppColors.primaryGreen,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomButton(
            width: buttonWidth,
            height: buttonHeight,
            onTap: () {
              Provider.of<LocationProvider>(context, listen: false).toggleCreatingNewLocation();
            },
            color: AppColors.white,
            textColor: AppColors.primaryGreen,
            fontSize: fontSize,
            text: 'Create New Location',
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          CustomButton(
            width: buttonWidth,
            height: buttonHeight,
            onTap: () {
              // Implement bulk locations upload functionality here
            },
            color: AppColors.white,
            textColor: AppColors.primaryGreen,
            fontSize: fontSize,
            text: 'Bulk Locations Upload',
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          CustomButton(
            width: buttonWidth * 0.75,
            height: buttonHeight,
            onTap: _refreshData,
            color: AppColors.white,
            textColor: AppColors.primaryGreen,
            fontSize: fontSize,
            text: 'Refresh',
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 300,
            height: 35,
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.white60,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.white,
                    width: 1,
                  ),
                ),
              ),
              onChanged: (value) {
                locationProvider.filterWarehouses(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTable(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

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
              icon: const Icon(Icons.edit, color: AppColors.tealcolor),
              onPressed: () async {
                // Call the fetchWarehouse method using the warehouse ID
                await Provider.of<LocationProvider>(context, listen: false).fetchWarehouseById(warehouse['_id']);

                // Enable editing mode in LocationProvider
                Provider.of<LocationProvider>(context, listen: false).toggleEditingLocation();

                setState(() {});
              },
            ),
            // IconButton(
            //   icon: const Icon(Icons.delete, color: AppColors.cardsred),
            //   onPressed: () => _deleteWarehouse(context, warehouse['_id']),
            // ),
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
                    endColor: AppColors.primaryGreen,
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

void _showDetailsDialog(BuildContext context, Map<String, dynamic> warehouse) {
  final location = warehouse['location'];
  final billingAddress = location is Map<String, dynamic> ? location['billingAddress'] : {};
  final shippingAddress = location is Map<String, dynamic> ? location['shippingAddress'] : {};
  final otherDetails = location is Map<String, dynamic> ? location['otherDetails'] : {};

  String getDisplayValue(dynamic value) {
    return value == null || (value is String && value.isEmpty) ? 'N/A' : value.toString();
  }

  print(warehouse);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: Text('Details for ${getDisplayValue(warehouse['name'])}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListTile(Icons.key, 'Warehouse Key:', getDisplayValue(warehouse['_id'])),
              _buildListTile(Icons.pin_drop, 'Warehouse Pincode:', getDisplayValue(warehouse['warehousePincode'])),
              _buildListTile(Icons.list, 'Pincode List:',
                  getDisplayValue(warehouse['pincode'] is List ? warehouse['pincode'].join(', ') : warehouse['pincode'])),
              const SizedBox(height: 20),
              const Text('Billing Address:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              _buildListTile(Icons.home, 'Address Line 1:', getDisplayValue(billingAddress['addressLine1'])),
              _buildListTile(Icons.home, 'Address Line 2:', getDisplayValue(billingAddress['addressLine2'])),
              _buildListTile(Icons.location_city, 'City:', getDisplayValue(billingAddress['city'])),
              _buildListTile(Icons.location_on, 'State:', getDisplayValue(billingAddress['state'])),
              _buildListTile(Icons.flag, 'Country:', getDisplayValue(billingAddress['country'])),
              _buildListTile(Icons.code, 'Zip Code:', getDisplayValue(billingAddress['zipCode'])),
              _buildListTile(Icons.phone, 'Phone Number:', getDisplayValue(billingAddress['phoneNumber'])),
              const SizedBox(height: 20),
              const Text('Shipping Address:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              _buildListTile(Icons.home, 'Address Line 1:', getDisplayValue(shippingAddress['addressLine1'])),
              _buildListTile(Icons.home, 'Address Line 2:', getDisplayValue(shippingAddress['addressLine2'])),
              _buildListTile(Icons.location_city, 'City:', getDisplayValue(shippingAddress['city'])),
              _buildListTile(Icons.location_on, 'State:', getDisplayValue(shippingAddress['state'])),
              _buildListTile(Icons.flag, 'Country:', getDisplayValue(shippingAddress['country'])),
              _buildListTile(Icons.code, 'Zip Code:', getDisplayValue(shippingAddress['zipCode'])),
              _buildListTile(Icons.phone, 'Phone Number:', getDisplayValue(shippingAddress['phoneNumber'])),
              const SizedBox(height: 20),
              const Text('Other Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              _buildListTile(Icons.assignment, 'Tax Identification Number:', getDisplayValue(otherDetails['taxIdentificationNumber'])),
              const SizedBox(height: 20),
              _buildListTile(
                  Icons.category, 'Location Type:', getDisplayValue(location is Map<String, dynamic> ? location['locationType'] : null)),
              _buildListTile(Icons.check, 'Hold Stocks:',
                  getDisplayValue(location is Map<String, dynamic> ? (location['holdStocks'] ? 'Yes' : 'No') : 'N/A')),
              _buildListTile(Icons.copy, 'Copy Master SKU from Primary:',
                  getDisplayValue(location is Map<String, dynamic> ? (location['copyMasterSkuFromPrimary'] ? 'Yes' : 'No') : 'N/A')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Widget _buildListTile(IconData icon, String title, String value) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
    leading: Icon(icon, color: AppColors.primaryGreen),
    title: Text(title),
    subtitle: Text(value),
  );
}
