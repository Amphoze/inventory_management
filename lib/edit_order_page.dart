import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:provider/provider.dart';

class EditOrderPage extends StatefulWidget {
  final Order order; // Pass the order to edit
  final bool isBookPage;

  const EditOrderPage({Key? key, required this.order, required this.isBookPage})
      : super(key: key);

  @override
  _EditOrderPageState createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  late ScrollController _scrollController;
  late TextEditingController _orderIdController;
  late TextEditingController _dateController;
  late TextEditingController _paymentModeController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _skuTrackingIdController;
  late TextEditingController _totalWeightController;
  late TextEditingController _totalAmtController;
  late TextEditingController _coinController;
  late TextEditingController _codAmountController;
  late TextEditingController _prepaidAmountController;
  late TextEditingController _discountCodeController;
  late TextEditingController _discountSchemeController;
  late TextEditingController _discountPercentController;
  late TextEditingController _discountAmountController;
  late TextEditingController _taxPercentController;
  late TextEditingController _courierNameController;
  late TextEditingController _orderTypeController;
  late TextEditingController _marketplaceController;
  late TextEditingController _filterController;
  late TextEditingController _freightChargeDelhiveryController;
  late TextEditingController _freightChargeShiprocketController;
  late TextEditingController _agentController;
  late TextEditingController _notesController;
  late TextEditingController _expectedDeliveryDateController;
  late TextEditingController _preferredCourierController;
  late TextEditingController _deliveryTermController;
  late TextEditingController _transactionNumberController;
  late TextEditingController _microDealerOrderController;
  late TextEditingController _fulfillmentTypeController;
  late TextEditingController _numberOfBoxesController;
  late TextEditingController _totalQuantityController;
  late TextEditingController _skuQtyController;
  late TextEditingController _calcEntryNumberController;
  late TextEditingController _currencyController;
  late TextEditingController _paymentDateTimeController;
  late TextEditingController _paymentBankController;
  late TextEditingController _lengthController;
  late TextEditingController _breadthController;
  late TextEditingController _heightController;
  late TextEditingController _awbNumberController;
  late TextEditingController _trackingStatusController;

  // Controllers for customer
  late TextEditingController _customerIdController;
  late TextEditingController _customerFirstNameController;
  late TextEditingController _customerLastNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerGstinController;
  // Controllers for billing address
  late TextEditingController _billingFirstNameController;
  late TextEditingController _billingLastNameController;
  late TextEditingController _billingEmailController;
  late TextEditingController _billingAddress1Controller;
  late TextEditingController _billingAddress2Controller;
  late TextEditingController _billingPhoneController;
  late TextEditingController _billingCityController;
  late TextEditingController _billingPincodeController;
  late TextEditingController _billingStateController;
  late TextEditingController _billingCountryController;
  late TextEditingController _billingCountryCodeController;
  // Controllers for shipping address
  late TextEditingController _shippingFirstNameController;
  late TextEditingController _shippingLastNameController;
  late TextEditingController _shippingEmailController;
  late TextEditingController _shippingAddress1Controller;
  late TextEditingController _shippingAddress2Controller;
  late TextEditingController _shippingPhoneController;
  late TextEditingController _shippingCityController;
  late TextEditingController _shippingPincodeController;
  late TextEditingController _shippingStateController;
  late TextEditingController _shippingCountryController;
  late TextEditingController _shippingCountryCodeController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize controllers with the order data
    _orderIdController = TextEditingController(text: widget.order.orderId);
    _dateController = TextEditingController(
        text: widget.order.date != null ? formatDate(widget.order.date!) : '');
    _paymentModeController =
        TextEditingController(text: widget.order.paymentMode ?? '');
    _currencyCodeController =
        TextEditingController(text: widget.order.currencyCode ?? '');
    _skuTrackingIdController =
        TextEditingController(text: widget.order.skuTrackingId ?? '');
    _totalWeightController =
        TextEditingController(text: widget.order.totalWeight?.toString() ?? '');
    _totalAmtController =
        TextEditingController(text: widget.order.totalAmount?.toString() ?? '');
    _coinController =
        TextEditingController(text: widget.order.coin?.toString() ?? '');
    _codAmountController =
        TextEditingController(text: widget.order.codAmount?.toString() ?? '');
    _prepaidAmountController = TextEditingController(
        text: widget.order.prepaidAmount?.toString() ?? '');
    _discountCodeController =
        TextEditingController(text: widget.order.discountCode ?? '');
    _discountSchemeController =
        TextEditingController(text: widget.order.discountScheme ?? '');
    _discountPercentController = TextEditingController(
        text: widget.order.discountPercent?.toString() ?? '');
    _discountAmountController = TextEditingController(
        text: widget.order.discountAmount?.toString() ?? '');
    _taxPercentController =
        TextEditingController(text: widget.order.taxPercent?.toString() ?? '');
    _courierNameController =
        TextEditingController(text: widget.order.courierName ?? '');
    _orderTypeController =
        TextEditingController(text: widget.order.orderType ?? '');
    _marketplaceController = TextEditingController(
        text: widget.order.marketplace?.name?.toString() ?? '');
    _filterController = TextEditingController(text: widget.order.filter ?? '');
    _freightChargeDelhiveryController = TextEditingController(
        text: widget.order.freightCharge?.delhivery?.toString() ?? '');
    _freightChargeShiprocketController = TextEditingController(
        text: widget.order.freightCharge?.shiprocket?.toString() ?? '');

