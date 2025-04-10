import 'dart:convert';
import 'dart:developer';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_management/Api/label-api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Custom-Files/custom_pagination.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/combo_provider.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Api/lable-page-api.dart';
import 'package:http/http.dart' as http;

import 'Custom-Files/utils.dart';

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
bool showLabelForm = false;

class ShowLabelPage extends StatefulWidget {
  const ShowLabelPage({super.key});

  @override
  State<ShowLabelPage> createState() => _ShowLabelPageState();
}

class _ShowLabelPageState extends State<ShowLabelPage> {
  LabelPageApi? labelPageProvider;
  final GlobalKey<DropdownSearchState<String>> _dropdownKey = GlobalKey<DropdownSearchState<String>>();

  void _toggleFormVisibility() {
    setState(() {
      showLabelForm = !showLabelForm;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComboProvider>(context, listen: false).fetchProducts();
    });

    getData();
    getDataProduct();

    super.initState();
  }

  TextEditingController searchController = TextEditingController();

  Future<void> getData() async {
    LabelApi po = Provider.of<LabelApi>(context, listen: false);
    labelPageProvider = Provider.of<LabelPageApi>(context, listen: false);
    await labelPageProvider!.getProductDetails();
    await po.getLabel();
  }

  void getDataProduct() async {
    await labelPageProvider!.getProductDetails();
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) async {
    List<dynamic> labelLogs = data['labelLog'] ?? [];

    log('labelLogs: $labelLogs');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Updated Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['name']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.grey[100],
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300], thickness: 1.5),
                const SizedBox(height: 16),
                Expanded(
                  child: labelLogs.isNotEmpty
                      ? ListView.builder(
                          itemCount: labelLogs.length,
                          itemBuilder: (context, index) {
                            final log = labelLogs[index];
                            final (icon, iconColor) = _getIconProperties(log['changeType']);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      iconColor.withValues(alpha: 0.05),
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: iconColor.withValues(alpha: 0.15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: iconColor.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        icon,
                                        color: iconColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildEnhancedDetailRow(
                                            'Quantity Changed',
                                            '${log['quantityChanged']}',
                                            Colors.black87,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Previous Quantity',
                                            '${log['previousQuantity']}',
                                            Colors.grey[600]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'New Quantity',
                                            '${log['newQuantity']}',
                                            Colors.blue[700]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Updated By',
                                            '${log['updatedBy']}',
                                            Colors.grey[700]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Source',
                                            '${log['source']}',
                                            Colors.grey[600]!,
                                          ),
                                          _buildEnhancedDetailRow(
                                            'Timestamp',
                                            '${log['timestamp']}',
                                            Colors.grey[500]!,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No label logs available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  (IconData, Color) _getIconProperties(String changeType) {
    switch (changeType) {
      case 'Addition':
        return (Icons.add_circle_outline, Colors.green);
      case 'Subtraction':
        return (Icons.remove_circle_outline, Colors.red);
      default:
        return (Icons.info_outline, Colors.blue);
    }
  }

  Widget _buildEnhancedDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatProductSkus(List<dynamic> products) {
    if (products.isEmpty) return '';
    return products.map((product) {
      if (product['sku']?.toString().isNotEmpty ?? false) {
        return product['sku']?.toString() ?? '';
      }
    }).join(', ');
  }

  void _showUpdateQuantityDialog(BuildContext context, Map<String, dynamic> data) {
    TextEditingController quantityController = TextEditingController();
    TextEditingController reasonController = TextEditingController();

    quantityController.text = data['quantity'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'New Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(
              width: 5,
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                Navigator.of(context).pop();

                String newQuantity = quantityController.text.trim();
                String reason = reasonController.text.trim();

                int? parsedQuantity = int.tryParse(newQuantity);
                if (parsedQuantity == null) {
                  print('Invalid quantity entered');
                  return;
                }

                final labelProvider = Provider.of<LabelApi>(context, listen: false);

                await labelProvider.updateLabelQuantity(
                  data['_id'],
                  parsedQuantity,
                  reason,
                );

                data['quantity'] = parsedQuantity;

                log('Updated quantity for ${data['name']}: $newQuantity');
                if (reason.isNotEmpty) {
                  log('Reason: $reason');
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  final ScrollController scrollController = ScrollController();

  final TextEditingController _pageController = TextEditingController();

  void _goToPage(int page) {
    final provider = Provider.of<LabelApi>(context, listen: false);
    if (page >= 1 && page <= provider.totalPage) {
      provider.goToPage(page);
    }
  }

  void _jumpToPage() {
    final provider = Provider.of<LabelApi>(context, listen: false);
    int page = int.tryParse(_pageController.text) ?? 1;
    if (page >= 1 && page <= provider.totalPage) {
      _goToPage(page - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = ['IMAGE', 'Label SKU', 'Name', 'Quantity', 'Product SKU'];
    return Consumer<LabelApi>(
      builder: (context, l, child) => Scaffold(
        backgroundColor: Colors.white,
        body: l.labelInformation.isNotEmpty && l.loading == false
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      children: [
                        if (!showLabelForm) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: SizedBox(
                                width: 300,
                                height: 35,
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                    border: const OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryBlue,
                                        width: 2.0,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                  ),
                                  onSubmitted: l.onSearchChanged,
                                  onChanged: l.onSearchChanged,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh',
                            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                            onPressed: () async {
                              await getData();
                            },
                          ),
                        ],
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            _toggleFormVisibility();
                          },
                          child: Text(
                            showLabelForm ? 'Back' : 'Create Label',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!showLabelForm)
                          ElevatedButton(
                            onPressed: downloadCsv,
                            child: isDownloadingCsv
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Download Label CSV'),
                          ),
                      ],
                    ),
                  ),
                  if (showLabelForm)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2, left: 16),
                              child: Text("Create Label", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              child: SizedBox(
                                width: 620,
                                child:
                                    SingleChildScrollView(child: LabelFormFields(labelPageProvider: labelPageProvider)),
                              ),
                            ),
                            const SizedBox(height: 7),
                            LabelButtons(
                              labelPageProvider: labelPageProvider,
                              dropdownKey: _dropdownKey,
                            ),
                            const SizedBox(
                              height: 62,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!showLabelForm) ...[
                    if (searchController.text.isEmpty && l.labelInformation.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "hit reload",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: scrollController,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.resolveWith(
                              (states) => Colors.blue.withValues(alpha: 0.2),
                            ),
                            columns: columns.map((name) {
                              return DataColumn(
                                label: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              );
                            }).toList(),
                            rows: l.labelInformation.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Image.network(
                                      (item['images']?.isNotEmpty ?? false) ? item['images'][0] : "",
                                      width: 50,
                                      height: 50,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 40,
                                        );
                                      },
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  DataCell(Text(item['labelSku']?.toString() ?? 'N/A')),
                                  DataCell(Text(item['name']?.toString() ?? 'N/A')),
                                  DataCell(
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['quantity']?.toString() ?? '0',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 16),
                                                onPressed: () {
                                                  _showUpdateQuantityDialog(context, item);
                                                },
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () => _showDetailsDialog(context, item),
                                            child: const Text(
                                              'View Details',
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatProductSkus(item['products'] ?? []))),
                                ],
                              );
                            }).toList(),
                            headingRowHeight: 80,
                            dataRowHeight: 100,
                            columnSpacing: 55,
                            horizontalMargin: 16,
                            dataTextStyle: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    CustomPaginationFooter(
                      currentPage: l.currentPage,
                      totalPages: l.totalPage,
                      totalCount: l.totalLabels,
                      buttonSize: MediaQuery.of(context).size.width > 600 ? 32 : 24,
                      pageController: _pageController,
                      onFirstPage: () => _goToPage(1),
                      onLastPage: () => _goToPage(l.totalPage),
                      onNextPage: () {
                        if (l.currentPage - 1 < l.totalPage) {
                          _goToPage(l.currentPage + 1);
                        }
                      },
                      onPreviousPage: () {
                        if (l.currentPage > 1) {
                          _goToPage(l.currentPage - 1);
                        }
                      },
                      onGoToPage: _goToPage,
                      onJumpToPage: _jumpToPage,
                    ),
                  ],
                ],
              )
            : const Center(child: LoadingLabelAnimation()),
      ),
    );
  }

  Widget fieldTitle(String filTitle, String value,
      {bool show = true, double width = 133, var fontWeight = FontWeight.bold}) {
    return Container(
      alignment: Alignment.topRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width,
            child: Align(
                alignment: Alignment.topLeft,
                child: Text(filTitle, style: GoogleFonts.daiBannaSil(fontSize: 20, fontWeight: fontWeight))),
          ),
          const Text(":", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'googlefont')),
          show
              ? Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.daiBannaSil(fontSize: 20, fontWeight: FontWeight.normal),
                  ),
                )
              : const Text('  '),
        ],
      ),
    );
  }

  bool isDownloadingCsv = false;
  Future<void> downloadCsv() async {
    setState(() {
      isDownloadingCsv = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      String baseUrl = await Constants.getBaseUrl();

      if (token == null || token.isEmpty) {
        throw Exception('Authorization token is missing or invalid.');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/label/download'),
        headers: headers,
      );

      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        log("jsonBody: $jsonBody");

        final downloadUrl = jsonBody['downloadUrl'];

        if (downloadUrl != null) {
          final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
          if (canLaunch) {
            await launchUrl(Uri.parse(downloadUrl));

            Utils.showSnackBar(context, 'CSV download started successfully');
          } else {
            throw 'Could not launch $downloadUrl';
          }
        } else {
          throw Exception('No download URL found');
        }
      } else {
        throw Exception('Failed to load CSV: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      log('error: $error');
      log('Error during report generation: $error');

      Utils.showSnackBar(context, 'Error downloading CSV', details: error.toString(), isError: true);
    } finally {
      setState(() {
        isDownloadingCsv = false;
      });
    }
  }
}

class LoadingLabelAnimation extends StatefulWidget {
  const LoadingLabelAnimation({super.key});

  @override
  _LoadingLabelAnimationState createState() => _LoadingLabelAnimationState();
}

class _LoadingLabelAnimationState extends State<LoadingLabelAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: Colors.blue,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.label_important,
            color: _colorAnimation.value,
            size: 80,
          ),
        );
      },
    );
  }
}

