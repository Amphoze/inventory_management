import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../models/recheck_order_model.dart';
import '../provider/check_orders_provider.dart';

class RecheckOrderCard extends StatelessWidget {
  final RecheckOrderModel order;

  const RecheckOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _buildInfoColumn('Order ID', order.orderId),
                      const SizedBox(width: 24),
                      _buildInfoColumn('Packlist ID', order.packListId),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(context, 'Reject', Colors.red, false),
                      const SizedBox(width: 8),
                      _buildActionButton(context, 'Accept', Colors.green, true),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildPackedBySection()),
                // const SizedBox(width: 16),
                // Expanded(
                //   child: _buildStatusSection(),
                // ),
                const Spacer(),
                if (order.orderPics.isNotEmpty) ...[
                  // const SizedBox(height: 12),
                  Expanded(child: _buildImagesSection(context)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPackedBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Utils.richText('Packed By: ', '${order.packedBy.name} (${order.packedBy.email})'),
        const SizedBox(height: 4),
        Utils.richText('Contact: ', order.packedBy.contact.toString()),
        const SizedBox(height: 4),
        Utils.richText('Is Checked: ', order.isChecked ? 'Yes' : 'No'),
        const SizedBox(height: 4),
        Utils.richText('ReChecked: ', order.reChecked ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    final allImages = order.orderPics.expand((pic) => [pic.image1, pic.image2]).where((url) => url.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Images:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80, // Increased height for better visibility
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allImages.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _showImageGallery(context, allImages, index),
                child: _buildImage(allImages[index], 80),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _errorImage(size),
            )
          : Container(
              width: size,
              height: size,
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
            ),
    );
  }

  Widget _errorImage(double size) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 20, color: Colors.red),
      );

  // Widget _buildStatusSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text('Is Checked: ${order.isChecked ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 12)),
  //       const SizedBox(height: 4),
  //       Text('ReChecked: ${order.reChecked ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
  //     ],
  //   );
  // }

  Widget _buildActionButton(BuildContext context, String label, Color color, bool status) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _showConfirmDialog(context, label, status),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          textStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }

  void _showImageGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageGalleryScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String action, bool checkStatus) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm $action', style: const TextStyle(fontSize: 16)),
        content: Text('Are you sure you want to $action this order?', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(
                  content: Row(
                    children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Processing...')],
                  ),
                ),
              );
              try {
                final provider = Provider.of<CheckOrdersProvider>(context, listen: false);
                await provider.updateCheckStatus(
                  orderId: order.orderId,
                  pickListId: order.packListId,
                  check: checkStatus,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order ${action}ed successfully')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to $action order: $e')),
                );
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryScreen({required this.images, required this.initialIndex});

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(widget.images[_currentIndex]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            errorBuilder: (_, __, ___) => const Center(
              child: Text('Failed to load image', style: TextStyle(color: Colors.white)),
            ),
          ),
          if (widget.images.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_left, color: Colors.white, size: 32),
                  onPressed: () => setState(() => _currentIndex--),
                ),
              ),
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_right, color: Colors.white, size: 32),
                  onPressed: () => setState(() => _currentIndex++),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