    _agentController = TextEditingController(text: widget.order.agent ?? '');
    _notesController = TextEditingController(text: widget.order.notes ?? '');
    _expectedDeliveryDateController = TextEditingController(
        text: widget.order.expectedDeliveryDate != null
            ? formatDate(widget.order.expectedDeliveryDate!)
            : '');
    _preferredCourierController =
        TextEditingController(text: widget.order.preferredCourier ?? '');
    _deliveryTermController =
        TextEditingController(text: widget.order.deliveryTerm ?? '');
    _transactionNumberController =
        TextEditingController(text: widget.order.transactionNumber ?? '');
    _microDealerOrderController =
        TextEditingController(text: widget.order.microDealerOrder ?? '');
    _fulfillmentTypeController =
        TextEditingController(text: widget.order.fulfillmentType ?? '');
    _numberOfBoxesController = TextEditingController(
        text: widget.order.numberOfBoxes?.toString() ?? '');
    _totalQuantityController = TextEditingController(
        text: widget.order.totalQuantity?.toString() ?? '');
    _skuQtyController =
        TextEditingController(text: widget.order.skuQty?.toString() ?? '');
    _calcEntryNumberController =
        TextEditingController(text: widget.order.calcEntryNumber ?? '');
    _currencyController =
        TextEditingController(text: widget.order.currency ?? '');
    _paymentDateTimeController = TextEditingController(
        text: widget.order.paymentDateTime != null
            ? formatDate(widget.order.paymentDateTime!)
            : '');
    _paymentBankController =
        TextEditingController(text: widget.order.paymentBank ?? '');
    _lengthController =
        TextEditingController(text: widget.order.length?.toString() ?? '');
    _breadthController =
        TextEditingController(text: widget.order.breadth?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.order.height?.toString() ?? '');

    _awbNumberController = TextEditingController(text: widget.order.awbNumber);
    _trackingStatusController =
        TextEditingController(text: widget.order.trackingStatus ?? '');

    // Initalize customer details controllers
    _customerIdController =
        TextEditingController(text: widget.order.customer?.customerId ?? '');
    _customerFirstNameController =
        TextEditingController(text: widget.order.customer?.firstName ?? '');
    _customerLastNameController =
        TextEditingController(text: widget.order.customer?.lastName ?? '');
    _customerEmailController =
        TextEditingController(text: widget.order.customer?.email ?? '');
    _customerPhoneController = TextEditingController(
        text: widget.order.customer?.phone?.toString() ?? '');
    _customerGstinController =
        TextEditingController(text: widget.order.customer?.customerGstin ?? '');

