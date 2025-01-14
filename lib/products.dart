import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/product-page-api.dart';
import 'package:inventory_management/Widgets/dropdown.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';
import 'package:inventory_management/Custom-Files/custom-textfield.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/multi-image-picker.dart';
import 'package:inventory_management/Custom-Files/textfield-in-alert-box.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  // String productProvider!.selectedProductCategory = "Create Simple Product";
  List<String>? webImages;
  // int variationCount = 1;

  CustomDropdown brandd = CustomDropdown();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productIdentifierController =
      TextEditingController();
  final TextEditingController _productBrandController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _accountingItemNameController =
      TextEditingController();
  final TextEditingController _accountingItemUnitController =
      TextEditingController();
  final TextEditingController _materialTypeController = TextEditingController();
  final TextEditingController _predefinedTaxRuleController =
      TextEditingController();
  final TextEditingController _productTaxCodeController =
      TextEditingController();
  final TextEditingController _productSpecificationController =
      TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _netWeightController = TextEditingController();
  final TextEditingController _grossWeightController = TextEditingController();
  final TextEditingController _shopifyController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _eanUpcController = TextEditingController();
  final TextEditingController _technicalNameController =
      TextEditingController();
  final TextEditingController _variantNameController = TextEditingController();
  final TextEditingController _parentSkuController = TextEditingController();
  String? token;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<CustomDropdownState> dropdownKey =
      GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> categoryKey =
      GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> labelKey =
      GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> colorKey =
      GlobalKey<CustomDropdownState>();

  final GlobalKey<CustomDropdownState> sizeKey =
      GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> gradeKey =
      GlobalKey<CustomDropdownState>();
  // final GlobalKey<CustomDropdown> _scaffoldKey = GlobalKey<CustomDropdown>();
  // Add a form key
  // final _brandDropdownKey = GlobalKey<CustomDropdownState>();
  String? selectedItemName;
  String? selectedBrandId;
  String? selectedCategory;
  String? selectedLabelSku;
  String? selectedBoxName;
  String? selectedGrade;
  String? selectedParentSku;

  @override
  void dispose() {
    _productNameController.dispose();
    _productIdentifierController.dispose();
    _productBrandController.dispose();
    _modelNameController.dispose();
    _modelNumberController.dispose();
    _descriptionController.dispose();
    _accountingItemNameController.dispose();
    _accountingItemUnitController.dispose();
    _materialTypeController.dispose();
    _predefinedTaxRuleController.dispose();
    _productTaxCodeController.dispose();
    _productSpecificationController.dispose();
    _mrpController.dispose();
    _costController.dispose();
    _netWeightController.dispose();
    _grossWeightController.dispose();
    _shopifyController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _technicalNameController.dispose();
    _variantNameController.dispose();
    _parentSkuController.dispose();

    super.dispose();
  }

  void clear() {
    setState(() {
      // Reset dropdown indexes
      selectedIndexOfBrand = 0;
      selectedIndexOfCategory = 0;
      selectedIndexOfLabel = 0;
      selectedIndexOfBoxSize = 0;
      selectedIndexOfColorDrop = 0;

      // Reset dropdown states
      dropdownKey.currentState!.reset();
      categoryKey.currentState!.reset();
      labelKey.currentState!.reset();
      colorKey.currentState!.reset();
      sizeKey.currentState!.reset();
      gradeKey.currentState!.reset();

      // Clear all text controllers
      _productNameController.clear();
      _productIdentifierController.clear();
      _productBrandController.clear();
      _modelNameController.clear();
      _modelNumberController.clear();
      _descriptionController.clear();
      _accountingItemNameController.clear();
      _accountingItemUnitController.clear();
      _materialTypeController.clear();
      _predefinedTaxRuleController.clear();
      _productTaxCodeController.clear();
      _productSpecificationController.clear();
      _mrpController.clear();
      _costController.clear();
      _netWeightController.clear();
      _grossWeightController.clear();
      _shopifyController.clear();
      _lengthController.clear();
      _widthController.clear();
      _depthController.clear();
      _sizeController.clear();
      _eanUpcController.clear();
      _colorController.clear();
      _skuController.clear();
      _technicalNameController.clear();
      _variantNameController.clear();
      _parentSkuController.clear();

      // Reset selected values
      selectedBrandId = null;
      selectedCategory = null;
      selectedLabelSku = null;
      selectedBoxName = null;
      selectedParentSku = null;
      selectedGrade = null;
      selectedItemName = null;

      // Reset active status if needed
      activeStatus = false;

      // Clear any web images if they exist
      webImages?.clear();

      // Reset product category to default if needed
      // productProvider?.selectedProductCategory = "Create Simple Product";
    });
  }

  ProductProvider? productProvider;
  int selectedIndexOfBrand = 0;
  int selectedIndexOfCategory = 0;
  int selectedIndexOfLabel = 0;
  int selectedIndexOfBoxSize = 0;
  int selectedIndexOfColorDrop = 0;
  bool activeStatus = false;
  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    try {
      productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider!.getCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("some error ${e.toString()}")));
      productProvider!.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, pr, child) => productProvider!.noData
          ? const Center(
              child: Text(
              "You cannot create product due to some internal error",
              style: TextStyle(fontSize: 16, color: Colors.red),
            ))
          : productProvider!.isloading
              ? _buildMainContent(context)
              : const Center(
                  child: LoadingAnimation(
                    icon: Icons.production_quantity_limits_rounded,
                    beginColor: Color.fromRGBO(189, 189, 189, 1),
                    endColor: AppColors.primaryBlue,
                    size: 80.0,
                  ),
                ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return
        // MediaQuery.of(context).size.width > 1200
        //     ?
        Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add header section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_business, color: AppColors.primaryBlue),
                  SizedBox(width: 12),
                  Text(
                    'Create New Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: webLayout(context),
              ),
            ),
          ],
        ),
      ),
    );
    // : mobileLayout(context);
  }

  Widget formLayout(Widget title, Widget anyWidget,
      {MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
      double width = 1200}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Container(
            width: 200,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24, top: 8),
            child: title,
          ),
          const SizedBox(width: 24),
          Expanded(child: anyWidget),
        ],
      ),
    );
  }

  Widget fieldTitle(String filTitle,
      {double height = 51, double width = 173.3, bool show = false}) {
    return SizedBox(
      height: height,
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            filTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              letterSpacing: 0.3,
            ),
          ),
          show
              ? const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                )
              : const Text(' '),
        ],
      ),
    );
  }

  Widget radioCheck(String title, Function(String?) onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Radio<String>(
            value: title,
            groupValue: productProvider!.selectedProductCategory,
            onChanged: onTap,
            activeColor: AppColors.primaryBlue,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildSaveActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Wrap(
        // Changed from Row to Wrap
        spacing: 16, // Horizontal spacing between buttons
        runSpacing: 16, // Vertical spacing between rows if buttons wrap
        children: [
          // Save Button
          SizedBox(
            width: 200,
            height: 45,
            child: ElevatedButton(
              onPressed: productProvider!.saveButtonClick ? null : saveButton,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primaryBlue,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withOpacity(0.1);
                    }
                    return null;
                  },
                ),
              ),
              child: productProvider!.saveButtonClick
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Save Product",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Reset Button
          SizedBox(
            width: 150,
            height: 45,
            child: TextButton(
              onPressed: clear,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.grey[100];
                    }
                    return null;
                  },
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    "Reset",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void saveButton() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate dropdown selections
    if (!_validateDropdowns()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required dropdown fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure SKU and Parent SKU are the same for 'Variant Product Creation'
    if (productProvider!.selectedProductCategory ==
        'Variant Product Creation') {
      selectedParentSku = _skuController.text.trim();
    }

    productProvider!.saveButtonClickStatus();

    try {
      var res = await ProductPageApi().createProduct(
        context: context,
        displayName: _productNameController.text.trim(),
        parentSku: productProvider!.selectedProductCategory == 'Create Simple Product'
            ? _skuController.text.trim()
            : selectedParentSku ?? '',
        sku: _skuController.text.trim(),
        ean: _eanUpcController.text.trim(),
        brand_id: selectedBrandId ?? '', ///////////////////////////////////////
        outerPackage_quantity:
            selectedBoxName ?? '', ///////////////////////////
        description: _descriptionController.text.trim(),
        technicalName: _technicalNameController.text.trim(),
        label_quantity: selectedLabelSku ?? '', ////////////////////////////
        tax_rule: _predefinedTaxRuleController.text.trim(),
        length: _lengthController.text.trim(),
        width: _widthController.text.trim(),
        height: _depthController.text.trim(),
        netWeight: _netWeightController.text.trim(),
        grossWeight: _grossWeightController.text.trim(),
        mrp: _mrpController.text.trim(),
        cost: _costController.text.trim(),
        active: productProvider!.activeStatus,
        labelSku: selectedLabelSku ?? '', //////////////////////////////////////
        outerPackage_sku: selectedBoxName ?? '', ////////////////////////////
        categoryName: selectedCategory ?? '', //////////////////////////////
        grade: selectedGrade ?? 'A', ///////////////////////////////////////
        shopifyImage: _shopifyController.text.trim(),
        variant_name: _variantNameController.text.trim(),
        itemQty: selectedBoxName ?? '', /////////////////////////////////
      );

      // Log the actual values being sent
      log('''
      Sending to API:
      Brand ID: $selectedBrandId
      Category: $selectedCategory
      Label SKU: $selectedLabelSku
      Box Name: $selectedBoxName
      ''');

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product created successfully')),
        );
        clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.body}')),
        );
      }
    } catch (error) {
      log('Error creating product: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      productProvider!.saveButtonClickStatus();
    }
  }

  // Add new method to validate dropdowns
  bool _validateDropdowns() {
    // if (selectedBrandId == null) {
    //   _scrollToField('Brand');
    //   return false;
    // }
    // if (selectedCategory == null) {
    //   _scrollToField('Category');
    //   return false;
    // }
    // if (selectedLabelSku == null) {
    //   _scrollToField('Label');
    //   return false;
    // }
    // if (selectedBoxName == null) {
    //   _scrollToField('Size');
    //   return false;
    // }
    if (productProvider!.selectedProductCategory ==
            'Variant Product Creation' &&
        selectedParentSku == null) {
      _scrollToField('Parent SKU');
      return false;
    }
    return true;
  }

  // Helper method to scroll to problematic field
  void _scrollToField(String fieldName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select a $fieldName'),
        backgroundColor: Colors.red,
      ),
    );
  }

  //for web layout
  Widget webLayout(
    BuildContext context,
  ) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              formLayout(
                fieldTitle('Product Category'),
                customRadioButtonLayout(context),
              ),
              const SizedBox(
                height: 8,
              ),
              formLayout(
                fieldTitle('Product Name', show: true),
                CustomTextField(
                    controller: _productNameController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product Name is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(
                height: 12,
              ),
              if (productProvider!.selectedProductCategory ==
                  'Variant Product Creation')
                formLayout(
                  fieldTitle('Parent SKU', show: true),
                  SizedBox(
                    width: 550,
                    child: PaginatedSearchDropdown(
                      hintText: 'Search Parent SKU...',
                      fetchItems: fetchParentSkusFromApi,
                      dropdownWidth: 550,
                      isParentSku: true,
                      onItemSelected: (id) {
                        setState(() {
                          selectedParentSku = id;
                        });
                        log('Selected Parent SKU: $id');
                      },
                    ),
                  ),
                ),
              if (productProvider!.selectedProductCategory ==
                  'Variant Product Creation')
                const SizedBox(height: 12),
              formLayout(
                fieldTitle('SKU', show: true, height: 50, width: 110),
                SizedBox(
                  child: CustomTextField(
                      controller: _skuController,
                      height: 51,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'SKU is required';
                        }
                        return null;
                      }),
                ),
              ),
              const SizedBox(height: 12),

              // formLayout(
              //   fieldTitle('Variant Name', height: 50, width: 150),
              //   CustomTextField(
              //     controller: _variantNameController,
              //     height: 51,
              //     // validator: (value) {
              //     //   if (value == null || value.isEmpty) {
              //     //     return 'Variant Name is required';
              //     //   }
              //     //   return null;
              //     // },
              //   ),
              // ),
              // const SizedBox(height: 12),

              formLayout(
                fieldTitle('Brand'),
                SizedBox(
                  width: 550,
                  child: PaginatedSearchDropdown(
                    hintText: 'Search Brand...',
                    fetchItems: fetchBrandsFromApi,
                    dropdownWidth: 550,
                    isBrand: true,
                    onItemSelected: (id) {
                      setState(() {
                        selectedBrandId = id;
                      });
                      debugPrint('Selected Brand ID: $id');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Category'),
                Row(
                  children: [
                    SizedBox(
                      width: 550,
                      child: PaginatedSearchDropdown(
                        hintText: 'Search Category...',
                        fetchItems: fetchCategoryFromApi,
                        dropdownWidth: 550,
                        onItemSelected: (id) {
                          setState(() {
                            selectedCategory = id;
                          });
                          log('Selected Category ID: $id');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          CustomAlertBox.diaglogWithOneTextField(context);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'New',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          backgroundColor: Colors.blue.shade50,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          minimumSize: const Size(70, 51),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.hovered)) {
                                return Colors.blue.shade100;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // productProvider!.selectedProductCategory ==
              //         'Variant Product Creation'
              //     ? formLayout(
              //         fieldTitle('Variations'),
              //         variantProductCreation(context),
              //       )
              //     : const SizedBox(),
              productProvider!.selectedProductCategory ==
                      'Variant Product Creation'
                  ? const SizedBox(height: 12)
                  : const SizedBox(),
              productProvider!.selectedProductCategory ==
                      'Variant Product Creation'
                  ? formLayout(
                      fieldTitle('Technical Name'),
                      CustomTextField(
                        controller: _technicalNameController,
                        height: 51,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Technical name is required';
                        //   }
                        //   return null;
                        // },
                      ),
                    )
                  : const SizedBox(),
              const SizedBox(height: 12),
              ///////////////////////////////////////////// same as brand field
              formLayout(
                fieldTitle('Label'),
                SizedBox(
                  width: 550,
                  child: PaginatedSearchDropdown(
                    hintText: 'Search Label...',
                    isLabel: true,
                    fetchItems: fetchLabelFromApi,
                    dropdownWidth: 550,
                    onItemSelected: (id) {
                      setState(() {
                        selectedLabelSku = id;
                      });
                      log('Selected Label ID: $id');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Description'),
                CustomTextField(
                  controller: _descriptionController,
                  height: 100,
                  maxLines: 150,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Description is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),

              const SizedBox(height: 12),

              formLayout(
                fieldTitle('Predefined Tax Rule'),
                CustomTextField(
                  controller: _predefinedTaxRuleController,
                  height: 51,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Accounting Item Name is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              // const SizedBox(height: 12),
              const SizedBox(height: 12),
              // formLayout(
              //   fieldTitle('Specifications'),
              //   Container(
              //     width: 550,
              //     height: 250,
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.black.withOpacity(0.2)),
              //       borderRadius: BorderRadius.circular(10),
              //       color: Colors.white30,
              //     ),
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         formLayout(
              //             fieldTitle(
              //               'Size',
              //               height: 51,
              //             ),
              //             CustomTextField(
              //               controller: _sizeController,
              //               width: 150,
              //               validator: (value) {
              //                 if (value == null || value.isEmpty) {
              //                   return 'Size is required';
              //                 }
              //                 return null;
              //               },
              //             ),
              //             mainAxisAlignment: MainAxisAlignment.center),
              //         const SizedBox(height: 8.0),
              //         formLayout(
              //             fieldTitle(
              //               'Color',
              //               height: 51,
              //             ),
              //             SizedBox(
              //               // color: Colors.blueAccent,
              //               width: 150,
              //               height: 51,
              //               child: CustomDropdown(
              //                 key: colorKey,
              //                 option: productProvider!.colorDrop,
              //                 onSelectedChanged: (val) {
              //                   selectedIndexOfColorDrop = val;
              //                 },
              //               ),
              //             ),
              //             mainAxisAlignment: MainAxisAlignment.center),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
              formLayout(
                fieldTitle('MRP'),
                CustomTextField(
                  controller: _mrpController,
                  height: 51,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'MRP is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Cost'),
                CustomTextField(
                  controller: _costController,
                  height: 51,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Cost is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Net Weight'),
                CustomTextField(
                  controller: _netWeightController,
                  height: 51,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Weight is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Gross Weight'),
                CustomTextField(
                  controller: _grossWeightController,
                  height: 51,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Weight is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Shopify Image'),
                CustomTextField(
                  controller: _shopifyController,
                  height: 51,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'image is required';
                  //   }
                  //   return null;
                  // },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Package Dimensions', width: 200),
                SizedBox(
                  width: 550,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _lengthController,
                          prefix: 'L',
                          // width: MediaQuery.of(context).size.width * 0.15,
                          unit: 'cm',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('x'),
                      const SizedBox(width: 6),
                      Expanded(
                        child: CustomTextField(
                          controller: _widthController,
                          // width: MediaQuery.of(context).size.width * 0.15,
                          prefix: 'W',
                          unit: 'cm',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('x'),
                      const SizedBox(width: 6),
                      Expanded(
                        child: CustomTextField(
                          controller: _depthController,
                          // width: MediaQuery.of(context).size.width * 0.15,
                          prefix: 'H',
                          unit: 'cm',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Size'),
                SizedBox(
                  width: 550,
                  child: PaginatedSearchDropdown(
                    hintText: 'Search Box Size...',
                    fetchItems: fetchBoxSizeFromApi,
                    dropdownWidth: 550,
                    isBoxSize: true,
                    onItemSelected: (id) {
                      Logger().e(id);
                      setState(() {
                        selectedBoxName = id;
                      });
                      log('Selected Box Size ID: $id');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Grade'),
                SizedBox(
                  width: 550,
                  child: CustomDropdown(
                    key: gradeKey,
                    grade: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Custom Fields', show: false),
                Container(
                  height: 120,
                  width: 550,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Custom Properties',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                CustomAlertBox.showKeyValueDialog(context);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Field'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'No custom fields added yet',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Active Status'),
                SizedBox(
                  width: 550,
                  child: CupertinoSwitch(
                    value: productProvider!.activeStatus,
                    onChanged: (value) {
                      productProvider!.changeActiveStaus();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Select Image'),
                const SizedBox(
                  width: 550,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        child: CustomPicker(),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              formLayout(
                fieldTitle(''),
                buildSaveActionButtons(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget customRadioButtonLayout(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.width > 1200 &&
              MediaQuery.of(context).size.width < 1400
          ? 90
          : 50,
      child: Column(
        children: [
          const SizedBox(height: 9.0),
          Row(
            children: [
              radioCheck('Create Simple Product', (val) {
                productProvider!.updateSelectedProductCategory(val!);
              }),
              radioCheck('Variant Product Creation', (val) {
                productProvider!.updateSelectedProductCategory(val!);
              }),
              // MediaQuery.of(context).size.width > 1400
              //     ? radioCheck('Create Virtual Combo Products', (val) {
              //         productProvider!.updateSelectedProductCategory(val!);
              //       })
              //     : const SizedBox(),
              // MediaQuery.of(context).size.width > 1400
              //     ? radioCheck('Create Kit Products', (val) {
              //         productProvider!.updateSelectedProductCategory(val!);
              //       })
              //     : const SizedBox(),
            ],
          ),
          // MediaQuery.of(context).size.width > 1200 &&
          //         MediaQuery.of(context).size.width < 1400
          //     ? Padding(
          //         padding: const EdgeInsets.only(left: 20),
          //         child: Row(
          //           children: [
          //             radioCheck('Create Virtual Combo Products', (val) {
          //               productProvider!.updateSelectedProductCategory(val!);
          //             }),
          //             radioCheck('Create Kit Products', (val) {
          //               productProvider!.updateSelectedProductCategory(val!);
          //             }),
          //           ],
          //         ),
          //       )
          //     : const SizedBox(),
        ],
      ),
    );
  }

  Widget variantProductCreation(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.64,
      // color:Colors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50 +
                ((MediaQuery.of(context).size.width > 940 ? 51.0 : 102 + 40.0) *
                    productProvider!.countVariationFields),
            child: ListView.builder(
              itemBuilder: (context, index) {
                return MediaQuery.of(context).size.width > 940
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              index == 0
                                  ? const Text('Colors')
                                  : const SizedBox(),
                              SizedBox(
                                width: 130,
                                // color:Colors.brown,
                                child: CustomTextField(
                                  controller: productProvider!.color[index],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              index == 0
                                  ? const Text('Size')
                                  : const SizedBox(),
                              SizedBox(
                                width: 130,
                                child: CustomTextField(
                                    controller: productProvider!.size[index],
                                    height: 51,
                                    width: 130),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              index == 0 ? const Text('SKU') : const SizedBox(),
                              SizedBox(
                                width: 130,
                                child: CustomTextField(
                                    controller: productProvider!.sku[index],
                                    height: 51,
                                    width: 130),
                              ),
                            ],
                          ),
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomButton(
                                  width: 40,
                                  height: 40,
                                  onTap: () {
                                    productProvider!
                                        .deleteTextEditingController(index);
                                  },
                                  color: AppColors.cardsgreen,
                                  textColor: AppColors.black,
                                  fontSize: 25,
                                  text: '--')),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                  width: 150,
                                  child: Column(
                                    children: [
                                      const Text('Colors'),
                                      CustomTextField(
                                          controller:
                                              productProvider!.color[index]),
                                    ],
                                  )),
                              const SizedBox(
                                width: 2,
                              ),
                              SizedBox(
                                  width: 150,
                                  child: Column(
                                    children: [
                                      const Text('Size'),
                                      CustomTextField(
                                          controller:
                                              productProvider!.size[index]),
                                    ],
                                  ))
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                  width: 150,
                                  child: Column(
                                    children: [
                                      const Text('SKU'),
                                      CustomTextField(
                                          controller:
                                              productProvider!.sku[index]),
                                    ],
                                  )),
                            ],
                          ),
                          CustomButton(
                              width: 40,
                              height: 40,
                              onTap: () {
                                productProvider!
                                    .deleteTextEditingController(index);
                              },
                              color: AppColors.cardsgreen,
                              textColor: AppColors.black,
                              fontSize: 25,
                              text: '--')
                        ],
                      );
              },
              itemCount: productProvider!.countVariationFields,
            ),
          ),
          CustomButton(
              width: 150,
              height: 25,
              onTap: () {
                productProvider!.addNewTextEditingController();
              },
              color: AppColors.cardsgreen,
              textColor: AppColors.black,
              fontSize: 15,
              text: '+ Add New')
        ],
      ),
    );
  }
}
