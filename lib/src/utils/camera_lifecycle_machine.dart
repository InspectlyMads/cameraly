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
    if (_lastOrientationChange != null) {
      final elapsed = now.difference(_lastOrientationChange!).inMilliseconds;
      if (elapsed < 2500) {
        debugPrint('🎥 Orientation change too soon (${elapsed}ms), ignoring');
        return false;
      }
    }

    // Check if any camera anywhere is already resuming - if so, skip
    // We need to use a different approach since we can't access private static fields
    if (_activeOperations.containsKey('resume')) {
      debugPrint('🎥 Resume already in progress, skipping orientation change');
      return false;
    }

    // Check if orientation actually changed from current orientation
    if (controller.value.deviceOrientation == orientation) {
      debugPrint('🎥 Skipping orientation change - orientation unchanged: $orientation');
      return true; // Return success since no change was needed
    }

    // If we're already dealing with an orientation change, prevent duplicate
    if (_activeOperations.containsKey('orientation')) {
      debugPrint('🎥 Orientation change already in progress, ignoring duplicate');
      return false;
    }

    // Update the timestamp for orientation change
    _lastOrientationChange = now;

    _operationInProgress = true;
    final previousState = _currentState;
    _changeState(CameraLifecycleState.recreating);

    try {
      final completer = Completer<void>();
      _activeOperations['orientation'] = completer;

      try {
        // For Android, try using a more lightweight orientation update approach first
        if (Platform.isAndroid) {
          try {
            debugPrint('🎥 Trying lightweight orientation change first');
            // Try to just lock the capture orientation without full recreation
            await controller.cameraController?.lockCaptureOrientation(orientation);

            // Small delay to ensure the orientation change has applied
            await Future.delayed(const Duration(milliseconds: 100));

            // If that worked, update controller value but keep camera running
            controller.value = controller.value.copyWith(deviceOrientation: orientation);
            _changeState(CameraLifecycleState.ready);
            completer.complete();
            _operationInProgress = false;
            return true;
          } catch (e) {
            debugPrint('🎥 Simple orientation lock failed, falling back to full recreation: $e');
            // Fall back to full recreation
          }
        }

        // Use the controller's built-in orientation handling as fallback
        debugPrint('🎥 Using full camera recreation for orientation change');
        await controller.handleDeviceOrientationChange();
        _changeState(CameraLifecycleState.ready);
        completer.complete();
        _operationInProgress = false;
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

        // Android needs explicit pause
        if (Platform.isAndroid && controller.cameraController != null) {
          try {
            await controller.cameraController!.pausePreview();
          } catch (e) {
            debugPrint('📸 Error pausing camera: $e');
          }
        }
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
