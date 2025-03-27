import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/accounts_page.dart';
import 'package:inventory_management/invoiced_orders.dart';
import 'package:inventory_management/all_orders_page.dart';
import 'package:inventory_management/ba_approve_page.dart';
import 'package:inventory_management/bin_master.dart';
import 'package:inventory_management/book_orders_by_csv.dart';
import 'package:inventory_management/book_page.dart';
import 'package:inventory_management/booked_page.dart';
import 'package:inventory_management/cancelled_orders.dart';
import 'package:inventory_management/category_master.dart';
import 'package:inventory_management/checker_page.dart';
import 'package:inventory_management/combo_page.dart';
import 'package:inventory_management/combo_upload.dart';
import 'package:inventory_management/confirm_orders.dart';
import 'package:inventory_management/confirm_outbound_by_csv.dart';
import 'package:inventory_management/create-label-page.dart';
import 'package:inventory_management/create_account.dart';
import 'package:inventory_management/create_invoice_by_csv.dart';
import 'package:inventory_management/create_order.dart';
import 'package:inventory_management/create_orders_by_csv.dart';
import 'package:inventory_management/dashboard_cards.dart';
import 'package:inventory_management/dispatch_order.dart';
import 'package:inventory_management/download_orders.dart';
import 'package:inventory_management/inner_packaging.dart';
import 'package:inventory_management/inventory_upload.dart';
import 'package:inventory_management/invoice_page.dart';
import 'package:inventory_management/label_upload.dart';
import 'package:inventory_management/location_master.dart';
import 'package:inventory_management/login_page.dart';
import 'package:inventory_management/manage_inventory.dart';
import 'package:inventory_management/manage_label_page.dart';
import 'package:inventory_management/manage_outerbox.dart';
import 'package:inventory_management/manifest_page.dart';
import 'package:inventory_management/manifested_orders.dart';
import 'package:inventory_management/marketplace_page.dart';
import 'package:inventory_management/merge_orders_by_csv.dart';
import 'package:inventory_management/orders_page.dart';
import 'package:inventory_management/outbound_page.dart';
import 'package:inventory_management/packer_page.dart';
import 'package:inventory_management/picker_page.dart';
import 'package:inventory_management/planning.dart';
import 'package:inventory_management/product_master.dart';
import 'package:inventory_management/product_upload.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/provider/label_in_out.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/racked_page.dart';
import 'package:inventory_management/reordering_page.dart';
import 'package:inventory_management/return_entry.dart';
import 'package:inventory_management/return_orders.dart';
import 'package:inventory_management/routing_page.dart';
import 'package:inventory_management/show-label-page.dart';
import 'package:inventory_management/stockship_version_control/crm_updated_date_widget.dart';
import 'package:inventory_management/support_page.dart';
import 'package:inventory_management/threshold_upload.dart';
import 'package:inventory_management/transfer_order.dart';
import 'package:inventory_management/upload_inner.dart';
import 'package:inventory_management/upload_marketplace_sku.dart';
import 'package:inventory_management/upload_warehouse.dart';
import 'package:inventory_management/uploadproduct-quantity.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/switch_warehouse.dart';
import 'check_orders/check_orders_page.dart';

class DashboardPage extends StatefulWidget {
  final String warehouseId;

  const DashboardPage({super.key, required this.warehouseId});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedDrawerItem = 'Dashboard';
  DateTime? selectedDate; // State variable to hold the selected date
  DateTime? lastUpdatedTime; // Make sure this is initialized properly in your actual code
  DateTime? previousDate;
  // bool isCreateOrderPage = false;
  // String? selectedWarehouse;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, String>> statuses = [];
  List<String> temp = [];

