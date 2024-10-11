import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/book_page.dart';
import 'package:inventory_management/combo_page.dart';
import 'package:inventory_management/create-label-page.dart';
import 'package:inventory_management/location_master.dart';
import 'package:inventory_management/login_page.dart';
import 'package:inventory_management/manage-inventory.dart';
import 'package:inventory_management/manage_inventory.dart';
import 'package:inventory_management/marketplace_page.dart';
import 'package:inventory_management/order-page.dart';
import 'package:inventory_management/products.dart';
import 'package:inventory_management/category_master.dart';
import 'package:inventory_management/dashboard_cards.dart';
import 'package:inventory_management/checker_page.dart';
import 'package:inventory_management/label_upload.dart';
import 'package:inventory_management/create-label-page.dart';
import 'package:inventory_management/location_master.dart';
import 'package:inventory_management/manage-inventory.dart';
import 'package:inventory_management/manifest_page.dart';
import 'package:inventory_management/marketplace_page.dart';
import 'package:inventory_management/product_upload.dart';
import 'package:inventory_management/packer_page.dart';
import 'package:inventory_management/picker_page.dart';
import 'package:inventory_management/orders_page.dart';
import 'package:inventory_management/products.dart';
import 'package:inventory_management/category_master.dart';
import 'package:inventory_management/dashboard_cards.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:inventory_management/racked_page.dart';
import 'package:inventory_management/show-label-page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Custom-Files/colors.dart';
import 'package:inventory_management/product_manager.dart';

class DashboardPage extends StatefulWidget {
  final String inventoryId;
  const DashboardPage({super.key, required this.inventoryId});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedDrawerItem = 'Dashboard';

  DateTime? lastUpdatedTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void initState() {
    super.initState();
    lastUpdatedTime = DateTime.now();
  }

