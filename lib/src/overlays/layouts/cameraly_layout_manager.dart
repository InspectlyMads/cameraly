import 'package:flutter/material.dart';

import '../cameraly_overlay_theme.dart';
import '../components/recording_timer.dart';
import '../widgets/placeholder_widget.dart';

class CameralyLayoutManager extends StatelessWidget {
  const CameralyLayoutManager({
    super.key,
    required this.isLandscape,
    required this.theme,
    required this.topArea,
    required this.centerArea,
    required this.bottomArea,
    required this.bottomOverlayWidget,
    required this.showPlaceholders,
    required this.isRecording,
    required this.hasVideoDurationLimit,
    required this.recordingDuration,
    required this.maxVideoDuration,
    required this.getBottomAreaHeight,
  });

  final bool isLandscape;
  final CameralyOverlayTheme theme;
  final Widget topArea;
  final Widget centerArea;
  final Widget bottomArea;
  final Widget? bottomOverlayWidget;
  final bool showPlaceholders;
  final bool isRecording;
  final bool hasVideoDurationLimit;
  final Duration recordingDuration;
  final Duration? maxVideoDuration;
  final double Function(bool) getBottomAreaHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      key: ValueKey<Orientation>(MediaQuery.of(context).orientation),
      children: [
        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: CircleAvatar(
                backgroundColor: Colors.black.withAlpha(102),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),

        // Main layout
        isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),

        // Video duration limit UI
        if (isRecording && hasVideoDurationLimit && maxVideoDuration != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: RecordingTimer(
                duration: recordingDuration,
                maxDuration: maxVideoDuration,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Stack(
      children: [
        // Top area
        topArea,

        // Center area
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomOverlayWidget != null ? 100 : 0,
          child: centerArea,
        ),

        // Bottom overlay widget
        if (bottomOverlayWidget != null || showPlaceholders)
          Positioned(
            left: 20,
            right: 20,
            bottom: getBottomAreaHeight(false) + 20,
            child: bottomOverlayWidget ?? const PlaceholderWidget(type: PlaceholderType.bottomOverlay),
          ),

        // Bottom area with gradient
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: bottomArea,
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    const leftAreaWidth = 80.0;
    const rightAreaWidth = 120.0;

    return Stack(
      children: [
        // Left area (top area in portrait)
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          width: leftAreaWidth,
          child: topArea,
        ),

        // Center area
        Positioned(
          top: 0,
          left: leftAreaWidth,
          right: rightAreaWidth,
          bottom: 0,
          child: centerArea,
        ),

        // Right area with controls
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: rightAreaWidth,
          child: bottomArea,
        ),

        // Bottom overlay widget
        if (bottomOverlayWidget != null || showPlaceholders)
          Positioned(
            left: leftAreaWidth + 20,
            right: rightAreaWidth + 20,
            bottom: 20,
            child: bottomOverlayWidget ?? const PlaceholderWidget(type: PlaceholderType.bottomOverlay),
          ),
      ],
    );
  }
}
