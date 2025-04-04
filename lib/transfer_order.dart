import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Widgets/combo_card.dart';
import 'package:inventory_management/Widgets/product_card.dart';
import 'package:inventory_management/Widgets/searchable_dropdown.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:inventory_management/provider/transfer_order_provider.dart';
import 'package:provider/provider.dart';
import 'Custom-Files/utils.dart';
import 'model/combo_model.dart' hide Product;
import 'model/orders_model.dart';

class TransferOrderPage extends StatefulWidget {
  const TransferOrderPage({super.key});

  @override
  _TransferOrderPageState createState() => _TransferOrderPageState();
}

class _TransferOrderPageState extends State<TransferOrderPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  late TransferOrderProvider provider;

  @override
  void initState() {
    provider = context.read<TransferOrderProvider>();
    provider.initializeControllers();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<MarketplaceProvider>().fetchMarketplaces();
    // });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveOrder(TransferOrderProvider provider) async {
    provider.setBillingSameAsShipping(provider.isBillingSameAsShipping);

    if (provider.selectedFromWarehouse == null ||
        provider.selectedFromWarehouse!.isEmpty ||
        provider.selectedToWarehouse == null ||
        provider.selectedToWarehouse!.isEmpty) {
      Utils.showSnackBar(context, 'Please select both source and destination warehouses.');
      return;
    }

    if (provider.selectedFromWarehouse == provider.selectedToWarehouse) {
      Utils.showSnackBar(context, 'Please select different warehouses.');
      return;
    }

    if (provider.addedProductList.isEmpty && provider.addedComboList.isEmpty) {
      Utils.showSnackBar(context, 'Please add items to the order.');
      return;
    }

    if ((provider.billingStateController.text.trim().length < 3) || (provider.shippingStateController.text.trim().length < 3)) {
      Utils.showSnackBar(context, 'State name must be at least 3 characters long');
      return;
    }

    if (_formKey.currentState!.validate()) {
      final res = await provider.saveOrder();
      if (res['success'] == true) {
        Utils.showSnackBar(context, 'Order Transferred successfully!', color: Colors.green);
        Utils.showInfoDialog(context, 'Order ID: ${res['message'] ?? ''}!', true);
      } else {
        Utils.showSnackBar(context, 'Error transferring order: ${res['error'] ?? ''}', details: res['details'] ?? '', color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferOrderProvider>(
      builder: (context, provider, child) {
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transfer Orders',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildWarehouseSection(context, provider),
                const SizedBox(height: 30),
                _buildShippingAddressSection(provider),
                if (provider.isBillingSameAsShipping == false) const SizedBox(height: 30),
                if (provider.isBillingSameAsShipping == false) _buildBillingAddressSection(provider),
                const SizedBox(height: 30),
                _buildOrderDetailsSection(context, provider),
                const SizedBox(height: 30),
                _buildItemsSection(context, provider),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: provider.isSavingOrder ? null : () => _saveOrder(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: provider.isSavingOrder
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Transfer', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseSection(BuildContext context, TransferOrderProvider provider) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: _buildHeading("Warehouse Details"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<LocationProvider>(
                      builder: (context, pro, child) {
                        return Flexible(
                          child: _buildDropdown(
                            value: provider.selectedFromWarehouse,
                            icon: Icons.store,
                            label: 'Source Warehouse',
                            items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                            onChanged: provider.selectFromWarehouse,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Consumer<LocationProvider>(
                      builder: (context, pro, child) {
                        return Flexible(
                          child: _buildDropdown(
                            value: provider.selectedToWarehouse,
                            icon: Icons.home_work,
                            label: 'Destination Warehouse',
                            items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                            onChanged: (value) {
                              final selectedWarehouse = pro.warehouses.firstWhere((e) => e['name'] == value);
                              provider.selectToWarehouse(value, selectedWarehouse['_id'].toString());
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: _buildTextField(
                        controller: provider.notesController,
                        label: 'Notes',
                        icon: Icons.note,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection(BuildContext context, TransferOrderProvider provider) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: _buildHeading("Other Details"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: _buildTextField(
                    controller: TextEditingController(text: provider.selectedMarketplace),
                    label: 'Marketplace',
                    icon: Icons.format_list_numbered,
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _buildTextField(
                    controller: provider.totalQuantityController,
                    label: 'Total Items',
                    icon: Icons.format_list_numbered,
                    enabled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingAddressSection(TransferOrderProvider provider) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            _buildHeading("Billing Address "),
            // const Text("(Enter the pincode only. We'll fetch the address for you.)", style: TextStyle(color: Colors.red)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: provider.billingAddress1Controller,
                        label: 'Address 1',
                        icon: Icons.location_on,
                        enabled: !provider.isBillingSameAsShipping,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: provider.billingAddress2Controller,
                        label: 'Address 2',
                        icon: Icons.location_on,
                        enabled: !provider.isBillingSameAsShipping,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: provider.billingPincodeController,
                        label: 'Pincode/Zipcode',
                        icon: Icons.code,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                        onSubmitted: (value) {
                          if (value.isEmpty) {
                            context.read<TransferOrderProvider>().clearLocationDetails(isBilling: true);
                          }
                          context.read<TransferOrderProvider>().getLocationDetails(context: context, pincode: value, isBilling: true);
                        },
                        // isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: provider.billingCityController,
                        label: 'City',
                        icon: Icons.location_city,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                        enabled: !provider.isBillingSameAsShipping,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: provider.billingStateController,
                        label: 'State',
                        icon: Icons.map,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                        enabled: !provider.isBillingSameAsShipping,
                      ),
                    ),
                    // const SizedBox(width: 10),
                    // Expanded(
                    //   child: _buildTextField(
                    //     controller: provider.billingCountryController,
                    //     label: 'Country',
                    //     icon: Icons.public,
                    //     validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                    //     enabled: !provider.isBillingSameAsShipping,
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: provider.billingCountryController,
                        label: 'Country',
                        icon: Icons.public,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                        enabled: !provider.isBillingSameAsShipping,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _buildPhoneField(
                        phoneController: provider.billingPhoneController,
                        label: 'Phone',
                        enabled: !provider.isBillingSameAsShipping,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressSection(TransferOrderProvider provider) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            _buildHeading("Shipping Address "),
            // const Text("(Enter the pincode only. We'll fetch the address for you.)", style: TextStyle(color: Colors.red)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: const Text('Billing address same as shipping'),
                  value: provider.isBillingSameAsShipping,
                  onChanged: (bool? value) => provider.setBillingSameAsShipping(value),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: provider.shippingAddress1Controller,
                        label: 'Address 1',
                        icon: Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: provider.shippingAddress2Controller,
                        label: 'Address 2',
                        icon: Icons.location_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: provider.shippingPincodeController,
                        label: 'Pincode',
                        icon: Icons.code,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                        onSubmitted: (value) {
                          if (value.isEmpty) {
                            context.read<TransferOrderProvider>().clearLocationDetails(isBilling: false);
                          }
                          context.read<TransferOrderProvider>().getLocationDetails(context: context, pincode: value, isBilling: false);
                        },
                        // isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: provider.shippingCityController,
                        label: 'City',
                        icon: Icons.location_city,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: provider.shippingStateController,
                        label: 'State',
                        icon: Icons.map,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: provider.shippingCountryController,
                        label: 'Country',
                        icon: Icons.public,
                        validator: (value) => (value?.isEmpty ?? false) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPhoneField(phoneController: provider.shippingPhoneController, label: 'Phone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, TransferOrderProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeading('Items (Product Details)'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: DropdownButtonFormField<String>(
                value: provider.selectedItemType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                items: const [
                  DropdownMenuItem(value: 'Product', child: Text('Product')),
                  DropdownMenuItem(value: 'Combo', child: Text('Combo')),
                ],
                onChanged: (value) {
                  setState(() {
                    provider.selectedItemType = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: SearchableDropdown(
                key: ValueKey(provider.selectedItemType),
                label: 'Select ${provider.selectedItemType}',
                isCombo: provider.selectedItemType == 'Combo',
                onChanged: (selected) {
                  if (selected != null) {
                    if (provider.selectedItemType == 'Product') {
                      provider.addProduct(context, selected);
                    } else {
                      provider.addCombo(context, selected);
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.productsFuture.length,
                itemBuilder: (context, index) {
                  final product = provider.productsFuture[index];
                  if (product == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: ProductCard(product: product, index: index),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: _buildTextField(
                                  controller: provider.addedProductQuantityControllers[index],
                                  isNumber: true,
                                  label: 'Qty',
                                  icon: Icons.production_quantity_limits,
                                  onChanged: (_) => provider.setTotalQuantity(),
                                  // onSubmitted: (_) => provider.setTotalQuantity(),
                                ),
                              ),
                              // const SizedBox(height: 8),
                              // SizedBox(
                              //   width: 200,
                              //   child: _buildTextField(
                              //     controller: provider.addedProductRateControllers[index],
                              //     label: 'Rate',
                              //     isNumber: true,
                              //     icon: Icons.currency_rupee,
                              //     // onSubmitted: (_) => provider.updateTotalAmount(),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => provider.deleteProduct(context, index, product.id!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.combosFuture.length,
                itemBuilder: (context, index) {
                  final combo = provider.combosFuture[index];
                  if (combo == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: ComboCard(combo: combo, index: index),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: _buildTextField(
                                  controller: provider.addedComboQuantityControllers[index],
                                  isNumber: true,
                                  label: 'Qty',
                                  icon: Icons.production_quantity_limits,
                                  onChanged: (_) => provider.setTotalQuantity(),
                                  // onSubmitted: (_) => provider.setTotalQuantity(),
                                ),
                              ),
                              // const SizedBox(height: 8),
                              // SizedBox(
                              //   width: 200,
                              //   child: _buildTextField(
                              //     controller: provider.addedComboRateControllers[index],
                              //     label: 'Rate',
                              //     isNumber: true,
                              //     icon: Icons.currency_rupee,
                              //     // onSubmitted: (_) => provider.updateTotalAmount(),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => provider.deleteCombo(context, index, combo.comboSku),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
    void Function(String)? onChanged,
    int? maxLength,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
      // keyboardType: isNumber! ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly, if (label == 'Rate') FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : [],
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    IconData icon = Icons.list,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        label: Text(label, style: const TextStyle(color: Colors.black)),
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
      hint: Text('Select $label'),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController phoneController,
    required String label,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: phoneController,
      maxLength: 13,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator ??
          (value) {
            if (value != null) {
              if (value.isEmpty) {
                return 'Required';
              }
              // else if (value.length != 10) {
              //   return 'Invalid phone number';
              // }
            }
            return null;
          },
      decoration: InputDecoration(
        label: Text(label, style: const TextStyle(color: Colors.black)),
        prefixIcon: Icon(Icons.phone, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      ),
    );
  }
}
