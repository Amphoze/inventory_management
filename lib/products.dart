import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inventory_management/Api/product-page-api.dart';

import 'package:inventory_management/Api/products-provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';
import 'package:inventory_management/Custom-Files/custom-textfield.dart';
import 'package:inventory_management/Custom-Files/loading_indicator.dart';
import 'package:inventory_management/Custom-Files/multi-image-picker.dart';
import 'package:inventory_management/Custom-Files/test-drop.dart';
import 'package:inventory_management/Custom-Files/textfield-in-alert-box.dart';
// import 'package:inventory_management/Custom-Files/textfield-in-alert-box.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

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
    _grossWeightController.dispose();
    _netWeightController.dispose();
    _shopifyController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _technicalNameController.dispose();

    super.dispose();
  }

  void clear() {
    selectedIndexOfBrand = 0;
    selectedIndexOfCategory = 0;
    selectedIndexOfLabel = 0;
    selectedIndexOfBoxSize = 0;
    selectedIndexOfColorDrop = 0;
    dropdownKey.currentState!.reset();
    categoryKey.currentState!.reset();
    labelKey.currentState!.reset();
    colorKey.currentState!.reset();
    sizeKey.currentState!.reset();
    gradeKey.currentState!.reset();
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
              child: Text("You cannot create product of some internal error"))
          : Scaffold(
              backgroundColor: Colors.white,
              body: productProvider!.isloading
                  ? (MediaQuery.of(context).size.width > 1200
                      ? webLayout(
                          context,
                        )
                      : mobileLayout(
                          context,
                        ))
                  : const Center(
                      child: LoadingAnimation(
                        icon: Icons.production_quantity_limits_rounded,
                        beginColor: Color.fromRGBO(189, 189, 189, 1),
                        endColor: AppColors.primaryBlue,
                        size: 80.0,
                      ),
                    )),
    );
  }

