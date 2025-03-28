import 'package:flutter_test/flutter_test.dart';

import 'camera_orientation_test.dart' as orientation_tests;
import 'camera_performance_test.dart' as performance_tests;

void main() {
  group('Running All Cameraly Tests', () {
    test('Camera Orientation Tests', () {
      orientation_tests.main();
    });

    test('Camera Performance Tests', () {
      performance_tests.main();
    });
  });
}
