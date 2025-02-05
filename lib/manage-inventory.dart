// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:inventory_management/Custom-Files/colors.dart';
// import 'package:inventory_management/Custom-Files/custom-dropdown.dart';
// import 'package:inventory_management/Custom-Files/custom-textfield.dart';
// import 'package:inventory_management/provider/manage-inventory-provider.dart';
// import 'package:pagination_flutter/pagination.dart';
// import 'package:provider/provider.dart';

// class ManageInventory extends StatefulWidget {
//   const ManageInventory({super.key});

//   @override
//   State<ManageInventory> createState() => _ManageInventoryState();
// }

// class _ManageInventoryState extends State<ManageInventory> {
//   String handleNullValue(String? value) {
//     return value ?? 'NA';
//   }

//   @override
//   Widget build(BuildContext context) {
//     var manageInventoryProvider = Provider.of<ManagementProvider>(context);
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Container(
//           color: AppColors.greyBackground,
//           child: Column(
//             children: [
//               Container(
//                 color: AppColors.greyBackground,
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     screenWidth > 1415
//                         ? Row(
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text('Stock Level',
//                                       style: AppColors().simpleHeadingStyle),
//                                   Row(
//                                     children: [
//                                       CustomTextField(
//                                         controller: TextEditingController(),
//                                         width: screenWidth * 0.12,
//                                       ),
//                                       const SizedBox(width: 10),
//                                       CustomTextField(
//                                         controller: TextEditingController(),
//                                         width: screenWidth * 0.12,
//                                       ),
//                                       const SizedBox(width: 20),
//                                       const buttonForThisPage(
//                                           width: 70,
//                                           height: 50,
//                                           buttonTitle: 'GO'),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(width: 10),
//                               SizedBox(
//                                 width: screenWidth * 0.5,
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Search',
//                                         style: AppColors().simpleHeadingStyle),
//                                     Row(
//                                       children: [
//                                         SizedBox(
//                                           width: 100,
//                                           child: CustomDropdown(),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         CustomTextField(
//                                           controller: TextEditingController(),
//                                           width: screenWidth * 0.12,
//                                         ),
//                                         const SizedBox(
//                                           width: 5,
//                                         ),
//                                         Text('Search Exact SKU',
//                                             style:
//                                                 AppColors().simpleHeadingStyle),
//                                         const SizedBox(
//                                           width: 5,
//                                         ),
//                                         const buttonForThisPage(
//                                             buttonTitle: 'Search',
//                                             height: 50,
//                                             width: 100),
//                                         const SizedBox(
//                                           width: 5,
//                                         ),
//                                         const buttonForThisPage(
//                                             buttonTitle: 'Download Inventory',
//                                             height: 50,
//                                             width: 175),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                             ],
//                           )
//                         : Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Stock Level',
//                                   style: AppColors().simpleHeadingStyle),
//                               Row(
//                                 children: [
//                                   CustomTextField(
//                                     controller: TextEditingController(),
//                                     width: 145,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   CustomTextField(
//                                     controller: TextEditingController(),
//                                     width: 145,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   screenWidth > 450
//                                       ? const buttonForThisPage(
//                                           width: 70,
//                                           height: 50,
//                                           buttonTitle: 'GO')
//                                       : const SizedBox(),
//                                 ],
//                               ),
//                               screenWidth < 450
//                                   ? const buttonForThisPage(
//                                       width: 70, height: 50, buttonTitle: 'GO')
//                                   : const SizedBox(),
//                               Text('Search',
//                                   style: AppColors().simpleHeadingStyle),
//                               Row(
//                                 children: [
//                                   SizedBox(
//                                     width: 100,
//                                     child: CustomDropdown(),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   CustomTextField(
//                                     controller: TextEditingController(),
//                                     width: screenWidth * 0.15,
//                                     label: 'Search Exact SKU',
//                                   ),
//                                   const SizedBox(
//                                     width: 5,
//                                   ),
//                                   screenWidth > 450
//                                       ? Text('Search Exact SKU',
//                                           style: AppColors().simpleHeadingStyle)
//                                       : const SizedBox(),
//                                   const SizedBox(
//                                     width: 5,
//                                   ),
//                                   const buttonForThisPage(
//                                       buttonTitle: 'Search',
//                                       height: 50,
//                                       width: 100),
//                                   const SizedBox(
//                                     width: 5,
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 5,
//                               ),
//                               const buttonForThisPage(
//                                   buttonTitle: 'Download Inventory',
//                                   height: 50,
//                                   width: 175),
//                             ],
//                           ),
//                     const SizedBox(height: 10),
//                     Text('Filters', style: AppColors().simpleHeadingStyle),
//                     Container(
//                       height: 80,
//                       decoration: BoxDecoration(
//                           border: Border.all(
//                               color: AppColors.black.withOpacity(0.2)),
//                           borderRadius: BorderRadius.circular(10)),
//                       child: Align(
//                         alignment: Alignment.topLeft,
//                         child: SizedBox(
//                           width: 150,
//                           height: 51,
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: CustomDropdown(),
//                           ),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//               Container(
//                 height: 30,
//                 color: AppColors.white,
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: CustomTextField(
//                       controller: TextEditingController(text: 'Hello'),
//                       width: 150,
//                       label: 'Search',
//                       icon: Icons.search,
//                     ),
//                   ),
//                 ],
//               ),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   showBottomBorder: true,
//                   dataRowMaxHeight: 100,
//                   columns: [
//                     DataColumn(
//                         label: Text('COMPANY NAME',
//                             style: AppColors().headerStyle)),
//                     DataColumn(
//                         label:
//                             Text('CATEGORY', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label: Text('IMAGE', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label: Text('BRAND', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label: Text('SKU', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label: Text('PRODUCT NAME',
//                             style: AppColors().headerStyle)),
//                     DataColumn(
//                         label:
//                             Text('MODEL NO', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label: Text('MRP', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label:
//                             Text('QUANTITY', style: AppColors().headerStyle)),
//                     DataColumn(
//                       label: ElevatedButton(
//                         onPressed: () {
//                           // Save all action
//                         },
//                         child: const Text('Save All'),
//                       ),
//                     ),
//                     DataColumn(
//                         label:
//                             Text('FLIPKART', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label:
//                             Text('SNAPDEAL', style: AppColors().headerStyle)),
//                     DataColumn(
//                         label:
//                             Text('AMAZON.IN', style: AppColors().headerStyle)),
//                   ],
//                   rows: manageInventoryProvider.inventoryList.map((inventory) {
//                     return DataRow(
//                       cells: [
//                         DataCell(Text(
//                             handleNullValue(inventory.product?.companyName))),
//                         DataCell(
//                             Text(handleNullValue(inventory.product?.category))),
//                         DataCell(Image.network(
//                           handleNullValue(inventory.product?.imageUrl),
//                           width: 100,
//                           height: 100,
//                           errorBuilder: (context, error, stackTrace) {
//                             return const Text('Image failed to load');
//                           },
//                         )),
//                         DataCell(
//                             Text(handleNullValue(inventory.product?.brand))),
//                         DataCell(Text(handleNullValue(inventory.product?.sku))),
//                         DataCell(Text(
//                             handleNullValue(inventory.product?.displayName))),
//                         DataCell(
//                             Text(handleNullValue(inventory.product?.modelNo))),
//                         DataCell(Text(handleNullValue(
//                             inventory.product?.mrp))),
//                         DataCell(
//                           Container(
//                             constraints: const BoxConstraints(maxWidth: 200),
//                             child: SingleChildScrollView(
//                               scrollDirection: Axis.vertical,
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Column(
//                                         children: [
//                                           Container(
//                                             height: 30,
//                                             width: 130,
//                                             decoration: BoxDecoration(
//                                               border: Border.all(
//                                                   color: AppColors.black),
//                                             ),
//                                             child: Center(
//                                               child:
//                                                   Text(handleNullValue("50")),
//                                             ),
//                                           ),
//                                           const SizedBox(height: 3),
//                                           const buttonForThisPage(),
//                                         ],
//                                       ),
//                                       const SizedBox(width: 4),
//                                       const InkWell(
//                                         child: Icon(
//                                           Icons.cloud,
//                                           color: AppColors.cardsgreen,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Text(DateTime.now().toString()),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         DataCell(ElevatedButton(
//                           onPressed: () {
//                             // Save action for individual item
//                           },
//                           child: const Text('Save'),
//                         )),
//                         DataCell(Text(
//                             handleNullValue(inventory.product?.flipkartLink))),
//                         DataCell(Text(
//                             handleNullValue(inventory.product?.snapdealLink))),
//                         DataCell(Text(
//                             handleNullValue(inventory.product?.amazonLink))),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   InkWell(
//                     child: const FaIcon(FontAwesomeIcons.chevronLeft),
//                     onTap: () {
//                       manageInventoryProvider.upDateSelectedPage(1);
//                     },
//                   ),
//                   Pagination(
//                     numOfPages: manageInventoryProvider.numberofPages,
//                     selectedPage: manageInventoryProvider.selectedPage,
//                     pagesVisible: 5,
//                     spacing: 10,
//                     onPageChanged: (page) {
//                       manageInventoryProvider.upDateSelectedPage(page);
//                     },
//                     nextIcon: const Icon(
//                       Icons.chevron_right_rounded,
//                       color: AppColors.primaryBlue,
//                       size: 20,
//                     ),
//                     previousIcon: const Icon(
//                       Icons.chevron_left_rounded,
//                       color: AppColors.primaryBlue,
//                       size: 20,
//                     ),
//                     activeTextStyle: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     activeBtnStyle: ButtonStyle(
//                       backgroundColor:
//                           WidgetStateProperty.all(AppColors.primaryBlue),
//                       shape: WidgetStateProperty.all(const CircleBorder(
//                         side:
//                             BorderSide(color: AppColors.primaryBlue, width: 1),
//                       )),
//                     ),
//                     inactiveBtnStyle: ButtonStyle(
//                       elevation: WidgetStateProperty.all(0),
//                       backgroundColor: WidgetStateProperty.all(Colors.white),
//                       shape: WidgetStateProperty.all(const CircleBorder(
//                         side:
//                             BorderSide(color: AppColors.primaryBlue, width: 1),
//                       )),
//                     ),
//                     inactiveTextStyle: const TextStyle(
//                       fontSize: 14,
//                       color: AppColors.primaryBlue,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   InkWell(
//                     child: const FaIcon(FontAwesomeIcons.chevronRight),
//                     onTap: () {
//                       manageInventoryProvider.upDateSelectedPage(
//                           manageInventoryProvider.numberofPages);
//                     },
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Container(
//                       height: 30,
//                       width: 50,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: AppColors.lightBlue),
//                       ),
//                       child: Center(
//                         child: Text(
//                             '${manageInventoryProvider.selectedPage}/${manageInventoryProvider.numberofPages}'),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class buttonForThisPage extends StatelessWidget {
//   final double width;
//   final double height;
//   final String buttonTitle;

//   const buttonForThisPage({
//     super.key,
//     this.width = 150,
//     this.height = 30,
//     this.buttonTitle = 'View Details',
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: width,
//       height: height,
//       child: ElevatedButton(
//         style: const ButtonStyle(
//           fixedSize: WidgetStatePropertyAll(Size(130, 7)),
//         ),
//         onPressed: () {
//           // View details action
//         },
//         child: Text(buttonTitle),
//       ),
//     );
//   }
// }
