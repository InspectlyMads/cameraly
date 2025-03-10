import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'zoom_slider.dart';

class TopControls extends StatelessWidget {
  const TopControls({
    super.key,
    required this.isVideoMode,
    required this.isRecording,
    required this.isFrontCamera,
    required this.flashMode,
    required this.torchEnabled,
    required this.showFlashButton,
    required this.showZoomControls,
    required this.onFlashModeChanged,
    required this.onTorchToggled,
    required this.onZoomToggled,
    required this.hasFlashCapability,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.showZoomSlider,
    required this.onZoomChanged,
    this.isLandscape = false,
    this.showRelocatedGalleryButton = false,
    this.showRelocatedSwitchButton = false,
    this.onGalleryTap,
    this.onSwitchCamera,
  });

  final bool isVideoMode;
  final bool isRecording;
  final bool isFrontCamera;
  final FlashMode flashMode;
  final bool torchEnabled;
  final bool showFlashButton;
  final bool showZoomControls;
  final ValueChanged<FlashMode> onFlashModeChanged;
  final VoidCallback onTorchToggled;
  final VoidCallback onZoomToggled;
  final bool hasFlashCapability;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final bool showZoomSlider;
  final ValueChanged<double> onZoomChanged;
  final bool isLandscape;
  final bool showRelocatedGalleryButton;
  final bool showRelocatedSwitchButton;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onSwitchCamera;

  IconData _getFlashIcon() {
    switch (flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    bool disabled = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: isLandscape ? 20 : 12),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
          ),
          child: IconButton.filled(
            onPressed: disabled ? null : onPressed,
            icon: Icon(icon, size: 28),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: disabled ? Colors.grey.withAlpha(77) : (backgroundColor ?? Colors.black54),
              foregroundColor: disabled ? Colors.white60 : (foregroundColor ?? Colors.white),
              minimumSize: const Size(56, 56),
              fixedSize: const Size(56, 56),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLandscape) {
      return _buildLandscapeLayout(context);
    }
    return _buildPortraitLayout(context);
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flash/Torch controls
          if (showFlashButton && !isFrontCamera && hasFlashCapability)
            !isVideoMode
                ? AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isRecording ? 0.0 : 1.0,
                    child: _buildControlButton(
                      icon: _getFlashIcon(),
                      onPressed: () {
                        final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
                        final nextIndex = (modes.indexOf(flashMode) + 1) % modes.length;
                        onFlashModeChanged(modes[nextIndex]);
                      },
                      backgroundColor: flashMode == FlashMode.always ? const Color.fromRGBO(255, 193, 7, 0.3) : Colors.black54,
                      foregroundColor: flashMode == FlashMode.off ? Colors.white60 : Colors.white,
                    ),
                  )
                : _buildControlButton(
                    icon: torchEnabled ? Icons.flashlight_on : Icons.flashlight_off,
                    onPressed: onTorchToggled,
                    backgroundColor: torchEnabled ? const Color.fromRGBO(255, 193, 7, 0.3) : Colors.black54,
                    foregroundColor: torchEnabled ? Colors.white : Colors.white60,
                  ),

          // Zoom controls
          if (showZoomControls) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showZoomSlider)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ZoomSlider(
                        currentZoom: currentZoom,
                        minZoom: minZoom,
                        maxZoom: maxZoom,
                        onZoomChanged: onZoomChanged,
                        isLandscape: isLandscape,
                      ),
                    ),
                  IconButton.filled(
                    onPressed: onZoomToggled,
                    icon: const Icon(Icons.zoom_in, size: 28),
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: showZoomSlider ? Colors.white : Colors.white60,
                      minimumSize: const Size(56, 56),
                      fixedSize: const Size(56, 56),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Switch camera button - always show in landscape
          if (onSwitchCamera != null)
            _buildControlButton(
              icon: Icons.switch_camera,
              onPressed: onSwitchCamera,
            ),

          // Gallery button - always show in landscape when customLeftButton is provided
          if (onGalleryTap != null && showRelocatedGalleryButton)
            _buildControlButton(
              icon: Icons.photo_library,
              onPressed: onGalleryTap,
              disabled: isRecording,
            ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),

            // Flash button (for photo mode)
            if (showFlashButton && !isVideoMode && !isFrontCamera && hasFlashCapability)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isRecording ? 0.0 : 1.0,
                child: _buildControlButton(
                  icon: _getFlashIcon(),
                  onPressed: () {
                    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off];
                    final nextIndex = (modes.indexOf(flashMode) + 1) % modes.length;
                    onFlashModeChanged(modes[nextIndex]);
                  },
                  backgroundColor: flashMode == FlashMode.always ? const Color.fromRGBO(255, 193, 7, 0.3) : Colors.black54,
                  foregroundColor: flashMode == FlashMode.off ? Colors.white60 : Colors.white,
                ),
              ),

            // Torch button (for video mode)
            if (showFlashButton && isVideoMode && !isFrontCamera && hasFlashCapability)
              _buildControlButton(
                icon: torchEnabled ? Icons.flashlight_on : Icons.flashlight_off,
                onPressed: onTorchToggled,
                backgroundColor: torchEnabled ? const Color.fromRGBO(255, 193, 7, 0.3) : Colors.black54,
                foregroundColor: torchEnabled ? Colors.white : Colors.white60,
              ),

            // Zoom controls
            if (showZoomControls) ...[
              Container(
                margin: EdgeInsets.only(top: isLandscape ? 20 : 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showZoomSlider)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ZoomSlider(
                          currentZoom: currentZoom,
                          minZoom: minZoom,
                          maxZoom: maxZoom,
                          onZoomChanged: onZoomChanged,
                          isLandscape: isLandscape,
                        ),
                      ),
                    IconButton.filled(
                      onPressed: onZoomToggled,
                      icon: const Icon(Icons.zoom_in, size: 28),
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: showZoomSlider ? Colors.white : Colors.white60,
                        minimumSize: const Size(56, 56),
                        fixedSize: const Size(56, 56),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Gallery and camera switch buttons - show either relocated or custom buttons
            if (showRelocatedGalleryButton && onGalleryTap != null)
              _buildControlButton(
                icon: Icons.photo_library,
                onPressed: onGalleryTap,
                disabled: isRecording,
              ),

            if (showRelocatedSwitchButton && onSwitchCamera != null)
              _buildControlButton(
                icon: Icons.switch_camera,
                onPressed: onSwitchCamera,
              ),

            if (!showRelocatedGalleryButton && onGalleryTap != null)
              _buildControlButton(
                icon: Icons.photo_library,
                onPressed: onGalleryTap,
                disabled: isRecording,
              ),

            if (!showRelocatedSwitchButton && onSwitchCamera != null)
              _buildControlButton(
                icon: Icons.switch_camera,
                onPressed: onSwitchCamera,
              ),
          ],
        ),
      ),
    );
  }
}
