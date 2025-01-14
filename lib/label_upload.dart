import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/excelFileUpload.dart';
import 'package:inventory_management/provider/label_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Api/auth_provider.dart';
// Import the html library

class LabelUpload extends StatefulWidget {
  const LabelUpload({super.key});

  @override
  State<LabelUpload> createState() => _LabelUploadState();
}

class _LabelUploadState extends State<LabelUpload> {
  Future<void> _uploadLabels(BuildContext context) async {
    final authProvider = AuthProvider();
    final labelDataProvider =
        Provider.of<LabelDataProvider>(context, listen: false);

    if (labelDataProvider.labelDataGroups.isEmpty) {
      _showMessage(context, 'No data available to upload.', isError: true);
      return;
    }

    labelDataProvider.setUploading(true);
    int successCount = 0;
    List<String> errorMessages = [];

    for (var labelData in labelDataProvider.labelDataGroups) {
      Map<String, dynamic> labelApiData = {
        'name': labelData['name'] ?? '',
        'labelSku': labelData['labelSku'] ?? '',
        'quantity': labelData['quantity'] ?? '',
        'description': labelData['description'] ?? '',
      };

      print('Uploading Label: $labelApiData');

      String? result = await authProvider.createLabel(labelApiData);

      if (result!.contains('successfully')) {
        successCount++;
        print('Upload Success: $result');
        print('------------------------------');
      } else {
        errorMessages.add(result ?? 'Unknown error');
        print('Upload Failed: $result');
        print('------------------------------');
      }
    }

    labelDataProvider.setUploading(false);

    // Log final result summary
    print('$successCount labels uploaded successfully.');
    print('------------------------------');

    if (successCount > 0) {
      labelDataProvider.reset();
      _showMessage(context, '$successCount labels uploaded successfully!');
    }

    if (errorMessages.isNotEmpty) {
      _showMessage(context, errorMessages.join('\n'), isError: true);
    }
  }

  void _showMessage(BuildContext context, String message,
      {bool isError = false, bool isCancelled = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isCancelled
            ? Colors.orange
            : (isError ? AppColors.cardsred : AppColors.primaryGreen),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Do not change or close this tab."),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelDataProvider = Provider.of<LabelDataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTextSize =
        screenWidth > 1200 ? 16.0 : (screenWidth > 800 ? 15.0 : 14.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (labelDataProvider.isLoadingDataGroups) {
        _showLoadingDialog(context);
      } else {
        // Close the dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcelFileUploader(
                  sheetName: 'Sheet1',
                  onUploadSuccess: labelDataProvider.setDataGroups,
                  onError: (errorMessage) =>
                      _showMessage(context, errorMessage, isError: true),
                ),
                if (labelDataProvider.isUploadSuccessful) ...[
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    ),
                    onPressed: labelDataProvider.isUploading
                        ? null
                        : () => _uploadLabels(context),
                    child: const Text('Upload Labels'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      labelDataProvider.reset();
                      _showMessage(context, 'Upload cancelled.',
                          isCancelled: true);
                    },
                  ),
                ],
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () =>
                      AuthProvider().downloadTemplate(context, 'label'),
                  child: const Text('Download Template'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: labelDataProvider.labelDataGroups.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available.',
                        style: TextStyle(fontSize: 18.0, color: AppColors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: labelDataProvider.labelDataGroups.length,
                      itemBuilder: (context, index) {
                        final dataMap =
                            labelDataProvider.labelDataGroups[index];
                        return _buildListItem(context, dataMap, baseTextSize);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, Map<String, String> dataMap, double baseTextSize) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blueAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: _buildRowContent(dataMap, baseTextSize),
      ),
    );
  }

  Widget _buildRowContent(Map<String, String> dataMap, double baseTextSize) {
    final fieldsToShow = dataMap.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final imageWidget = SizedBox(
          width: isSmallScreen ? 120 : 150,
          height: isSmallScreen ? 120 : 150,
          child: dataMap['image'] != null && dataMap['image']!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    dataMap['image']!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  Icons.image,
                  size: 100,
                  color: AppColors.grey,
                ),
        );

        final textFields = fieldsToShow.map((field) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: RichText(
              text: TextSpan(
                text: '$field: ',
                style: TextStyle(
                  fontSize: baseTextSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                children: [
                  TextSpan(
                    text: dataMap[field] ?? 'N/A',
                    style: TextStyle(
                      fontSize: baseTextSize,
                      fontWeight: FontWeight.normal,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();

        return isSmallScreen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageWidget,
                  const SizedBox(height: 8.0),
                  ...textFields,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageWidget,
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: textFields,
                    ),
                  ),
                ],
              );
      },
    );
  }
}
