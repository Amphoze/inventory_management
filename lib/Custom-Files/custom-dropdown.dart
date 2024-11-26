import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:provider/provider.dart';

class CustomDropdown extends StatefulWidget {
  final double fontSize;
  int selectedIndex;

  final List<Map<String, dynamic>> option;
  final String? Function(String?)? validator;
  final bool isboxSize;
  final bool label;
  final bool grade;
  final bool isBrand;
  ValueChanged<int>? onSelectedChanged;

  CustomDropdown({
    super.key,
    this.validator,
    this.fontSize = 17,
    this.option = const [],
    this.isboxSize = false,
    this.label = false,
    this.selectedIndex = 0,
    this.onSelectedChanged,
    this.grade = false,
    this.isBrand = false,
  });

  @override
  State<CustomDropdown> createState() => CustomDropdownState();
}

class CustomDropdownState extends State<CustomDropdown> {
  String? _selectedItem = 'Select option';
  bool isLoading = false;
  final List<String> _items = ['Select option'];
  TextEditingController searchController = TextEditingController();

  void updateData() {
    // _items.clear();
    if (widget.label) {
      for (int i = 0; i < widget.option.length; i++) {
        _items.add(widget.option[i]['labelSku']);
      }
    } else if (widget.isboxSize) {
      for (int i = 0; i < widget.option.length; i++) {
        _items.add('${widget.option[i]['box_name']}');
      }
    } else if (widget.grade) {
      _items.addAll(['A', 'B', 'C', 'D']);
    } else {
      for (int i = 0; i < widget.option.length; i++) {
        _items.add('${widget.option[i]['name']}');
      }
    }
    _selectedItem = _items[widget.selectedIndex];
    setState(() {});
  }

  void reset() {
    _selectedItem = _items[0];
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    updateData();
  }

  void searchData(String brandName) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';

    final token = await AuthProvider().getToken();
    final url = Uri.parse('$baseUrl/category?name=$brandName');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    var reslt = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("here dipu with reslut ${reslt['categories']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        alignment: Alignment.topCenter,
        // padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // errorStyle:'',
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: DropdownSearch<String>(
          items: _items,
          selectedItem: _selectedItem,
          // filterFn: (s, d) {
          //   isLoading = true;
          //   setState(() {});
          //   searchData(d);
          //   return true;
          // },
          popupProps: PopupProps.menu(
            fit: FlexFit.tight,
            showSelectedItems: true,
            showSearchBox: true,
            loadingBuilder: ((context, searchEntry) {
              print("hete is loading bilder");
              return const Text('data');
            }),

            menuProps: const MenuProps(
              elevation: 10,
            ),
            searchFieldProps: TextFieldProps(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search for an option",
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                ),
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxHeight: 30),
                isDense: true,
                filled: true,
                label: Text('Search'),
                contentPadding: EdgeInsets.all(0),
              ),
            ),
            // scrollbarOrientation:ScrollEndNotification
            //       // notificationPredicate:(b){
            //       //   print("b is ssssss $b");
            //       //   return true;
            //       // }
            scrollbarProps: ScrollbarProps(
              notificationPredicate: (a) {
                print(
                    "heelo i am dipu pix ${a.metrics.pixels}  max ${a.metrics.maxScrollExtent}  nn${a.metrics.devicePixelRatio}");
                return true;
              },
            ),
            listViewProps: const ListViewProps(),
          ),
          onChanged: (String? newValue) {
            widget.selectedIndex =
                _items.indexWhere((element) => element == newValue);
            if (widget.onSelectedChanged != null) {
              widget.onSelectedChanged!(widget.selectedIndex);
            }
            if (widget.grade) {
              Provider.of<ProductProvider>(context, listen: false)
                  .grade(newValue!);
            }
            setState(() {
              _selectedItem = newValue;
            });
          },
        ),
      ),
    );
  }
}

class SimpleDropDown extends StatefulWidget {
  const SimpleDropDown({super.key});

  @override
  State<SimpleDropDown> createState() => _SimpleDropDownState();
}

class _SimpleDropDownState extends State<SimpleDropDown> {
  // DropdownMenuItem<String> vale='Hwlo';
  List<String> ans = ['option 0', 'option 1'];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: DropdownButton(
        value: 'option 0',
        items: ans.map((e) => DropdownMenuItem(child: Text(e))).toList(),
        onChanged: (val) {},
      ),
    );
  }
}

class DropDownWithRow extends StatefulWidget {
  const DropDownWithRow({super.key});

  @override
  State<DropDownWithRow> createState() => _DropDownWithRowState();
}

class _DropDownWithRowState extends State<DropDownWithRow> {
  // DropdownMenuItem<String> vale='Hwlo';
  List<String> ans = ['option 0', 'option 1'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: DropdownButton(
        value: 'option 0',
        items: ans.map((e) => DropdownMenuItem(child: Text(e))).toList(),
        onChanged: (val) {},
      ),
    );
  }
}