//  void resetBrand() {
//     setState(() {
//       selectedIndexOfBrand = 0;
//     });
//   }
//mobile layout
  Widget mobileLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: 40.0, left: MediaQuery.of(context).size.width > 450 ? 70 : 0),
      child: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      fieldTitle('Product Category', height: 50, width: 140),
                      SizedBox(
                        child: Column(
                          children: [
                            radioCheck('Create Simple Product', (val) {
                              productProvider!
                                  .updateSelectedProductCategory(val!);
                            }),
                            radioCheck('Variant Product Creation', (val) {
                              productProvider!
                                  .updateSelectedProductCategory(val!);
                            }),
                            radioCheck('Create Virtual Combo Products', (val) {
                              productProvider!
                                  .updateSelectedProductCategory(val!);
                            }),
                            radioCheck('Create Kit Products', (val) {
                              productProvider!
                                  .updateSelectedProductCategory(val!);
                            }),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 5.0),
                      fieldTitle('Product Name', height: 50, width: 110),
                      SizedBox(
                        child: CustomTextField(
                            controller: _productNameController,
                            height: 51,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Product Name is required';
                              }
                              return null;
                            }),
                      ),

                      fieldTitle('Product identifier', height: 50, width: 130),
                      Container(
                        height: 250,
                        width: 550,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withOpacity(0.2),
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                fieldTitle(
                                  'SKU',
                                  height: 51,
                                  // width:51
                                ),
                                const SizedBox(height: 8.0),
                                fieldTitle('EAM/UPC',
                                    // width:,
                                    show: false,
                                    height: 51),
                              ],
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomTextField(
                                    controller: _skuController,
                                    height: 51,
                                    width: 150,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'SKU is required';
                                      }
                                      return null;
                                    }),
                                const SizedBox(height: 8.0),
                                CustomTextField(
                                  controller: _eanUpcController,
                                  height: 51,
                                  width: 150,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      fieldTitle('Product Brand', height: 50, width: 110),
                      SizedBox(
                          height: 51,
                          width: 200,
                          child: CustomDropdown(
                            key: dropdownKey,
                            option: productProvider!.brand,
                            selectedIndex: 0,
                            onSelectedChanged: (int a) {
                              selectedIndexOfBrand = a;
                            },
                          )
                          // child: SearchableDropdown(
                          //   label: 'heelo',
                          // ),
                          ),

                      fieldTitle('Category',
                          show: false, height: 50, width: 69.5),
                      SizedBox(
                        child: MediaQuery.of(context).size.width > 450
                            ? Row(
                                children: [
                                  SizedBox(
                                    height: 51,
                                    width: 260,
                                    child: CustomDropdown(
                                      key: categoryKey,
                                      option: productProvider!.cat,
                                      onSelectedChanged: (int a) {
                                        selectedIndexOfCategory = a;
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      // errorStyle:'',
                                      border: Border.all(
                                          color: Colors.blue.shade50),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.blue.shade50,
                                    ),
                                    height: 51,
                                    width: 70,
                                    child: InkWell(
                                      child: const Center(
                                          child: Text(
                                        '+ New',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                      onTap: () {
                                        CustomAlertBox.diaglogWithOneTextField(
                                            context);
                                      },
                                    ),
                                  )
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 51,
                                    width: 260,
                                    child: CustomDropdown(
                                      key: categoryKey,
                                      option: productProvider!.cat,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  InkWell(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        // errorStyle:'',
                                        border: Border.all(
                                            color: Colors.blue.shade50),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.blue.shade50,
                                      ),
                                      height: 51,
                                      width: 70,
                                      child: InkWell(
                                        child: const Center(
                                            child: Text(
                                          '+ New',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        )),
                                        onTap: () {
                                          CustomAlertBox
                                              .diaglogWithOneTextField(context);
                                        },
                                      ),
                                    ),
                                    onTap: () {
                                      CustomAlertBox.showKeyValueDialog(
                                          context);
                                    },
                                  )
                                ],
                              ),
                      ),
                      productProvider!.selectedProductCategory ==
                              'Variant Product Creation'
                          ? fieldTitle('Variations', width: 80)
                          : const SizedBox(),
                      productProvider!.selectedProductCategory ==
                              'Variant Product Creation'
                          ? variantProductCreation(context)
                          : const SizedBox(),

                      fieldTitle('Technical Name',
                          show: false, height: 50, width: 95.5 + 23),
                      CustomTextField(
                          controller: _technicalNameController,
                          height: 51,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Technical Name is required';
                            }
                            return null;
                          }),

                      fieldTitle('Label', height: 50, width: 50),
                      SizedBox(
                        width: 200,
                        height: 51,
                        child: CustomDropdown(
                          key: labelKey,
                          option: productProvider!.label,
                          label: true,
                          onSelectedChanged: (val) {
                            selectedIndexOfLabel = val;
                          },
                        ),
                      ),

                      fieldTitle('Description',
                          show: false, height: 70, width: 89.5),
                      SizedBox(
                        child: CustomTextField(
                          controller: _descriptionController,
                          maxLines: 10,
                          height: 70,
                        ),
                      ),

                      const SizedBox(height: 8.0),
                      fieldTitle('Predefined Tax Rule',
                          show: false, height: 50, width: 144.5),
                      CustomTextField(
                          controller: _predefinedTaxRuleController,
                          height: 51,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Predefined Tax is required';
                            }
                            return null;
                          }),

                      fieldTitle('Product Specification',
                          show: false, height: 50, width: 156),
                      Container(
                        height: 250,
                        width: 550,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.black.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white30,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  fieldTitle(
                                    'Size',
                                    show: false,
                                    height: 30,
                                  ),
                                  const SizedBox(height: 33.0),
                                  fieldTitle('Color', show: false, height: 30),
                                ],
                              ),
                              const SizedBox(
                                width: 2,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomTextField(
                                    controller: _sizeController,
                                    height: 51,
                                    width: 150,
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 15.0),
                                  SizedBox(
                                    height: 51,
                                    width: 150,
                                    child: CustomDropdown(
                                      key: colorKey,
                                      option: productProvider!.colorDrop,
                                      onSelectedChanged: (val) {
                                        selectedIndexOfColorDrop = val;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      fieldTitle('MRP', show: false, height: 50, width: 40),
                      SizedBox(
                        child: CustomTextField(
                          controller: _mrpController,
                          height: 51,
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),

                      fieldTitle('Cost', height: 50, width: 42),
                      SizedBox(
                        child: CustomTextField(
                          controller: _costController,
                          height: 51,
                          icon: Icons.currency_rupee_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Cost is required';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                        ),
                      ),

                      fieldTitle('Net Weight',
                          show: false, height: 50, width: 84),
                      SizedBox(
                        child: CustomTextField(
                          controller: _netWeightController,
                          height: 51,
                          unit: '(in gram)',
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      fieldTitle('Gross Weight',
                          show: false, height: 50, width: 100.5),
                      SizedBox(
                        child: CustomTextField(
                          controller: _grossWeightController,
                          height: 51,
                          unit: '(in gram)',
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      fieldTitle('Spotify Image Url',
                          show: false, height: 50, width: 126.2),
                      SizedBox(
                        child: CustomTextField(
                          controller: _shopifyController,
                          height: 51,
                          // unit: '(in gram)',
                          // icon: Icons.currency_rupee_rounded,
                          // keyboardType: TextInputType.number,
                        ),
                      ),
                      fieldTitle('Package Dimension',
                          show: false, height: 50, width: 144),
                      SizedBox(
                        width: 550,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomTextField(
                              controller: _lengthController,
                              prefix: 'L',
                              width: MediaQuery.of(context).size.width * 0.15,
                              unit: 'cm',
                              keyboardType: TextInputType.number,
                            ),
                            const Text('x'),
                            CustomTextField(
                              controller: _widthController,
                              width: MediaQuery.of(context).size.width * 0.15,
                              prefix: 'W',
                              unit: 'cm',
                              keyboardType: TextInputType.number,
                            ),
                            const Text('x'),
                            CustomTextField(
                              controller: _depthController,
                              width: MediaQuery.of(context).size.width * 0.15,
                              prefix: 'D',
                              unit: 'cm',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      fieldTitle('Size', width: 42),
                      SizedBox(
                          width: 200,
                          height: 51,
                          child: CustomDropdown(
                            key: sizeKey,
                            option: productProvider!.boxSize,
                            onSelectedChanged: (val) {
                              print("box size val is heer $val");
                              selectedIndexOfBoxSize = val;
                            },
                            isboxSize: true,
                          )),

                      fieldTitle('Custom Field',
                          show: false, height: 50, width: 1),
                      Container(
                        height: 51,
                        width: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.black.withOpacity(0.2)),
                        ),
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomButton(
                                  width: 140,
                                  height: 25,
                                  onTap: () {
                                    CustomAlertBox.showKeyValueDialog(context);
                                  },
                                  color: AppColors.primaryBlue,
                                  textColor: AppColors.white,
                                  fontSize: 18,
                                  text: 'Add Field'),
                            )),
                      ),
                      const SizedBox(height: 8.0),
                      fieldTitle('Grade'),
                      SizedBox(
                        width: 550,
                        child: CustomDropdown(
                          key: gradeKey,
                          grade: true,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      fieldTitle('Active Status',
                          show: false, height: 50, width: 1),
                      CupertinoSwitch(
                        value: productProvider!.activeStatus,
                        onChanged: (value) {
                          productProvider!.changeActiveStaus();
                        },
                      ),
                      const SizedBox(height: 8.0),
                      productProvider!.selectedProductCategory ==
                                  'Create Simple Product' ||
                              productProvider!.selectedProductCategory ==
                                  'Variant Product Creation'
                          ? const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Select Image'),
                                SizedBox(
                                  height: 5,
                                ),
                                SizedBox(
                                  height: 120,
                                  width: 600,
                                  child: CustomPicker(),
                                )
                              ],
                            )
                          : const SizedBox(),
                      const SizedBox(height: 10.0),
                      productProvider!.selectedProductCategory ==
                              'Create Simple Product'
                          ? const Text(
                              '* please select all mandantotry field',
                              style: TextStyle(color: Colors.red),
                            )
                          : const Text(''),
                      productProvider!.selectedProductCategory ==
                              'Create Simple Product'
                          ? const SizedBox(height: 10.0)
                          : const SizedBox(
                              height: 0,
                            ),
                      SizedBox(
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 200,
                              child: ElevatedButton(
                                onPressed: saveButton,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      const Color.fromRGBO(6, 90, 216, 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                ),
                                child: productProvider!.saveButtonClick
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Save Product",
                                      ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              height: 50,
                              width: 80,
                              child: ElevatedButton(
                                onPressed: () {
                                  print("Reset called");
                                  clear();
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue.shade500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                ),
                                child: const Text("Reset"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 70,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void saveButton() async {
    productProvider!.saveButtonClickStatus();
// print('''
// Product Name: ${_productNameController.text}
// Parent SKU: ${_skuController.text}
// SKU: ${_skuController.text}
// EAN: ${_eanUpcController.text}
// Description: ${_descriptionController.text}
// Brand ID: ${productProvider!.brand[selectedIndexOfBrand-1]['_id']}
// Category: ${productProvider!.cat[selectedIndexOfCategory-1]['name']}
// Technical Name: ${_technicalNameController.text}
// Label SKU: ${productProvider!.label[selectedIndexOfLabel-1]['labelSku']}
// Color ID: ${productProvider!.colorDrop[selectedIndexOfColorDrop-1]['_id']}
// Tax Rule: ${_predefinedTaxRuleController.text}
// Dimensions: {"length": 12, "breadth": 122, "height": 1222}
// Weight: ${_widthController.text}
// Box Name: ${productProvider!.boxSize[selectedIndexOfBoxSize-1]["box_name"]}
// MRP: ${_mrpController.text}
// Cost: ${_costController.text}
// Active: ${productProvider!.activeStatus}
// Net Weight: ${_netWeightController.text}
// Gross Weight: ${_grossWeightController.text}
// Shopify Image: ${_shopifyController.text}
// ${productProvider!.activeStatus}

// ''');

    try {
      if (productProvider!.selectedProductCategory == 'Create Simple Product') {
        var res = await ProductPageApi().createProduct(
          context: context,
          productName: _productNameController.text,
          parentSku: _skuController.text,
          sku: _skuController.text,
          ean: _eanUpcController.text,
          description: _descriptionController.text,
          brandId: (selectedIndexOfBrand - 1 < 0)
              ? ''
              : productProvider!.brand[selectedIndexOfBrand - 1]['_id']
                  .toString(),
          category: (selectedIndexOfCategory - 1 < 0)
              ? ''
              : productProvider!.cat[selectedIndexOfCategory - 1]['name']
                  .toString(),
          technicalName: _technicalNameController.text,
          labelSku: (selectedIndexOfLabel - 1 < 0)
              ? ''
              : productProvider!.label[selectedIndexOfLabel - 1]['labelSku']
                  .toString(),
          colorId: (selectedIndexOfColorDrop - 1 < 0)
              ? ''
              : productProvider!.colorDrop[selectedIndexOfColorDrop - 1]['_id']
                  .toString(),
          taxRule: _predefinedTaxRuleController.text,
          dimensions: {
            "length": _lengthController.text,
            "breadth": _widthController.text,
            "height": _depthController.text
          },
          weight: '12',
          boxName: (selectedIndexOfBoxSize - 1 < 0)
              ? ''
              : productProvider!.boxSize[selectedIndexOfBoxSize - 1]
                  ["box_name"],
          mrp: _mrpController.text,
          cost: _costController.text,
          active: productProvider!.activeStatus,
          netWeight: _netWeightController.text,
          grossWeight: _grossWeightController.text,
          shopifyImage: _shopifyController.text,
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                ' Product is created successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green, // Change color as needed
              behavior:
                  SnackBarBehavior.floating, // Optional: Makes it floating
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              duration: Duration(seconds: 3), // Duration for how long it shows
            ),
          );
          clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Product creation failed. Please try again.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red, // Change color as needed
              behavior:
                  SnackBarBehavior.floating, // Optional: Makes it floating
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              duration:
                  const Duration(seconds: 3), // Duration for how long it shows
            ),
          );
        }
      } else {
        for (int i = 0; i < productProvider!.countVariationFields; i++) {
          var res = await ProductPageApi().createProduct(
            context: context,
            productName: _productNameController.text,
            parentSku: _skuController.text,
            sku: productProvider!.sku[i].text,
            ean: _eanUpcController.text,
            description: _descriptionController.text,
            brandId: (selectedIndexOfBrand - 1 < 0)
                ? ''
                : productProvider!.brand[selectedIndexOfBrand - 1]['id']
                    .toString(),
            category: (selectedIndexOfCategory - 1 < 0)
                ? ''
                : productProvider!.cat[selectedIndexOfCategory - 1]['name']
                    .toString(),
            technicalName: _technicalNameController.text,
            labelSku: (selectedIndexOfLabel - 1 < 0)
                ? ''
                : productProvider!.label[selectedIndexOfLabel - 1]['labelSku']
                    .toString(),
            colorId: (selectedIndexOfColorDrop - 1 < 0)
                ? ''
                : productProvider!.colorDrop[selectedIndexOfColorDrop - 1]
                        ['_id']
                    .toString(),
            taxRule: _predefinedTaxRuleController.text,
            dimensions: {
              "length": _lengthController.text,
              "breadth": _widthController.text,
              "height": _depthController.text
            },
            weight: '12',
            boxName: (selectedIndexOfBoxSize - 1 < 0)
                ? ''
                : productProvider!.boxSize[selectedIndexOfBoxSize - 1]
                    ["box_name"],
            mrp: _mrpController.text,
            cost: _costController.text,
            active: productProvider!.activeStatus,
            netWeight: _netWeightController.text,
            grossWeight: _grossWeightController.text,
            shopifyImage: _shopifyController.text,
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Variant $i Product is created successfully!',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green, // Change color as needed
                behavior:
                    SnackBarBehavior.floating, // Optional: Makes it floating
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                duration:
                    Duration(seconds: 3), // Duration for how long it shows
              ),
            );
            clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Product creation failed. Please try again.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red, // Change color as needed
                behavior:
                    SnackBarBehavior.floating, // Optional: Makes it floating
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                duration: const Duration(
                    seconds: 3), // Duration for how long it shows
              ),
            );
          }
        }
        clear();
      }
    } catch (e) {
      // print(e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${e.toString()}')));
    }

    productProvider!.saveButtonClickStatus();
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
                fieldTitle('Product Name'),
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
              formLayout(
                fieldTitle('Product Identifier'),
                Container(
                  width: 550,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      formLayout(
                          fieldTitle(
                            'SKU',
                            height: 51,
                          ),
                          CustomTextField(
                            controller: _skuController,
                            width: 150,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'SKU is required';
                              }
                              return null;
                            },
                          ),
                          mainAxisAlignment: MainAxisAlignment.center),
                      const SizedBox(height: 8.0),
                      formLayout(
                          fieldTitle(
                            'EAM/UPC',
                            height: 51,
                          ),
                          Container(
                            // color: Colors.blueAccent,
                            width: 150,
                            height: 51,
                            child: CustomTextField(
                              controller: _eanUpcController,
                              width: 150,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'EAM/UPC is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          mainAxisAlignment: MainAxisAlignment.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Brand'),
                SizedBox(
                  height: 51,
                  width: 300,
                  child: CustomDropdown(
                    selectedIndex: 0,
                    key: dropdownKey,
                    option: productProvider!.brand,
                    onSelectedChanged: (int a) {
                      selectedIndexOfBrand = a;
                    },
                    // onReset:resetBrand,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                  fieldTitle('Category'),
                  Row(
                    children: [
                      SizedBox(
                          width: 300,
                          height: 51,
                          child: CustomDropdown(
                            key: categoryKey,
                            option: productProvider!.cat,
                            onSelectedChanged: (int a) {
                              selectedIndexOfCategory = a;
                            },
                          )),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade50),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue.shade50,
                        ),
                        height: 51,
                        width: 70,
                        child: InkWell(
                          child: const Center(
                              child: Text(
                            '+ New',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                          onTap: () {
                            CustomAlertBox.diaglogWithOneTextField(context);
                          },
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 12),

              productProvider!.selectedProductCategory ==
                      'Variant Product Creation'
                  ? formLayout(
                      fieldTitle('Variations'),
                      variantProductCreation(context),
                    )
                  : const SizedBox(),
              productProvider!.selectedProductCategory ==
                      'Variant Product Creation'
                  ? const SizedBox(height: 12)
                  : const SizedBox(),
              formLayout(
                fieldTitle('Technical Name'),
                CustomTextField(
                    controller: _technicalNameController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Technical name is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Label'),
                SizedBox(
                  width: 300,
                  height: 51,
                  child: CustomDropdown(
                    key: labelKey,
                    option: productProvider!.label,
                    label: true,
                    onSelectedChanged: (val) {
                      selectedIndexOfLabel = val;
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    }),
              ),

              const SizedBox(height: 12),

              formLayout(
                fieldTitle('Predefined Tax Rule'),
                CustomTextField(
                    controller: _predefinedTaxRuleController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Accounting Item Name is required';
                      }
                      return null;
                    }),
              ),
              // const SizedBox(height: 12),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Specifications'),
                Container(
                  width: 550,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      formLayout(
                          fieldTitle(
                            'Size',
                            height: 51,
                          ),
                          CustomTextField(
                            controller: _sizeController,
                            width: 150,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Size is required';
                              }
                              return null;
                            },
                          ),
                          mainAxisAlignment: MainAxisAlignment.center),
                      const SizedBox(height: 8.0),
                      formLayout(
                          fieldTitle(
                            'Color',
                            height: 51,
                          ),
                          SizedBox(
                            // color: Colors.blueAccent,
                            width: 150,
                            height: 51,
                            child: CustomDropdown(
                              key: colorKey,
                              option: productProvider!.colorDrop,
                              onSelectedChanged: (val) {
                                selectedIndexOfColorDrop = val;
                              },
                            ),
                          ),
                          mainAxisAlignment: MainAxisAlignment.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('MRP'),
                CustomTextField(
                    controller: _mrpController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'MRP is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Cost'),
                CustomTextField(
                    controller: _costController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Cost is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Net Weight'),
                CustomTextField(
                    controller: _netWeightController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Weight is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Gross Weight'),
                CustomTextField(
                    controller: _grossWeightController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Weight is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Spotify Image'),
                CustomTextField(
                    controller: _shopifyController,
                    height: 51,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'image is required';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 12),
              formLayout(
                fieldTitle('Package Dimensions'),
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
                      const Text('x'),
                      Expanded(
                        child: CustomTextField(
                          controller: _widthController,
                          // width: MediaQuery.of(context).size.width * 0.15,
                          prefix: 'W',
                          unit: 'cm',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const Text('x'),
                      Expanded(
                        child: CustomTextField(
                          controller: _depthController,
                          // width: MediaQuery.of(context).size.width * 0.15,
                          prefix: 'D',
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
                  child: CustomDropdown(
                    key: sizeKey,
                    option: productProvider!.boxSize,
                    isboxSize: true,
                    onSelectedChanged: (val) {
                      selectedIndexOfBoxSize = val;
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
                  const Text('Custom Field'),
                  Container(
                    height: 100,
                    width: 550,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white30,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 25,
                          width: 150,
                          child: CustomButton(
                              width: 30,
                              height: 25,
                              onTap: () {
                                CustomAlertBox.showKeyValueDialog(context);
                              },
                              color: AppColors.primaryBlue,
                              textColor: AppColors.white,
                              fontSize: 18,
                              text: 'Add Field'),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              formLayout(
                SizedBox(
                    height: 20,
                    // width: 40,
                    child: fieldTitle('Active Status  ')),
                SizedBox(
                  height: 20,
                  width: 40,
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
                  const Text('Select Image'),
                  const SizedBox(
                    height: 150,
                    width: 600,
                    child: CustomPicker(),
                  )
                  // InkWell(
                  //   child: Row(
                  //     children: [
                  //       const Icon(Icons.add_a_photo),
                  //       webImages != null
                  //           ? SizedBox(
                  //               height: 100,
                  //               width: 550,
                  //               child: CustomHorizontalImageScroller(
                  //                 webImageUrls: webImages,
                  //               ))
                  //           : const SizedBox(),
                  //     ],
                  //   ),
                  //   onTap: () async {
                  //     webImages = await MultiImagePicker().pickImages(context);
                  //     setState(() {});
                  //   },
                  // ),
                  ),
              const SizedBox(
                height: 10,
              ),
              formLayout(
                  fieldTitle(''),
                  Row(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: saveButton,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromRGBO(6, 90, 216, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: productProvider!.saveButtonClick
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Save Product",
                                ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      CustomButton(
                          width: 150,
                          height: 40,
                          onTap: () {
                            clear();
                          },
                          color: AppColors.primaryBlue,
                          textColor: AppColors.white,
                          fontSize: 15,
                          text: 'Reset')
                    ],
                  )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget formLayout(Widget title, Widget anyWidget,
      {MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
      double width = 1200}) {
    return Container(
      // color:Colors.black,
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          // Spacer(),
          Container(
              width: 200,
              // color: Colors.red,
              alignment: Alignment.topRight,
              child: title),
          const SizedBox(
            width: 5,
          ),
          anyWidget
        ],
      ),
    );
  }

  SizedBox customRadioButtonLayout(BuildContext context) {
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
              MediaQuery.of(context).size.width > 1400
                  ? radioCheck('Create Virtual Combo Products', (val) {
                      productProvider!.updateSelectedProductCategory(val!);
                    })
                  : const SizedBox(),
              MediaQuery.of(context).size.width > 1400
                  ? radioCheck('Create Kit Products', (val) {
                      productProvider!.updateSelectedProductCategory(val!);
                    })
                  : const SizedBox(),
            ],
          ),
          MediaQuery.of(context).size.width > 1200 &&
                  MediaQuery.of(context).size.width < 1400
              ? Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      radioCheck('Create Virtual Combo Products', (val) {
                        productProvider!.updateSelectedProductCategory(val!);
                      }),
                      radioCheck('Create Kit Products', (val) {
                        productProvider!.updateSelectedProductCategory(val!);
                      }),
                    ],
                  ),
                )
              : const SizedBox(),
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
                              index == 0
                                  ? const Text('EAN/UPC')
                                  : const SizedBox(),
                              SizedBox(
                                width: 130,
                                child: CustomTextField(
                                    controller: productProvider!.eanUpc[index],
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
                                      const Text('EAN/UPC'),
                                      CustomTextField(
                                          controller:
                                              productProvider!.eanUpc[index]),
                                    ],
                                  )),
                              const SizedBox(
                                width: 2,
                              ),
                              SizedBox(
                                  width: 150,
                                  child: Column(
                                    children: [
                                      const Text('SKU'),
                                      CustomTextField(
                                          controller:
                                              productProvider!.sku[index]),
                                    ],
                                  ))
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

  Widget fieldTitle(String filTitle,
      {double height = 51, double width = 168.3, bool show = true}) {
    return SizedBox(
      height: height,
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(filTitle, style: const TextStyle(fontSize: 15)),
          show
              ? const Text(
                  ' *',
                  style: TextStyle(color: Colors.red),
                )
              : const Text('  '),
        ],
      ),
    );
  }

  Widget radioCheck(
    String title,
    Function(String?) onTap,
  ) {
    return Row(
      children: [
        Radio<String>(
          value: title,
          groupValue: productProvider!.selectedProductCategory,
          onChanged: onTap,
        ),
        Text(title),
      ],
    );
  }
}
