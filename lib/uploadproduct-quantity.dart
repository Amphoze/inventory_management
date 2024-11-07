import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/update-quantity-by-sku.dart';
import 'package:provider/provider.dart';

class UploadProductSku extends StatefulWidget {
  const UploadProductSku({super.key});

  @override
  State<UploadProductSku> createState() => _UploadProductSkuState();
}

class _UploadProductSkuState extends State<UploadProductSku> {
  Map<String, Map<String, dynamic>> jsonData = {};
  @override
  void initState() {
    super.initState();
    Provider.of<UpdateQuantityBySku>(context, listen: false)
        .updateJsonData(isfalse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateQuantityBySku>(
      builder: (context, provider, child) => Column(
        children: [
          Container(
            height: 50,
            width: 150,
            child: ElevatedButton(
                onPressed: () async {
                  FilePickerResult? pickedFile =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['xlsx'],
                    allowMultiple: false,
                  );
                  if (pickedFile != null) {
                    // print("i ma hete ");
                    var bytes = pickedFile.files.single.bytes;
                    var excel = Excel.decodeBytes(bytes!);
                    for (var table in excel.tables.keys) {
                      int i = 0;
                      for (var row in excel.tables[table]!.rows) {
                        if (i != 0) {
                          jsonData[row[1]!.value.toString()] = {
                            "newTotal": int.parse(row[0]!.value.toString()),
                            "warehouseId": "66fceb5163c6d5c106cfa809",
                            "additionalInfo": {"reason": "Excel update"}
                          };
                        } else {
                          i++;
                        }
                      }
                      if (jsonData.isNotEmpty) {
                        provider.updateJsonData();
                      }
                    }
                  }
                },
                child: Text("Upload Excel")),
          ),
          ElevatedButton(
            onPressed: !provider.jsonHaveData
                ? null
                : () {
                    for (String i in jsonData!.keys) {
                      print("data is here $i => ${jsonData[i].toString()}");
                    }
                  },
            child: const Text("check Data"),
          )
        ],
      ),
    );
  }
}
