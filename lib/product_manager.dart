import 'dart:developer';
//
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'Custom-Files/colors.dart';
import 'products.dart';
import 'Custom-Files/product-card.dart';
import 'Custom-Files/filter-section.dart';
import 'Custom-Files/dropdown.dart';

//
class ProductDashboardPage extends StatefulWidget {
  const ProductDashboardPage({super.key});
//
  @override
  _ProductDashboardPageState createState() => _ProductDashboardPageState();
}

//
class _ProductDashboardPageState extends State<ProductDashboardPage> {
  final int _itemsPerPage = 30;
  final List<Product> _products = [];
  int totalProducts = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _showCreateProduct = false;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchbarController = TextEditingController();
//
  String _searchQuery = '';
  //String? _selectedSearchOption;
  String? _selectedSearchOption = 'Display Name';
  final List<String> _searchOptions = [
    'Display Name',
    // 'Description',
    // 'Category',
    'SKU',
    'Show All Products'
  ];
//
  @override
  void initState() {
    super.initState();
    loadMoreProducts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

//
  @override
  void dispose() {
    _searchController.dispose();
    _searchbarController.dispose();
    super.dispose();
  }

//
  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
//
    setState(() {
      _isLoading = true;
    });
//
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.getAllProducts(page: _currentPage, itemsPerPage: _itemsPerPage);
//
      if (response['success']) {
        final List<dynamic> productData = response['data'];
        final newProducts = productData.map((data) {
          return Product(
            sku: data['sku'] ?? '',
            parentSku: data['parentSku'] ?? '',
            ean: data['ean'] ?? '',
            description: data['description'] ?? '',
            categoryName: data['categoryName'] ?? '',
            brand: data['brand'] ?? '',
            colour: data['colour'] ?? '',
            netWeight: data['netWeight']?.toString() ?? '',
            grossWeight: data['grossWeight']?.toString() ?? '',
            labelSku: data['labelSku'] ?? '',
            outerPackage_quantity: data['outerPackage_quantity']?.toString() ?? '',
            outerPackage_name: data['outerPackage_name'] ?? '',
            grade: data['grade'] ?? '',
            technicalName: data['technicalName'] ?? '',
            length: data['length']?.toString() ?? '',
            width: data['width']?.toString() ?? '',
            height: data['height']?.toString() ?? '',
            mrp: data['mrp']?.toString() ?? '',
            cost: data['cost']?.toString() ?? '',
            tax_rule: data['tax_rule']?.toString() ?? '',
            shopifyImage: data['shopifyImage'] ?? '',
            createdDate: data['createdAt'] ?? '',
            lastUpdated: data['updatedAt'] ?? '',
            displayName: data['displayName'] ?? '',
            variantName: data['variant_name'] ?? '',
          );
        }).toList();
//
        setState(() {
          totalProducts = response['totalProducts'];
          _products.addAll(newProducts);
          _hasMore = newProducts.length == _itemsPerPage;
          if (_hasMore) _currentPage++;
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (error) {
      setState(() {
        _hasMore = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Row(
        children: [
          // Left Sidebar
          //if (isWideScreen && !_showCreateProduct) _buildSidebar(),
          // Main content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: !_showCreateProduct ? _buildProductList() : const Products(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

//
  // Widget _buildSidebar() {
  //   return ConstrainedBox(
  //     constraints: BoxConstraints(
  //       maxWidth: 240,
  //       minHeight: MediaQuery.of(context).size.height,
  //     ),
  //     child: Container(
  //       color: Colors.grey[200],
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildSearchField(),
  //           const SizedBox(height: 16),
  //           Expanded(child: _buildFilterSections()),
  //         ],
  //       ),
  //     ),
  //   );
  // }
//
  // Widget _buildSearchField() {
  //   return SizedBox(
  //     width: 300,
  //     child: TextField(
  //       controller: _searchController,
  //       decoration: InputDecoration(
  //         filled: true,
  //         fillColor: Colors.white,
  //         hintText: 'Search...',
  //         prefixIcon: const Icon(Icons.search, color: Colors.orange),
  //         contentPadding:
  //             const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12.0),
  //           borderSide: const BorderSide(color: Colors.orange, width: 2.0),
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12.0),
  //           borderSide: const BorderSide(color: Colors.orange, width: 2.0),
  //         ),
  //       ),
  //     ),
  //   );
  // }
//
  Widget _buildFilterSections() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSection(
            title: 'Category',
            items: _categories,
            searchQuery: _searchQuery,
          ),
          FilterSection(
            title: 'Brand',
            items: _brands,
            searchQuery: _searchQuery,
          ),
          FilterSection(
            title: 'Product Type',
            items: _productTypes,
            searchQuery: _searchQuery,
          ),
          FilterSection(
            title: 'Colour',
            items: _colours,
            searchQuery: _searchQuery,
          ),
        ],
      ),
    );
  }

//
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButtons(),
        const SizedBox(width: 16),
        // if (!_showCreateProduct)
        //   Text('Total Products: ${_products.length}',
        //       style: const TextStyle(fontSize: 16)),
      ],
    );
  }

//
  Widget _buildActionButtons() {
    return Row(
      children: [
        // _buildSearchDropdown(),
        // const SizedBox(width: 16),
        if (_selectedSearchOption != null && _selectedSearchOption != 'Show All Products') _buildConditionalSearchBar(),
        const SizedBox(width: 300),
        if (!_showCreateProduct) Text('Total Products: $totalProducts', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 20),
        CustomButton(
          width: 150,
          height: 37,
          onTap: () => setState(() => _showCreateProduct = !_showCreateProduct),
          color: AppColors.primaryBlue,
          textColor: Colors.white,
          fontSize: 16,
          text: _showCreateProduct ? 'Back' : 'Create Products',
          borderRadius: BorderRadius.circular(8.0),
        ),
      ],
    );
  }

  Widget _buildSearchDropdown() {
    return CustomDropdown<String>(
      items: _searchOptions,
      selectedItem: _selectedSearchOption, // Default selected value
      hint: 'Search by',
      onChanged: (String? newValue) {
        setState(() {
          _selectedSearchOption = newValue; // Update the selected option
          _searchbarController.clear();
//
          // Load all products if "Show All Products" is selected
          if (_selectedSearchOption == 'Show All Products') {
            _currentPage = 1; // Reset the current page
            _hasMore = true;
            _products.clear(); // Clear the existing products
            loadMoreProducts(); // Call the method to load products
          }
        });
      },
      hintStyle: const TextStyle(color: Colors.grey),
      itemStyle: const TextStyle(color: Colors.black),
      // dropdownColor: Colors.white,
      borderColor: Colors.orange,
      borderWidth: 2.0,
      elevation: 8.0,
    );
  }

//
  Widget _buildConditionalSearchBar() {
    return SizedBox(
      width: 420,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchbarController,
              decoration: InputDecoration(
                hintText: 'Search by SkU or Name',
                // hintText: _getSearchHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.orange, width: 2.0),
                ),
              ),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _performSearch,
            // style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Search'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _refreshPage,
            // onPressed: loadMoreProducts,
            // style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

//
  String _getSearchHint() {
    switch (_selectedSearchOption) {
      case 'Display Name':
        return 'Search by Display Name';
      case 'SKU':
        return 'Search by SKU';
      default:
        return '';
    }
  }

//
  void _performSearch() async {
    if (_selectedSearchOption == null || _searchbarController.text.trim().isEmpty) {
      _refreshPage();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasMore = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final searchTerm = _searchbarController.text.trim();

    Logger().e("Search Term: $searchTerm");

    try {
      final response = searchTerm.contains('-')
          ? await authProvider.searchProductsBySKU(searchTerm)
          : await authProvider.searchProductsByDisplayName(searchTerm);

      if (response['success'] == true) {
        final List<dynamic>? productData = response['products'] ?? response['data'];

        Logger().e("Product Data: $productData");

        setState(() {
          _products.clear();
          if (productData != null) {
            _products.addAll(productData.map((data) => Product(
              sku: data['sku'] ?? '',
              parentSku: data['parentSku'] ?? '',
              ean: data['ean'] ?? '',
              description: data['description'] ?? '',
              categoryName: data['categoryName'] ?? '',
              brand: data['brand'] ?? '',
              colour: data['colour'] ?? '',
              netWeight: data['netWeight']?.toString() ?? '',
              grossWeight: data['grossWeight']?.toString() ?? '',
              labelSku: data['labelSku'] ?? '',
              outerPackage_quantity: data['outerPackage_quantity']?.toString() ?? '',
              outerPackage_name: data['outerPackage_name'] ?? '',
              grade: data['grade'] ?? '',
              technicalName: data['technicalName'] ?? '',
              length: data['length']?.toString() ?? '',
              width: data['width']?.toString() ?? '',
              height: data['height']?.toString() ?? '',
              mrp: data['mrp']?.toString() ?? '',
              cost: data['cost']?.toString() ?? '',
              tax_rule: data['tax_rule']?.toString() ?? '',
              shopifyImage: data['shopifyImage'] ?? '',
              createdDate: data['createdAt'] ?? '',
              lastUpdated: data['updatedAt'] ?? '',
              displayName: data['displayName'] ?? '',
              variantName: data['variant_name'] ?? '',
            )));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'No products found.')),
            );
          }
        });
      } else {
        _handleError(response['message']);
      }
    } catch (error) {
      log("Error - $error");
      _handleError('An error occurred: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refreshPage() {
    setState(() {
      _products.clear();
      _searchbarController.clear();
      loadMoreProducts();
    });
  }

  void _handleError(String? message) {
    setState(() => _products.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Something went wrong.')),
    );
  }

//
  Widget _buildProductList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          loadMoreProducts();
        }
        return false;
      },
      child: _products.isEmpty
          ? const Center(
              child: LoadingAnimation(
                icon: Icons.production_quantity_limits_rounded,
                beginColor: Color.fromRGBO(189, 189, 189, 1),
                endColor: AppColors.primaryBlue,
                size: 80.0,
              ),
            )
          : ListView.builder(
              itemCount: _products.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _products.length) {
                  return const Center(
                    child: LoadingAnimation(
                      icon: Icons.production_quantity_limits_rounded,
                      beginColor: Color.fromRGBO(189, 189, 189, 1),
                      endColor: AppColors.primaryBlue,
                      size: 80.0,
                    ),
                  );
                }
                return ProductCard(product: _products[index]);
              },
            ),
    );
  }

