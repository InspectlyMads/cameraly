# Cameraly Test Suite

This directory contains tests for the Cameraly camera package, focusing on validating the fixes for camera reinitialization issues during orientation changes.

## Test Categories

### 1. Camera Lifecycle Tests

Located in `camera_orientation_test.dart`, these tests verify:
- Proper state transitions in the Camera Lifecycle State Machine
- Correct handling of camera initialization
- Proper behavior during orientation changes
- Debouncing of rapid orientation changes
- Correct app lifecycle handling (background/foreground transitions)

### 2. Performance Tests

Located in `camera_performance_test.dart`, these tests measure:
- Camera initialization performance under different simulated device conditions
- Orientation change performance with various delays
- Debounce mechanism effectiveness during rapid orientation changes

## Running Tests

Run all tests with:

```bash
flutter test
```

Or run individual test files:

```bash
flutter test test/camera_orientation_test.dart
flutter test test/camera_performance_test.dart
```

## Test Architecture

The tests use mock implementations of the `CameralyController` to simulate various camera behaviors without requiring actual device hardware. This allows us to:

1. Test orientation change handling without real sensors
2. Measure performance with controlled timing
3. Verify state transitions in isolation
4. Test edge cases that might be difficult to reproduce on real devices

## Key Testing Areas

- **Initialization**: Verifies camera initializes correctly and transitions to ready state
- **Orientation Changes**: Tests handling of device rotation, including state transitions
- **Debouncing**: Confirms rapid orientation changes are properly throttled
- **Error Handling**: Verifies proper recovery from error states
- **Performance**: Measures timing for key operations to ensure responsiveness
- **Resource Cleanup**: Ensures resources are properly disposed

## Test Maintenance

When modifying the camera functionality, ensure that:
1. All tests still pass
2. Performance metrics remain within acceptable ranges
3. New features have corresponding test coverage
4. Edge cases are properly tested 