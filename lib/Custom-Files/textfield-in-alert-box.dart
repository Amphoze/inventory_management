import 'package:flutter/material.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:inventory_management/Custom-Files/custom-textfield.dart';
import 'package:provider/provider.dart';

class CustomAlertBox {
  static void showKeyValueDialog(BuildContext context) {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        var productPageProvider =
            Provider.of<ProductProvider>(context, listen: true);
        return AlertDialog(
          title: const Text('Enter Key and Value'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0;
                      i < productPageProvider.alertBoxFieldCount;
                      i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Key',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                CustomTextField(
                                  controller: productPageProvider
                                      .alertBoxKeyEditingController[i],
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Value',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                CustomTextField(
                                  controller: productPageProvider
                                      .alertBoxPairEditingController[i],
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                productPageProvider
                                    .addNewTextEditingControllerInAlertBox();
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String key = keyController.text;
                String value = valueController.text;
                print('Key: $key, Value: $value');
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  static void diaglogWithOneTextField(BuildContext context) {
    final TextEditingController keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // var productPageProvider=Provider.of<ProductProvider>(context,listen:true);
        return AlertDialog(
          title: const Text('Add Category'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    CustomTextField(
                      controller: keyController,
                      width: double.infinity,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String key = keyController.text;
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
