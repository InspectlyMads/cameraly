import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cameraly/providers/camera_providers.dart';

void main() {
  group('Camera Grid Tests', () {
    test('Grid toggle should work correctly', () {
      final container = ProviderContainer();
      
      // Get the camera controller notifier
      final controller = container.read(cameraControllerProvider.notifier);
      
      // Initial state should have grid off
      expect(container.read(cameraControllerProvider).showGrid, false);
      
      // Toggle grid on
      controller.toggleGrid();
      expect(container.read(cameraControllerProvider).showGrid, true);
      
      // Toggle grid off
      controller.toggleGrid();
      expect(container.read(cameraControllerProvider).showGrid, false);
      
      container.dispose();
    });
  });
}