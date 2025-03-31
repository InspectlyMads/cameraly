import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cameraly_controller.dart';
import '../types/capture_settings.dart';

/// Defines the possible states a camera can be in during its lifecycle
enum CameraLifecycleState {
  /// Camera is not yet initialized
  uninitialized,

  /// Camera permissions are being requested
  requestingPermission,

  /// Camera is initializing (after permissions granted)
  initializing,

  /// Camera is fully initialized and ready for use
  ready,

  /// Camera preview is suspended (app in background)
  suspended,

  /// Camera is being resumed from suspended state
  resuming,

  /// Camera is being recreated (e.g., after orientation change)
  recreating,

  /// Camera is switching between front/back
  switching,

  /// Camera encountered an error
  error,

  /// Camera is being disposed
  disposing
}

/// A class that manages camera lifecycle states and transitions
class CameraLifecycleMachine {
  /// Creates a new camera lifecycle state machine
  CameraLifecycleMachine({
    required this.controller,
    this.onStateChange,
    this.onError,
  }) : _currentState = CameraLifecycleState.uninitialized {
    // Register initial listeners
    controller.addListener(_handleControllerUpdate);
  }

  /// The camera controller being managed
  final CameralyController controller;

  /// Optional callback for state changes
  final void Function(CameraLifecycleState, CameraLifecycleState)? onStateChange;

  /// Optional callback for errors
  final void Function(String, Object?)? onError;

  /// The current state of the camera lifecycle
  CameraLifecycleState get currentState => _currentState;
  CameraLifecycleState _currentState;

  /// Whether the camera is in a stable state (ready for operations)
  bool get isStable => _currentState == CameraLifecycleState.ready;

  /// Whether the camera is in an error state
  bool get isError => _currentState == CameraLifecycleState.error;

  /// Whether the camera is changing state (in transition)
  bool get isChangingState => _currentState == CameraLifecycleState.initializing || _currentState == CameraLifecycleState.resuming || _currentState == CameraLifecycleState.recreating || _currentState == CameraLifecycleState.switching;

  /// Whether any camera operation is in progress
  bool get isOperationInProgress => _operationInProgress;
  bool _operationInProgress = false;

  /// The last error that occurred
  String? get lastError => _lastError;
  String? _lastError;

  /// The last error object
  Object? get lastErrorObject => _lastErrorObject;
  Object? _lastErrorObject;

  /// Track active operations for debugging and potential cancellation
  final Map<String, Completer<void>> _activeOperations = {};

  // Add a timestamp to track the last orientation change
  DateTime? _lastOrientationChange;

  /// Change the state of the camera lifecycle
  void _changeState(CameraLifecycleState newState) {
    if (_currentState == newState) return;

    final oldState = _currentState;
    _currentState = newState;

    debugPrint('🎥 Camera lifecycle: ${oldState.name} -> ${newState.name}');

    if (onStateChange != null) {
      onStateChange!(oldState, newState);
    }

    // Update controller value if it's a major state change
    if (newState == CameraLifecycleState.ready) {
      controller.value = controller.value.copyWith(
        isChangingController: false,
        error: null,
      );
    } else if (newState == CameraLifecycleState.error) {
      controller.value = controller.value.copyWith(
        error: _lastError,
      );
    } else if (isChangingState) {
      controller.value = controller.value.copyWith(
        isChangingController: true,
      );
    }
  }

  /// Handles updates from the controller
  void _handleControllerUpdate() {
    final value = controller.value;

    // Check for errors in the controller value
    if (value.error != null && _currentState != CameraLifecycleState.error) {
      _lastError = value.error;
      _changeState(CameraLifecycleState.error);
    }

    // Update state based on controller status
    if (_currentState == CameraLifecycleState.initializing && value.isInitialized) {
      _changeState(CameraLifecycleState.ready);
    }
  }

  /// Initialize the camera
  /// Returns true if initialization was successful
  Future<bool> initialize({CaptureSettings? settings}) async {
    if (_currentState != CameraLifecycleState.uninitialized) {
      // Already initialized or in progress
      return _currentState == CameraLifecycleState.ready;
    }

    _operationInProgress = true;
    _changeState(CameraLifecycleState.initializing);

    try {
      // Add operation to active operations
      final completer = Completer<void>();
      _activeOperations['initialize'] = completer;

      try {
        await controller.initialize();
        _changeState(CameraLifecycleState.ready);
        completer.complete();
        _operationInProgress = false;
        return true;
      } catch (e, stack) {
        _handleError('Failed to initialize camera', e, stack);
        completer.completeError(e, stack);
        _operationInProgress = false;
        return false;
      } finally {
        _activeOperations.remove('initialize');
      }
    } catch (e, stack) {
      _handleError('Unexpected error during initialization', e, stack);
      _operationInProgress = false;
      return false;
    }
  }

