import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryScreen({super.key, required this.images, required this.initialIndex});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late int _currentIndex;
  late PhotoViewController _controller;
  double _scale = 1.0;
  double _rotation = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PhotoViewController()
      ..outputStateStream.listen((PhotoViewControllerValue value) {
        setState(() {
          _scale = value.scale ?? 1.0; // Update _scale whenever it changes
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _scale = (_scale + 0.2).clamp(1.0, 5.0);
    _controller.scale = _scale;
  }

  void _zoomOut() {
    _scale = (_scale - 0.2).clamp(1.0, 5.0);
    _controller.scale = _scale;
  }

  void _rotateRight() {
    _rotation += 90.0;
    _controller.rotation = _rotation * (3.14159 / 180);
  }

  void _rotateLeft() {
    _rotation -= 90.0;
    _controller.rotation = _rotation * (3.14159 / 180);
  }

  void _reset() {
    _scale = 1.0;
    _rotation = 0.0;
    _controller
      ..scale = 1.0
      ..rotation = 0.0
      ..position = Offset.zero;
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
            controller: _controller,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 5,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            enableRotation: true,
            errorBuilder: (_, __, ___) => const Center(
              child: Text('Failed to load image', style: TextStyle(color: Colors.white)),
            ),
            onScaleEnd: (_, details, controllerValue) {
              _scale = controllerValue.scale ?? 1.0; // Backup update method
            },
            gestureDetectorBehavior: HitTestBehavior.opaque,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.images.length > 1)
                    FloatingActionButton(
                      heroTag: 'prev-image',
                      mini: true,
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: const CircleBorder(),
                      onPressed: _currentIndex > 0
                          ? () {
                        setState(() {
                          _currentIndex--;
                          _reset();
                        });
                      }
                          : null,
                      tooltip: 'Previous Image',
                      child: const Icon(Icons.arrow_left, size: 28),
                    ),
                  if (widget.images.length > 1) const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'rotate-left',
                    mini: true,
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    onPressed: _rotateLeft,
                    tooltip: 'Rotate Left',
                    child: const Icon(Icons.rotate_left, size: 24),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'rotate-right',
                    mini: true,
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    onPressed: _rotateRight,
                    tooltip: 'Rotate Right',
                    child: const Icon(Icons.rotate_right, size: 24),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'zoom-out',
                    mini: true,
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    onPressed: _scale > 1.0 ? _zoomOut : null,
                    tooltip: 'Zoom Out',
                    child: const Icon(Icons.zoom_out, size: 24),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'zoom-in',
                    mini: true,
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    onPressed: _scale < 5.0 ? _zoomIn : null,
                    tooltip: 'Zoom In',
                    child: const Icon(Icons.zoom_in, size: 24),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'reset',
                    mini: true,
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    onPressed: _reset,
                    tooltip: 'Reset View',
                    child: const Icon(Icons.refresh, size: 24),
                  ),
                  if (widget.images.length > 1) const SizedBox(width: 24),
                  if (widget.images.length > 1)
                    FloatingActionButton(
                      heroTag: 'next-image',
                      mini: true,
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: const CircleBorder(),
                      onPressed: _currentIndex < widget.images.length - 1
                          ? () {
                        setState(() {
                          _currentIndex++;
                          _reset();
                        });
                      }
                          : null,
                      tooltip: 'Next Image',
                      child: const Icon(Icons.arrow_right, size: 28),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}