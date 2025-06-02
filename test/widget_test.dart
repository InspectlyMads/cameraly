// This is a basic Flutter test file.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:camera_test/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Camera Test app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CameraTestApp()));

    // Verify that our app shows the correct title.
    expect(find.text('Camera Test'), findsOneWidget);
    expect(find.text('Camera Orientation Testing'), findsOneWidget);

    // Verify that we have camera mode options
    expect(find.text('Photo Mode'), findsOneWidget);
    expect(find.text('Video Mode'), findsOneWidget);
    expect(find.text('Combined Mode'), findsOneWidget);
  });
}
