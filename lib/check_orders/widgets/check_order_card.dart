import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../models/check_order_model.dart';
import '../provider/check_orders_provider.dart';

class CheckOrderCard extends StatelessWidget {
  final String orderId;
  final List<Item> items;
  final List<OrderPic> orderPics;
  final String pickListId;

  const CheckOrderCard({
    super.key,
    required this.orderId,
    required this.items,
    required this.orderPics,
    required this.pickListId,
  });

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Make header responsive based on screen size
            isSmallScreen
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoColumn('Order ID', orderId)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoColumn('Picklist ID', pickListId)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(context, 'Reject', Colors.red, false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(context, 'Accept', Colors.green, true),
                    ),
                  ],
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _buildInfoColumn('Order ID', orderId),
                      const SizedBox(width: 24),
                      _buildInfoColumn('Picklist ID', pickListId),
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
            GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.4 : 1.0,
              ),
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildItemRow(context, items[index], isSmallScreen),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(context, 'Reject', Colors.red, false),
                const SizedBox(width: 8),
                _buildActionButton(context, 'Accept', Colors.green, true),
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

  Widget _buildItemRow(BuildContext context, Item item, bool isSmallScreen) {
    final matchingOrderPic = orderPics.firstWhere(
          (pic) => pic.itemSku == item.sku,
      orElse: () => OrderPic(itemSku: item.sku, image1: '', image2: ''),
    );
    final allImages = [
      if (item.shopifyImage.isNotEmpty) item.shopifyImage,
      if (matchingOrderPic.image1.isNotEmpty) matchingOrderPic.image1,
      if (matchingOrderPic.image2.isNotEmpty) matchingOrderPic.image2,
    ];

    // Calculate image sizes based on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final mainImageSize = isSmallScreen ? (screenWidth - 64) : 360.0;
    final secondaryImageSize = isSmallScreen ? (screenWidth - 64) / 2 : 180.0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'SKU: ${item.sku}',
          //   style: const TextStyle(fontSize: 16, color: Colors.grey),
          //   overflow: TextOverflow.ellipsis,
          // ),
          Utils.richText('SKU: ', item.sku),
          const SizedBox(height: 12),
          // Make image layout responsive
          isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: allImages.isNotEmpty ? () => _showImageGallery(context, allImages, 0) : null,
                child: _buildImage(item.shopifyImage, mainImageSize, mainImageSize),
              ),
              const SizedBox(height: 8),
              if (allImages.length > 1)
                Row(
                  children: [
                    if (matchingOrderPic.image1.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () => _showImageGallery(context, allImages, 1),
                            child: _buildImage(matchingOrderPic.image1, secondaryImageSize, secondaryImageSize),
                          ),
                        ),
                      ),
                    if (matchingOrderPic.image2.isNotEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () => _showImageGallery(context, allImages, allImages.length > 2 ? 2 : 1),
                            child: _buildImage(matchingOrderPic.image2, secondaryImageSize, secondaryImageSize),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: allImages.isNotEmpty ? () => _showImageGallery(context, allImages, 0) : null,
                child: _buildImage(item.shopifyImage, mainImageSize, mainImageSize),
              ),
              const SizedBox(width: 16),
              if (allImages.length > 1)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (matchingOrderPic.image1.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _showImageGallery(context, allImages, 1),
                          child: _buildImage(matchingOrderPic.image1, secondaryImageSize, secondaryImageSize),
                        ),
                      ),
                    if (matchingOrderPic.image2.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImageGallery(context, allImages, allImages.length > 2 ? 2 : 1),
                        child: _buildImage(matchingOrderPic.image2, secondaryImageSize, secondaryImageSize),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isNotEmpty
          ? Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorImage(width, height),
      )
          : Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _errorImage(double width, double height) => Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image, size: 40, color: Colors.red),
  );

  Widget _buildActionButton(BuildContext context, String label, Color color, bool status) {
    return ElevatedButton(
      onPressed: () => _showConfirmDialog(context, label, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
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
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(child: Text('Processing...')),
                    ],
                  ),
                ),
              );
              final provider = Provider.of<CheckOrdersProvider>(context, listen: false);
              final res = await provider.updateCheckStatus(
                orderId: orderId,
                pickListId: pickListId,
                check: checkStatus,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res ? 'Order ${action}ed successfully' : 'Failed to $action order')),
              );
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