    // Initialize billing address controllers
    _billingFirstNameController = TextEditingController(
        text: widget.order.billingAddress?.firstName ?? '');
    _billingLastNameController = TextEditingController(
        text: widget.order.billingAddress?.lastName ?? '');
    _billingEmailController =
        TextEditingController(text: widget.order.billingAddress?.email ?? '');
    _billingAddress1Controller = TextEditingController(
        text: widget.order.billingAddress?.address1 ?? '');
    _billingAddress2Controller = TextEditingController(
        text: widget.order.billingAddress?.address2 ?? '');
    _billingPhoneController = TextEditingController(
        text: widget.order.billingAddress?.phone?.toString() ?? '');
    _billingCityController =
        TextEditingController(text: widget.order.billingAddress?.city ?? '');
    _billingPincodeController = TextEditingController(
        text: widget.order.billingAddress?.pincode?.toString() ?? '');
    _billingStateController =
        TextEditingController(text: widget.order.billingAddress?.state ?? '');
    _billingCountryController =
        TextEditingController(text: widget.order.billingAddress?.country ?? '');
    _billingCountryCodeController = TextEditingController(
        text: widget.order.billingAddress?.countryCode ?? '');

    // Initialize shipping address controllers
    _shippingFirstNameController = TextEditingController(
        text: widget.order.shippingAddress?.firstName ?? '');
    _shippingLastNameController = TextEditingController(
        text: widget.order.shippingAddress?.lastName ?? '');
    _shippingEmailController =
        TextEditingController(text: widget.order.shippingAddress?.email ?? '');
    _shippingAddress1Controller = TextEditingController(
        text: widget.order.shippingAddress?.address1 ?? '');
    _shippingAddress2Controller = TextEditingController(
        text: widget.order.shippingAddress?.address2 ?? '');
    _shippingPhoneController = TextEditingController(
        text: widget.order.shippingAddress?.phone?.toString() ?? '');
    _shippingCityController =
        TextEditingController(text: widget.order.shippingAddress?.city ?? '');
    _shippingPincodeController = TextEditingController(
        text: widget.order.shippingAddress?.pincode?.toString() ?? '');
    _shippingStateController =
        TextEditingController(text: widget.order.shippingAddress?.state ?? '');
    _shippingCountryController = TextEditingController(
        text: widget.order.shippingAddress?.country ?? '');
    _shippingCountryCodeController = TextEditingController(
        text: widget.order.shippingAddress?.countryCode ?? '');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _orderIdController.dispose();
    _dateController.dispose();
    _paymentModeController.dispose();
    _currencyCodeController.dispose();
    _skuTrackingIdController.dispose();
    _totalWeightController.dispose();
    _totalAmtController.dispose();
    _coinController.dispose();
    _codAmountController.dispose();
    _prepaidAmountController.dispose();
    _discountCodeController.dispose();
    _discountSchemeController.dispose();
    _discountPercentController.dispose();
    _discountAmountController.dispose();
    _taxPercentController.dispose();
    _courierNameController.dispose();
    _orderTypeController.dispose();
    _marketplaceController.dispose();
    _filterController.dispose();
    _freightChargeDelhiveryController.dispose();
    _freightChargeShiprocketController.dispose();
    _expectedDeliveryDateController.dispose();
    _preferredCourierController.dispose();
    _deliveryTermController.dispose();
    _transactionNumberController.dispose();
    _microDealerOrderController.dispose();
    _fulfillmentTypeController.dispose();
    _numberOfBoxesController.dispose();
    _totalQuantityController.dispose();
    _skuQtyController.dispose();
    _calcEntryNumberController.dispose();
    _currencyController.dispose();
    _paymentDateTimeController.dispose();
    _paymentBankController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _heightController.dispose();
    _agentController.dispose();
    _notesController.dispose();
    _trackingStatusController.dispose();
    _awbNumberController.dispose();

    // Dispose customer details controllers
    _customerIdController.dispose();
    _customerFirstNameController.dispose();
    _customerLastNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerGstinController.dispose();

