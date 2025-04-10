import 'dart:convert';
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
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'Custom-Files/sub_category_search_field.dart';
import 'Custom-Files/utils.dart';

class CreateProduct extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateProduct({super.key, required this.onCreated});

  @override
  State<CreateProduct> createState() => _CreateProductState();
}

class _CreateProductState extends State<CreateProduct> {
  String? token;
  List<String>? webImages;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productIdentifierController = TextEditingController();
  final TextEditingController _productBrandController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _accountingItemNameController = TextEditingController();
  final TextEditingController _accountingItemUnitController = TextEditingController();
  final TextEditingController _materialTypeController = TextEditingController();
  final TextEditingController _predefinedTaxRuleController = TextEditingController();
  final TextEditingController _productTaxCodeController = TextEditingController();
  final TextEditingController _productSpecificationController = TextEditingController();
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
  final TextEditingController _itemQtyController = TextEditingController();

  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _eanUpcController = TextEditingController();
  final TextEditingController _technicalNameController = TextEditingController();
  final TextEditingController _variantNameController = TextEditingController();
  final TextEditingController _parentSkuController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<CustomDropdownState> dropdownKey = GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> categoryKey = GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> labelKey = GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> colorKey = GlobalKey<CustomDropdownState>();

  final GlobalKey<CustomDropdownState> sizeKey = GlobalKey<CustomDropdownState>();
  final GlobalKey<CustomDropdownState> gradeKey = GlobalKey<CustomDropdownState>();

  String? selectedItemName;
  String? selectedBrandId;
  String? selectedBrandName;
  String? selectedCategoryId;
  String? selectedCategoryName;
  String? selectedLabelSku;
  String? selectedLabelId;
  String? selectedBoxName;
  String? selectedBoxId;
  String? selectedGrade;
  String? selectedParentSku;
  String? selectedSubCategoryName;
  String? selectedSubCategoryId;

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
      selectedIndexOfBrand = 0;
      selectedIndexOfCategory = 0;
      selectedIndexOfLabel = 0;
      selectedIndexOfBoxSize = 0;
      selectedIndexOfColorDrop = 0;

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

      selectedBrandId = null;
      selectedBrandName = null;
      selectedCategoryId = null;
      selectedCategoryName = null;
      selectedLabelSku = null;
      selectedLabelId = null;
      selectedBoxName = null;
      selectedBoxId = null;
      selectedParentSku = null;
      selectedGrade = null;
      selectedItemName = null;
      selectedSubCategoryName = null;
      selectedSubCategoryId = null;

      activeStatus = false;

