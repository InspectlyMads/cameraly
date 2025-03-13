import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// A screen that displays a single photo with zoom and pan capabilities.
class ImageViewScreen extends StatelessWidget {
  /// Creates a new [ImageViewScreen].
  const ImageViewScreen({
    required this.imageFile,
    this.onDelete,
    this.onShare,
    super.key,
  });

  /// The image file to display.
  final XFile imageFile;

  /// Callback when the image is deleted.
  final void Function(XFile file)? onDelete;

  /// Callback when the image is shared.
  final void Function(XFile file)? onShare;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => onShare?.call(imageFile),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                onDelete?.call(imageFile);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageFile.path,
            child: Image.file(
              File(imageFile.path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to display this image',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
