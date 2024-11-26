import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Api/label-api.dart';
import 'package:inventory_management/Api/lable-page-api.dart';
import 'package:inventory_management/Api/order-page-checkbox-provider.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:inventory_management/Api/update-quantity-by-sku.dart';
import 'package:inventory_management/dashboard.dart';
import 'package:inventory_management/login_page.dart';
import 'package:inventory_management/provider/accounts_provider.dart';
import 'package:inventory_management/provider/ba_approve_provider.dart';
import 'package:inventory_management/provider/book_provider.dart';
import 'package:inventory_management/provider/cancelled_provider.dart';
import 'package:inventory_management/provider/combo_provider.dart';
import 'package:inventory_management/provider/dashboard_provider.dart';
import 'package:inventory_management/provider/inventory_provider.dart';
import 'package:inventory_management/provider/invoice_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/category_provider.dart';
import 'package:inventory_management/provider/label_data_provider.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/manage-inventory-provider.dart';
import 'package:inventory_management/provider/product_data_provider.dart';
import 'package:inventory_management/provider/dispatched_provider.dart';
import 'package:inventory_management/provider/show-details-order-provider.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:inventory_management/provider/picker_provider.dart';
import 'package:inventory_management/provider/packer_provider.dart';
import 'package:inventory_management/provider/checker_provider.dart';
import 'package:inventory_management/provider/racked_provider.dart';
import 'package:inventory_management/provider/manifest_provider.dart';
import 'package:provider/provider.dart';

// import 'package:inventory_management/create_account.dart';
// prarthi2474@gmail.com
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => LabelApi()),
      ChangeNotifierProvider(create: (context) => AuthProvider()),
      ChangeNotifierProvider(create: (context) => CheckBoxProvider()),
      ChangeNotifierProvider(create: (context) => ManagementProvider()),
      ChangeNotifierProvider(create: (context) => DashboardProvider()),
      ChangeNotifierProvider(create: (context) => LabelPageApi()),
      ChangeNotifierProvider(create: (context) => MarketplaceProvider()),
      ChangeNotifierProvider(create: (context) => BookProvider()),
      ChangeNotifierProvider(create: (context) => ProductProvider()),
      ChangeNotifierProvider(create: (context) => ComboProvider()),
      ChangeNotifierProvider(create: (context) => PickerProvider()),
      ChangeNotifierProvider(create: (context) => PackerProvider()),
      ChangeNotifierProvider(create: (context) => CheckerProvider()),
      ChangeNotifierProvider(create: (context) => ManifestProvider()),
      ChangeNotifierProvider(create: (context) => RackedProvider()),
      ChangeNotifierProvider(create: (context) => OrdersProvider()),
      ChangeNotifierProvider(create: (context) => DispatchedProvider()),
      ChangeNotifierProvider(create: (context) => CancelledProvider()),
      ChangeNotifierProvider(
          create: (context) => LocationProvider(
              authProvider: Provider.of<AuthProvider>(context, listen: false))),
      ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ChangeNotifierProvider(create: (context) => ProductDataProvider()),
      ChangeNotifierProvider(create: (context) => LabelDataProvider()),
      ChangeNotifierProvider(create: (context) => OrderItemProvider()),
      ChangeNotifierProvider(create: (context) => InventoryProvider()),
      ChangeNotifierProvider(create: (context) => InvoiceProvider()),
      ChangeNotifierProvider(create: (context) => AccountsProvider()),
      ChangeNotifierProvider(create: (context) => BAApproveProvider()),
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
      title: 'StockShip',
      theme: ThemeData(
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
          ),
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  AuthProvider? authprovider;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // getData();
  }

  // void getData()async{
  //    authprovider=Provider.of<AuthProvider>(context,listen:true);
  //    await authprovider!.getToken();
  // }
  @override
  Widget build(BuildContext context) {
    // var prov=Provider.of<AuthProvider>(context,listen:true);

    return Consumer<AuthProvider>(
      builder: (context, authprovider, child) => FutureBuilder<String?>(
          future: authprovider.getToken(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snap.hasData) {
              if (authprovider.isAuthenticated) {
                return const DashboardPage(
                  inventoryId: '',
                );
              } else {
                return const LoginPage();
              }
            } else {
              return const LoginPage();
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
