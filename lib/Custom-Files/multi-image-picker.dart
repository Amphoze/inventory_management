import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_management/Api/products-provider.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:provider/provider.dart';

class CustomPicker extends StatefulWidget {
  const CustomPicker({super.key});

  @override
  State<CustomPicker> createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker> {
  final List<File> _images = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
      if (pickedFiles.isNotEmpty) {
        final newImages = pickedFiles.map((e) => File(e.path)).toList();
        setState(() => _images.addAll(newImages));
        await Provider.of<ProductProvider>(context, listen: false).setImage(_images);
      }
    } catch (e) {
      if (kDebugMode) print('Error picking images: $e');
      if (mounted) {
       Utils.showSnackBar(context, 'Failed to pick images. Please try again.', isError: true);
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
    Provider.of<ProductProvider>(context, listen: false).setImage(_images);
  }

  void _showImageDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            kIsWeb ? Image.network(_images[index].path) : Image.file(_images[index]),
            Positioned(right: 8, top: 8, child: IconButton(icon: const Icon(Icons.close), color: Colors.white, onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_images.isEmpty)
              _buildEmptyState(context)
            else ...[
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildImageGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, width: 2), borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
      child: InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text('Click to select images', style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Supported formats: JPG, PNG', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Images (${_images.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Drag to reorder • Click × to remove', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate, size: 20),
          label: const Text('Add More'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), elevation: 2),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: GridView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemCount: _images.length,
        itemBuilder: (context, index) => Stack(
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
              clipBehavior: Clip.antiAlias,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Stack(
                  children: [
                    kIsWeb ? Image.network(_images[index].path, fit: BoxFit.cover, width: double.infinity, height: double.infinity) : Image.file(_images[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () => _showImageDialog(index)))),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _removeImage(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}