  void _refreshData() {
    setState(() {
      lastUpdatedTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider =Provider.of<InventoryProvider>(context, listen: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isSmallScreen
              ? SizedBox(
                  width: 220,
                  child: Drawer(
                    child: Container(
                      color: Colors.grey[200],
                      child: _buildDrawerContent(isSmallScreen),
                    ),
                  ),
                )
              : null,
          body: Row(
            children: <Widget>[
              if (!isSmallScreen)
                Container(
                  width: 200,
                  color: AppColors.lightGrey,
                  child: _buildDrawerContent(isSmallScreen),
                ),
              Expanded(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          if (isSmallScreen)
                            IconButton(
                              icon:
                                  const Icon(Icons.menu, color: AppColors.grey),
                              onPressed: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildMainContent(
                            selectedDrawerItem, isSmallScreen),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerContent(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image(
                  fit: BoxFit.cover,
                  image: const AssetImage('assets/homeLogo.png'),
                ), // const Padding(
                //   padding: EdgeInsets.all(20.0),
                //   child: Text(
                //     'StockShip',
                //     style: TextStyle(
                //       fontSize: 27,
                //       fontWeight: FontWeight.bold,
                //       color: AppColors.primaryBlue,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  isSelected: selectedDrawerItem == 'Dashboard',
                  onTap: () => _onDrawerItemTapped('Dashboard', isSmallScreen),
                ),
                _buildOrdersSection(isSmallScreen),
                _buildInventorySection(isSmallScreen),
                _buildMasterSection(isSmallScreen),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  text: 'Accounting',
                  isSelected: selectedDrawerItem == 'Accounting',
                  onTap: () => _onDrawerItemTapped('Accounting', isSmallScreen),
                ),
                _buildDrawerItem(
                  icon: Icons.upload_file,
                  text: 'Upload Products',
                  isSelected: selectedDrawerItem == 'Upload Products',
                  onTap: () =>
                      _onDrawerItemTapped('Upload Products', isSmallScreen),
                ),
                _buildDrawerItem(
                  icon: Icons.new_label,
                  text: 'Upload Labels',
                  isSelected: selectedDrawerItem == 'Upload Labels',
                  onTap: () =>
                      _onDrawerItemTapped('Upload Labels', isSmallScreen),
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  isSelected: selectedDrawerItem == 'Logout',
                  onTap: () async {
                    try {
                      SharedPreferences _pref =
                          await SharedPreferences.getInstance();
                      bool cleared = await _pref.clear();

                      if (cleared) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logout successful!'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Could not clear session.'),
                            backgroundColor: AppColors.cardsred,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('An error occurred during logout.'),
                          backgroundColor: AppColors.cardsred,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
         collapsedBackgroundColor:["Orders Page","Book Page","Picker Page","Packer Page","Checker Page","Racked Page","Manifest Page"].contains(selectedDrawerItem)?Colors.blue.withOpacity(0.2):AppColors.white,
        title: Text(
          'Orders',
          style: TextStyle(
            color: selectedDrawerItem == 'Orders'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.shopping_cart,
          color: selectedDrawerItem == 'Orders'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Orders'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.assignment_rounded,
              text: 'Orders',
              isSelected: selectedDrawerItem == 'Orders Page',
              onTap: () => _onDrawerItemTapped('Orders Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.menu_book,
              text: 'Book',
              isSelected: selectedDrawerItem == 'Book Page',
              onTap: () => _onDrawerItemTapped('Book Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.local_shipping,
              text: 'Picker',
              isSelected: selectedDrawerItem == 'Picker Page',
              onTap: () => _onDrawerItemTapped('Picker Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.backpack_rounded,
              text: 'Packer',
              isSelected: selectedDrawerItem == 'Packer Page',
              onTap: () => _onDrawerItemTapped('Packer Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.check_circle,
              text: 'Checker',
              isSelected: selectedDrawerItem == 'Checker Page',
              onTap: () => _onDrawerItemTapped('Checker Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.shelves,
              text: 'Racked',
              isSelected: selectedDrawerItem == 'Racked Page',
              onTap: () => _onDrawerItemTapped('Racked Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.star_border,
              text: 'Manifest',
              isSelected: selectedDrawerItem == 'Manifest Page',
              onTap: () => _onDrawerItemTapped('Manifest Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
         collapsedBackgroundColor:["Manage Inventory"].contains(selectedDrawerItem)?Colors.blue.withOpacity(0.2):AppColors.white,
        title: Text(
          'Inventory',
          style: TextStyle(
            color: selectedDrawerItem == 'Inventory'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.inventory,
          color: selectedDrawerItem == 'Inventory'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Inventory'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.production_quantity_limits,
              text: 'Manage Inventory',
              isSelected: selectedDrawerItem == 'Manage Inventory',
              onTap: () =>
                  _onDrawerItemTapped('Manage Inventory', isSmallScreen),
              isIndented: true, // Pass the indentation flag
              iconSize: 20, // Adjust icon size
              fontSize: 14, // Adjust font size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor:["Label Page","Create Label Page","Product Master","Category Master","Combo Master","Marketplace Master","Location Master"].contains(selectedDrawerItem)?Colors.blue.withOpacity(0.2):AppColors.white,
        
        
        title: Text(
          'Master',
          style: TextStyle(
            color: selectedDrawerItem == 'Master'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.pages,
          color: selectedDrawerItem == 'Master'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Master'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.label_important,
              text: 'Label Master',
              isSelected: selectedDrawerItem == 'Label Page',
              onTap: () => _onDrawerItemTapped('Label Page', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(left: 10.0),
          //   child: _buildDrawerItem(
          //     icon: Icons.production_quantity_limits,
          //     text: 'Create Label Page',
          //     isSelected: selectedDrawerItem == 'Create Label Page',
          //     onTap: () =>
          //         _onDrawerItemTapped('Create Label Page', isSmallScreen),
          //     isIndented: true,
          //     iconSize: 20,
          //     fontSize: 14,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.production_quantity_limits,
              text: 'Product Master',
              isSelected: selectedDrawerItem == 'Product Master',
              onTap: () => _onDrawerItemTapped('Product Master', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.category,
              text: 'Category Master',
              isSelected: selectedDrawerItem == 'Category Master',
              onTap: () =>
                  _onDrawerItemTapped('Category Master', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.list,
              text: 'Combo Master',
              isSelected: selectedDrawerItem == 'Combo Master',
              onTap: () => _onDrawerItemTapped('Combo Master', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.add_business,
              text: 'Marketplace Master',
              isSelected: selectedDrawerItem == 'Marketplace Master',
              onTap: () =>
                  _onDrawerItemTapped('Marketplace Master', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.warehouse,
              text: 'Location Master',
              isSelected: selectedDrawerItem == 'Location Master',
              onTap: () =>
                  _onDrawerItemTapped('Location Master', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _onDrawerItemTapped(String item, bool isSmallScreen) {
    setState(() {
      selectedDrawerItem = item;
      if (isSmallScreen) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    bool isIndented = false,
    double iconSize = 24,
    double fontSize = 16,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: isIndented ? 32.0 : 8.0),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryBlueLight,
                    AppColors.primaryBlue,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          leading: Icon(
            icon,
            color: isSelected ? AppColors.white : AppColors.primaryBlue,
            size: iconSize,
          ),
          title: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.primaryBlue,
              fontSize: fontSize,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildMainContent(String selectedDrawerItem, bool isSmallScreen) {
    final provider =Provider.of<InventoryProvider>(context, listen: false);
    switch (selectedDrawerItem) {
      case 'Dashboard':
        // return Products();
        return _buildDashboardContent(isSmallScreen);
      case 'Sales Orders':
        return const Center(child: Text("Sales Orders content goes here"));
      case 'Inventory':
        return const Center(child: Text("Inventory content goes here"));
      case 'Products':
        return const Products();
      case 'Manage Inventory':
        return const ManageInventoryPage();
      case 'Orders Page':
        return const OrdersNewPage();
      case 'Book Page':
        return const BookPage();
      case 'Picker Page':
        return const PickerPage();
      case 'Packer Page':
        return const PackerPage();
      case 'Checker Page':
        return const CheckerPage();
      case 'Racked Page':
        return const RackedPage();
      case 'Manifest Page':
        return const ManifestPage();
      case 'Product Master':
        return const ProductDashboardPage();
      case 'Create Label Page':
        return const CreateLabelPage();
      case 'Label Page':
        return const LabelPage();
      case 'Category Master':
        return CategoryMasterPage();
      case 'Combo Master':
        return const ComboPage();
      case 'Location Master':
        return const LocationMaster();
      case 'Marketplace Master':
        return const MarketplacePage();
      case 'Accounting':
        return const Center(child: Text("Accounting content goes here"));
      case 'Upload Products':
        return const ProductDataDisplay();
      case 'Upload Labels':
        return const LabelUpload();

      default:
        return const Center(child: Text("Select a menu item"));
    }
  }

  Widget _buildDashboardContent(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Hello, Saksham',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 10),
          const Text(
            "Here's what's happening with your store today",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 20),
          const DashboardCards(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Last updated: ${lastUpdatedTime != null ? DateFormat('hh:mm a').format(lastUpdatedTime!) : 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