    // Dispose billing address controllers
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingEmailController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingPhoneController.dispose();
    _billingCityController.dispose();
    _billingPincodeController.dispose();
    _billingStateController.dispose();
    _billingCountryController.dispose();
    _billingCountryCodeController.dispose();

    // Dispose shipping address controllers
    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingEmailController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingPhoneController.dispose();
    _shippingCityController.dispose();
    _shippingPincodeController.dispose();
    _shippingStateController.dispose();
    _shippingCountryController.dispose();
    _shippingCountryCodeController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _orderIdController.clear();
    _dateController.clear();
    _paymentModeController.clear();
    _currencyCodeController.clear();
    _skuTrackingIdController.clear();
    _totalWeightController.clear();
    _totalAmtController.clear();
    _coinController.clear();
    _codAmountController.clear();
    _prepaidAmountController.clear();
    _discountCodeController.clear();
    _discountSchemeController.clear();
    _discountPercentController.clear();
    _discountAmountController.clear();
    _taxPercentController.clear();
    _courierNameController.clear();
    _orderTypeController.clear();
    _marketplaceController.clear();
    _filterController.clear();
    _freightChargeDelhiveryController.clear();
    _freightChargeShiprocketController.clear();
    _expectedDeliveryDateController.clear();
    _preferredCourierController.clear();
    _deliveryTermController.clear();
    _transactionNumberController.clear();
    _microDealerOrderController.clear();
    _fulfillmentTypeController.clear();
    _numberOfBoxesController.clear();
    _totalQuantityController.clear();
    _skuQtyController.clear();
    _calcEntryNumberController.clear();
    _currencyController.clear();
    _paymentDateTimeController.clear();
    _paymentBankController.clear();
    _lengthController.clear();
    _breadthController.clear();
    _heightController.clear();
    _agentController.clear();
    _notesController.clear();
    _trackingStatusController.clear();
    _awbNumberController.clear();

    // Clear customer details
    _customerIdController.clear();
    _customerFirstNameController.clear();
    _customerLastNameController.clear();
    _customerEmailController.clear();
    _customerPhoneController.clear();
    _customerGstinController.clear();

    // Clear billing address
    _billingFirstNameController.clear();
    _billingLastNameController.clear();
    _billingEmailController.clear();
    _billingAddress1Controller.clear();
    _billingAddress2Controller.clear();
    _billingPhoneController.clear();
    _billingCityController.clear();
    _billingPincodeController.clear();
    _billingStateController.clear();
    _billingCountryController.clear();
    _billingCountryCodeController.clear();