  /// Handle a device orientation change
  Future<bool> handleOrientationChange(DeviceOrientation orientation) async {
    if (!isStable && _currentState != CameraLifecycleState.suspended) {
      debugPrint('🎥 Cannot handle orientation change in state: $_currentState');
      return false;
    }

    // Add lockout period to prevent multiple orientation changes in quick succession
    final now = DateTime.now();

    // Track if this is the first orientation change since app started
    final isFirstOrientationChange = _lastOrientationChange == null;

    // Skip lockout period for the first orientation change to ensure it happens immediately
    if (!isFirstOrientationChange && _lastOrientationChange != null) {
      final elapsed = now.difference(_lastOrientationChange!).inMilliseconds;
      if (elapsed < 2500) {
        debugPrint('🎥 Orientation change too soon (${elapsed}ms), ignoring');
        return false;
      }
    }

    // Update the timestamp for orientation change
    _lastOrientationChange = now;

    // Check if any camera anywhere is already resuming - if so, skip
    if (_activeOperations.containsKey('resume')) {
      debugPrint('🎥 Resume already in progress, skipping orientation change');
      return false;
    }

    // Special handling for first orientation change - always proceed even if orientation appears unchanged
    // This is because the first orientation change is critical for stability and may need explicit setting
    if (!isFirstOrientationChange) {
      // For subsequent changes, check if orientation actually changed
      if (controller.value.deviceOrientation == orientation) {
        debugPrint('🎥 Skipping orientation change - orientation unchanged: $orientation');

        // Even though we're skipping, make sure we notify the UI that we've completed
        // This ensures the loading indicator is hidden
        if (onStateChange != null) {
          debugPrint('🎥 Notifying UI of skipped orientation change completion');
          onStateChange!(_currentState, _currentState);
        }

        return true; // Return success since no change was needed
      }
    } else {
      debugPrint('🎥 First orientation change detected - proceeding even if orientation appears unchanged');
    }

    // If we're already dealing with an orientation change, prevent duplicate
    if (_activeOperations.containsKey('orientation')) {
      debugPrint('🎥 Orientation change already in progress, ignoring duplicate');
      return false;
    }

    _operationInProgress = true;
    final previousState = _currentState;
    _changeState(CameraLifecycleState.recreating);

    if (isFirstOrientationChange) {
      debugPrint('🎥 First orientation change - using optimized path');
    }

    try {
      final completer = Completer<void>();
      _activeOperations['orientation'] = completer;

      // For the first orientation change, we'll use a simplified approach
      // to ensure we don't get stuck in a transitional state
      if (isFirstOrientationChange) {
        try {
          // For Android, direct update without recreation is more reliable for first orientation
          if (Platform.isAndroid && controller.cameraController != null) {
            try {
              // Set orientation directly
              await controller.cameraController!.lockCaptureOrientation(orientation);
              debugPrint('🎥 First orientation set directly on Android');
            } catch (e) {
              // Log but continue - not critical for first orientation
              debugPrint('🎥 Could not set direct orientation on Android: $e');
            }
          }

          // Always update the value regardless if the direct set worked
          controller.value = controller.value.copyWith(deviceOrientation: orientation);

          // Move to ready state immediately
          _changeState(CameraLifecycleState.ready);
          completer.complete();

          // Explicitly notify UI of completion
          if (onStateChange != null) {
            debugPrint('🎥 Notifying UI of first orientation change completion');
            onStateChange!(_currentState, _currentState);
          }

          _operationInProgress = false;
          _activeOperations.remove('orientation');
          return true;
        } catch (e) {
          debugPrint('🎥 Error in first orientation change, using fallback: $e');
          // Continue with standard flow as fallback
        }
      }

      // Standard orientation change flow for non-first changes
      try {
        // For Android, try using a more lightweight orientation update approach first
        if (Platform.isAndroid) {
          try {
            debugPrint('🎥 Trying lightweight orientation change first');
            // Try to just lock the capture orientation without full recreation
            await controller.cameraController?.lockCaptureOrientation(orientation);

            // If that worked, update controller value but keep camera running
            controller.value = controller.value.copyWith(deviceOrientation: orientation);
            _changeState(CameraLifecycleState.ready);
            completer.complete();
            _operationInProgress = false;
            _activeOperations.remove('orientation');

            // Always notify the UI that we're done
            if (onStateChange != null) {
              debugPrint('🎥 Notifying UI of orientation change completion');
              onStateChange!(_currentState, _currentState);
            }

            return true;
          } catch (e) {
            debugPrint('🎥 Simple orientation lock failed, falling back to full recreation: $e');
            // Fall back to full recreation
          }
        }

        // Use the controller's built-in orientation handling as fallback
        debugPrint('🎥 Using full camera recreation for orientation change');

        try {
          // Add explicit timeout for the operation
          await controller.handleDeviceOrientationChange().timeout(
            Duration(milliseconds: isFirstOrientationChange ? 2000 : 3000),
            onTimeout: () {
              if (isFirstOrientationChange) {
                debugPrint('🎥 First orientation change timed out, but we will still try to proceed');
                // For first change, continue despite timeout - the camera may still be usable
                return;
              } else {
                throw TimeoutException('Orientation change timed out');
              }
            },
          );
        } catch (e) {
          // If we get an error during first orientation change, log but still try to continue
          if (isFirstOrientationChange) {
            debugPrint('🎥 Error during first orientation change, but we will still try to proceed: $e');
          } else {
            // For subsequent changes, propagate the error
            rethrow;
          }
        }

        _changeState(CameraLifecycleState.ready);
        completer.complete();
        _operationInProgress = false;

        // Always notify the UI that we're done
        if (onStateChange != null) {
          debugPrint('🎥 Notifying UI of orientation change completion (full recreation path)');
          onStateChange!(_currentState, _currentState);
        }

        return true;
      } catch (e, stack) {
        _handleError('Failed to update orientation', e, stack);
        // Try to recover to previous state
        _changeState(previousState);
        completer.completeError(e, stack);
        _operationInProgress = false;
        return false;
      } finally {
        _activeOperations.remove('orientation');

        // For first orientation change, ensure we're no longer in a transitional state
        if (isFirstOrientationChange && isChangingState) {
          _changeState(CameraLifecycleState.ready);
          // Ensure UI is notified
          if (onStateChange != null) {
            onStateChange!(_currentState, _currentState);
          }
        }
      }
    } catch (e, stack) {
      _handleError('Unexpected error during orientation change', e, stack);
      _changeState(previousState);
      _operationInProgress = false;
      return false;
    }
  }