class LabelFormFields extends StatefulWidget {
  final LabelPageApi? labelPageProvider;

  const LabelFormFields({super.key, this.labelPageProvider});

  @override
  State<LabelFormFields> createState() => _LabelFormFieldsState();
}

class _LabelFormFieldsState extends State<LabelFormFields> {
  final bool _autoValidateMode = false;

  String? _requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidateMode ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: Column(
        children: [
          _buildFormSection(
            'Basic Information',
            [
              _buildCardTextField(
                controller: widget.labelPageProvider!.nameController,
                label: "Name",
                validator: (value) => _requiredFieldValidator(value, 'a name'),
                prefixIcon: const Icon(Icons.label),
                required: true,
              ),
              _buildCardTextField(
                controller: widget.labelPageProvider!.labelSkuController,
                label: "Label SKU",
                validator: (value) => _requiredFieldValidator(value, 'an SKU'),
                prefixIcon: const Icon(Icons.qr_code),
                required: true,
              ),
            ],
          ),
          _buildFormSection(
            'Additional Details',
            [
              _buildCardTextField(
                  controller: widget.labelPageProvider!.descriptionController,
                  label: "Description",
                  validator: (value) => _requiredFieldValidator(value, 'a Description'),
                  prefixIcon: const Icon(Icons.description),
                  maxLines: 3,
                  required: true),
              _buildCardTextField(
                  controller: widget.labelPageProvider!.quantityController,
                  label: "Quantity",
                  validator: (value) => _requiredFieldValidator(value, 'a Quantity'),
                  prefixIcon: const Icon(Icons.numbers),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  required: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Icon? prefixIcon,
    bool required = false,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: SizedBox(
          width: 600,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            maxLines: maxLines ?? 1,
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: prefixIcon,
              contentPadding: const EdgeInsets.all(16.0),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LabelButtons extends StatefulWidget {
  final LabelPageApi? labelPageProvider;
  final LabelApi? l;
  final GlobalKey<DropdownSearchState<String>> dropdownKey;

  const LabelButtons({
    super.key,
    this.labelPageProvider,
    required this.dropdownKey,
    this.l,
  });

  @override
  State<LabelButtons> createState() => _LabelButtonsState();
}

class _LabelButtonsState extends State<LabelButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 16),
        _buildRoundedButton("Reset", Colors.grey, () {
          widget.labelPageProvider!.clearControllers(widget.dropdownKey);
        }),
        const SizedBox(width: 16),
        _buildRoundedButton("Save", Colors.blueAccent, () => _saveLabel(context), loader: true),
      ],
    );
  }

  Widget _buildRoundedButton(String text, Color color, VoidCallback onPressed, {bool loader = false}) {
    return Consumer<LabelPageApi>(
      builder: (context, provider, child) {
        final isLoading = loader && provider.buttonTap;

        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            minimumSize: const Size(100, 45),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        );
      },
    );
  }

  Future<void> _saveLabel(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) {
      Utils.showSnackBar(context, 'Please fill in all required fields correctly', isError: true);
      return;
    }

    final labelProvider = context.read<LabelPageApi>();

    try {
      if (labelProvider.nameController.text.isEmpty || labelProvider.labelSkuController.text.isEmpty) {
        throw 'Name and SKU are required fields';
      }

      final res = await labelProvider.createLabel();

      if (res.isEmpty) {
        throw 'Failed to create label: Empty response';
      }

      if (res["res"] == "success") {
        setState(() {
          labelProvider.clearControllers(widget.dropdownKey);
          showLabelForm = false;
        });
        Utils.showSnackBar(context, 'Label created successfully', color: AppColors.cardsgreen);
      } else {
        throw res["res"] ?? 'Unknown error occurred';
      }
    } catch (e) {
      Utils.showSnackBar(context, 'Error creating label: ${e.toString()}', isError: true);
    }
  }
}