    // Clear shipping address
    _shippingFirstNameController.clear();
    _shippingLastNameController.clear();
    _shippingEmailController.clear();
    _shippingAddress1Controller.clear();
    _shippingAddress2Controller.clear();
    _shippingPhoneController.clear();
    _shippingCityController.clear();
    _shippingPincodeController.clear();
    _shippingStateController.clear();
    _shippingCountryController.clear();
    _shippingCountryCodeController.clear();
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Current date
      firstDate: DateTime(2000), // Earliest date
      lastDate: DateTime(2101), // Latest date
    );
    if (picked != null) {
      setState(() {
        // Use formatDate to format the selected date
        _dateController.text = formatDate(picked);
      });
    }
  }

  Future<void> _selectExpectedDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final formattedDate = formatDate(picked);
      // Access the provider and update the expected delivery date
      Provider.of<OrdersProvider>(context, listen: false)
          .updateExpectedDeliveryDate(formattedDate);
    }
  }

  Future<void> _selectPaymentDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // Select time after picking the date
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final formattedDateTime = formatDate(finalDateTime);

        // Access the provider and update the payment date time
        Provider.of<OrdersProvider>(context, listen: false)
            .updatePaymentDateTime(formattedDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Edit Order'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.orange),
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12.0)),
              ),
              onPressed: () {
                // provider.updateOrder(updatedOrder);
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Field
              const Text(
                "Order Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.green,
                ),
              ),
              const Divider(thickness: 1, color: AppColors.grey),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        controller: _orderIdController,
                        label: 'Order ID',
                        icon: Icons.confirmation_number,
                        enabled: false),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _dateController,
                          label: "Date",
                          icon: Icons.date_range,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Consumer<OrdersProvider>(
                      builder: (context, ordersProvider, child) {
                        final String? selectedPayment =
                            ordersProvider.selectedPayment;

                        return DropdownButtonFormField<String>(
                          value: selectedPayment?.isNotEmpty == true
                              ? selectedPayment
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode',
                            prefixIcon: Icon(Icons.payment),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Select Payment Mode'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'PrePaid',
                              child: Text('PrePaid'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'COD',
                              child: Text('COD'),
                            ),
                          ],
                          onChanged: (value) {
                            ordersProvider.selectPayment(value);
                          },
                          hint: const Text('Select Payment Mode'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _currencyCodeController,
                      label: "Currency Code",
                      icon: Icons.currency_bitcoin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _skuTrackingIdController,
                      label: 'SKU Tracking ID',
                      icon: Icons.local_shipping,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _coinController,
                      label: 'Coin',
                      icon: Icons.monetization_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalWeightController,
                      label: 'Total Weight',
                      icon: Icons.line_weight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _taxPercentController,
                      label: 'Tax Percent',
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _codAmountController,
                      label: 'COD Amount',
                      icon: Icons.money,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _prepaidAmountController,
                      label: 'Prepaid Amount',
                      icon: Icons.credit_card,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _totalAmtController,
                      label: 'Total Amount',
                      icon: Icons.attach_money,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _discountCodeController,
                      label: 'Discount Code',
                      icon: Icons.discount,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _discountSchemeController,
                      label: 'Discount Scheme',
                      icon: Icons.card_giftcard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _discountPercentController,
                      label: 'Discount Percent',
                      icon: Icons.percent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _discountAmountController,
                      label: 'Discount Amount',
                      icon: Icons.money_off,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Consumer<OrdersProvider>(
                  builder: (context, ordersProvider, child) {
                return DropdownButtonFormField<String>(
                  value: ordersProvider.selectedCourier,
                  decoration: const InputDecoration(
                    labelText: 'Courier Name',
                    prefixIcon: Icon(Icons.local_shipping),
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Select Courier'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Delhivery',
                      child: Text('Delhivery'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Shiprocket',
                      child: Text('Shiprocket'),
                    ),
                  ],
                  onChanged: (value) {
                    ordersProvider.selectCourier(value);
                  },
                );
              }),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _orderTypeController,
                label: 'Order Type',
                icon: Icons.shopping_cart,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _marketplaceController,
                      label: 'Marketplace',
                      icon: Icons.shop,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _filterController,
                      label: 'Filter',
                      icon: Icons.filter_1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectExpectedDeliveryDate(context),
                      child: AbsorbPointer(
                        child: Consumer<OrdersProvider>(
                          builder: (context, orderProvider, child) {
                            _expectedDeliveryDateController.text =
                                orderProvider.expectedDeliveryDate;

                            return _buildTextField(
                              controller: _expectedDeliveryDateController,
                              label: 'Expected Delivery Date',
                              icon: Icons.calendar_today,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _preferredCourierController,
                      label: 'Preferred Courier',
                      icon: Icons.local_shipping,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _deliveryTermController,
                      label: 'Delivery Term',
                      icon: Icons.description,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _transactionNumberController,
                      label: 'Transaction Number',
                      icon: Icons.confirmation_number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _microDealerOrderController,
                      label: 'Micro Dealer Order',
                      icon: Icons.shopping_cart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _fulfillmentTypeController,
                      label: 'Fulfillment Type',
                      icon: Icons.assignment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _numberOfBoxesController,
                      label: 'Number of Boxes',
                      icon: Icons.inbox,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _totalQuantityController,
                      label: 'Total Quantity',
                      icon: Icons.format_list_numbered,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _skuQtyController,
                      label: 'SKU Quantity',
                      icon: Icons.list_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _currencyController,
                      label: 'Currency',
                      icon: Icons.monetization_on,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _calcEntryNumberController,
                      label: 'Calculation Entry Number',
                      icon: Icons.calculate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _paymentBankController,
                      label: 'Payment Bank',
                      icon: Icons.account_balance,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<OrdersProvider>(
                    builder: (context, orderProvider, child) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _selectPaymentDateTime(context),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _paymentDateTimeController
                                ..text = orderProvider.paymentDateTime,
                              label: 'Payment Date & Time',
                              icon: Icons.access_time,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lengthController,
                      label: 'Length',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _breadthController,
                      label: 'Breadth',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height',
                      icon: Icons.height,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _agentController,
                      label: 'Agent',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _notesController,
                      label: 'Notes',
                      icon: Icons.note,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _trackingStatusController,
                      label: 'Tracking Status',
                      icon: Icons.local_shipping,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.isBookPage)
                    Expanded(
                      child: _buildTextField(
                        controller: _awbNumberController,
                        label: 'AWB Number',
                        icon: Icons.confirmation_number,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),
              // Customer Details
              _buildHeading("Customer Details"),
              const Divider(thickness: 1, color: AppColors.grey),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _customerIdController,
                      label: 'Customer ID',
                      icon: Icons.perm_identity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _customerEmailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _customerFirstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _customerLastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _customerPhoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _customerGstinController,
                      label: 'Customer GSTin',
                      icon: Icons.business,
                    ),
                  ),
                ],
              ),

              // Billing Address
              const SizedBox(height: 30),
              _buildHeading("Billing Address"),
              const Divider(thickness: 1, color: AppColors.grey),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingFirstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingLastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingEmailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingAddress1Controller,
                      label: 'Address 1',
                      icon: Icons.location_on,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingAddress2Controller,
                      label: 'Address 2',
                      icon: Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingCityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingStateController,
                      label: 'State',
                      icon: Icons.map,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingCountryController,
                      label: 'Country',
                      icon: Icons.public,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _billingPhoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingPincodeController,
                      label: 'Pincode',
                      icon: Icons.code,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _billingCountryCodeController,
                      label: 'Country Code',
                      icon: Icons.travel_explore,
                    ),
                  ),
                ],
              ),

              // Shipping Address
              const SizedBox(height: 30),
              _buildHeading("Shipping Address"),
              const Divider(thickness: 1, color: AppColors.grey),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingFirstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingLastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingEmailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingAddress1Controller,
                      label: 'Address 1',
                      icon: Icons.location_on,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingAddress2Controller,
                      label: 'Address 2',
                      icon: Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingCityController,
                      label: 'City',
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingStateController,
                      label: 'State',
                      icon: Icons.map,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingCountryController,
                      label: 'Country',
                      icon: Icons.public,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingPhoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingPincodeController,
                      label: 'Pincode',
                      icon: Icons.code,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _shippingCountryCodeController,
                      label: 'Country Code',
                      icon: Icons.travel_explore,
                    ),
                  ),
                ],
              ),

              //Product Details
              const SizedBox(height: 30),
              _buildHeading('Product Details'),
              const Divider(
                  thickness: 1, color: Color.fromARGB(164, 158, 158, 158)),
              const SizedBox(height: 10),

              if (widget.order.items.isEmpty)
                const Center(
                  child: Text(
                    'No Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.order.items.length,
                  itemBuilder: (context, itemIndex) {
                    final item = widget.order.items[itemIndex];

                    return OrderItemCard(
                      item: item,
                      index: itemIndex,
                      courierName: widget.order.courierName,
                      orderStatus: widget.order.orderStatus.toString(),
                      cardColor: AppColors.lightGrey,
                    );
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build headings
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

  // Function to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
          color: enabled ? AppColors.green : Colors.grey[700],
          fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey[400]!,
          ),
        ),
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[300],
      ),
    );
  }
}
