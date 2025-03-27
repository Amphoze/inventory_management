import 'dart:convert';
import 'dart:developer';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;

import 'Custom-Files/colors.dart';

class UIConstants {
  static const double cardPadding = 20.0;
  static const double spacing = 24.0;
  static const BorderRadius defaultBorderRadius = BorderRadius.all(Radius.circular(12));
}

class MaterialPlanning extends StatefulWidget {
  const MaterialPlanning({super.key});

  @override
  _MaterialPlanningState createState() => _MaterialPlanningState();
}

class _MaterialPlanningState extends State<MaterialPlanning> with SingleTickerProviderStateMixin {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  String? selectedWarehouse;
  List<String> selectedMarketplaces = [];
  TextEditingController days = TextEditingController();

  bool isLoading = false;
  bool showPreview = false;
  List<dynamic> csvPreviewData = [];
  String statusMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void clearPlanningFilters() {
    setState(() {
      selectedMonth = DateTime.now().month;
      selectedYear = DateTime.now().year;
      selectedWarehouse = null;
      selectedMarketplaces.clear();
      days.clear();

      _formKey.currentState?.reset();

      showPreview = false;
      statusMessage = '';
    });
  }

  Future<void> _fetchPlanningData() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => statusMessage = "Please fill all required fields.");
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = '';
      showPreview = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");

    var payload = {
      "month": selectedMonth,
      "days": days.text.trim(),
      "year": selectedYear,
      "warehouse": selectedWarehouse,
      "marketplace": selectedMarketplaces,
    };

    log('Payload: $payload');

    try {
      var response = await http.post(
        Uri.parse("${await Constants.getBaseUrl()}/planning"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode(payload),
      );
      log('Response: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData["success"] == true && responseData["data"] != null) {
          setState(() {
            csvPreviewData = responseData["data"];
            showPreview = true;
          });
          _showPreviewDialog();
        } else {
          setState(() => statusMessage = "No data found for the selected filters.");
        }
      } else {
        setState(() => statusMessage = "Server error (${response.statusCode}). Please try later.");
      }
    } catch (e) {
      setState(() => statusMessage = "An error occurred: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _triggerDownload(String csvContent, String fileName) {
    final csvWithBom = '\uFEFF$csvContent';
    final bytes = Uint8List.fromList(utf8.encode(csvWithBom));
    final blob = web.Blob(
      [bytes] as JSArray<web.BlobPart>,
      web.BlobPropertyBag(type: 'text/csv'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..click();
    web.URL.revokeObjectURL(url);
  }

  void _downloadCsv() {
    if (csvPreviewData.isEmpty) return;

    List<List<String>> csvData = [
      ["SKU", "Total Quantity Sold", "Required", "Total Quantity In Warehouse"]
    ];
    for (var item in csvPreviewData) {
      csvData.add([
        item["sku"].toString(),
        item["totalQuantitySold"].toString(),
        item["required"].toString(),
        item["totalQuantityInWarehouse"].toString(),
      ]);
    }

    String csvString = csvData.map((e) => e.join(",")).join("\n");
    _triggerDownload(csvString, "planning_${selectedMonth}_${selectedYear}.csv");
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Material Planning Data Export",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue.withValues(alpha: 0.9), AppColors.primaryBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRow([
                  _buildSelectionCard(
                    title: "Choose Days",
                    child: _buildTextField(
                      controller: days,
                      label: 'Days',
                      keyboardType: TextInputType.number
                    ),
                  ),
                  _buildSelectionCard(
                    title: "Select Month",
                    child: _buildStyledDropdown<int>(
                      value: selectedMonth,
                      items: List.generate(12, (index) => index + 1),
                      itemBuilder: (item) => DateFormat.MMMM().format(DateTime(0, item)),
                      onChanged: (value) => setState(() => selectedMonth = value!),
                    ),
                  ),
                  _buildSelectionCard(
                    title: "Select Year",
                    child: _buildStyledDropdown<int>(
                      value: selectedYear,
                      items: List.generate(
                        currentYear - (currentYear - 5) + 1,
                        (index) => currentYear - 5 + index,
                      ),
                      itemBuilder: (item) => item.toString(),
                      onChanged: (value) => setState(() => selectedYear = value!),
                    ),
                  ),
                ]),
                const SizedBox(height: UIConstants.spacing),
                _buildRow([
                  _buildSelectionCard(
                    title: "Select Warehouse",
                    child: Consumer<LocationProvider>(
                      builder: (context, pro, child) => _buildStyledDropdown<String>(
                        value: selectedWarehouse,
                        items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                        itemBuilder: (item) => item,
                        onChanged: (value) => setState(() => selectedWarehouse = value),
                        validator: (value) => value == null ? 'Please select a warehouse' : null,
                      ),
                    ),
                  ),
                  _buildSelectionCard(
                    title: "Select Marketplace",
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.primaryBlue.withAlpha(120)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      child: MultiSelectDialogField(
                        items: Provider.of<MarketplaceProvider>(context, listen: false)
                            .marketplaces
                            .map((e) => MultiSelectItem(e.name, e.name))
                            .toList(),
                        title: const Text("Select Marketplace", style: TextStyle(color: AppColors.primaryBlue)),
                        buttonText: const Text("Choose Marketplaces", style: TextStyle(color: AppColors.primaryBlue)),
                        buttonIcon: const Icon(Icons.arrow_drop_down_outlined, color: AppColors.black),
                        initialValue: selectedMarketplaces,
                        onConfirm: (values) => setState(() => selectedMarketplaces = List.from(values)),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent),
                          color: Colors.white,
                        ),
                        chipDisplay: MultiSelectChipDisplay.none(),
                      ),
                    ),
                  )
                ]),
                if (selectedMarketplaces.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 100,
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      // decoration: BoxDecoration(
                      //   border: Border.all(color: Colors.grey.shade300),
                      //   borderRadius: BorderRadius.circular(6),
                      // ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selectedMarketplaces
                              .map((marketplace) => Chip(
                                    label: Text(
                                      marketplace,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.blueAccent,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: UIConstants.spacing),
                ElevatedButton(
                  onPressed: isLoading ? null : _fetchPlanningData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: UIConstants.defaultBorderRadius),
                    elevation: 6,
                    shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Start Planing",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: UIConstants.spacing),
                if (statusMessage.isNotEmpty)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: UIConstants.defaultBorderRadius,
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: UIConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    return DataTable(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      columns: const [
        DataColumn(label: Text("SKU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(label: Text("Total Sold", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(label: Text("Required", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(label: Text("In Warehouse", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
      ],
      rows: csvPreviewData
          .map((item) => DataRow(
                color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                  return states.contains(MaterialState.selected) ? Colors.blue.shade100 : null;
                }),
                cells: [
                  DataCell(Text(item["sku"].toString())),
                  DataCell(Text(item["totalQuantitySold"].toString())),
                  DataCell(Text(item["required"].toString())),
                  DataCell(Text(item["totalQuantityInWarehouse"].toString())),
                ],
              ))
          .toList(),
      border: TableBorder.all(color: Colors.black45, width: 1),
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.all(AppColors.primaryBlue),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children:
          children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: child))).toList(),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: UIConstants.defaultBorderRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: UIConstants.defaultBorderRadius,
          borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UIConstants.defaultBorderRadius,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(color: AppColors.primaryBlue),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(itemBuilder(item)))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Material Planning"),
        content: SingleChildScrollView(
            child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPreviewTable(),
              const SizedBox(height: 20),
            ],
          ),
        )),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: UIConstants.defaultBorderRadius),
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withOpacity(0.4),
            ),
            onPressed: () {
              _downloadCsv();

              clearPlanningFilters();

              Navigator.of(context).pop();
            },
            child: const Text(
              "Download CSV",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          SizedBox(
            width: 18,
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: UIConstants.defaultBorderRadius),
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withOpacity(0.4),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              "Closed",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          // TextButton(
          //   style: Bu,
          //   onPressed: () => Navigator.of(context).pop(),
          //   child: const Text("Close"),
          // ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isRequired = false,
    int maxLines = 1,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        inputFormatters: [if (keyboardType == TextInputType.number) FilteringTextInputFormatter.digitsOnly],
        // maxLength: label == 'Vendor Phone' ? 10 : null,
        decoration: InputDecoration(
          hintText: isRequired ? '$label *' : label,
          hintStyle: const TextStyle(color: AppColors.primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryBlue.withAlpha(120)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryBlue.withAlpha(120), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          // contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffix,
          errorStyle: TextStyle(color: Colors.red[700]),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
      ),
    );
  }
}
