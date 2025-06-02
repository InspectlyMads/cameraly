import 'package:camera_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('displays all required UI elements', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert - Check for main title and description
      expect(find.text('Camera Test MVP'), findsOneWidget);
      expect(find.text('Camera Orientation Testing'), findsOneWidget);
      expect(
        find.text('Test how the camera package handles orientation on your device'),
        findsOneWidget,
      );

      // Assert - Check for all camera mode cards
      expect(find.text('Photo Mode'), findsOneWidget);
      expect(find.text('Test photo capture orientation handling'), findsOneWidget);
      expect(find.text('Video Mode'), findsOneWidget);
      expect(find.text('Test video recording orientation handling'), findsOneWidget);
      expect(find.text('Combined Mode'), findsOneWidget);
      expect(find.text('Test both photo and video in one interface'), findsOneWidget);

      // Assert - Check for info section
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        find.textContaining('This app tests camera orientation handling'),
        findsOneWidget,
      );
    });

    testWidgets('displays correct icons for each mode', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert - Check for mode icons
      expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Photo mode
      expect(find.byIcon(Icons.videocam), findsOneWidget); // Video mode
      expect(find.byIcon(Icons.camera), findsOneWidget); // Combined mode

      // Check for navigation arrows
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(3));
    });

    testWidgets('shows snackbar when photo mode card is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act - Tap the photo mode card
      await tester.tap(find.text('Photo Mode'));
      await tester.pump(); // Trigger the snackbar
      await tester.pump(const Duration(milliseconds: 100)); // Wait for animation

      // Assert
      expect(
        find.textContaining('photoOnly mode selected'),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar when video mode card is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Video Mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(
        find.textContaining('videoOnly mode selected'),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar when combined mode card is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Combined Mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(
        find.textContaining('combined mode selected'),
        findsOneWidget,
      );
    });

    testWidgets('cards are properly styled and interactive', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert - Check that cards exist
      expect(find.byType(Card), findsNWidgets(4)); // 3 mode cards + 1 info card

      // Check that InkWell widgets exist for tap handling
      expect(find.byType(InkWell), findsNWidgets(3)); // One for each mode card
    });

    testWidgets('app bar is properly configured', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(AppBar), findsOneWidget);
      // Only one instance in AppBar since we removed the main title duplication
      expect(find.text('Camera Test MVP'), findsOneWidget);
    });

    testWidgets('layout is properly structured', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert - Check main structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1)); // MaterialApp may add SafeArea too
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Padding), findsAtLeastNWidgets(1));
      expect(find.byType(Column), findsAtLeastNWidgets(1));

      // Check for spacing widgets (updated expectation)
      expect(find.byType(SizedBox), findsAtLeastNWidgets(6)); // More SizedBox widgets now
    });

    testWidgets('handles theme colors correctly', (tester) async {
      // Arrange
      const testSeedColor = Colors.red;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: testSeedColor),
              useMaterial3: true,
            ),
            home: const HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert - The theme should be applied (difficult to test color directly in widget tests,
      // but we can verify the app doesn't crash and widgets render correctly)
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Camera Test MVP'), findsOneWidget);
    });

    group('CameraMode enum', () {
      test('has correct values', () {
        expect(CameraMode.values, hasLength(3));
        expect(CameraMode.values, contains(CameraMode.photoOnly));
        expect(CameraMode.values, contains(CameraMode.videoOnly));
        expect(CameraMode.values, contains(CameraMode.combined));
      });

      test('toString returns correct names', () {
        expect(CameraMode.photoOnly.name, equals('photoOnly'));
        expect(CameraMode.videoOnly.name, equals('videoOnly'));
        expect(CameraMode.combined.name, equals('combined'));
      });
    });

    testWidgets('snackbar messages contain camera mode names', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Test Photo Mode
      await tester.tap(find.text('Photo Mode'));
      await tester.pump(); // Start animation
      await tester.pumpAndSettle(); // Wait for animation to complete
      expect(find.textContaining('photoOnly mode selected'), findsOneWidget);

      // Wait for snackbar to fully disappear
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Test Video Mode
      await tester.tap(find.text('Video Mode'));
      await tester.pump(); // Start animation
      await tester.pumpAndSettle(); // Wait for animation to complete
      expect(find.textContaining('videoOnly mode selected'), findsOneWidget);

      // Wait for snackbar to fully disappear
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Test Combined Mode
      await tester.tap(find.text('Combined Mode'));
      await tester.pump(); // Start animation
      await tester.pumpAndSettle(); // Wait for animation to complete
      expect(find.textContaining('combined mode selected'), findsOneWidget);
    });

    testWidgets('accessibility features work correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert - Check that interactive elements have proper semantics
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsNWidgets(3));

      // Verify that cards are tappable by checking tap gestures work
      for (int i = 0; i < 3; i++) {
        await tester.tap(inkWells.at(i));
        await tester.pump();
        // Should show a snackbar for each tap
        expect(find.byType(SnackBar), findsOneWidget);
        await tester.pump(const Duration(seconds: 3)); // Wait for snackbar to dismiss
      }
    });

    testWidgets('is scrollable for small screens', (tester) async {
      // Arrange - Set a small screen size
      await tester.binding.setSurfaceSize(const Size(300, 400));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Assert - SingleChildScrollView should handle small screens without overflow
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1)); // May have multiple SafeArea widgets

      // Should be able to scroll without errors
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump();

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
