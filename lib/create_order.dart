import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  _CreateOrderPageState createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _customerFirstNameController = TextEditingController();
  final TextEditingController _customerLastNameController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  final TextEditingController _customerGstinController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  final TextEditingController _billingFirstNameController = TextEditingController();
  final TextEditingController _billingLastNameController = TextEditingController();
  final TextEditingController _billingEmailController = TextEditingController();
  final TextEditingController _billingAddress1Controller = TextEditingController();
  final TextEditingController _billingAddress2Controller = TextEditingController();
  final TextEditingController _billingPhoneController = TextEditingController();
  final TextEditingController _billingCityController = TextEditingController();
  final TextEditingController _billingPincodeController = TextEditingController();
  final TextEditingController _billingStateController = TextEditingController();
  final TextEditingController _billingStateCodeController = TextEditingController();
  final TextEditingController _billingCountryController = TextEditingController();
  final TextEditingController _billingCountryCodeController = TextEditingController();

  final TextEditingController _shippingFirstNameController = TextEditingController();
  final TextEditingController _shippingLastNameController = TextEditingController();
  final TextEditingController _shippingEmailController = TextEditingController();
  final TextEditingController _shippingAddress1Controller = TextEditingController();
  final TextEditingController _shippingAddress2Controller = TextEditingController();
  final TextEditingController _shippingPhoneController = TextEditingController();
  final TextEditingController _shippingCityController = TextEditingController();
  final TextEditingController _shippingPincodeController = TextEditingController();
  final TextEditingController _shippingStateController = TextEditingController();
  final TextEditingController _shippingStateCodeController = TextEditingController();
  final TextEditingController _shippingCountryController = TextEditingController();
  final TextEditingController _shippingCountryCodeController = TextEditingController();

  final TextEditingController _paymentModeController = TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _itemQtyController = TextEditingController();
  final TextEditingController _itemSkuController = TextEditingController();
  final TextEditingController _itemAmountController = TextEditingController();
  final TextEditingController _totalAmtController = TextEditingController();
  final TextEditingController _codAmountController = TextEditingController();
  final TextEditingController _coinController = TextEditingController();
  final TextEditingController _prepaidAmountController = TextEditingController();

  final TextEditingController _marketplaceController = TextEditingController();
  final TextEditingController _discountCodeController = TextEditingController();
  final TextEditingController _discountSchemeController = TextEditingController();
  final TextEditingController _discountAmountController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _agentController = TextEditingController();

  Future<void> submitOrder({
    required String orderId,
    required Map<String, dynamic> customer,
    required Map<String, dynamic> billingAddr,
    required Map<String, dynamic> shippingAddr,
    required String paymentMode,
    required String currencyCode,
    required List<Map<String, dynamic>> items,
    required double totalAmt,
    required double codAmount,
    required double taxPercent,
    required String source,
    required String agent,
    required int totalQuantity,
    required String marketplace,
    required String notes,
    required BuildContext context, // Added BuildContext
  }) async {
    String baseUrl = await Constants.getBaseUrl();
    final apiUrl = Uri.parse('$baseUrl/orders');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final Map<String, dynamic> requestBody = {
      "order_id": orderId,
      "customer": customer,
      "billing_addr": billingAddr,
      "shipping_addr": shippingAddr,
      "payment_mode": paymentMode,
      "currency_code": currencyCode,
      "items": items,
      "total_amt": totalAmt,
      "cod_amount": codAmount,
      "tax_percent": taxPercent,
      "source": source,
      "agent": agent,
      "total_quantity": totalQuantity,
      "marketplace": marketplace,
      "notes": notes,
    };

    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitting order...'), duration: Duration(seconds: 1)));

      final response = await http.post(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Clear any existing snackbars
      ScaffoldMessenger.of(context).clearSnackBars();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to submit order');
      }
    } catch (e) {
      // Clear existing snackbars and show error
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSection(),
                  const SizedBox(height: 32),
                  _buildExpandableSection(
                    'Customer Information',
                    _buildCustomerSection(),
                  ),
                  const SizedBox(height: 24),
                  _buildAddressSection(),
                  const SizedBox(height: 24),
                  _buildPaymentSection(),
                  const SizedBox(height: 24),
                  _buildOtherDetailsSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildOrderSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Order Information'),
            const SizedBox(height: 16),
            _buildTextField(_orderIdController, 'Order ID', prefixIcon: Icons.shopping_cart),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(_customerFirstNameController, 'First Name', prefixIcon: Icons.person),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_customerLastNameController, 'Last Name', prefixIcon: Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_customerEmailController, 'Email', prefixIcon: Icons.email),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_customerPhoneController, 'Phone', prefixIcon: Icons.phone),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(_customerGstinController, 'GSTIN', prefixIcon: Icons.receipt_long),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildExpandableSection(
            'Billing Address',
            _buildAddressFields(
              firstNameController: _billingFirstNameController,
              lastNameController: _billingLastNameController,
              emailController: _billingEmailController,
              phoneController: _billingPhoneController,
              address1Controller: _billingAddress1Controller,
              address2Controller: _billingAddress2Controller,
              cityController: _billingCityController,
              pincodeController: _billingPincodeController,
              stateController: _billingStateController,
              countryController: _billingCountryController,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildExpandableSection(
            'Shipping Address',
            _buildAddressFields(
              firstNameController: _shippingFirstNameController,
              lastNameController: _shippingLastNameController,
              emailController: _shippingEmailController,
              phoneController: _shippingPhoneController,
              address1Controller: _shippingAddress1Controller,
              address2Controller: _shippingAddress2Controller,
              cityController: _shippingCityController,
              pincodeController: _shippingPincodeController,
              stateController: _shippingStateController,
              countryController: _shippingCountryController,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressFields({
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController emailController,
    required TextEditingController phoneController,
    required TextEditingController address1Controller,
    required TextEditingController address2Controller,
    required TextEditingController cityController,
    required TextEditingController pincodeController,
    required TextEditingController stateController,
    required TextEditingController countryController,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(firstNameController, 'First Name', prefixIcon: Icons.person),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(lastNameController, 'Last Name', prefixIcon: Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(address1Controller, 'Address Line 1', prefixIcon: Icons.home),
        const SizedBox(height: 16),
        _buildTextField(address2Controller, 'Address Line 2', prefixIcon: Icons.home_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(cityController, 'City', prefixIcon: Icons.location_city),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(pincodeController, 'Pincode', prefixIcon: Icons.pin_drop),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(stateController, 'State', prefixIcon: Icons.map),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(countryController, 'Country', prefixIcon: Icons.public),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return _buildExpandableSection(
      'Payment Details',
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(_paymentModeController, 'Payment Mode', prefixIcon: Icons.payment),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_currencyCodeController, 'Currency Code', prefixIcon: Icons.currency_exchange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_itemQtyController, 'Quantity', prefixIcon: Icons.shopping_basket),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_itemAmountController, 'Amount', prefixIcon: Icons.attach_money),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherDetailsSection() {
    return _buildExpandableSection(
      'Additional Details',
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(_marketplaceController, 'Marketplace', prefixIcon: Icons.store),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_sourceController, 'Source', prefixIcon: Icons.source),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_discountCodeController, 'Discount Code', prefixIcon: Icons.discount),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_discountAmountController, 'Discount Amount', prefixIcon: Icons.money_off),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? prefixIcon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: const Text('Create Order'),
      ),
    );
  }

  _submitForm() {
    if (_formKey.currentState!.validate()) {
      final customer = {
        "first_name": _customerFirstNameController.text,
        "last_name": _customerLastNameController.text,
        "email": _customerEmailController.text,
        "phone": int.parse(_customerPhoneController.text),
      };

      final billingAddr = {
        "first_name": _billingFirstNameController.text,
        "last_name": _billingLastNameController.text,
        "email": _billingEmailController.text,
        "address1": _billingAddress1Controller.text,
        "address2": _billingAddress2Controller.text,
        "phone": int.parse(_billingPhoneController.text),
        "city": _billingCityController.text,
        "pincode": int.parse(_billingPincodeController.text),
        "state": _billingStateController.text,
        "country": _billingCountryController.text,
        "country_code": _billingCountryCodeController.text,
      };

      final shippingAddr = {
        "first_name": _shippingFirstNameController.text,
        "last_name": _shippingLastNameController.text,
        "email": _shippingEmailController.text,
        "address1": _shippingAddress1Controller.text,
        "address2": _shippingAddress2Controller.text,
        "phone": int.parse(_shippingPhoneController.text),
        "city": _shippingCityController.text,
        "pincode": int.parse(_shippingPincodeController.text),
        "state": _shippingStateController.text,
        "country": _shippingCountryController.text,
        "country_code": _shippingCountryCodeController.text,
      };

      final items = [
        {
          "qty": int.parse(_itemQtyController.text),
          "sku": _itemSkuController.text,
          "amount": double.parse(_itemAmountController.text),
        }
      ];

      submitOrder(
        context: context,
        orderId: _orderIdController.text,
        customer: customer,
        billingAddr: billingAddr,
        shippingAddr: shippingAddr,
        paymentMode: _paymentModeController.text,
        currencyCode: _currencyCodeController.text,
        items: items,
        totalAmt: double.parse(_totalAmtController.text),
        codAmount: double.parse(_codAmountController.text),
        taxPercent: 0.0,
        source: _sourceController.text,
        agent: _agentController.text,
        totalQuantity: int.parse(_itemQtyController.text),
        marketplace: _marketplaceController.text,
        notes: "Handle with care.",
      );
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerFirstNameController.dispose();
    _customerLastNameController.dispose();
    _customerEmailController.dispose();
    _customerGstinController.dispose();
    _customerPhoneController.dispose();

    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingEmailController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingPhoneController.dispose();
    _billingCityController.dispose();
    _billingPincodeController.dispose();
    _billingStateController.dispose();
    _billingStateCodeController.dispose();
    _billingCountryController.dispose();
    _billingCountryCodeController.dispose();

    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingEmailController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingPhoneController.dispose();
    _shippingCityController.dispose();
    _shippingPincodeController.dispose();
    _shippingStateController.dispose();
    _shippingStateCodeController.dispose();
    _shippingCountryController.dispose();
    _shippingCountryCodeController.dispose();

    _paymentModeController.dispose();
    _currencyCodeController.dispose();
    _itemQtyController.dispose();
    _itemSkuController.dispose();
    _itemAmountController.dispose();
    _totalAmtController.dispose();
    _codAmountController.dispose();
    _coinController.dispose();
    _prepaidAmountController.dispose();

    _marketplaceController.dispose();
    _discountCodeController.dispose();
    _discountSchemeController.dispose();
    _discountAmountController.dispose();
    _sourceController.dispose();
    _agentController.dispose();

    super.dispose();
  }
}
