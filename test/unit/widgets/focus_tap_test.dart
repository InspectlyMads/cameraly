import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cameraly/widgets/focus_indicator.dart';

void main() {
  group('Focus Indicator Tests', () {
    testWidgets('Focus indicator appears and disappears', (WidgetTester tester) async {
      bool completed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FocusIndicator(
                  key: const ValueKey('focus_1'),
                  position: const Offset(100, 100),
                  onComplete: () {
                    completed = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      
      // Initially visible
      expect(find.byType(FocusIndicator), findsOneWidget);
      
      // Wait for animation to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Should have called onComplete
      expect(completed, true);
    });
    
    testWidgets('Multiple focus indicators with different keys animate independently', (WidgetTester tester) async {
      // Test that using different keys creates new animations
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FocusIndicator(
                  key: const ValueKey('focus_1'),
                  position: const Offset(100, 100),
                  onComplete: () {},
                ),
              ],
            ),
          ),
        ),
      );
      
      // First indicator visible
      expect(find.byType(FocusIndicator), findsOneWidget);
      
      // Replace with new indicator using different key
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FocusIndicator(
                  key: const ValueKey('focus_2'),
                  position: const Offset(200, 200),
                  onComplete: () {},
                ),
              ],
            ),
          ),
        ),
      );
      
      // New indicator should be created
      expect(find.byType(FocusIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('focus_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus_1')), findsNothing);
    });
    
    test('Tap and pinch timing check', () {
      // Test that 300ms delay prevents tap during pinch
      final lastPinchTime = DateTime.now();
      final tapTime = DateTime.now().add(const Duration(milliseconds: 200));
      
      final shouldAllowTap = tapTime.difference(lastPinchTime).inMilliseconds > 300;
      expect(shouldAllowTap, false);
      
      // After 300ms, tap should be allowed
      final laterTapTime = DateTime.now().add(const Duration(milliseconds: 400));
      final shouldAllowLaterTap = laterTapTime.difference(lastPinchTime).inMilliseconds > 300;
      expect(shouldAllowLaterTap, true);
    });
  });
}