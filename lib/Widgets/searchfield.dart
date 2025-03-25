// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';

// class CustomDropdownSearch<T> extends StatefulWidget {
//   final String hintText;
//   final Future<List<T>> Function() fetchItems;
//   final void Function(T?) onChanged;
//   final String Function(T) itemAsString;

//   const CustomDropdownSearch({
//     Key? key,
//     required this.hintText,
//     required this.fetchItems,
//     required this.onChanged,
//     required this.itemAsString,
//   }) : super(key: key);

//   @override
//   State<CustomDropdownSearch<T>> createState() => _CustomDropdownSearchState<T>();
// }

// class _CustomDropdownSearchState<T> extends State<CustomDropdownSearch<T>> {
//   List<T> _items = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     final items = await widget.fetchItems();
//     setState(() {
//       _items = items;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: DropdownSearch<T>(
//         popupProps: PopupProps.menu(
//           showSearchBox: true,
//           searchFieldProps: TextFieldProps(
//             decoration: InputDecoration(
//               hintText: 'Search ${widget.hintText}',
//               prefixIcon: const Icon(Icons.search),
//               border: const OutlineInputBorder(),
//             ),
//           ),
//         ),
//         items: _items,
//         dropdownDecoratorProps: DropDownDecoratorProps(
//           dropdownSearchDecoration: InputDecoration(
//             hintText: widget.hintText,
//             border: const OutlineInputBorder(),
//           ),
//         ),
//         onChanged: widget.onChanged,
//         itemAsString: widget.itemAsString,
//       ),
//     );
//   }
// }
