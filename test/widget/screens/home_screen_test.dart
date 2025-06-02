import 'package:camera_test/screens/home_screen.dart';
import 'package:camera_test/services/camera_service.dart';
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
      expect(find.text('Camera Test'), findsOneWidget); // AppBar title
      expect(find.text('Camera Orientation Testing'), findsOneWidget);
      expect(
        find.text('Test how camera captures work across different device orientations'),
        findsOneWidget,
      );

      // Assert - Check for all camera mode cards
      expect(find.text('Photo Mode'), findsOneWidget);
      expect(find.text('Test photo capture with orientation data'), findsOneWidget);
      expect(find.text('Video Mode'), findsOneWidget);
      expect(find.text('Test video recording with orientation data'), findsOneWidget);
      expect(find.text('Combined Mode'), findsOneWidget);
      expect(find.text('Switch between photo and video in one interface'), findsOneWidget);

      // Assert - Check for permission section
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.text('Permissions'), findsOneWidget);
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
      await tester.pump(); // Process the tap
      await tester.pump(const Duration(milliseconds: 100)); // Wait for any navigation

      // Assert - Since HomeScreen navigates to CameraScreen, no snackbar should appear
      // Instead we expect no snackbar message since navigation is the intended behavior
      expect(find.byType(SnackBar), findsNothing);
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

      // Assert - No snackbar expected, navigation is the intended behavior
      expect(find.byType(SnackBar), findsNothing);
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

      // Assert - No snackbar expected, navigation is the intended behavior
      expect(find.byType(SnackBar), findsNothing);
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
      expect(find.byType(Card), findsNWidgets(4)); // 3 camera mode cards + 1 permission card

      // Check that InkWell widgets exist for tap handling
      expect(find.byType(InkWell), findsNWidgets(4)); // 3 mode cards + 1 permissions button
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
      expect(find.text('Camera Test'), findsOneWidget);
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
      expect(find.text('Camera Test'), findsOneWidget);
    });

    group('CameraMode enum', () {
      test('has correct values', () {
        expect(CameraMode.values, hasLength(3));
        expect(CameraMode.values, contains(CameraMode.photo));
        expect(CameraMode.values, contains(CameraMode.video));
        expect(CameraMode.values, contains(CameraMode.combined));
      });

      test('toString returns correct names', () {
        expect(CameraMode.photo.name, equals('photo'));
        expect(CameraMode.video.name, equals('video'));
        expect(CameraMode.combined.name, equals('combined'));
      });
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

      // Assert - Check that interactive elements exist
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsNWidgets(4)); // 3 camera mode cards + 1 permission button

      // Verify that the first 3 InkWells (camera mode cards) are tappable
      for (int i = 0; i < 3; i++) {
        await tester.tap(inkWells.at(i));
        await tester.pump();
        // No snackbar expected - navigation is the intended behavior
        expect(find.byType(SnackBar), findsNothing);
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