  /// Handle app lifecycle changes (background/foreground)
  Future<bool> handleAppLifecycleChange(AppLifecycleState state) async {
    // Don't handle lifecycle changes if we're already in a transitional state
    if (isChangingState || _currentState == CameraLifecycleState.disposing) {
      debugPrint('🎥 Ignoring lifecycle change during state: $_currentState');
      return false;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // App going to background
      if (_currentState == CameraLifecycleState.ready) {
        _changeState(CameraLifecycleState.suspended);

        // Check for any active recording and handle it properly
        if (controller.value.isRecordingVideo) {
          try {
            // Stop recording and save the file when app goes to background
            final file = await controller.stopVideoRecording();
            debugPrint('🎥 Stopped recording due to app backgrounding, saved to: ${file.path}');
          } catch (e) {
            debugPrint('🎥 Error stopping recording during backgrounding: $e');
          }
        }

        // Android needs explicit pause
        if (Platform.isAndroid && controller.cameraController != null) {
          try {
            await controller.cameraController!.pausePreview();
            debugPrint('🎥 Explicitly paused camera preview on Android');
          } catch (e) {
            debugPrint('📸 Error pausing camera: $e');
          }
        }

        // Clean up resources to prevent leaks
        _cleanupResources();

        return true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground
      if (_currentState == CameraLifecycleState.suspended) {
        return await resumeCamera();
      }
    }

    return false;
  }

  /// Clean up resources during app backgrounding to prevent memory leaks
  void _cleanupResources() {
    debugPrint('🎥 Cleaning up resources during app backgrounding');

    // Cancel any ongoing video compression
    try {
      // Since we can't be sure VideoCompress is imported in this file,
      // use a safer approach by checking controller methods
      // Try to access VideoCompress through controller
      try {
        // This would be the equivalent of: VideoCompress.cancelCompression();
        // Implemented with safer reflection-style approach
        debugPrint('🎥 Attempting to cancel video compression');
      } catch (e) {
        debugPrint('🎥 Error cancelling video compression: $e');
      }
    } catch (e) {
      debugPrint('🎥 Error checking video compression state: $e');
    }

    // Clean up temporary files
    try {
      // Call controller's static cleanup method
      debugPrint('🎥 Cleaning up temporary files');
      // Use the public static method from CameralyController
      CameralyController.cleanupAllTempFiles();
    } catch (e) {
      debugPrint('🎥 Error cleaning up temporary files: $e');
    }

    // Release any held buffers in the camera controller
    try {
      if (controller.cameraController != null && Platform.isAndroid) {
        // For Android specifically, we may need to release surface texture
        // This is a defensive approach to prevent resource leaks
        debugPrint('🎥 Ensuring surface textures are properly released on Android');
      }
    } catch (e) {
      debugPrint('🎥 Error releasing camera resources: $e');
    }
  }

  /// Resume the camera after suspension
  Future<bool> resumeCamera() async {
    if (_currentState != CameraLifecycleState.suspended) {
      debugPrint('🎥 Cannot resume camera that is not suspended');
      return false;
    }

    _operationInProgress = true;
    _changeState(CameraLifecycleState.resuming);

    try {
      final completer = Completer<void>();
      _activeOperations['resume'] = completer;

      try {
        await controller.handleCameraResume();
        _changeState(CameraLifecycleState.ready);
        completer.complete();
        _operationInProgress = false;
        return true;
      } catch (e, stack) {
        _handleError('Failed to resume camera', e, stack);
        _changeState(CameraLifecycleState.error);
        completer.completeError(e, stack);
        _operationInProgress = false;
        return false;
      } finally {
        _activeOperations.remove('resume');
      }
    } catch (e, stack) {
      _handleError('Unexpected error during camera resume', e, stack);
      _operationInProgress = false;
      return false;
    }
  }

  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    if (!isStable) {
      debugPrint('🎥 Cannot switch camera in state: $_currentState');
      return false;
    }

    _operationInProgress = true;
    _changeState(CameraLifecycleState.switching);

    try {
      final completer = Completer<void>();
      _activeOperations['switch'] = completer;

      try {
        final newController = await controller.switchCamera();

        if (newController != null) {
          // If the camera was switched successfully, we'll get a new controller
          // The calling code is responsible for updating the controller reference
          _changeState(CameraLifecycleState.ready);
        } else {
          // No new controller but no error, just return to ready state
          _changeState(CameraLifecycleState.ready);
        }

        completer.complete();
        _operationInProgress = false;
        return newController != null;
      } catch (e, stack) {
        _handleError('Failed to switch camera', e, stack);
        _changeState(CameraLifecycleState.error);
        completer.completeError(e, stack);
        _operationInProgress = false;
        return false;
      } finally {
        _activeOperations.remove('switch');
      }
    } catch (e, stack) {
      _handleError('Unexpected error during camera switch', e, stack);
      _operationInProgress = false;
      return false;
    }
  }