//
  // Sample data for filter sections
  List<String> get _categories => const [
        'NPK Fertilizer',
        'Hydroponic Nutrients',
        'Chemical product',
        'Organic Pest Control',
        'Lure & Traps',
      ];
//
  List<String> get _brands => const [
        'Katyayani Organics',
        'Katyayani',
        'KATYAYNI',
        'Samarthaa (Bulk)',
        'quinalphos 25%ec',
      ];
//
  List<String> get _productTypes => const [
        'Simple Products',
        'Products with Variants',
        'Virtual Combos',
        'Physical Combos(Kits)',
      ];
//
  List<String> get _colours => const [
        'NA',
        'shown an image',
        'Multicolour',
        '0',
      ];
}

// import 'package:flutter/material.dart';
// // import 'package:inventory_management/Custom-Files/custom-button.dart';
// import 'package:inventory_management/Custom-Files/loading_indicator.dart';
// import 'package:inventory_management/Custom-Files/colors.dart';
// import 'package:inventory_management/Custom-Files/product-card.dart';
// import 'package:inventory_management/Custom-Files/dropdown.dart';
// import 'package:inventory_management/provider/products-provider.dart';
// import 'package:provider/provider.dart';

// // import 'product_provider.dart';

// class ProductDashboardPage extends StatefulWidget {
//   const ProductDashboardPage({super.key});