      webImages?.clear();
    });

    widget.onCreated.call();
  }

  late ProductProvider productProvider;
  int selectedIndexOfBrand = 0;
  int selectedIndexOfCategory = 0;
  int selectedIndexOfLabel = 0;
  int selectedIndexOfBoxSize = 0;
  int selectedIndexOfColorDrop = 0;
  bool activeStatus = false;
  @override
  void initState() {
    productProvider = Provider.of<ProductProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getData();
    });
    super.initState();
  }

  void getData() async {
    try {
      productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.getCategories();
    } catch (e) {
      Utils.showSnackBar(context, e.toString(), seconds: 5, color: AppColors.cardsred);
      productProvider.update();
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
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
  }

  Widget formLayout(Widget title, Widget anyWidget, {MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start, double width = 1200}) {
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

  Widget fieldTitle(String filTitle, {double height = 51, double width = 173.3, bool required = false}) {
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
          required
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
        spacing: 16,
        runSpacing: 16,
        children: [
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
                      return Colors.white.withValues(alpha: 0.1);
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
                        Icon(
                          Icons.save,
                          size: 20,
                          color: Colors.white,
                        ),
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
    if (!_formKey.currentState!.validate()) {
      Utils.showSnackBar(context, 'Please fill all required fields correctly', isError: true);
      return;
    }

    if (!_validateDropdowns()) {
      Utils.showSnackBar(context, 'Please select all required dropdown fields', isError: true);
      return;
    }

    if (productProvider!.selectedProductCategory == 'Variant Product Creation') {
      selectedParentSku = _skuController.text.trim();
    }

    productProvider!.saveButtonClickStatus();

    try {
      var res = await ProductPageApi().createProduct(
        context: context,
        displayName: _productNameController.text.trim(),
        parentSku: productProvider.selectedProductCategory == 'Create Simple Product'
            ? _skuController.text.trim().replaceAll(RegExp(r'\s+'), '')
            : selectedParentSku?.replaceAll(RegExp(r'\s+'), '') ?? '',
        sku: _skuController.text.trim().replaceAll(RegExp(r'\s+'), ''),
        ean: _eanUpcController.text.trim(),
        brand_id: selectedBrandId ?? '',
        outerPackage_quantity: selectedBoxName ?? '',
        description: _descriptionController.text.trim(),
        technicalName: _technicalNameController.text.trim(),
        label_quantity: selectedLabelSku ?? '',
        tax_rule: _predefinedTaxRuleController.text.trim(),
        length: _lengthController.text.trim(),
        width: _widthController.text.trim(),
        height: _depthController.text.trim(),
        netWeight: _netWeightController.text.trim(),
        grossWeight: _grossWeightController.text.trim(),
        mrp: _mrpController.text.trim(),
        cost: _costController.text.trim(),
        active: productProvider!.activeStatus,
        labelSku: selectedLabelId ?? '',
        outerPackage_sku: selectedBoxName ?? '',
        category: selectedCategoryId ?? '',
        sub_category: selectedSubCategoryId ?? '',
        grade: selectedGrade ?? 'A',
        shopifyImage: _shopifyController.text.trim(),
        variant_name: _variantNameController.text.trim(),
        itemQty: _itemQtyController.text.trim() ?? '',
      );

      final responseData = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Utils.showSnackBar(context, 'Product created successfully', color: AppColors.cardsgreen);
        clear();
      } else {
        Utils.showSnackBar(context, responseData['message'], isError: true);
      }
    } catch (error, s) {
      log('Error creating product: $error \n\n$s');
      Utils.showSnackBar(context, error.toString(), details: error.toString(), isError: true);
    } finally {
      productProvider!.saveButtonClickStatus();
    }
  }

  bool _validateDropdowns() {
    if (selectedCategoryId == null) {
      _scrollToField('Category');
      return false;
    }

    if (productProvider!.selectedProductCategory == 'Variant Product Creation' && selectedParentSku == null) {
      _scrollToField('Parent SKU');
      return false;
    }
    return true;
  }

  void _scrollToField(String fieldName) {
    Utils.showSnackBar(context, 'Please select a $fieldName', isError: true);
  }

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
                fieldTitle('Product Name', required: true),
                CustomTextField(
                    controller: _productNameController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Product Name is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(
                height: 12,
              ),
              if (productProvider!.selectedProductCategory == 'Variant Product Creation')
                formLayout(
                  fieldTitle('Parent SKU', required: true),
                  SizedBox(
                    width: 550,
                    child: PaginatedSearchDropdown(
                      hintText: 'Search Parent SKU...',
                      fetchItems: fetchParentSkusFromApi,
                      dropdownWidth: 550,
                      isParentSku: true,
                      onItemSelected: (data) {
                        setState(() {
                          selectedParentSku = data['value'];
                        });
                      },
                    ),
                  ),
                ),
              if (productProvider!.selectedProductCategory == 'Variant Product Creation') const SizedBox(height: 12),
              formLayout(
                fieldTitle('SKU', required: true, height: 50, width: 110),
                SizedBox(
                  child: CustomTextField(
                      controller: _skuController,
                      height: 51,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'SKU is required';
                        }
                        return null;
                      }),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Item Quantity', required: true),
                SizedBox(
                  child: CustomTextField(
                    controller: _itemQtyController,
                    height: 51,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Item quantity is required";
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Brand'),
                SizedBox(
                  width: 550,
                  child: PaginatedSearchDropdown(
                    hintText: 'Search Brand...',
                    fetchItems: fetchBrandsFromApi,
                    dropdownWidth: 550,
                    isBrand: true,
                    onItemSelected: (data) {
                      setState(() {
                        selectedBrandId = data['id'];
                        selectedBrandName = data['value'];
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Category', required: true),
                Row(
                  children: [
                    SizedBox(
                      width: 550,
                      child: PaginatedSearchDropdown(
                        hintText: 'Search Category...',
                        fetchItems: fetchCategoryFromApi,
                        dropdownWidth: 550,
                        onItemSelected: (data) {
                          setState(() {
                            selectedCategoryId = data['id'];
                            selectedCategoryName = data['value'];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Sub-category', required: true),
                SubCategorySearchableTextField(
                  isRequired: true,
                  categoryName: selectedCategoryName,
                  onSelected: (subCategory) {
                    if (subCategory != null) {
                      setState(() {
                        selectedSubCategoryName = subCategory.name;
                        selectedSubCategoryId = subCategory.id;
                      });
                      print('Selected: ${subCategory.name}, ID: ${subCategory.id}, Category: ${subCategory.category}');
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              productProvider!.selectedProductCategory == 'Variant Product Creation' ? const SizedBox(height: 12) : const SizedBox(),
              productProvider!.selectedProductCategory == 'Variant Product Creation'
                  ? formLayout(
                      fieldTitle('Technical Name'),
                      CustomTextField(
                        controller: _technicalNameController,
                        height: 51,
                      ),
                    )
                  : const SizedBox(),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Label'),
                SizedBox(
                  width: 550,
                  child: PaginatedSearchDropdown(
                    hintText: 'Search Label...',
                    isLabel: true,
                    fetchItems: fetchLabelFromApi,
                    dropdownWidth: 550,
                    onItemSelected: (data) {
                      setState(() {
                        selectedLabelId = data['id'];
                        selectedLabelSku = data['value'];
                      });
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
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Predefined Tax Rule'),
                CustomTextField(
                  controller: _predefinedTaxRuleController,
                  height: 51,
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('MRP'),
                CustomTextField(
                  controller: _mrpController,
                  height: 51,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Cost'),
                CustomTextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  height: 51,
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Net Weight', required: true),
                CustomTextField(
                  controller: _netWeightController,
                  height: 51,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weight is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Gross Weight', required: true),
                CustomTextField(
                  keyboardType: TextInputType.number,
                  controller: _grossWeightController,
                  height: 51,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weight is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Shopify Image'),
                CustomTextField(
                  controller: _shopifyController,
                  height: 51,
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
                    onItemSelected: (data) {
                      Logger().e(data);
                      setState(() {
                        selectedBoxName = data['value'];
                      });
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
      height: MediaQuery.of(context).size.width > 1200 && MediaQuery.of(context).size.width < 1400 ? 90 : 50,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget variantProductCreation(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50 + ((MediaQuery.of(context).size.width > 940 ? 51.0 : 102 + 40.0) * productProvider!.countVariationFields),
            child: ListView.builder(
              itemBuilder: (context, index) {
                return MediaQuery.of(context).size.width > 940
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              index == 0 ? const Text('Colors') : const SizedBox(),
                              SizedBox(
                                width: 130,
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
                              index == 0 ? const Text('Size') : const SizedBox(),
                              SizedBox(
                                width: 130,
                                child: CustomTextField(controller: productProvider!.size[index], height: 51, width: 130),
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
                                child: CustomTextField(controller: productProvider!.sku[index], height: 51, width: 130),
                              ),
                            ],
                          ),
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomButton(
                                  width: 40,
                                  height: 40,
                                  onTap: () {
                                    productProvider!.deleteTextEditingController(index);
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
                                      CustomTextField(controller: productProvider!.color[index]),
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
                                      CustomTextField(controller: productProvider!.size[index]),
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
                                      CustomTextField(controller: productProvider!.sku[index]),
                                    ],
                                  )),
                            ],
                          ),
                          CustomButton(
                              width: 40,
                              height: 40,
                              onTap: () {
                                productProvider!.deleteTextEditingController(index);
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
