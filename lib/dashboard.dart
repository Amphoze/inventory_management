import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:inventory_management/Custom-Files/product-card.dart';
import 'package:inventory_management/accounts_page.dart';
import 'package:inventory_management/accounts_section.dart';
import 'package:inventory_management/all_orders_page.dart';
import 'package:inventory_management/ba_approve_page.dart';
import 'package:inventory_management/bin_master.dart';
import 'package:inventory_management/booked_page.dart';
import 'package:inventory_management/cancelled_orders.dart';
import 'package:inventory_management/combo_upload.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/create_account.dart';
import 'package:inventory_management/inventory_upload.dart';
import 'package:inventory_management/invoice_page.dart';
import 'package:inventory_management/book_page.dart';
import 'package:inventory_management/combo_page.dart';
import 'package:inventory_management/create-label-page.dart';
import 'package:inventory_management/location_master.dart';
import 'package:inventory_management/login_page.dart';
import 'package:inventory_management/manage_inventory.dart';
import 'package:inventory_management/manage_label_page.dart';
import 'package:inventory_management/manage_outerbox.dart';
import 'package:inventory_management/manifest_section.dart';
import 'package:inventory_management/marketplace_page.dart';
import 'package:inventory_management/category_master.dart';
import 'package:inventory_management/dashboard_cards.dart';
import 'package:inventory_management/checker_page.dart';
import 'package:inventory_management/label_upload.dart';
import 'package:inventory_management/manifest_page.dart';
import 'package:inventory_management/outbound_page.dart';
import 'package:inventory_management/product_upload.dart';
import 'package:inventory_management/packer_page.dart';
import 'package:inventory_management/picker_page.dart';
import 'package:inventory_management/orders_page.dart';
import 'package:inventory_management/provider/all_orders_provider.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/racked_page.dart';
import 'package:inventory_management/dispatch_order.dart';
import 'package:inventory_management/reordering_page.dart';
import 'package:inventory_management/return_orders.dart';
import 'package:inventory_management/routing_page.dart';
import 'package:inventory_management/show-label-page.dart';
import 'package:inventory_management/threshold_upload.dart';
import 'package:inventory_management/uploadproduct-quantity.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Custom-Files/colors.dart';
import 'package:inventory_management/product_manager.dart';
import 'package:http/http.dart' as http;

class DashboardPage extends StatefulWidget {
  final String warehouseId;
  const DashboardPage({super.key, required this.warehouseId});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedDrawerItem = 'Dashboard';
  DateTime? selectedDate; // State variable to hold the selected date
  DateTime?
      lastUpdatedTime; // Make sure this is initialized properly in your actual code
  DateTime? previousDate;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, String>> statuses = [];
  // List<String> dropdownItems = [];
  List<String> temp = [];

  // String? userRole;

  @override
  void initState() {
    super.initState();
    lastUpdatedTime = DateTime.now();

    _fetchUserRole();
    fetchStatuses();
    _loadSelectedDrawerItem();
  }