  @override
  void initState() {
    super.initState();
    lastUpdatedTime = DateTime.now();
    // getWarehouse();
    _fetchUserRole();
    _loadSelectedDrawerItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      context.read<LocationProvider>().fetchWarehouses();
      context.read<MarketplaceProvider>().fetchMarketplaces();
    });
  }

  // void getWarehouse() async {
  //   selectedWarehouse = await context.read<AuthProvider>().getWarehouseName();
  //   log('Warehouse ID: $selectedWarehouse');
  // }

  String sanitizeEmail(String email) {
    return email.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  Future<void> call() async {
    final prefs = await SharedPreferences.getInstance();

    String? email = prefs.getString('email');
    String sanitizedEmail = sanitizeEmail(email!);

    await FirebaseMessaging.instance.subscribeToTopic(sanitizedEmail);
  }

  Future<void> _fetchData() async {
    await context.read<MarketplaceProvider>().fetchMarketplaces();
  }

  void _loadSelectedDrawerItem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedDrawerItem = prefs.getString('selectedDrawerItem') ?? 'Dashboard';
    });
  }

  void _saveSelectedDrawerItem(String item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedDrawerItem', item);
  }

  bool? isSuperAdmin;
  bool? isAdmin;
  bool? isConfirmer;
  bool? isBooker;
  bool? isAccounts;
  bool? isPicker;
  bool? isPacker;
  bool? isChecker;
  bool? isRacker;
  bool? isManifest;
  bool? isOutbound;
  bool? isSupport;
  bool? isCreateOrder;
  bool? isGGV;
  String? userName;

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
      isAdmin = prefs.getBool('_isAdminAssigned');
      isConfirmer = prefs.getBool('_isConfirmerAssigned');
      isBooker = prefs.getBool('_isBookerAssigned');
      isAccounts = prefs.getBool('_isAccountsAssigned');
      isPicker = prefs.getBool('_isPickerAssigned');
      isPacker = prefs.getBool('_isPackerAssigned');
      isChecker = prefs.getBool('_isCheckerAssigned');
      isRacker = prefs.getBool('_isRackerAssigned');
      isManifest = prefs.getBool('_isManifestAssigned');
      isOutbound = prefs.getBool('_isOutboundAssigned');
      isSupport = prefs.getBool('_isSupportAssigned');
      isCreateOrder = prefs.getBool('_isCreateOrderAssigned');
      isGGV = prefs.getBool('_isGGVAssigned');
      userName = prefs.getString('userName');
    });
  }

  void _refreshData() {
    setState(() {
      lastUpdatedTime = DateTime.now();
    });
  }

  Future<bool> clearLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // List of keys to remove
    List<String> keys = [
      'warehouseId',
      'warehouseName',
      'isPrimary',
      '_isSuperAdminAssigned',
      '_isAdminAssigned',
      '_isConfirmerAssigned',
      '_isBookerAssigned',
      '_isAccountsAssigned',
      '_isPickerAssigned',
      '_isPackerAssigned',
      '_isCheckerAssigned',
      '_isRackerAssigned',
      '_isManifestAssigned',
      '_isOutboundAssigned',
      '_isSupportAssigned',
      '_isCreateOrderAssigned',
      '_isGGVAssigned',
      'userName',
      'selectedDrawerItem',
      'authToken',
      'date',
      'email',
      'password',
      'combos',
    ];

    // Flag to track removal status
    bool allRemoved = true;

    // Attempt to remove each key
    for (String key in keys) {
      bool removed = await prefs.remove(key);
      if (!removed) {
        allRemoved = false;
      }
    }

    return allRemoved;
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: LayoutBuilder(
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
            // appBar: AppBar(
            //   actions: [
            //     Text('hi')
            //   ]
            // ),
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
                        Row(
                          children: <Widget>[
                            if (isSmallScreen)
                              IconButton(
                                icon: const Icon(Icons.menu, color: AppColors.grey),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SwitchWarehouse(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildMainContent(selectedDrawerItem, isSmallScreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerContent(bool isSmallScreen) {
    // final versionProvider = Provider.of<VersionProvider>(context);
    // String currentVersion =
    //     html.window.localStorage['app_version'] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/homeLogo.png'),
                    ),
                    CrmUpdatedDateWidget(),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  isSelected: selectedDrawerItem == 'Dashboard',
                  onTap: () => _onDrawerItemTapped('Dashboard', isSmallScreen),
                ),
                // isPrimary!
                // ?
                _buildDrawerItem(
                  icon: Icons.route,
                  text: 'Routing',
                  isSelected: selectedDrawerItem == 'Routing',
                  onTap: () => _onDrawerItemTapped('Routing', isSmallScreen),
                ),
                // : const SizedBox(),
                _buildOrdersSection(isSmallScreen),
                _buildInventorySection(isSmallScreen),
                _buildMasterSection(isSmallScreen),
                _buildAccountSection(isSmallScreen),
                _buildUploadSection(isSmallScreen),
                (isSuperAdmin == true || isAdmin == true)
                    ? _buildDrawerItem(
                        icon: Icons.person_add_alt_1_rounded,
                        text: 'Create Account',
                        isSelected: selectedDrawerItem == 'Create Account',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountPage()));
                        },
                      )
                    : Container(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  isSelected: selectedDrawerItem == 'Logout',
                  onTap: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: AppColors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop(); // Close the dialog

                                final cleared = await clearLocalStorage();
                                try {
                                  if (cleared) {
                                    setState(() {
                                      isSuperAdmin = false;
                                      isAdmin = false;
                                      isConfirmer = false;
                                      isBooker = false;
                                      isAccounts = false;
                                      isPicker = false;
                                      isPacker = false;
                                      isChecker = false;
                                      isRacker = false;
                                      isManifest = false;
                                      isOutbound = false;
                                    });

                                    context.read<AuthProvider>().resetRoles();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Logout successful!'),
                                        backgroundColor: AppColors.primaryGreen,
                                      ),
                                    );

                                    if (!context.mounted) return;
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Error: Could not clear session.'),
                                        backgroundColor: AppColors.cardsred,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('An error occurred during logout.'),
                                      backgroundColor: AppColors.cardsred,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: AppColors.cardsred),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor: ["Invoices"].contains(selectedDrawerItem) ? Colors.blue.withValues(alpha: 0.2) : AppColors.white,
        // initiallyExpanded: true,
        initiallyExpanded: ["Invoices"].contains(selectedDrawerItem),
        title: Text(
          'Accounting',
          style: TextStyle(
            color: selectedDrawerItem == 'Accounting' ? AppColors.white : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.analytics,
          color: selectedDrawerItem == 'Accounting' ? AppColors.white : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Accounting' ? const Color.fromRGBO(6, 90, 216, 0.1) : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.account_balance_outlined,
              text: 'Invoices',
              isSelected: selectedDrawerItem == 'Invoices',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Invoices', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              // Pass the indentation flag
              iconSize: 20,
              // Adjust icon size
              fontSize: 14, // Adjust font size
            ),
          ),
        ],
      ),
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
        collapsedBackgroundColor: [
          "Outbound",
          "Orders Page",
          "HOD Approval",
          "Accounts Page",
          "Invoiced Orders",
          "Book Page",
          "Booked Orders",
          "Picker Page",
          "Packer Page",
          "Checker Page",
          "Racked Page",
          "Manifest Page",
          "Manifested Orders",
          "Dispatched",
          "Support",
          "Cancelled",
          "RTO",
          "All Orders",
          "Return Entry"
              "Supervisor"
        ].contains(selectedDrawerItem)
            ? Colors.blue.withValues(alpha: 0.2)
            : AppColors.white,
        initiallyExpanded: [
          "Outbound",
          "Orders Page",
          "HOD Approval",
          "Accounts Page",
          "Invoiced Orders",
          "Book Page",
          "Booked Orders",
          "Picker Page",
          "Packer Page",
          "Checker Page",
          "Racked Page",
          "Manifest Page",
          "Manifested Orders",
          "Dispatched",
          "Support",
          "Cancelled",
          "RTO",
          "All Orders",
          "Return Entry",
          "Supervisor"
        ].contains(selectedDrawerItem),
        title: Text(
          'Orders',
          style: TextStyle(
            color: selectedDrawerItem == 'Orders' ? AppColors.white : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.shopping_cart,
          color: selectedDrawerItem == 'Orders' ? AppColors.white : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Orders' ? const Color.fromRGBO(6, 90, 216, 0.1) : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.outbond,
              text: 'Outbound',
              isSelected: selectedDrawerItem == 'Outbound',
              onTap: () => isOutbound == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Outbound', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.assignment_rounded,
              text: 'Orders',
              isSelected: selectedDrawerItem == 'Orders Page',
              onTap: () => isConfirmer == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Orders Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.approval,
              text: 'HOD Approval',
              isSelected: selectedDrawerItem == 'HOD Approval',
              onTap: () => isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('HOD Approval', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.account_box_rounded,
              text: 'Accounts',
              isSelected: selectedDrawerItem == 'Accounts Page',
              onTap: () => isAccounts == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Accounts Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: _buildDrawerItem(
              icon: Icons.subdirectory_arrow_right,
              text: 'Invoiced Orders',
              isSelected: selectedDrawerItem == 'Invoiced Orders',
              onTap: () => isAccounts == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Invoiced Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
              onTap: () => isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Book Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: _buildDrawerItem(
              icon: Icons.subdirectory_arrow_right,
              text: 'Booked Orders',
              isSelected: selectedDrawerItem == 'Booked Orders',
              onTap: () => isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Booked Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.local_shipping,
              text: 'Picker',
              isSelected: selectedDrawerItem == 'Picker Page',
              onTap: () => isPicker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Picker Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
              onTap: () => isPacker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Packer Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
              onTap: () => isChecker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Checker Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
              onTap: () => isRacker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Racked Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.star,
              text: 'Manifest',
              isSelected: selectedDrawerItem == 'Manifest Page',
              onTap: () => isManifest == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manifest Page', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: _buildDrawerItem(
              icon: Icons.subdirectory_arrow_right,
              text: 'Manifested Orders',
              isSelected: selectedDrawerItem == 'Manifested Orders',
              onTap: () => isManifest == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manifested Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.assignment_return,
              text: 'Dispatched',
              isSelected: selectedDrawerItem == 'Dispatched',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Dispatched', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.support_agent,
              text: 'Support',
              isSelected: selectedDrawerItem == 'Support',
              onTap: () => isSupport == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Support', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.cancel,
              text: 'Cancelled',
              isSelected: selectedDrawerItem == 'Cancelled',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Cancelled', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.restore_rounded,
              text: 'RTO',
              isSelected: selectedDrawerItem == 'RTO',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('RTO', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.apps,
              text: 'All Orders',
              isSelected: selectedDrawerItem == 'All Orders',
              onTap: () => _onDrawerItemTapped('All Orders', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.keyboard_return_outlined,
              text: 'Return Entry',
              isSelected: selectedDrawerItem == 'Return Entry',
              onTap: () => _onDrawerItemTapped('Return Entry', isSmallScreen),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.supervisor_account,
              text: 'Supervisor',
              isSelected: selectedDrawerItem == 'Supervisor',
              onTap: () => _onDrawerItemTapped('Supervisor', isSmallScreen),
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
        collapsedBackgroundColor:
            ["Manage Inventory", "Manage Label", "Manage Outerbox", "Manage Inner Packaging", "Reordering"].contains(selectedDrawerItem)
                ? Colors.blue.withValues(alpha: 0.2)
                : AppColors.white,
        initiallyExpanded:
            ["Manage Inventory", "Manage Label", "Manage Outerbox", "Manage Inner Packaging", "Reordering"].contains(selectedDrawerItem),
        title: Text(
          'Inventory',
          style: TextStyle(
            color: selectedDrawerItem == 'Inventory' ? AppColors.white : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.inventory,
          color: selectedDrawerItem == 'Inventory' ? AppColors.white : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Inventory' ? const Color.fromRGBO(6, 90, 216, 0.1) : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.production_quantity_limits,
              text: 'Manage Inventory',
              isSelected: selectedDrawerItem == 'Manage Inventory',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manage Inventory', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              // Pass the indentation flag
              iconSize: 20,
              // Adjust icon size
              fontSize: 14, // Adjust font size
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.label_important,
              text: 'Manage Label',
              isSelected: selectedDrawerItem == 'Manage Label',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manage Label', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.outbox,
              text: 'Manage Inner Packaging',
              isSelected: selectedDrawerItem == 'Manage Inner Packaging',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manage Inner Packaging', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.outbox,
              text: 'Manage Outerbox',
              isSelected: selectedDrawerItem == 'Manage Outerbox',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manage Outerbox', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.assessment,
              text: 'Reordering',
              isSelected: selectedDrawerItem == 'Reordering',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Reordering', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              // Pass the indentation flag
              iconSize: 20,
              // Adjust icon size
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
        collapsedBackgroundColor: [
          "Product Master",
          "Category Master",
          "Combo Master",
          "Marketplace Master",
          "Warehouse Master",
          "Bin Master",
          "Material Planning",
          "Label In-Out",
          "Transfer Order",
        ].contains(selectedDrawerItem)
            ? Colors.blue.withValues(alpha: 0.2)
            : AppColors.white,
        title: Text(
          'Master',
          style: TextStyle(
            color: selectedDrawerItem == 'Master' ? AppColors.white : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.pages,
          color: selectedDrawerItem == 'Master' ? AppColors.white : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Master' ? const Color.fromRGBO(6, 90, 216, 0.1) : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.production_quantity_limits,
              text: 'Product Master',
              isSelected: selectedDrawerItem == 'Product Master',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Product Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.category,
              text: 'Category Master',
              isSelected: selectedDrawerItem == 'Category Master',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Category Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Combo Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Marketplace Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.warehouse,
              text: 'Warehouse Master',
              isSelected: selectedDrawerItem == 'Warehouse Master',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Warehouse Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.archive,
              text: 'Bin Master',
              isSelected: selectedDrawerItem == 'Bin Master',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Bin Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.inventory,
              text: 'Material Planning',
              isSelected: selectedDrawerItem == 'Material Planning',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Material Planning', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.label_important,
              text: 'Label In-Out',
              isSelected: selectedDrawerItem == 'Label In-Out',
              onTap: () => isConfirmer == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Label In-Out', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.swap_horiz,
              text: 'Transfer Order',
              isSelected: selectedDrawerItem == 'Transfer Order',
              onTap: () => isConfirmer == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Transfer Order', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUploadSection(bool isSmallScreen) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
        collapsedBackgroundColor: [
          "Create Orders",
          "Confirm Orders",
          "Confirm Outbound",
          "Merge Orders",
          "Create Invoice",
          "Book Orders",
          "Upload Products",
          "Upload Marketplace SKU",
          "Upload Labels",
          "Manage Labels",
          "Upload Inner Packaging",
          "Upload Inventory",
          "Upload Warehouse",
          "Upload Threshold",
          "Upload Combo"
        ].contains(selectedDrawerItem)
            ? Colors.blue.withValues(alpha: 0.2)
            : AppColors.white,
        title: Text(
          'Uploads',
          style: TextStyle(
            color: selectedDrawerItem == 'Uploads' ? AppColors.white : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.upload_file,
          color: selectedDrawerItem == 'Uploads' ? AppColors.white : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Uploads' ? const Color.fromRGBO(6, 90, 216, 0.1) : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.note_add,
              text: 'Create Orders',
              isSelected: selectedDrawerItem == 'Create Orders',
              onTap: () => isCreateOrder == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Create Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.insert_drive_file,
              text: 'Confirm Orders',
              isSelected: selectedDrawerItem == 'Confirm Orders',
              onTap: () => isConfirmer == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Confirm Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.outbound,
              text: 'Confirm Outbound',
              isSelected: selectedDrawerItem == 'Confirm Outbound',
              onTap: () => isOutbound == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Confirm Outbound', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.merge,
              text: 'Merge Orders',
              isSelected: selectedDrawerItem == 'Merge Orders',
              onTap: () => isOutbound == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Merge Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: FontAwesomeIcons.fileInvoice,
              text: 'Create Invoice',
              isSelected: selectedDrawerItem == 'Create Invoice',
              onTap: () => isAccounts == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Create Invoice', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.menu_book,
              text: 'Book Orders',
              isSelected: selectedDrawerItem == 'Book Orders',
              onTap: () => isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Book Orders', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.upload_file,
              text: 'Upload Products',
              isSelected: selectedDrawerItem == 'Upload Products',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Products', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.cloud_upload,
              text: 'Upload Marketplace SKU',
              isSelected: selectedDrawerItem == 'Upload Marketplace SKU',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Marketplace SKU', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.new_label,
              text: 'Upload Labels',
              isSelected: selectedDrawerItem == 'Upload Labels',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Labels', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.label_important,
              text: 'Manage Labels',
              isSelected: selectedDrawerItem == 'Manage Labels',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Manage Labels', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.all_inbox,
              text: 'Upload Inner Packing',
              isSelected: selectedDrawerItem == 'Upload Inner Packaging',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Inner Packaging', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.inventory,
              text: 'Upload Inventory',
              isSelected: selectedDrawerItem == 'Upload Inventory',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Inventory', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.warehouse,
              text: 'Upload Warehouse',
              isSelected: selectedDrawerItem == 'Upload Warehouse',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Warehouse', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.linear_scale,
              text: 'Upload Threshold',
              isSelected: selectedDrawerItem == 'Upload Threshold',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Threshold', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.inventory,
              text: 'Upload Combo',
              isSelected: selectedDrawerItem == 'Upload Combo',
              onTap: () => isConfirmer == true || isAccounts == true || isBooker == true || isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('Upload Combo', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are not authorized to view this page.")),
                    ),
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
      _saveSelectedDrawerItem(item);
    });

    if (isSmallScreen) {
      Navigator.pop(context);
    }
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
    switch (selectedDrawerItem) {
      case 'Dashboard':
        return _buildDashboardContent(isSmallScreen);
      case 'Routing':
        return const RoutingPage();
      case 'Sales Orders':
        return const Center(child: Text("Sales Orders content goes here"));
      case 'Inventory':
        return const Center(child: Text("Inventory content goes here"));
      case 'Products':
        return const UploadProductSku();
      case 'Manage Inventory':
        return const ManageInventoryPage();
      case 'Manage Label':
        return const ShowLabelPage();
      case 'Manage Inner Packaging':
        return const ManageInner();
      case 'Manage Outerbox':
        return const ManageOuterbox();
      case 'Reordering':
        return const ReorderingPage();
      case 'Orders Page':
        return const OrdersNewPage();
      case 'Outbound':
        return const OutboundPage();
      case 'HOD Approval':
        return const BaApprovePage();
      case 'Accounts Page':
        return const AccountsPage();
      case 'Invoiced Orders':
        return const InvoicedOrders();
      case 'Book Page':
        return const BookPage();
      case 'Booked Orders':
        return const BookedPage();
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
      case 'Manifested Orders':
        return const ManifestedOrders();
      case 'Dispatched':
        return const DispatchedOrders();
      case 'Support':
        return const SupportPage();
      case 'Cancelled':
        return const CancelledOrders();
      case 'RTO':
        return const RTOOrders();
      case 'All Orders':
        return const AllOrdersPage();
      case 'Return Entry':
        return const ReturnEntry();
      case 'Supervisor':
        return const CheckOrdersPage();
      case 'Product Master':
        return const ProductMasterPage();
      case 'Create Label Page':
        return const CreateLabelPage();
      case 'Category Master':
        return const CategoryMasterPage();
      case 'Combo Master':
        return const ComboPage();
      case 'Warehouse Master':
        return const LocationMaster();
      case 'Bin Master':
        return const BinMasterPage();
      case 'Material Planning':
        return const MaterialPlanning();
      case 'Label In-Out':
        return const LabelFormPage();
      case 'Transfer Order':
        return const TransferOrderPage();
      case 'Marketplace Master':
        return const MarketplacePage();
      case 'Accounting':
        return const Center(child: Text("Accounting content goes here"));
      case 'Invoices':
        return const InvoicePage();
      case 'Create Orders':
        return const CreateOrdersByCSV();
      case 'Confirm Orders':
        return const ConfirmOrders();
      case 'Confirm Outbound':
        return const ConfirmOutboundByCSV();
      case 'Merge Orders':
        return const MergeOrdersByCsv();
      case 'Create Invoice':
        return const CreateInvoiceByCSV();
      case 'Book Orders':
        return const BookOrdersByCsv();
      case 'Upload Products':
        return const ProductDataDisplay();
      case 'Upload Marketplace SKU':
        return const UploadMarketplaceSKU();
      case 'Upload Labels':
        return const LabelUpload();
      case 'Manage Labels':
        return const ManageLabelPage();
      case 'Upload Inner Packaging':
        return const UploadInner();
      case 'Upload Inventory':
        return const InventoryUpload();
      case 'Upload Warehouse':
        return const UploadWarehouse();
      case 'Upload Threshold':
        return const ThresholdUpload();
      case 'Upload Combo':
        return const ComboUpload();
      default:
        return const Center(child: Text("Select a menu item"));
    }
  }

  Widget _buildDashboardContent(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // if (!isCreateOrderPage) ...[
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Hello, ',
                      children: [
                        TextSpan(
                          text: userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3), // Shadow color
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DownloadOrders(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Same border radius
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Button padding
                      ),
                      icon: const Icon(
                        Icons.download,
                        color: Colors.white,
                      ), // Button icon
                      label: const Text(
                        'Download Orders CSV', // Button label
                        style: TextStyle(
                          color: Colors.white, // Text color
                          fontSize: 16, // Font size
                        ),
                      ),
                    ),
                  ),
                ),
                // ],
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3), // Shadow color
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Same border radius
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Button padding
                      ),
                      label: const Text(
                        'Create Order', // Button label
                        style: const TextStyle(
                          color: Colors.white, // Text color
                          fontSize: 16, // Font size
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // if (!isCreateOrderPage) ...[
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Here's what's happening with your store today",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Last Updated Section
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.greyText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: ${lastUpdatedTime != null ? DateFormat('hh:mm a').format(lastUpdatedTime!) : 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (selectedDate != null) // Display selected date if not null
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.greyText.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.greyText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate!),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.greyText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3), // Shadow color
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          DateTime? pickedDate = await _selectDate(context);
                          if (pickedDate != null) {
                            String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                            Provider.of<DashboardProvider>(context, listen: false).fetchAllData(formattedDate);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue, // Button background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Same border radius
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Button padding
                        ),
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                        ), // Button icon
                        label: const Text(
                          'Select Date', // Button label
                          style: TextStyle(
                            color: Colors.white, // Text color
                            fontSize: 16, // Font size
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Refresh Button
                  Tooltip(
                    message: 'Update the below shown data',
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // selectedDate = DateTime.now();
                        refreshData();
                        _refreshData();
                      },
                      label: const Text(
                        'Update Data',
                        style: TextStyle(
                          fontSize: 16,
                          // fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DashboardCards(
                    date: picked ?? DateTime.now(),
                    isSuperAdmin: isSuperAdmin,
                    isAdmin: isAdmin,
                    isConfirmer: isConfirmer,
                    isBooker: isBooker,
                    isAccounts: isAccounts,
                    isPicker: isPicker,
                    isPacker: isPacker,
                    isChecker: isChecker,
                    isRacker: isRacker,
                    isManifest: isManifest,
                    isOutbound: isOutbound,
                  ),
                ),
              ],
            ),
            // ] else ...[
            //   const CreateOrderPage(),
            // ],
          ],
        ),
      ),
    );
  }

  List<String> selectedMarketplaces = [];

  void _openMultiSelectDialog(BuildContext context, List<String> marketplaces) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Marketplaces"),
              content: SingleChildScrollView(
                child: Column(
                  children: marketplaces.map((marketplace) {
                    final isSelected = selectedMarketplaces.contains(marketplace);
                    return CheckboxListTile(
                      title: Text(marketplace),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedMarketplaces.add(marketplace);
                          } else {
                            selectedMarketplaces.remove(marketplace);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime? picked;

  Future<DateTime?> _selectDate(BuildContext context) async {
    DateTime today = DateTime.now();
    picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
    );

    log('Picked Date: $picked');

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      Provider.of<DashboardProvider>(context, listen: false).fetchAllData(DateFormat('yyyy-MM-dd').format(selectedDate!));
    }
    return picked;
  }

  void refreshData() {
    // Refresh logic
    DateTime today = DateTime.now(); // Get today's date
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);
    setState(() {
      selectedDate = today;
      lastUpdatedTime = DateTime.now();
    });
    // Fetch today's data
    Provider.of<DashboardProvider>(context, listen: false).fetchAllData(formattedDate);
  }
}