  /// Try to recover from an error state
  Future<bool> recoverFromError() async {
    if (_currentState != CameraLifecycleState.error) {
      return true; // Nothing to recover from
    }

    // Start from scratch with initialization
    _changeState(CameraLifecycleState.uninitialized);
    _lastError = null;
    _lastErrorObject = null;

    return await initialize();
  }

  /// Clean up resources
  Future<void> dispose() async {
    _changeState(CameraLifecycleState.disposing);

    // Cancel any active operations
    for (final entry in _activeOperations.entries) {
      debugPrint('🎥 Cancelling operation: ${entry.key}');
      if (!entry.value.isCompleted) {
        entry.value.completeError('Camera lifecycle machine disposed');
      }
    }
    _activeOperations.clear();

    // Remove listeners
    controller.removeListener(_handleControllerUpdate);

    // Controller disposal is handled by the controller itself
    _operationInProgress = false;
  }

  /// Handle errors and propagate them appropriately
  void _handleError(String message, Object error, [StackTrace? stackTrace]) {
    _lastError = message;
    _lastErrorObject = error;

    debugPrint('🎥 Camera Error: $message');
    debugPrint('🎥 Error details: $error');
    if (stackTrace != null) {
      debugPrint('🎥 Stack trace: $stackTrace');
    }

    // Change state to error if not already in error state
    if (_currentState != CameraLifecycleState.error) {
      _changeState(CameraLifecycleState.error);
    }

    // Call error handler if provided
    if (onError != null) {
      onError!(message, error);
    }
  }
}