class CustomDropdownMultiple extends StatefulWidget {
  final double fontSize;
  int selectedIndex;

  final List<Map<String, dynamic>> option;
  final String? Function(String?)? validator;
  final bool isboxSize;
  final bool label;
  final bool grade;
  ValueChanged<int>? onSelectedChanged;

  CustomDropdownMultiple(
      {super.key,
      this.validator,
      this.fontSize = 17,
      this.option = const [],
      this.isboxSize = false,
      this.label = false,
      this.selectedIndex = 0,
      this.onSelectedChanged,
      this.grade = false});

  @override
  State<CustomDropdownMultiple> createState() => _CustomDropdownMultipleState();
}

class _CustomDropdownMultipleState extends State<CustomDropdownMultiple> {
  String? _selectedItem = 'Select option';
  final List<String> _items = ['Select option'];
  TextEditingController searchController = TextEditingController();
  void updateData() {
    // _items.clear();
    if (widget.label) {
      for (int i = 0; i < widget.option.length; i++) {
        _items.add(widget.option[i]['labelSku']);
      }
    } else if (widget.isboxSize) {
      for (int i = 0; i < widget.option.length; i++) {
        _items.add('${widget.option[i]['box_name']}');
      }
    } else if (widget.grade) {
      _items.addAll(['A', 'B', 'C', 'D']);
    } else {
      for (int i = 0; i < widget.option.length; i++) {
        _items.add('${widget.option[i]['name']}');
      }
    }
    _selectedItem = _items[widget.selectedIndex];
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    updateData();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        alignment: Alignment.topCenter,
        // padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // errorStyle:'',
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade100,
        ),
        child: DropdownSearch<String>.multiSelection(
            items: _items,
            // selectedItem: _selectedItem,
            // enabled:false,
            popupProps: PopupPropsMultiSelection.menu(
              fit: FlexFit.tight,
              showSelectedItems: true,
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                controller: searchController,
                // cursorHeight:3,
                decoration: const InputDecoration(
                  hintText: "Search for an option",
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                  ),
                  border: OutlineInputBorder(),
                  constraints: BoxConstraints(maxHeight: 30),
                  isDense: true,
                  filled: true,
                  label: Text('Search'),
                  contentPadding: EdgeInsets.all(0),
                ),
              ),
            )
            // //  itemBuilder: (context, item, isSelected)=>ListTile(
            // //       title: Text(item),
            // //       selected: isSelected,
            // //     ),
            //     scrollbarProps:ScrollbarProps(
            //       // scrollbarOrientation:ScrollEndNotification
            //       // notificationPredicate:(b){
            //       //   print("b is ssssss $b");
            //       //   return true;
            //       // }
            //     ),
            //   ),
            // onChanged: (String? newValue) {
            //     // _items.fin;
            //    widget.selectedIndex= _items.indexWhere((element) => element == newValue);
            //    if(widget.onSelectedChanged!=null){
            //     widget.onSelectedChanged!( widget.selectedIndex );
            //    }
            //    if(widget.grade){
            //     Provider.of<ProductProvider>(context,listen:false).grade(newValue!);
            //    }
            //   setState(() {
            //     _selectedItem = newValue;

            //   }
            //   );
            // },
            ),
      ),
    );
  }
}

class LazyLoadingDropdown extends StatefulWidget {
  const LazyLoadingDropdown({super.key});

  @override
  _LazyLoadingDropdownState createState() => _LazyLoadingDropdownState();
}

class _LazyLoadingDropdownState extends State<LazyLoadingDropdown> {
  List<String> items = [];
  String? selectedItem;
  bool isLoading = false;
  int page = 0;
  final int pageSize = 20;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData([String query = '']) async {
    setState(() {
      isLoading = true;
    });

    // Simulate an API call for data fetching (replace this with actual API logic)
    await Future.delayed(const Duration(seconds: 1), () {
      List<String> newItems = List.generate(
          pageSize, (index) => 'Item ${(page * pageSize) + index} $query');
      setState(() {
        items.addAll(newItems);
        isLoading = false;
        page++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lazy Loading Dropdown"),
      ),
      body: Column(
        children: [
          // TextField for search functionality
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                // Clear the current list and reset the page count for new search
                items.clear();
                page = 0;
                fetchData(value); // Fetch data based on search query
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Dropdown button to show selected item
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedItem,
              hint: const Text("Select an item"),
              onChanged: (newValue) {
                setState(() {
                  selectedItem = newValue;
                });
              },
              isExpanded: true,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Lazy-loading ListView with ListView.builder
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  fetchData(searchController.text); // Load more items
                  return true;
                }
                return false;
              },
              child: ListView.builder(
                itemCount: items.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    ); // Show loader at the end when fetching more data
                  }
                  return ListTile(
                    title: Text(items[index]),
                    onTap: () {
                      setState(() {
                        selectedItem = items[index]; // Set selected item
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
