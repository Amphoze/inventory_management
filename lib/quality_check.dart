import 'package:flutter/material.dart';
import 'package:inventory_management/provider/return_entry_provider.dart';
import 'package:provider/provider.dart';

class QualityCheck extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> itemsList;
  const QualityCheck({super.key, required this.orderId, required this.itemsList});

  @override
  State<QualityCheck> createState() => _QualityCheckState();
}

class _QualityCheckState extends State<QualityCheck> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReturnEntryProvider>(
      builder: (context, pro, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.orderId),
            centerTitle: true,
            elevation: 2,
            // backgroundColor: Colors.blueGrey[900],
          ),
          body: Stack(
            children: [
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Items Section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Items Inspection',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                ...widget.itemsList.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${item['sku']} (Total: ${item['total']})",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: item['goodQty'],
                                                decoration: InputDecoration(
                                                  labelText: 'Good Qty',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                ),
                                                validator: _validateQuantity,
                                                keyboardType: TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller: item['badQty'],
                                                decoration: InputDecoration(
                                                  labelText: 'Bad Qty',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                ),
                                                validator: _validateQuantity,
                                                keyboardType: TextInputType.number,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image Upload Section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Upload Evidence',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    TextButton(onPressed: pro.clearImages, child: const Text('Clear', style: TextStyle(color: Colors.red),))
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: pro.pickImages,
                                  icon: const Icon(Icons.upload_file, color: Colors.white),
                                  label: const Text('Select Images'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                if (pro.uploadedImages.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 120,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: pro.uploadedImages.length,
                                      itemBuilder: (context, index) {
                                        final file = pro.uploadedImages[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: file.bytes != null
                                                      ? Image.memory(
                                                          file.bytes!,
                                                          width: 100,
                                                          height: 100,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              width: 100,
                                                              height: 100,
                                                              color: Colors.grey[300],
                                                              child: const Center(child: Icon(Icons.error, color: Colors.red)),
                                                            );
                                                          },
                                                        )
                                                      : Container(
                                                          width: 100,
                                                          height: 100,
                                                          color: Colors.grey[300],
                                                          child: const Center(child: Text('No Image Data')),
                                                        ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: IconButton(
                                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                                  onPressed: () => pro.removeImage(index),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: pro.isLoading ? null : () => _submit(context, pro),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              // backgroundColor: Colors.blueGrey[900],
                            ),
                            child: const Text(
                              'Submit Quality Check',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (pro.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (int.tryParse(value) == null) return 'Enter a valid number';
    if (int.parse(value) < 0) return 'Cannot be negative';
    return null;
  }

  void _submit(BuildContext context, ReturnEntryProvider pro) async {
    if (!_formKey.currentState!.validate()) return;

    final result = await pro.submitQualityCheck(context, widget.orderId, widget.itemsList);
    if (context.mounted) {
      // Navigator.pop(context);
      if (result['success'] == true) {
        pro.showSnackBar(context, result['message'], Colors.green);
      } else {
        pro.showSnackBar(context, result['message'], Colors.red);
      }
    }
  }
}
