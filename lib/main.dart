import 'dart:developer';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Api/bin_api.dart';
import 'package:inventory_management/Api/label-api.dart';
import 'package:inventory_management/Api/lable-page-api.dart';
import 'package:inventory_management/Api/order-page-checkbox-provider.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:inventory_management/check_orders/provider/check_orders_provider.dart';
import 'package:inventory_management/dashboard.dart';
import 'package:inventory_management/firebase_options.dart';
import 'package:inventory_management/login_page.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:inventory_management/provider/all_orders_provider.dart';
import 'package:inventory_management/provider/ba_approve_provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/provider/cancelled_provider.dart';
import 'package:inventory_management/provider/category_provider.dart';
import 'package:inventory_management/provider/chat_provider.dart';
import 'package:inventory_management/provider/checker_provider.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/provider/dispatched_provider.dart';
import 'package:inventory_management/provider/inner_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:inventory_management/provider/invoice_provider.dart';
import 'package:inventory_management/provider/label_data_provider.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/manifest_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:inventory_management/provider/outbound_provider.dart';
import 'package:inventory_management/provider/outerbox_provider.dart';
import 'package:inventory_management/provider/packer_provider.dart';
import 'package:inventory_management/provider/picker_provider.dart';
import 'package:inventory_management/provider/product_data_provider.dart';
import 'package:inventory_management/provider/product_master_provider.dart';
import 'package:inventory_management/provider/racked_provider.dart';
import 'package:inventory_management/provider/return_entry_provider.dart';
import 'package:inventory_management/provider/return_provoider.dart';
import 'package:inventory_management/provider/routing_provider.dart';
import 'package:inventory_management/provider/show-details-order-provider.dart';
import 'package:inventory_management/provider/support_provider.dart';
import 'package:inventory_management/provider/transfer_order_provider.dart';
import 'package:inventory_management/stockship_version_control/version_controller.dart';
import 'package:inventory_management/warehouses_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider/create_order_provider.dart';

// import 'package:inventory_management/create_account.dart';
// prarthi2474@gmail.com

// prateekkhatri@katyayaniorganics.com

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => LabelApi()),
      ChangeNotifierProvider(create: (context) => BinApi()),
      ChangeNotifierProvider(create: (context) => AuthProvider()),
      ChangeNotifierProvider(create: (context) => CheckBoxProvider()),
      ChangeNotifierProvider(create: (context) => DashboardProvider()),
      ChangeNotifierProvider(create: (context) => LabelPageApi()),
      ChangeNotifierProvider(create: (context) => MarketplaceProvider()),
      ChangeNotifierProvider(create: (context) => BookProvider()),
      ChangeNotifierProvider(create: (context) => ProductProvider()),
      ChangeNotifierProvider(create: (context) => ProductMasterProvider()),
      ChangeNotifierProvider(create: (context) => ComboProvider()),
      ChangeNotifierProvider(create: (context) => PickerProvider()),
      ChangeNotifierProvider(create: (context) => PackerProvider()),
      ChangeNotifierProvider(create: (context) => CheckerProvider()),
      ChangeNotifierProvider(create: (context) => ManifestProvider()),
      ChangeNotifierProvider(create: (context) => RackedProvider()),
      ChangeNotifierProvider(create: (context) => OrdersProvider()),
      ChangeNotifierProvider(create: (context) => OutboundProvider()),
      ChangeNotifierProvider(create: (context) => DispatchedProvider()),
      ChangeNotifierProvider(create: (context) => CancelledProvider()),
      ChangeNotifierProvider(create: (context) => ReturnProvider()),
      ChangeNotifierProvider(create: (context) => AllOrdersProvider()),
      ChangeNotifierProvider(create: (context) => LocationProvider(authProvider: Provider.of<AuthProvider>(context, listen: false))),
      ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ChangeNotifierProvider(create: (context) => ProductDataProvider()),
      ChangeNotifierProvider(create: (context) => LabelDataProvider()),
      ChangeNotifierProvider(create: (context) => OrderItemProvider()),
      ChangeNotifierProvider(create: (context) => InventoryProvider()),
      ChangeNotifierProvider(create: (context) => InvoiceProvider()),
      ChangeNotifierProvider(create: (context) => AccountsProvider()),
      ChangeNotifierProvider(create: (context) => BaApproveProvider()),
      ChangeNotifierProvider(create: (context) => CreateOrderProvider()),
      ChangeNotifierProvider(create: (context) => TransferOrderProvider()),
      ChangeNotifierProvider(create: (context) => OuterboxProvider()),
      ChangeNotifierProvider(create: (context) => InnerPackagingProvider()),
      ChangeNotifierProvider(create: (context) => VersionController()),
      ChangeNotifierProvider(create: (context) => SupportProvider()),
      ChangeNotifierProvider(create: (context) => ChatProvider()),
      ChangeNotifierProvider(create: (context) => ReturnEntryProvider()),
      ChangeNotifierProvider(create: (context) => RoutingProvider()),
      ChangeNotifierProvider(create: (context) => CheckOrdersProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'StockShip',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        primaryColor: const Color.fromRGBO(6, 90, 216, 1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff09254A),
          primary: const Color(0xff09254A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color.fromRGBO(6, 90, 216, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              textStyle: const TextStyle(fontFamily: 'Poppins')),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          shape: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      home: const Home(),
    );
  }
}

Future<void> fetchAndSaveBaseUrl() async {
  try {
    // Initialize Firestore
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    // Fetch the document with ID 'baseUrl' from the 'MongoDb' collection
    QuerySnapshot<Map<String, dynamic>> doc = (await firestore.collection('MongoDb').where('docId', isEqualTo: 'baseUrl').get());
    log(doc.toString());
    if (doc.docs.isNotEmpty) {
      // Get the baseUrl from the document
      String baseUrl = doc.docs[0].data()['value'] ?? '';
      // Save the baseUrl to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('value', baseUrl);
      print(baseUrl);
    } else {
      print('Document does not exist');
    }
  } catch (e) {
    print('Error fetching baseUrl: $e');
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AuthProvider? authprovider;
  String? warehouseId;

  @override
  void initState() {
    fetchAndSaveBaseUrl();
    getWarehouseId();
    super.initState();
  }

  Future<String?> getWarehouseId() async {
    final prefs = await SharedPreferences.getInstance();
    warehouseId = prefs.getString('warehouseId');
    return warehouseId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authprovider, child) => FutureBuilder<String?>(
          future: authprovider.getToken(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snap.hasData) {
              if (authprovider.isAuthenticated) {
                if (warehouseId != null) {
                  return DashboardPage(warehouseId: warehouseId ?? '');
                } else {
                  return const WarehousesPage();
                }
              } else {
                return const LoginPage();
                // return const UnderMaintainence();
              }
            } else {
              return const LoginPage();
              // return const UnderMaintainence();
            }
          }),
      // home: const LoginPage(),
      // routes: {
      //   '/login': (context) => const LoginPage(),
      //   '/createAccount': (context) => const CreateAccountPage(),
      //   '/forgotPassword': (context) => const ForgotPasswordPage(),
      //   '/dashboard': (context) => const DashboardPage(),
      //   '/products': (context) => const Products(),
      //   '/reset_password': (context) => const ResetPasswordPage(),
      //   //'/dashoard/location-master': (context) => const LocationMaster()
      // },
    );
  }
}