  void fetchStatuses() async {
    final allOrdersProvider =
        Provider.of<AllOrdersProvider>(context, listen: false);
    statuses = await allOrdersProvider.getTrackingStatuses();
    temp = statuses.map((item) => item.keys.first).toList();

    log('statuses: $statuses');
    log('sss: ${statuses.firstWhere((map) => map.containsKey(_selectedStatus), orElse: () => {})['Failed']!}');
    log('temp: $temp');
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

  // bool? isPrimary;

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

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ////////////////////////////////
      // isPrimary = prefs.getBool('isPrimary');
      /////////////////////////////////
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
    });
  }

  void _refreshData() {
    setState(() {
      lastUpdatedTime = DateTime.now();
    });
  }

  //////////////////////////////////////////////////////////////////////////////////////////
  String? _selectedValue;
  String? _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  final List<String> _options = [
    'Today',
    'Last 5 days',
    'Last 15 days',
    'Last 30 days',
    'Custom range'
  ];

  void _updateDatesBasedOnSelection(String? value) {
    if (value == null) return;

    final now = DateTime.now();
    _endDate = now;

    if (value == 'Today') {
      _startDate = now;
    } else if (value == 'Last 5 days') {
      _startDate = now.subtract(const Duration(days: 5));
    } else if (value == 'Last 15 days') {
      _startDate = now.subtract(const Duration(days: 15));
    } else if (value == 'Last 30 days') {
      _startDate = now.subtract(const Duration(days: 30));
    } else {
      _startDate ??= now.subtract(const Duration(days: 7));
    }
    setState(() {});
  }

  // Future<void> _generateReport() async {

  // }

  bool get _canGenerate {
    if (_selectedValue == null) return false;
    if (_selectedValue == 'Custom range') {
      return _startDate != null;
    }
    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    return DateFormat('dd/MM/yyyy').format(date);
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
                                icon: const Icon(Icons.menu,
                                    color: AppColors.grey),
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
      ),
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
                const Image(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/homeLogo.png'),
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
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateAccountPage()));
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
                          content:
                              const Text('Are you sure you want to logout?'),
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
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Error: Could not clear session.'),
                                        backgroundColor: AppColors.cardsred,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'An error occurred during logout.'),
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
        collapsedBackgroundColor: ["Invoices"].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
        // initiallyExpanded: true,
        initiallyExpanded: ["Invoices"].contains(selectedDrawerItem),
        title: Text(
          'Accounting',
          style: TextStyle(
            color: selectedDrawerItem == 'Accounting'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.analytics,
          color: selectedDrawerItem == 'Accounting'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Accounting'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.account_balance_outlined,
              text: 'Invoices',
              isSelected: selectedDrawerItem == 'Invoices',
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Invoices', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true, // Pass the indentation flag
              iconSize: 20, // Adjust icon size
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
          "Accounts Section",
          "Book Page",
          "Booked Orders",
          "Picker Page",
          "Packer Page",
          "Checker Page",
          "Racked Page",
          "Manifest Page",
          "Manifest Section",
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
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
              icon: Icons.outbond,
              text: 'Outbound',
              isSelected: selectedDrawerItem == 'Outbound',
              onTap: () =>
                  isConfirmer == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Outbound', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isConfirmer == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Orders Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () => isSuperAdmin == true || isAdmin == true
                  ? _onDrawerItemTapped('HOD Approval', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () =>
                  isAccounts == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Accounts Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              text: 'Accounts Section',
              isSelected: selectedDrawerItem == 'Accounts Section',
              onTap: () =>
                  isAccounts == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Accounts Section', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isBooker == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Book Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isBooker == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Booked Orders', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isPicker == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Picker Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isPacker == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Packer Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isChecker == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Checker Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isRacker == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Racked Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () =>
                  isManifest == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Manifest Page', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              text: 'Manifest section',
              isSelected: selectedDrawerItem == 'Manifest Section',
              onTap: () =>
                  isManifest == true || isSuperAdmin == true || isAdmin == true
                      ? _onDrawerItemTapped('Manifest Section', isSmallScreen)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Dispatched', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Cancelled', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('RTO', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
        collapsedBackgroundColor: [
          "Manage Inventory",
          "Manage Label",
          "Manage Outerbox",
          "Reordering"
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Manage Inventory', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true, // Pass the indentation flag
              iconSize: 20, // Adjust icon size
              fontSize: 14, // Adjust font size
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.label_important,
              text: 'Manage Label',
              isSelected: selectedDrawerItem == 'Manage Label',
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Manage Label', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Manage Outerbox', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
              isIndented: true,
              iconSize: 20,
              fontSize: 14,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 10.0), // Ensure consistent padding
            child: _buildDrawerItem(
              icon: Icons.assessment,
              text: 'Reordering',
              isSelected: selectedDrawerItem == 'Reordering',
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Reordering', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
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
        collapsedBackgroundColor: [
          "Create Label Page",
          "Product Master",
          "Category Master",
          "Combo Master",
          "Marketplace Master",
          "Warehouse Master",
          "Bin Master",
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Product Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
                    ),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Category Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Combo Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Marketplace Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Warehouse Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Bin Master', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
          "Upload Products",
          "Upload Labels",
          "Manage Labels",
          "Upload Inventory",
          "Upload Threshold",
          "Upload Combo"
        ].contains(selectedDrawerItem)
            ? Colors.blue.withOpacity(0.2)
            : AppColors.white,
        title: Text(
          'Uploads',
          style: TextStyle(
            color: selectedDrawerItem == 'Uploads'
                ? AppColors.white
                : AppColors.primaryBlue,
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.upload_file,
          color: selectedDrawerItem == 'Uploads'
              ? AppColors.white
              : AppColors.primaryBlue,
          size: 24,
        ),
        backgroundColor: selectedDrawerItem == 'Uploads'
            ? const Color.fromRGBO(6, 90, 216, 0.1)
            : null,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildDrawerItem(
              icon: Icons.upload_file,
              text: 'Upload Products',
              isSelected: selectedDrawerItem == 'Upload Products',
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Upload Products', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Upload Labels', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Manage Labels', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Upload Inventory', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Upload Threshold', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
              onTap: () => isConfirmer == true ||
                      isAccounts == true ||
                      isBooker == true ||
                      isSuperAdmin == true ||
                      isAdmin == true
                  ? _onDrawerItemTapped('Upload Combo', isSmallScreen)
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You are not authorized to view this page.")),
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
        // return const ReorderingPage();
        return _buildDashboardContent(isSmallScreen);
      case 'Routing':
        // return const ReorderingPage();
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
        return const ManageLabel();
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
      case 'Accounts Section':
        return const AccountsSectionPage();
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
      case 'Manifest Section':
        return const ManifestSection();
      case 'Dispatched':
        return const DispatchedOrders();
      case 'Cancelled':
        return const CancelledOrders();
      case 'RTO':
        return const RTOOrders();
      case 'All Orders':
        return const AllOrdersPage();
      case 'Product Master':
        return const ProductDashboardPage();
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
      case 'Marketplace Master':
        return const MarketplacePage();
      case 'Accounting':
        return const Center(child: Text("Accounting content goes here"));
      case 'Invoices':
        return const InvoicePage();
      case 'Upload Products':
        return const ProductDataDisplay();
      case 'Upload Labels':
        return const LabelUpload();
      case 'Manage Labels':
        return const ManageLabelPage();
      case 'Upload Inventory':
        return const InventoryUpload();
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'Hello, Katyayani Organics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                if (selectedDate != null) // Display selected date if not null
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.greyText.withOpacity(0.08),
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
                          color: Colors.grey.withOpacity(0.3), // Shadow color
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
                          String formattedDate =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                          Provider.of<DashboardProvider>(context, listen: false)
                              .fetchAllData(formattedDate);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryBlue, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Same border radius
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0), // Button padding
                      ),
                      icon: const Icon(
                          Icons.calendar_month_outlined), // Button icon
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
                // const SizedBox(width: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3), // Shadow color
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                  builder: (context, setState) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.assessment_outlined,
                                                size: 28,
                                                color: AppColors.primaryBlue,
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  'All Orders Report',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          DropdownButtonFormField<String>(
                                            value: _selectedStatus,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color:
                                                        Colors.grey.shade300),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                    color:
                                                        AppColors.primaryBlue,
                                                    width: 2),
                                              ),
                                              labelText: 'Select Status',
                                              labelStyle: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16),
                                              prefixIcon: const Icon(
                                                  Icons.assignment_outlined,
                                                  color: AppColors.primaryBlue),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 16),
                                            ),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _selectedStatus = newValue;
                                                });
                                              }
                                            },
                                            items: [
                                              ...temp.map((status) =>
                                                  DropdownMenuItem<String>(
                                                    value: status.toString(),
                                                    child:
                                                        Text(status.toString()),
                                                  )),
                                              const DropdownMenuItem<String>(
                                                value: 'all',
                                                child: Text('All'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          DropdownButtonFormField<String>(
                                            value: _selectedValue,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppColors.primaryBlue,
                                                  width: 2,
                                                ),
                                              ),
                                              labelText: 'Select Period',
                                              labelStyle: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 16,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.calendar_month,
                                                color: AppColors.primaryBlue,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedValue = newValue;
                                                _updateDatesBasedOnSelection(
                                                    newValue);
                                              });
                                            },
                                            items: _options
                                                .map<DropdownMenuItem<String>>(
                                                    (String option) {
                                              return DropdownMenuItem(
                                                value: option,
                                                child: Text(option),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 24),
                                          if (_selectedValue != null) ...[
                                            if (_selectedValue ==
                                                'Custom range') ...[
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          onPressed: () async {
                                                            final DateTime?
                                                                pickedStart =
                                                                await showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  _startDate ??
                                                                      DateTime
                                                                          .now(),
                                                              firstDate:
                                                                  DateTime(
                                                                      2020),
                                                              lastDate:
                                                                  _endDate ??
                                                                      DateTime
                                                                          .now(),
                                                            );
                                                            if (pickedStart !=
                                                                null) {
                                                              setState(() =>
                                                                  _startDate =
                                                                      pickedStart);
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                            ),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          icon: const Icon(Icons
                                                              .calendar_today),
                                                          label: const Text(
                                                              'Select Start Date'),
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .grey.shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .date_range,
                                                                size: 20,
                                                                color: AppColors
                                                                    .primaryBlue,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                'Start: ${_formatDate(_startDate)}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          onPressed: () async {
                                                            final DateTime?
                                                                pickedEnd =
                                                                await showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  _endDate ??
                                                                      DateTime
                                                                          .now(),
                                                              firstDate:
                                                                  _startDate ??
                                                                      DateTime(
                                                                          2020),
                                                              lastDate: DateTime
                                                                  .now(),
                                                            );
                                                            if (pickedEnd !=
                                                                null) {
                                                              setState(() =>
                                                                  _endDate =
                                                                      pickedEnd);
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                            ),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          icon: const Icon(Icons
                                                              .calendar_today),
                                                          label: const Text(
                                                              'Select End Date'),
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .grey.shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .date_range,
                                                                size: 20,
                                                                color: AppColors
                                                                    .primaryBlue,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                'End: ${_formatDate(_endDate)}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
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
                                            ] else ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.date_range,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Selected Period: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                          if (_error != null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 16),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.red.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: Colors.red.shade700,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      _error!,
                                                      style: TextStyle(
                                                        color:
                                                            Colors.red.shade700,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 48,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if (_canGenerate &&
                                                    !_isLoading) {
                                                  setState(() {
                                                    _isLoading = true;
                                                    _error = null;
                                                  });

                                                  try {
                                                    final prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    final token = prefs
                                                        .getString('authToken');

                                                    String baseUrl =
                                                        await ApiUrls
                                                            .getBaseUrl();

                                                    final startDate =
                                                        DateFormat('yyyy-MM-dd')
                                                            .format(
                                                                _startDate!);
                                                    final endDate =
                                                        DateFormat('yyyy-MM-dd')
                                                            .format(_endDate);

                                                    if (token == null ||
                                                        token.isEmpty) {
                                                      throw Exception(
                                                          'Authorization token is missing or invalid.');
                                                    }

                                                    final headers = {
                                                      'Authorization':
                                                          'Bearer $token',
                                                      'Content-Type':
                                                          'application/json',
                                                    };

                                                    setState(() {
                                                      if (_selectedStatus !=
                                                          'all') {
                                                        _selectedStatus =
                                                            statuses.firstWhere(
                                                                (map) => map
                                                                    .containsKey(
                                                                        _selectedStatus),
                                                                orElse: () =>
                                                                    {})[_selectedStatus]!;
                                                      }
                                                    });
                                                    Logger().e(
                                                        '_selectedStatus: $_selectedStatus');

                                                    String url =
                                                        '$baseUrl/orders/download?startDate=$startDate&endDate=$endDate&order_status=$_selectedStatus';

                                                    Logger().e('url: $url');

                                                    final response =
                                                        await http.get(
                                                      Uri.parse(url),
                                                      headers: headers,
                                                    );

                                                    log('Response body: ${response.body}');

                                                    if (response.statusCode ==
                                                        200) {
                                                      final jsonBody =
                                                          json.decode(
                                                              response.body);
                                                      log("jsonBody: $jsonBody");

                                                      final downloadUrl =
                                                          jsonBody[
                                                              'downloadUrl'];

                                                      if (downloadUrl != null) {
                                                        final canLaunch =
                                                            await canLaunchUrl(
                                                                Uri.parse(
                                                                    downloadUrl));
                                                        if (canLaunch) {
                                                          await launchUrl(
                                                              Uri.parse(
                                                                  downloadUrl));
                                                        } else {
                                                          throw 'Could not launch $downloadUrl';
                                                        }
                                                      } else {
                                                        throw Exception(
                                                            'No download URL found');
                                                      }
                                                    } else {
                                                      throw Exception(
                                                          'Failed to load template: ${response.statusCode} ${response.body}');
                                                    }
                                                  } catch (error) {
                                                    setState(() {
                                                      _error = error.toString();
                                                    });
                                                    log('Error during report generation: $error');
                                                  } finally {
                                                    setState(() {
                                                      _isLoading = false;
                                                      _selectedStatus = 'all';
                                                    });
                                                  }
                                                }
                                              },
                                              // onPressed:
                                              //     _canGenerate && !_isLoading
                                              //         ? _generateReport
                                              //         : null,
                                              style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                backgroundColor:
                                                    AppColors.primaryBlue,
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white),
                                                      ),
                                                    )
                                                  : const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.download,
                                                            color:
                                                                Colors.white),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Download Report',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              });
                            });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryBlue, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Same border radius
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0), // Button padding
                      ),
                      icon: const Icon(Icons.download), // Button icon
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
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Here's what's happening with your store today",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.greyText,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        size: 20,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Last Deployed: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        '30-12-2024, 11:11 AM',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                  // Refresh Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // selectedDate = DateTime.now();
                      refreshData();
                      _refreshData();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      size: 20,
                    ),
                    label: const Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: DashboardCards(date: picked ?? DateTime.now())),
              ],
            ),
            // const SizedBox(height: 20),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     Text(
            //       'Last updated: ${lastUpdatedTime != null ? DateFormat('hh:mm a').format(lastUpdatedTime!) : 'N/A'}',
            //       style: const TextStyle(
            //         fontSize: 14,
            //         color: AppColors.greyText,
            //       ),
            //     ),
            //     const SizedBox(width: 10),
            //     ElevatedButton(
            //       onPressed: () {
            //         selectedDate = DateTime.now();
            //         refreshData(); // Call refresh data method
            //         _refreshData();
            //       },
            //       style: ElevatedButton.styleFrom(
            //         minimumSize: const Size(100, 50),
            //         backgroundColor: AppColors.primaryBlue,
            //       ),
            //       child: const Text(
            //         'Refresh',
            //         style: TextStyle(fontSize: 16),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
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
      Provider.of<DashboardProvider>(context, listen: false)
          .fetchAllData(DateFormat('yyyy-MM-dd').format(selectedDate!));
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
    Provider.of<DashboardProvider>(context, listen: false)
        .fetchAllData(formattedDate);
  }
}
