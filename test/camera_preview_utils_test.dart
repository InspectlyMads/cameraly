import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cameraly/src/utils/camera_preview_utils.dart';

void main() {
  group('CameraPreviewUtils Tests', () {
    group('calculatePreviewSize', () {
      test('calculates correct size for portrait orientation', () {
        final screenSize = const Size(375, 812); // iPhone X size
        const cameraAspectRatio = 4.0 / 3.0;
        
        final previewSize = CameraPreviewUtils.calculatePreviewSize(
          screenSize: screenSize,
          cameraAspectRatio: cameraAspectRatio,
          orientation: Orientation.portrait,
        );
        
        // Preview should fit within screen
        expect(previewSize.width, lessThanOrEqualTo(screenSize.width));
        expect(previewSize.height, lessThanOrEqualTo(screenSize.height));
        
        // Should maintain aspect ratio
        expect(previewSize.width / previewSize.height, closeTo(cameraAspectRatio, 0.001));
      });
      
      test('calculates correct size for landscape orientation', () {
        final screenSize = const Size(812, 375); // iPhone X landscape
        const cameraAspectRatio = 16.0 / 9.0;
        
        final previewSize = CameraPreviewUtils.calculatePreviewSize(
          screenSize: screenSize,
          cameraAspectRatio: cameraAspectRatio,
          orientation: Orientation.landscape,
        );
        
        expect(previewSize.width, lessThanOrEqualTo(screenSize.width));
        expect(previewSize.height, lessThanOrEqualTo(screenSize.height));
        expect(previewSize.width / previewSize.height, closeTo(cameraAspectRatio, 0.001));
      });
      
      test('respects safe area insets', () {
        final screenSize = const Size(375, 812);
        const cameraAspectRatio = 4.0 / 3.0;
        const safeArea = EdgeInsets.only(top: 44, bottom: 34);
        
        final previewSize = CameraPreviewUtils.calculatePreviewSize(
          screenSize: screenSize,
          cameraAspectRatio: cameraAspectRatio,
          orientation: Orientation.portrait,
          safeArea: safeArea,
        );
        
        final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
        expect(previewSize.height, lessThanOrEqualTo(availableHeight));
      });
    });
    
    group('calculatePreviewPadding', () {
      test('centers preview correctly', () {
        final screenSize = const Size(375, 812);
        final previewSize = const Size(375, 500);
        
        final padding = CameraPreviewUtils.calculatePreviewPadding(
          screenSize: screenSize,
          previewSize: previewSize,
        );
        
        expect(padding.left, 0);
        expect(padding.right, 0);
        expect(padding.top, greaterThan(0));
        expect(padding.bottom, greaterThan(0));
        expect(padding.top, equals(padding.bottom));
      });
      
      test('adds safe area to padding', () {
        final screenSize = const Size(375, 812);
        final previewSize = const Size(375, 500);
        const safeArea = EdgeInsets.only(top: 44, bottom: 34);
        
        final padding = CameraPreviewUtils.calculatePreviewPadding(
          screenSize: screenSize,
          previewSize: previewSize,
          safeArea: safeArea,
        );
        
        expect(padding.top, greaterThan(safeArea.top));
        expect(padding.bottom, greaterThan(safeArea.bottom));
      });
    });
    
    group('getStandardCameraAspectRatio', () {
      test('returns closest standard ratio for 4:3', () {
        final ratio = CameraPreviewUtils.getStandardCameraAspectRatio(1.33);
        expect(ratio, 4.0 / 3.0);
      });
      
      test('returns closest standard ratio for 16:9', () {
        final ratio = CameraPreviewUtils.getStandardCameraAspectRatio(1.78);
        expect(ratio, 16.0 / 9.0);
      });
      
      test('returns closest standard ratio for 3:2', () {
        final ratio = CameraPreviewUtils.getStandardCameraAspectRatio(1.5);
        expect(ratio, 3.0 / 2.0);
      });
      
      test('returns closest standard ratio for 1:1', () {
        final ratio = CameraPreviewUtils.getStandardCameraAspectRatio(1.0);
        expect(ratio, 1.0);
      });
      
      test('handles edge cases', () {
        final ratio1 = CameraPreviewUtils.getStandardCameraAspectRatio(1.4);
        expect(ratio1, anyOf(4.0 / 3.0, 3.0 / 2.0));
        
        final ratio2 = CameraPreviewUtils.getStandardCameraAspectRatio(2.0);
        expect(ratio2, 16.0 / 9.0);
      });
    });
    
    group('getPreviewBorderRadius', () {
      test('returns zero radius for full screen preview', () {
        final screenSize = const Size(375, 812);
        final previewSize = const Size(375, 812);
        
        final borderRadius = CameraPreviewUtils.getPreviewBorderRadius(
          previewSize: previewSize,
          screenSize: screenSize,
        );
        
        expect(borderRadius, BorderRadius.zero);
      });
      
      test('returns rounded corners for non-full screen preview', () {
        final screenSize = const Size(375, 812);
        final previewSize = const Size(300, 400);
        
        final borderRadius = CameraPreviewUtils.getPreviewBorderRadius(
          previewSize: previewSize,
          screenSize: screenSize,
        );
        
        expect(borderRadius, BorderRadius.circular(12));
      });
      
      test('considers 95% threshold for full screen', () {
        final screenSize = const Size(375, 812);
        final previewSize = Size(375 * 0.96, 812 * 0.96);
        
        final borderRadius = CameraPreviewUtils.getPreviewBorderRadius(
          previewSize: previewSize,
          screenSize: screenSize,
        );
        
        expect(borderRadius, BorderRadius.zero);
      });
    });
    
    group('getPreviewRect', () {
      test('creates correct rectangle from parameters', () {
        final screenSize = const Size(375, 812);
        final previewSize = const Size(300, 400);
        const padding = EdgeInsets.all(20);
        
        final rect = CameraPreviewUtils.getPreviewRect(
          screenSize: screenSize,
          previewSize: previewSize,
          padding: padding,
        );
        
        expect(rect.left, padding.left);
        expect(rect.top, padding.top);
        expect(rect.width, previewSize.width);
        expect(rect.height, previewSize.height);
      });
    });
    
    group('isPointInPreview', () {
      test('correctly identifies points inside preview', () {
        final previewRect = const Rect.fromLTWH(50, 100, 275, 400);
        
        expect(
          CameraPreviewUtils.isPointInPreview(
            point: const Offset(100, 200),
            previewRect: previewRect,
          ),
          isTrue,
        );
        
        expect(
          CameraPreviewUtils.isPointInPreview(
            point: const Offset(50, 100), // Top-left corner
            previewRect: previewRect,
          ),
          isTrue,
        );
      });
      
      test('correctly identifies points outside preview', () {
        final previewRect = const Rect.fromLTWH(50, 100, 275, 400);
        
        expect(
          CameraPreviewUtils.isPointInPreview(
            point: const Offset(10, 50),
            previewRect: previewRect,
          ),
          isFalse,
        );
        
        expect(
          CameraPreviewUtils.isPointInPreview(
            point: const Offset(400, 600),
            previewRect: previewRect,
          ),
          isFalse,
        );
      });
    });
    
    group('calculateControlZones', () {
      test('creates control zones when space is available', () {
        final screenSize = const Size(375, 812);
        final previewRect = const Rect.fromLTWH(37.5, 156, 300, 400);
        const safeArea = EdgeInsets.only(top: 44, bottom: 34);
        
        final zones = CameraPreviewUtils.calculateControlZones(
          screenSize: screenSize,
          previewRect: previewRect,
          safeArea: safeArea,
        );
        
        // Should have top and bottom zones
        expect(zones.containsKey('top'), isTrue);
        expect(zones.containsKey('bottom'), isTrue);
      });
      
      test('does not create zones when space is insufficient', () {
        final screenSize = const Size(375, 812);
        // Preview takes almost full screen
        final previewRect = const Rect.fromLTWH(0, 50, 375, 712);
        const safeArea = EdgeInsets.zero;
        
        final zones = CameraPreviewUtils.calculateControlZones(
          screenSize: screenSize,
          previewRect: previewRect,
          safeArea: safeArea,
        );
        
        // Should not have zones due to insufficient space
        expect(zones.containsKey('bottom'), isFalse);
      });
      
      test('respects minimum zone size of 60 pixels', () {
        final screenSize = const Size(375, 812);
        final previewRect = const Rect.fromLTWH(50, 100, 275, 612);
        const safeArea = EdgeInsets.zero;
        
        final zones = CameraPreviewUtils.calculateControlZones(
          screenSize: screenSize,
          previewRect: previewRect,
          safeArea: safeArea,
        );
        
        // Top zone should exist (100px available)
        expect(zones.containsKey('top'), isTrue);
        
        // Bottom zone should exist (100px available)
        expect(zones.containsKey('bottom'), isTrue);
        
        // Left zone should not exist (only 50px available)
        expect(zones.containsKey('left'), isFalse);
      });
      
      test('control zones have correct dimensions', () {
        final screenSize = const Size(375, 812);
        final previewRect = const Rect.fromLTWH(37.5, 200, 300, 400);
        const safeArea = EdgeInsets.only(top: 44, bottom: 34);
        
        final zones = CameraPreviewUtils.calculateControlZones(
          screenSize: screenSize,
          previewRect: previewRect,
          safeArea: safeArea,
        );
        
        // Check top zone
        if (zones.containsKey('top')) {
          final topZone = zones['top']!;
          expect(topZone.top, safeArea.top);
          expect(topZone.bottom, lessThan(previewRect.top));
        }
        
        // Check bottom zone
        if (zones.containsKey('bottom')) {
          final bottomZone = zones['bottom']!;
          expect(bottomZone.top, greaterThan(previewRect.bottom));
          expect(bottomZone.bottom, screenSize.height - safeArea.bottom);
        }
      });
    });
  });
}