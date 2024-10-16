import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';

class EditOrderPage extends StatefulWidget {
  final Order order; // Pass the order to edit

  const EditOrderPage({Key? key, required this.order}) : super(key: key);

  @override
  _EditOrderPageState createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  late TextEditingController _orderIdController;
  late TextEditingController _customerIdController;
  late TextEditingController _customerFirstNameController;
  late TextEditingController _customerLastNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerGstinController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the order data
    _orderIdController = TextEditingController(text: widget.order.orderId);
    _customerIdController =
        TextEditingController(text: widget.order.customer?.customerId);
    _customerFirstNameController =
        TextEditingController(text: widget.order.customer?.firstName);
    _customerLastNameController =
        TextEditingController(text: widget.order.customer?.lastName);
    _customerEmailController =
        TextEditingController(text: widget.order.customer?.email);
    _customerPhoneController =
        TextEditingController(text: widget.order.customer?.phone.toString());
    _customerGstinController =
        TextEditingController(text: widget.order.customer?.customerGstin);
  }

  @override
  void dispose() {
    // Dispose controllers when the page is destroyed
    _orderIdController.dispose();
    _customerIdController.dispose();
    _customerFirstNameController.dispose();
    _customerLastNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerGstinController.dispose();
    super.dispose();
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
                // Handle the save action here
                // Example: provider.updateOrder(updatedOrder);
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

              _buildTextField(
                controller: _orderIdController,
                label: 'Order ID',
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 20),

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

              //Product Details
              const SizedBox(height: 30),
              _buildHeading('Product Details'),
              const Divider(
                  thickness: 1, color: Color.fromARGB(164, 158, 158, 158)),
              const SizedBox(height: 10),

              // Check if there are no products
              if (widget.order.items.isEmpty)
                const Center(
                  child: Text(
                    'No Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors
                          .grey, // You can customize the color as needed
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
