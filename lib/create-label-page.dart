import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management/Api/lable-page-api.dart';
import 'package:inventory_management/Custom-Files/responsove-layout.dart';
import 'package:provider/provider.dart';

class CreateLabelPage extends StatefulWidget {
  const CreateLabelPage({super.key});

  @override
  State<CreateLabelPage> createState() => _CreateLabelPageState();
}

class _CreateLabelPageState extends State<CreateLabelPage> {
  
  // final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _labelSkuController = TextEditingController();
  // final TextEditingController _imageController = TextEditingController();
  // final TextEditingController _descriptionController = TextEditingController();
  // final TextEditingController _productIdController = TextEditingController();
  // final TextEditingController _quantityController = TextEditingController();
  LabelPageApi ? labelPageProvider;
  // final ScrollController controller = ScrollController();
  final GlobalKey<DropdownSearchState<String>> _dropdownKey = GlobalKey<DropdownSearchState<String>>();

  // void _resetFields() {
  //   _nameController.clear();
  //   _labelSkuController.clear();
  //   _imageController.clear();
  //   _descriptionController.clear();
  //   _productIdController.clear();
  //   _quantityController.clear();
  // }

 void _saveLabel() async {
  try {
    labelPageProvider!.buttonTapStatus();
    var res = await labelPageProvider!.createLabel();
    if (res["res"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
          content: Text("Label created successfully"),
          backgroundColor: Colors.green,
        ),
      );
      labelPageProvider!.clearControllers(_dropdownKey);
      labelPageProvider!.buttonTapStatus();
    } else {
      throw res["res"];

    }
  } catch (e) {
    labelPageProvider!.buttonTapStatus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    labelPageProvider=Provider.of<LabelPageApi>(context,listen:false);
    getData();
  }
  void getData()async{
    
    await labelPageProvider!.getProductDetails();
  }