//   @override
//   _ProductDashboardPageState createState() => _ProductDashboardPageState();
// }

// class _ProductDashboardPageState extends State<ProductDashboardPage> {
//   final TextEditingController _searchbarController = TextEditingController();
//   String? _selectedSearchOption = 'Display Name';
//   final List<String> _searchOptions = [
//     'Display Name',
//     'SKU',
//     'Show All Products'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final productProvider = Provider.of<ProductsProvider>(context, listen: false);
//       productProvider.loadMoreProducts();
//     });
//   }

//   @override
//   void dispose() {
//     _searchbarController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final productProvider = Provider.of<ProductsProvider>(context);

//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: Row(
//         children: [
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildHeader(productProvider),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: _buildProductList(productProvider),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(ProductsProvider productProvider) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildSearchDropdown(productProvider),
//         const SizedBox(width: 16),
//         Text('Total Products: ${productProvider.totalProducts}', style: const TextStyle(fontSize: 16)),
//       ],
//     );
//   }

//   Widget _buildSearchDropdown(ProductsProvider productProvider) {
//     return CustomDropdown<String>(
//       items: _searchOptions,
//       selectedItem: _selectedSearchOption,
//       hint: 'Search by',
//       onChanged: (String? newValue) {
//         setState(() {
//           _selectedSearchOption = newValue;
//           _searchbarController.clear();

//           if (_selectedSearchOption == 'Show All Products') {
//             productProvider.reset();
//             productProvider.loadMoreProducts();
//           }
//         });
//       },
//       hintStyle: const TextStyle(color: Colors.grey),
//       itemStyle: const TextStyle(color: Colors.black),
//       borderColor: Colors.orange,
//       borderWidth: 2.0,
//       elevation: 8.0,
//     );
//   }

