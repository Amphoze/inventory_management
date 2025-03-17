import 'dart:convert';
import 'dart:developer';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/provider/marketplace_provider.dart';
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

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  _PlanningScreenState createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  String? selectedWarehouse;
  String? selectedMarketplace;
  bool isLoading = false;
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

  Future<void> _fetchPlanningData() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        statusMessage = "Please fill all required fields.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = '';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");

    var payload = {"month": selectedMonth, "year": selectedYear, "warehouse": selectedWarehouse};
    if (selectedMarketplace != null) payload["marketplace"] = selectedMarketplace;

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
        if (responseData["success"] == true) {
          if (responseData["data"] == null || (responseData['data'] as List).isEmpty) {
            setState(() => statusMessage = "No data found for the selected filters.");
            return;
          }
          _downloadCsv(responseData["data"]);
          setState(() => statusMessage = "CSV downloaded successfully!");
        } else {
          setState(() => statusMessage = "Something went wrong. Please try again.");
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

  void _downloadCsv(List<dynamic> data) {
    if (data.isEmpty) {
      setState(() => statusMessage = "No data available to download.");
      return;
    }

    List<List<String>> csvData = [
      ["SKU", "Total Quantity Sold", "Required", "Total Quantity In Warehouse"]
    ];
    for (var item in data) {
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

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year; // Get current year dynamically

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
              colors: [AppColors.primaryBlue.withOpacity(0.9), AppColors.primaryBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRow([
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
                        currentYear - (currentYear - 5) + 1, // Generate years from 5 years ago to current year
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
                    child: Consumer<MarketplaceProvider>(
                      builder: (context, pro, child) => _buildStyledDropdown<String>(
                        value: selectedMarketplace,
                        items: pro.marketplaces.map((e) => e.name).toList(),
                        itemBuilder: (item) => item,
                        onChanged: (value) => setState(() => selectedMarketplace = value),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: UIConstants.spacing),
                ElevatedButton(
                  onPressed: isLoading ? null : _fetchPlanningData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: UIConstants.defaultBorderRadius),
                    elevation: 6,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.4),
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
                      "Download CSV",
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
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: UIConstants.defaultBorderRadius,
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
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

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: child))).toList(),
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
          borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
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
}