  @override
  Widget build(BuildContext context) {
    // labelPageProvider=Provider.of<LabelPageApi>(context,listen:false);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create New Label",
          style: GoogleFonts.daiBannaSil(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body:Consumer<LabelPageApi>(
        builder:(context,pro,child)=>true? ResponsiveLayout(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                // controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardTextField(labelPageProvider!.nameController, "Name"),
                    _buildCardTextField(labelPageProvider!.labelSkuController, "Label SKU"),
                    _buildCardTextField(labelPageProvider!.imageController, "Image URL"),
                    _buildCardTextField(labelPageProvider!.descriptionController, "Description"),
                    // _buildCardTextField(_productIdController, "Product ID"),
                    // dropDown(),
                    _buildCardTextField(
                      labelPageProvider!.quantityController,
                      "Quantity",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRoundedButton("Reset", Colors.grey,(){labelPageProvider!.clearControllers(_dropdownKey);}),
                        _buildRoundedButton(
                            "Save", Colors.blueAccent, _saveLabel,loader:true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ):const Center(
        child:Text('loading'),
      ),
      ),
    );
  }

  Widget _buildCardTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.daiBannaSil(
              // fontSize:,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16.0),
          ),
          style: GoogleFonts.daiBannaSil(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.purple.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedButton(String text, Color color, VoidCallback onPressed,{bool loader=false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed:!(labelPageProvider!.buttonTap )?onPressed:null,
        // onPressed:(){
        //   _dropdownKey.currentState?.clear();
        //   // Key("dipu").clearButtonProps();
        //   // dip;

        // },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child:(!(labelPageProvider!.buttonTap)||!loader)?Text(
          text,
          style: const TextStyle(fontSize: 16),
        ):const CircularProgressIndicator(),
      ),
    );
  }

  // Widget dropDown() {
  //   return DropdownButtonHideUnderline(
  //     child: Card(
  //       elevation: 10,
  //       // shape: RoundedRectangleBorder(
  //       //     borderRadius: BorderRadius.circular(12.0), side: BorderSide.none),
  //       child: DropdownSearch<String>(
  //         dropdownDecoratorProps: DropDownDecoratorProps(
  //           baseStyle: GoogleFonts.daiBannaSil(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 18,
  //             color: Colors.blueAccent,
  //           ),
  //           dropdownSearchDecoration: InputDecoration(
  //             labelText: 'Product Name: ',
  //             labelStyle: GoogleFonts.daiBannaSil(
  //               fontWeight: FontWeight.bold,
  //               color: Colors.blueAccent,
  //             ),
  //             border: const OutlineInputBorder(
  //               borderRadius: BorderRadius.all(Radius.circular(12)),
  //               borderSide: BorderSide.none,
  //             ),
  //             fillColor: Colors.white,
  //             filled: true,
  //           ),
  //         ),
  //         items:labelPageProvider!.productDeatils
  //   .map((map) => map['displayName'] as String?)
  //   .map((displayName) => displayName ?? 'null value') 
  //   .toList(),
  //         selectedItem: "Select a product",
  //         popupProps: PopupProps.menu(
  //           menuProps: MenuProps(
  //               elevation: 10,
  //               barrierColor: Colors.transparent.withOpacity(0.5),
  //               shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                   side: BorderSide(
  //                       strokeAlign: BorderSide.strokeAlignInside,
  //                       color: Colors.amber.withOpacity(0.2)))),
  //           itemBuilder: (con, val, tr) {
  //             return Padding(
  //               padding: const EdgeInsets.only(left: 30),
  //               child: Text(
  //                 val,
  //                 style: GoogleFonts.daiBannaSil(
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.blueAccent,
  //                 ),
  //               ),
  //             );
  //           },
  //           showSelectedItems: true,
  //           showSearchBox: true,
  //           searchFieldProps: TextFieldProps(
  //             // cursorHeight:3,
  //             decoration: InputDecoration(
  //               hintText: "Search for an option",
  //               helperStyle: GoogleFonts.daiBannaSil(
  //                 // fontSize:,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.blueAccent,
  //               ),
  //               prefixIcon: const Icon(
  //                 Icons.search,
  //                 size: 20,
  //                 color: Colors.blueAccent,
  //               ),
  //               border: InputBorder.none,
  //               constraints: const BoxConstraints(maxHeight: 30),
  //               isDense: true,
  //               filled: true,
  //               fillColor: Colors.white,
  //               label: Text(
  //                 'Search',
  //                 style: GoogleFonts.daiBannaSil(
  //                   // fontSize:,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.blueAccent,
  //                 ),
  //               ),
  //               contentPadding: const EdgeInsets.all(0),
  //             ),
  //           ),
  //           //  itemBuilder: (context, item, isSelected)=>ListTile(
  //           //       title: Text(item),
  //           //       selected: isSelected,
  //           //     ),
  //           scrollbarProps: const ScrollbarProps(
               
  //               ),
  //         ),
  //         onChanged: (String? newValue) {
  //           print("here s$newValue");
  //           // _items.fin;
            
  //           //  widget.selectedIndex= _items.indexWhere((element) => element == newValue);
  //           //  if(widget.onSelectedChanged!=null){
  //           //   widget.onSelectedChanged!( widget.selectedIndex );
  //           //  }

  //           // setState(() {
  //           //   _selectedItem = newValue;

  //           // }
  //           // );
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget dropDown() {
  return DropdownButtonHideUnderline(
    child: Card(
      elevation: 10,
      child: DropdownSearch<String>.multiSelection(
        key:_dropdownKey,
        dropdownDecoratorProps: DropDownDecoratorProps(
          baseStyle: GoogleFonts.daiBannaSil(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blueAccent,
          ),
          
          dropdownSearchDecoration: InputDecoration(
            labelText: 'Product Name: ',
            labelStyle: GoogleFonts.daiBannaSil(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
        // {
// "dipu":"1: jnsjnhj"
// "skkjk"Lmsjs
        // }
        items: labelPageProvider!.productDeatils
            .asMap()
            .entries
            .map((entry) => "${entry.key}:${entry.value['displayName'] as String? ?? 'null value'}")
            .toList(),
        popupProps: PopupPropsMultiSelection.menu(
          menuProps: MenuProps(
            elevation: 10,
            barrierColor: Colors.transparent.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                strokeAlign: BorderSide.strokeAlignInside,
                color: Colors.amber.withOpacity(0.2),
              ),
            ),
          ),
          itemBuilder: (context, item, isSelected) {
            String displayName = item.split(':')[1];
            return Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                displayName,
                style: GoogleFonts.daiBannaSil(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            );
          },
          showSelectedItems:false,
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search for an option",
              helperStyle: GoogleFonts.daiBannaSil(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Colors.blueAccent,
              ),
              border: InputBorder.none,
              constraints: const BoxConstraints(maxHeight: 30),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              label: Text(
                'Search',
                style: GoogleFonts.daiBannaSil(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              contentPadding: const EdgeInsets.all(0),
            ),
          ),
          scrollbarProps: const ScrollbarProps(),
        ),
        // onChanged: (String? newValue) {
        //   if (newValue != null && newValue != "Select a product") {
        //     List<String> parts = newValue.split(':');
        //     int selectedIndex = int.parse(parts[0]);
        //     String displayName = parts[1];
            
            
        //     labelPageProvider!.updateSelectedIndex(selectedIndex);
        //     // var selectedProduct = labelPageProvider!.productDeatils[selectedIndex];
        //     // print("Full product details: $selectedProduct");
        //   }
        // },
        onChanged:(arr){
          labelPageProvider!.selectedListIndexClear();
          List<int>index=[];
          List<String>data=[];
          for(String a in arr){
            data.add(a);
            List<String> parts = a.split(':');
            int selectedIndex = int.parse(parts[0]);
            index.add(selectedIndex);
          }
          labelPageProvider!.updateSelectedIndex(index);
        },
      ),
    ),
  );
}
}