//   Widget _buildProductList(ProductsProvider productProvider) {
//     return NotificationListener<ScrollNotification>(
//       onNotification: (ScrollNotification scrollInfo) {
//         if (!productProvider.isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//           productProvider.loadMoreProducts();
//         }
//         return false;
//       },
//       child: productProvider.products.isEmpty
//           ? const Center(
//               child: LoadingAnimation(
//                 icon: Icons.production_quantity_limits_rounded,
//                 beginColor: Color.fromRGBO(189, 189, 189, 1),
//                 endColor: AppColors.primaryBlue,
//                 size: 80.0,
//               ),
//             )
//           : ListView.builder(
//               itemCount: productProvider.products.length + (productProvider.hasMore ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index == productProvider.products.length) {
//                   return const Center(
//                     child: LoadingAnimation(
//                       icon: Icons.production_quantity_limits_rounded,
//                       beginColor: Color.fromRGBO(189, 189, 189, 1),
//                       endColor: AppColors.primaryBlue,
//                       size: 80.0,
//                     ),
//                   );
//                 }
//                 return ProductCard(product: productProvider.products[index]);
//               },
//             ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:inventory_management/Custom-Files/custom-button.dart';
// import 'package:inventory_management/Custom-Files/loading_indicator.dart';
// import 'package:inventory_management/Custom-Files/colors.dart';
// import 'package:inventory_management/Custom-Files/product-card.dart';
// import 'package:inventory_management/Custom-Files/dropdown.dart';
// import 'package:inventory_management/products.dart';
// import 'package:inventory_management/provider/products-provider.dart';
// import 'package:provider/provider.dart';

// class ProductDashboardPage extends StatefulWidget {
//   const ProductDashboardPage({super.key});

//   @override
//   _ProductDashboardPageState createState() => _ProductDashboardPageState();
// }

// class _ProductDashboardPageState extends State<ProductDashboardPage> {
//   final TextEditingController _searchbarController = TextEditingController();
//   String? _selectedSearchOption = 'Display Name';
//   final List<String> _searchOptions = ['Display Name', 'SKU', 'Show All Products'];
//   bool _showCreateProduct = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final productProvider = Provider.of<ProductsProvider>(context, listen: false);
//       productProvider.loadMoreProducts();
//     });
//   }

//   @override
//   void dispose() {
//     _searchbarController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final productProvider = Provider.of<ProductsProvider>(context);

//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: Row(
//         children: [
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildHeader(productProvider),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: !_showCreateProduct
//                         ? _buildProductList(productProvider)
//                         : const Products(),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(ProductsProvider productProvider) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildSearchDropdown(productProvider),
//         const SizedBox(width: 16),
//         Text(
//           'Total Products: ${productProvider.totalProducts}',
//           style: const TextStyle(fontSize: 16),
//         ),
//         const SizedBox(width: 20),
//         CustomButton(
//           width: 150,
//           height: 37,
//           onTap: () => setState(() => _showCreateProduct = !_showCreateProduct),
//           color: AppColors.primaryBlue,
//           textColor: Colors.white,
//           fontSize: 16,
//           text: _showCreateProduct ? 'Back' : 'Create Product',
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchDropdown(ProductsProvider productProvider) {
//     return CustomDropdown<String>(
//       items: _searchOptions,
//       selectedItem: _selectedSearchOption,
//       hint: 'Search by',
//       onChanged: (String? newValue) {
//         setState(() {
//           _selectedSearchOption = newValue;
//           _searchbarController.clear();

//           if (_selectedSearchOption == 'Show All Products') {
//             productProvider.reset();
//             productProvider.loadMoreProducts();
//           }
//         });
//       },
//       hintStyle: const TextStyle(color: Colors.grey),
//       itemStyle: const TextStyle(color: Colors.black),
//       borderColor: Colors.orange,
//       borderWidth: 2.0,
//       elevation: 8.0,
//     );
//   }

//   Widget _buildProductList(ProductsProvider productProvider) {
//     return NotificationListener<ScrollNotification>(
//       onNotification: (ScrollNotification scrollInfo) {
//         if (!productProvider.isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
//           productProvider.loadMoreProducts();
//         }
//         return false;
//       },
//       child: productProvider.products.isEmpty
//           ? const Center(
//         child: LoadingAnimation(
//           icon: Icons.production_quantity_limits_rounded,
//           beginColor: Color.fromRGBO(189, 189, 189, 1),
//           endColor: AppColors.primaryBlue,
//           size: 80.0,
//         ),
//       )
//           : ListView.builder(
//         itemCount: productProvider.products.length + (productProvider.hasMore ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == productProvider.products.length) {
//             return const Center(
//               child: LoadingAnimation(
//                 icon: Icons.production_quantity_limits_rounded,
//                 beginColor: Color.fromRGBO(189, 189, 189, 1),
//                 endColor: AppColors.primaryBlue,
//                 size: 80.0,
//               ),
//             );
//           }
//           return ProductCard(product: productProvider.products[index]);
//         },
//       ),
//     );
//   }
// }
