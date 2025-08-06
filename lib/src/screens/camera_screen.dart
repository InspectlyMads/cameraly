import 'dart:async';

import 'package:camera/camera.dart' as camera;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../localization/cameraly_localizations.dart';
import '../models/camera_custom_widgets.dart';
import '../models/camera_settings.dart';
import '../models/media_item.dart';
import '../providers/camera_providers.dart';
import '../providers/permission_providers.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../utils/orientation_ui_helper.dart';
import '../widgets/camera_grid_overlay.dart';
import '../widgets/camera_zoom_control.dart' show CameraZoomControl, CameraZoomControlState;
import '../widgets/focus_indicator.dart';
import '../widgets/permission_dialog.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final CameraMode initialMode;
  final bool showGridButton;
  final bool showGalleryButton;
  final bool showCheckButton;
  final bool captureLocationMetadata;
  final bool autoSaveToGallery;

  /// Custom widgets configuration
  final CameraCustomWidgets? customWidgets;

  /// Optional video duration limit in seconds
  final int? videoDurationLimit;

  /// Camera settings for quality, aspect ratio, etc.
  final CameraSettings? settings;

  final Function(MediaItem)? onMediaCaptured;
  final Function()? onGalleryPressed;
  final Function()? onCheckPressed;
  final Function(String)? onError;

  const CameraScreen({
    super.key,
    required this.initialMode,
    this.showGridButton = false,
    this.showGalleryButton = true,
    this.showCheckButton = true,
    this.captureLocationMetadata = true,
    this.autoSaveToGallery = false,
    this.customWidgets,
    this.videoDurationLimit,
    this.settings,
    this.onMediaCaptured,
    this.onGalleryPressed,
    this.onCheckPressed,
    this.onError,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  bool _hasInitializationFailed = false;
  bool _isPinching = false;
  double _baseZoom = 1.0;
  Offset? _focusPoint;
  DateTime? _lastScaleUpdateTime;
  Timer? _videoDurationTimer;
  Timer? _videoCountdownTimer;
  int _remainingSeconds = 0;
  int _recordingSeconds = 0;
  Timer? _photoTimer;
  int _photoTimerCountdown = 0;

  // Capture throttling
  bool _isCapturing = false;

  // Add a key to access zoom control state
  final GlobalKey<CameraZoomControlState> _zoomControlKey = GlobalKey();

  // Orientation handling
  DateTime? _lastOrientationChange;
  Timer? _orientationDebounceTimer;

  // Track if camera has been initialized at least once
  bool _hasBeenInitializedOnce = false;

  // Track if app is in foreground to prevent orientation handling during app resume
  bool _isInForeground = true;

  // Track if we're reinitializing camera after Android background
  bool _isReinitializingAfterBackground = false;
  
  // Track if permission dialog is showing
  bool _isShowingPermissionDialog = false;
  bool _wentToSettings = false;
  bool _isReinitializingAfterSettings = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize camera with the specified mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithMode();
    });
  }

  @override
  void dispose() {
    // Cancel timers first
    _videoDurationTimer?.cancel();
    _videoCountdownTimer?.cancel();
    _photoTimer?.cancel();
    _orientationDebounceTimer?.cancel();

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    // Note: Camera disposal is handled by the provider's own lifecycle
    // We don't access ref here to avoid "Cannot use ref after widget was disposed" errors
    debugPrint('🔄 CameraScreen dispose: widget cleanup complete');

    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check if widget is still mounted before accessing ref
    if (!mounted) return;

    try {
      final cameraController = ref.read(cameraControllerProvider.notifier);
      final cameraState = ref.read(cameraControllerProvider);

      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _isInForeground = false;
          debugPrint('📱 App going to background (state: $state)');
          // Stop recording if in progress
          if (cameraState.isRecording) {
            cameraController.stopVideoRecording();
          }
          // On Android, dispose camera completely to avoid timeout issues
          if (Theme.of(context).platform == TargetPlatform.android) {
            debugPrint('🔄 Android: Disposing camera completely');
            setState(() {
              _isReinitializingAfterBackground = true;
            });
            cameraController.disposeCamera();
          } else {
            // On iOS, pause is usually sufficient
            debugPrint('🔄 iOS: Pausing camera preview');
            cameraController.pauseCamera();
          }
          break;
        case AppLifecycleState.resumed:
          _isInForeground = true;
          debugPrint('🔄 App resumed - attempting to resume camera');
          
          // Check if we're returning from settings
          if (_wentToSettings) {
            _wentToSettings = false;
            debugPrint('🔄 Returning from settings, checking permissions...');
            
            // Clear any error state first
            ref.read(cameraControllerProvider.notifier).clearError();
            
            // Reset the initialization flags and mark that we're reinitializing
            setState(() {
              _hasInitializationFailed = false;
              _isReinitializingAfterSettings = true;
              // Don't set _hasBeenInitializedOnce here - let it be set naturally when camera initializes
            });
            
            // Use longer delay for production apps and add retry mechanism
            // Initial delay is longer to ensure app is fully resumed
            Future.delayed(const Duration(milliseconds: 1500), () async {
              if (mounted) {
                final permissionService = ref.read(permissionServiceProvider);
                final hasPermissions = await permissionService.hasRequiredPermissionsForMode(widget.initialMode);
                
                if (hasPermissions) {
                  debugPrint('✅ Permissions granted, initializing camera...');
                  
                  // Try to initialize with retry mechanism
                  int retryCount = 0;
                  const maxRetries = 3;
                  
                  while (retryCount < maxRetries && mounted) {
                    try {
                      await _initializeWithMode();
                      
                      // Wait a bit to ensure camera is ready
                      await Future.delayed(const Duration(milliseconds: 300));
                      
                      // Check if camera is actually initialized
                      final cameraState = ref.read(cameraControllerProvider);
                      if (cameraState.isInitialized && cameraState.controller != null) {
                        debugPrint('✅ Camera initialized successfully after ${retryCount + 1} attempt(s)');
                        if (mounted) {
                          setState(() {
                            _isReinitializingAfterSettings = false;
                          });
                        }
                        break;
                      } else {
                        throw Exception('Camera not fully initialized');
                      }
                    } catch (e) {
                      retryCount++;
                      debugPrint('⚠️ Camera initialization attempt $retryCount failed: $e');
                      
                      if (retryCount < maxRetries) {
                        // Wait before retrying, with increasing delays
                        await Future.delayed(Duration(milliseconds: 500 * retryCount));
                      } else {
                        // Max retries reached, clear flag and show error
                        debugPrint('❌ Failed to initialize camera after $maxRetries attempts');
                        if (mounted) {
                          setState(() {
                            _isReinitializingAfterSettings = false;
                          });
                        }
                      }
                    }
                  }
                } else {
                  debugPrint('❌ Permissions still denied, showing dialog...');
                  setState(() {
                    _isReinitializingAfterSettings = false;
                  });
                  _showPermissionDialog();
                }
              }
            });
            return;
          }

          // On Android, we need longer delay and full reinitialization
          final isAndroid = Theme.of(context).platform == TargetPlatform.android;
          // Use even longer delays for production apps
          final delay = isAndroid ? const Duration(milliseconds: 1200) : const Duration(milliseconds: 500);

          Future.delayed(delay, () async {
            if (mounted) {
              debugPrint('🔄 Starting camera resume after delay (Android: $isAndroid)');

              if (isAndroid) {
                // On Android, always reinitialize since we disposed the camera
                debugPrint('🔄 Android: Full camera reinitialization');
                try {
                  await _initializeWithMode();
                  debugPrint('✅ Camera reinitialized successfully');
                  if (mounted) {
                    setState(() {
                      _isReinitializingAfterBackground = false;
                    });
                  }
                } catch (e) {
                  debugPrint('❌ Error reinitializing camera: $e');
                  if (mounted) {
                    setState(() {
                      _isReinitializingAfterBackground = false;
                    });
                    widget.onError?.call('Failed to restart camera. Please try again.');
                  }
                }
              } else {
                // On iOS, try to resume first
                try {
                  await cameraController.resumeCamera();
                  debugPrint('✅ Camera resumed successfully');
                } catch (e) {
                  debugPrint('❌ Error resuming camera: $e');
                  // Fallback to full initialization
                  if (mounted) {
                    debugPrint('🔄 iOS: Falling back to full reinitialization');
                    await _initializeWithMode();
                  }
                }
              }
            }
          });
          break;
        case AppLifecycleState.detached:
          break;
        case AppLifecycleState.hidden:
          _isInForeground = false;
          debugPrint('📱 App hidden (state: $state)');
          // Stop recording if in progress
          if (cameraState.isRecording) {
            cameraController.stopVideoRecording();
          }
          // Use same logic as paused state
          if (Theme.of(context).platform == TargetPlatform.android) {
            debugPrint('🔄 Android: Disposing camera completely (hidden)');
            setState(() {
              _isReinitializingAfterBackground = true;
            });
            cameraController.disposeCamera();
          } else {
            debugPrint('🔄 iOS: Pausing camera preview (hidden)');
            cameraController.pauseCamera();
          }
          break;
      }
    } catch (e) {
      // Widget disposed, ignore
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Handle orientation changes to fix camera surface issues
    if (!mounted) return;

    // Skip if app is not in foreground (prevents interference with app resume)
    if (!_isInForeground) {
      debugPrint('📱 Skipping metrics change - app not in foreground');
      return;
    }

    // Cancel any pending orientation change
    _orientationDebounceTimer?.cancel();

    // Debounce orientation changes to prevent multiple reinitializations
    // Reduced from 500ms to 250ms for faster response while still preventing bouncing
    _orientationDebounceTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted || !_isInForeground) return;

      try {
        final cameraState = ref.read(cameraControllerProvider);
        final cameraController = ref.read(cameraControllerProvider.notifier);

        // Only handle if camera is initialized and not recording or transitioning
        if (cameraState.isInitialized && !cameraState.isRecording && !cameraState.isLoading && !cameraState.isTransitioning && cameraState.controller != null) {
          // Check if enough time has passed since last orientation change
          final now = DateTime.now();
          if (_lastOrientationChange != null && now.difference(_lastOrientationChange!).inMilliseconds < 1000) {
            return;
          }

          _lastOrientationChange = now;

          // For Android, we need to handle surface changes during orientation
          if (Theme.of(context).platform == TargetPlatform.android) {
            debugPrint('🔄 Handling orientation change for Android');


            // This will reinitialize the camera to handle surface recreation
            await cameraController.updateCameraOrientation();
          }
        }
      } catch (e) {
        debugPrint('Error handling orientation change: $e');
      }
    });
  }

  Future<void> _initializeWithMode() async {
    // Prevent multiple initializations
    final cameraState = ref.read(cameraControllerProvider);
    if (cameraState.isLoading || cameraState.isInitialized) {
      debugPrint('⚠️ CameraScreen: Already ${cameraState.isLoading ? "initializing" : "initialized"}, skipping duplicate call');
      return;
    }

    setState(() {
      _hasInitializationFailed = false;
    });

    debugPrint('🚀 CameraScreen: Initializing with mode: ${widget.initialMode}');

    // Check permissions before initializing camera
    final permissionService = ref.read(permissionServiceProvider);
    final hasPermissions = await permissionService.hasRequiredPermissionsForMode(widget.initialMode);
    
    if (!hasPermissions && mounted) {
      debugPrint('🚀 CameraScreen: Permissions not granted, checking if permanently denied');
      
      // Check if permissions are permanently denied first
      final isPermanentlyDenied = await permissionService.arePermissionsPermanentlyDeniedForMode(widget.initialMode);
      
      if (isPermanentlyDenied) {
        debugPrint('🚀 CameraScreen: Permissions permanently denied, showing settings dialog');
        // Show dialog for permanently denied permissions
        _showPermissionDialog();
        return;
      }
      
      debugPrint('🚀 CameraScreen: Requesting permissions automatically');
      // Request permissions automatically
      final granted = await permissionService.requestPermissionsForMode(widget.initialMode);
      
      if (!granted && mounted) {
        debugPrint('🚀 CameraScreen: Permissions denied after request, showing dialog');
        // If still not granted after request, show dialog
        _showPermissionDialog();
        return;
      }
    }

    final cameraController = ref.read(cameraControllerProvider.notifier);
    await cameraController.switchMode(widget.initialMode);

    debugPrint('🚀 CameraScreen: Mode switched, now initializing camera');

    await cameraController.initializeCamera(
      captureLocationMetadata: widget.captureLocationMetadata,
      settings: widget.settings,
    );

    // Check if initialization failed due to permissions
    final updatedCameraState = ref.read(cameraControllerProvider);
    if (updatedCameraState.errorMessage != null && updatedCameraState.errorMessage!.contains('permissions')) {
      setState(() {
        _hasInitializationFailed = true;
        _isReinitializingAfterSettings = false; // Clear the flag on error
      });
    } else if (updatedCameraState.isInitialized) {
      // Clear the reinitializing flag on successful initialization
      setState(() {
        _isReinitializingAfterSettings = false;
      });
    }
  }

  Future<void> _retryInitialization() async {
    // Just retry initialization - let the initialization handle permission checks
    await _initializeWithMode();
  }

  Future<void> _handleBackPress() async {
    final cameraState = ref.read(cameraControllerProvider);

    // If recording, show confirmation dialog
    if (cameraState.isRecording) {
      final shouldStop = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(cameralyL10n.dialogStopRecordingTitle),
          content: Text(cameralyL10n.dialogStopRecordingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cameralyL10n.dialogContinueRecording),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(cameralyL10n.dialogStopAndDiscard),
            ),
          ],
        ),
      );

      if (shouldStop == true) {
        // Stop recording without saving
        await ref.read(cameraControllerProvider.notifier).stopVideoRecording();
        // Stop timers
        _videoDurationTimer?.cancel();
        _videoCountdownTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } else {
      // Not recording, can pop normally
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final cameraState = ref.read(cameraControllerProvider);

        // If recording, show confirmation dialog
        if (cameraState.isRecording) {
          final shouldStop = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(cameralyL10n.dialogStopRecordingTitle),
              content: Text(cameralyL10n.dialogStopRecordingMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cameralyL10n.dialogContinueRecording),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(cameralyL10n.dialogStopAndDiscard),
                ),
              ],
            ),
          );

          if (shouldStop == true) {
            // Stop recording without saving
            await ref.read(cameraControllerProvider.notifier).stopVideoRecording();
            // Stop timers
            _videoDurationTimer?.cancel();
            _videoCountdownTimer?.cancel();
            return true; // Allow pop
          }
          return false; // Prevent pop
        }

        return true; // Allow pop when not recording
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: _buildCameraInterface(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraInterface() {
    // Use selective watching to reduce rebuilds
    final isLoading = ref.watch(cameraControllerProvider.select((state) => state.isLoading));
    final errorMessage = ref.watch(cameraControllerProvider.select((state) => state.errorMessage));
    final isInitialized = ref.watch(cameraControllerProvider.select((state) => state.isInitialized));
    final hasController = ref.watch(cameraControllerProvider.select((state) => state.controller != null));
    final isTransitioning = ref.watch(cameraControllerProvider.select((state) => state.isTransitioning));

    // Update our initialization tracking
    if (isInitialized && hasController && !_hasBeenInitializedOnce) {
      _hasBeenInitializedOnce = true;
    }

    if ((isLoading && !_hasBeenInitializedOnce) || _isReinitializingAfterSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _buildErrorState(errorMessage);
    }

    // During orientation transitions, keep showing the camera UI
    // Only show initialization screen on first load
    if (!_hasBeenInitializedOnce && (!isInitialized || !hasController)) {
      return _buildPermissionOrInitializationState();
    }

    final cameraState = ref.watch(cameraControllerProvider);

    return OrientationBuilder(
      builder: (context, orientation) {
        return Stack(
          children: [
            // Camera preview with gesture detection
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                // Only process tap if not pinching and enough time has passed since last scale
                if (!_isPinching && (_lastScaleUpdateTime == null || DateTime.now().difference(_lastScaleUpdateTime!).inMilliseconds > 300)) {
                  _handleTapToFocus(details.localPosition, cameraState);
                }
              },
              onScaleStart: (details) {
                _baseZoom = cameraState.currentZoom;
                _lastScaleUpdateTime = DateTime.now();
              },
              onScaleUpdate: (details) {
                _lastScaleUpdateTime = DateTime.now();
                // Only treat as pinch if scale differs significantly from 1.0
                if ((details.scale - 1.0).abs() > 0.05) {
                  if (!_isPinching) {
                    _isPinching = true;
                    _zoomControlKey.currentState?.showSlider();
                  }

                  final newZoom = (_baseZoom * details.scale).clamp(cameraState.minZoom, cameraState.maxZoom);
                  ref.read(cameraControllerProvider.notifier).setZoomLevel(newZoom);
                }
              },
              onScaleEnd: (_) {
                if (_isPinching) {
                  _isPinching = false;
                  _zoomControlKey.currentState?.setPinching(false);
                }
              },
              child: Stack(
                children: [
                  // Camera preview - safely handle controller state
                  Builder(
                    builder: (context) {
                      // During transitions, Android reinitialization, or settings return, show black screen
                      if ((isTransitioning || _isReinitializingAfterBackground || _isReinitializingAfterSettings)) {
                        return Container(color: Colors.black);
                      }

                      // Show camera preview only if controller is available, initialized, and not reinitializing
                      if (cameraState.controller != null && 
                          cameraState.isInitialized && 
                          !_isReinitializingAfterBackground &&
                          !_isReinitializingAfterSettings &&
                          !cameraState.isLoading) {
                        // Additional safety check - verify controller is still valid
                        try {
                          if (cameraState.controller!.value.isInitialized) {
                            return _buildCameraPreview(cameraState.controller!);
                          }
                        } catch (e) {
                          debugPrint('⚠️ Camera controller check failed: $e');
                        }
                      }

                      return Container(color: Colors.black);
                    },
                  ),

                  // Show loading indicator during transitions, Android reinitialization, or settings return
                  if ((isTransitioning || _isReinitializingAfterBackground || _isReinitializingAfterSettings))
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                      ),
                    ),

                  // Grid overlay
                  if (cameraState.showGrid)
                    const CameraGridOverlay(
                      gridType: GridType.ruleOfThirds,
                      opacity: 0.3,
                    ),

                  // Focus indicator
                  if (_focusPoint != null)
                    FocusIndicator(
                      position: _focusPoint!,
                      onComplete: () {
                        setState(() {
                          _focusPoint = null;
                        });
                      },
                    ),
                ],
              ),
            ),

            // UI overlay - outside of GestureDetector
            _buildOrientationSpecificUI(orientation, cameraState),

            // Photo timer countdown overlay
            if (_photoTimerCountdown > 0) _buildPhotoTimerOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildOrientationSpecificUI(Orientation orientation, CameraState cameraState) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Special handling for video mode
    if (cameraState.mode == CameraMode.video) {
      return Stack(
        children: [
          // Top controls (back button and torch during recording)
          _buildTopControls(orientation),

          // Main controls
          if (orientation == Orientation.landscape)
            // Landscape video controls
            Positioned(
              right: 16 + safeArea.right,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button - hide during recording
                  if (!cameraState.isRecording) _buildGalleryButton() else const SizedBox(height: 60), // Maintain spacing

                  // Video record button
                  _buildVideoRecordButton(cameraState),

                  // Check button - hide during recording
                  if (!cameraState.isRecording) _buildCheckFab() else const SizedBox(height: 60), // Maintain spacing
                ],
              ),
            )
          else
            // Portrait video controls
            Positioned(
              bottom: 32 + safeArea.bottom,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button - hide during recording
                  if (!cameraState.isRecording) _buildGalleryButton() else const SizedBox(width: 60),

                  // Column for countdown and record button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show timer during recording
                      if (cameraState.isRecording) ...[
                        _buildVideoCountdown(),
                        const SizedBox(height: 8),
                      ],

                      // Video record button
                      _buildVideoRecordButton(cameraState),
                    ],
                  ),

                  // Check button - hide during recording
                  if (!cameraState.isRecording) _buildCheckFab() else const SizedBox(width: 60),
                ],
              ),
            ),

          // Flash and camera controls on left side (always visible in landscape)
          if (orientation == Orientation.landscape)
            Positioned(
              left: 16 + safeArea.left,
              top: 72 + safeArea.top, // Below back button
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFlashControl(),
                  const SizedBox(height: 8),
                  if (!cameraState.isRecording) _buildCameraSwitchControl(),
                ],
              ),
            ),

          // Timer during recording - positioned above center
          if (orientation == Orientation.landscape && cameraState.isRecording)
            Positioned(
              right: 16 + safeArea.right,
              top: screenSize.height / 2 - 100, // Above center
              child: _buildVideoCountdown(),
            ),

          // Zoom control for video mode
          _buildZoomControl(cameraState),
        ],
      );
    }

    return Stack(
      children: [
        // Top controls (same for both orientations)
        _buildTopControls(orientation),

        // Orientation-specific layout
        if (OrientationUIHelper.isLandscape(orientation)) _buildLandscapeUI(screenSize, safeArea, cameraState) else _buildPortraitUI(screenSize, safeArea, cameraState),
      ],
    );
  }

  Widget _buildCameraPreview(camera.CameraController controller) {
    // Check if controller is properly initialized and not disposed
    try {
      if (!controller.value.isInitialized) {
        return Container(color: Colors.black);
      }
    } catch (e) {
      // Controller is disposed, return black container
      debugPrint('⚠️ Camera controller is disposed, showing black screen');
      return Container(color: Colors.black);
    }

    final orientation = MediaQuery.of(context).orientation;
    final cameraAspectRatio = controller.value.aspectRatio;
    final cameraState = ref.read(cameraControllerProvider);

    // Always use the native camera aspect ratio (no stretching)
    final adjustedAspectRatio = orientation == Orientation.portrait ? 1 / cameraAspectRatio : cameraAspectRatio;

    Widget preview;
    try {
      preview = Center(
        child: AspectRatio(
          aspectRatio: adjustedAspectRatio,
          child: camera.CameraPreview(controller),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error building camera preview: $e');
      return Container(color: Colors.black);
    }

    // Mirror the preview for front camera on Android only
    // iOS handles this automatically
    if (defaultTargetPlatform == TargetPlatform.android && cameraState.lensDirection == CameraLensDirection.front) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: preview,
      );
    }

    return preview;
  }


  Widget _buildTopControls(Orientation orientation) {
    final safeArea = MediaQuery.of(context).padding;
    final cameraState = ref.watch(cameraControllerProvider);
    final isRecording = cameraState.isRecording;

    // During recording, show only back button and torch control (torch only in portrait)
    if (isRecording) {
      return Positioned(
        top: 16 + safeArea.top,
        left: 16 + safeArea.left,
        right: 16 + safeArea.right,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button - use custom if provided
            widget.customWidgets?.backButton ??
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _handleBackPress(),
                  ),
                ),
            // Torch control only in portrait mode (landscape has it on the left side)
            if (orientation == Orientation.portrait || cameraState.mode != CameraMode.video) _buildFlashControl() else const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Positioned(
      top: 16 + safeArea.top,
      left: 16 + safeArea.left,
      right: 16 + safeArea.right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button - use custom if provided
          widget.customWidgets?.backButton ??
              CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

          // Right side controls - only show in portrait mode
          if (OrientationUIHelper.isPortrait(orientation)) _buildRightControlsColumn(),
        ],
      ),
    );
  }

  Widget _buildRightControlsColumn() {
    final cameraState = ref.watch(cameraControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Flash control
        _buildFlashControl(),

        const SizedBox(height: 8),

        // Camera switch - hide during recording
        if (!cameraState.isRecording) _buildCameraSwitchControl(),

        if (widget.showGridButton) ...[
          const SizedBox(height: 8),
          // Grid toggle
          _buildGridControl(),
        ],
      ],
    );
  }

  Widget _buildFlashControl() {
    final hasFlash = ref.watch(cameraHasFlashProvider);
    final cameraState = ref.watch(cameraControllerProvider);

    if (!hasFlash) {
      return const SizedBox(width: 48, height: 48); // Placeholder to maintain layout
    }

    // Get proper flash icon based on mode and state
    IconData flashIcon;
    if (cameraState.mode == CameraMode.video) {
      // Video mode: Off/Torch
      flashIcon = cameraState.videoFlashMode == VideoFlashMode.torch ? Icons.flashlight_on : Icons.flashlight_off;
    } else {
      // Photo mode: Off/Auto/On
      switch (cameraState.photoFlashMode) {
        case PhotoFlashMode.off:
          flashIcon = Icons.flash_off;
          break;
        case PhotoFlashMode.auto:
          flashIcon = Icons.flash_auto;
          break;
        case PhotoFlashMode.on:
          flashIcon = Icons.flash_on;
          break;
      }
    }

    // Use custom flash control if provided
    if (widget.customWidgets?.flashControl != null) {
      return widget.customWidgets!.flashControl!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 24,
        child: IconButton(
          icon: Icon(flashIcon, color: Colors.white),
          onPressed: () {
            ref.read(cameraControllerProvider.notifier).cycleFlashMode();
          },
        ),
      ),
    );
  }

  Widget _buildCameraSwitchControl() {
    final canSwitch = ref.watch(canSwitchCameraProvider);

    if (!canSwitch) {
      return const SizedBox(width: 48, height: 48); // Placeholder to maintain layout
    }

    // Use custom camera switcher if provided
    if (widget.customWidgets?.cameraSwitcher != null) {
      return widget.customWidgets!.cameraSwitcher!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 24,
        child: IconButton(
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          onPressed: () {
            ref.read(cameraControllerProvider.notifier).switchCamera();
          },
        ),
      ),
    );
  }

  Widget _buildGridControl() {
    final showGrid = ref.watch(cameraControllerProvider.select((state) => state.showGrid));

    // Use custom grid toggle if provided
    if (widget.customWidgets?.gridToggle != null) {
      return widget.customWidgets!.gridToggle!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 24,
        child: IconButton(
          icon: Icon(
            showGrid ? Icons.grid_on : Icons.grid_off,
            color: Colors.white,
          ),
          onPressed: () {
            ref.read(cameraControllerProvider.notifier).toggleGrid();
          },
        ),
      ),
    );
  }

  Widget _buildCaptureButton(CameraState cameraState) {
    if (cameraState.mode == CameraMode.photo) {
      // Photo mode button
      return _buildPhotoButton();
    } else if (cameraState.mode == CameraMode.video) {
      // Video mode button
      return _buildVideoRecordButton(cameraState);
    } else {
      // Combined mode - dynamic button based on selected mode
      return _isVideoModeSelected ? _buildVideoRecordButton(cameraState) : _buildPhotoButton();
    }
  }

  Widget _buildPhotoButton() {
    final cameraState = ref.watch(cameraControllerProvider);
    final isDisabled = _isCapturing || cameraState.isTransitioning;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) {
            HapticFeedback.lightImpact();
          }
        },
        onTap: isDisabled ? null : _takePhoto,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDisabled ? Colors.white54 : Colors.white,
                  width: 4,
                ),
              ),
            ),
            // Inner circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: _isCapturing ? 48 : 56,
              height: _isCapturing ? 48 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisabled ? Colors.white54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoRecordButton(CameraState cameraState) {
    final isRecording = cameraState.isRecording;
    const double size = 72.0;
    const double innerSize = 32.0;

    return GestureDetector(
      onTap: () {
        if (isRecording) {
          _stopVideoRecording();
        } else {
          _startVideoRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.white : Colors.transparent,
          border: Border.all(
            color: isRecording ? Colors.white : Colors.red,
            width: 4,
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isRecording ? 8 : (size - 16) / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isRecording ? innerSize : size - 16,
              height: isRecording ? innerSize : size - 16,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  bool get _isVideoModeSelected {
    // This is managed locally for combined mode
    // You might want to store this in a provider for persistence
    return false; // Default to photo mode
  }

  void _handleTapToFocus(Offset position, CameraState cameraState) {
    if (!cameraState.isInitialized || cameraState.controller == null) return;

    // Calculate relative position (0-1)
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(position);
    final Size size = renderBox.size;

    final double x = localPosition.dx / size.width;
    final double y = localPosition.dy / size.height;

    // Set focus point for UI
    setState(() {
      _focusPoint = position;
    });

    // Set actual camera focus
    ref.read(cameraControllerProvider.notifier).setFocusPoint(Offset(x, y));

    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  Widget _buildModeSelector() {
    // Use custom mode switcher if provided
    if (widget.customWidgets?.modeSwitcher != null) {
      return widget.customWidgets!.modeSwitcher!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeToggleButton('PHOTO', !_isVideoModeSelected),
        const SizedBox(width: 16),
        _buildModeToggleButton('VIDEO', _isVideoModeSelected),
      ],
    );
  }

  Widget _buildModeToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle mode locally
          // In a real implementation, this should update the camera mode
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow : Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    // Permission errors are now handled proactively in _initializeWithMode
    // so we shouldn't see them here, but just in case:
    if (errorMessage.toLowerCase().contains('permission') || 
        errorMessage.contains('Camera access') ||
        errorMessage.contains('Microphone access')) {
      // Just retry initialization which will handle permissions
      _initializeWithMode();
      
      // Return a loading screen while retrying
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
              const SizedBox(height: 16),
              Text(
                cameralyL10n.permissionRequesting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // For non-permission errors, show the error UI
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(cameraControllerProvider.notifier).clearError();
                _initializeWithMode();
              },
              child: Text(cameralyL10n.buttonRetry),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cameralyL10n.buttonGoBack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionOrInitializationState() {
    final cameraState = ref.watch(cameraControllerProvider);

    // Show different states based on the situation
    if (_hasInitializationFailed || (cameraState.errorMessage != null && cameraState.errorMessage!.contains('permission'))) {
      // For permission issues, we handle them in _initializeWithMode
      // Just show a loading state here
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
              const SizedBox(height: 16),
              Text(
                cameralyL10n.permissionRequesting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            cameralyL10n.statusInitializingCamera,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cameralyL10n.statusSettingUpCamera,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),

          // Retry button if initialization is taking too long
          TextButton(
            onPressed: () async {
              await _retryInitialization();
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    // Prevent multiple captures
    if (_isCapturing) return;

    // Check if camera is transitioning
    final cameraState = ref.read(cameraControllerProvider);
    if (cameraState.isTransitioning) return;

    // Check if photo timer is set
    final timerSeconds = widget.settings?.photoTimerSeconds;
    if (timerSeconds != null && timerSeconds > 0) {
      // Start timer countdown
      setState(() {
        _photoTimerCountdown = timerSeconds;
      });

      _photoTimer?.cancel();
      _photoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _photoTimerCountdown--;
        });

        // Play countdown sound if enabled
        if (widget.settings?.enableSounds ?? true) {
          HapticFeedback.lightImpact();
        }

        if (_photoTimerCountdown <= 0) {
          timer.cancel();
          _capturePhotoNow();
        }
      });
    } else {
      // Take photo immediately
      _capturePhotoNow();
    }
  }

  Future<void> _capturePhotoNow() async {
    // Prevent multiple captures
    if (_isCapturing) return;

    // Check if camera is transitioning
    final cameraState = ref.read(cameraControllerProvider);
    if (cameraState.isTransitioning) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Check storage space first (5MB should be enough for a photo)
      final hasSpace = await StorageService.hasEnoughSpace(requiredMB: 5);
      if (!hasSpace && mounted) {
        widget.onError?.call('Not enough storage space');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cameralyL10n.errorStorageFull),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final cameraController = ref.read(cameraControllerProvider.notifier);

      // Haptic feedback
      if (widget.settings?.enableHaptics ?? true) {
        HapticFeedback.mediumImpact();
      }

      final imageFile = await cameraController.takePicture();

      // Reset capture flag immediately after camera has taken the photo
      // This allows for faster consecutive captures
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }

      if (imageFile != null && mounted) {
        // Photo saved successfully
        final mediaItem = MediaItem(
          path: imageFile.path,
          type: MediaType.photo,
          capturedAt: DateTime.now(),
        );
        widget.onMediaCaptured?.call(mediaItem);
      } else if (imageFile == null && mounted) {
        // Photo capture succeeded but save failed
        widget.onError?.call('Failed to save photo');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cameralyL10n.errorCaptureFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error is logged in the camera provider, no need for UI notification
      widget.onError?.call(cameralyL10n.errorCaptureFailed);
      // Reset capture flag on error
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _startVideoRecording() async {
    // Check storage space first (need more for video)
    final requiredMB = widget.settings?.maxVideoSizeMB ?? 500;
    final hasSpace = await StorageService.hasEnoughSpace(requiredMB: requiredMB);
    if (!hasSpace && mounted) {
      widget.onError?.call(cameralyL10n.statusNotEnoughStorage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cameralyL10n.statusNotEnoughStorage),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final cameraController = ref.read(cameraControllerProvider.notifier);

    try {
      // Get current orientation and lock to it during recording
      if (!mounted) return;
      final currentOrientation = MediaQuery.of(context).orientation;
      if (currentOrientation == Orientation.portrait) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      // Haptic feedback
      HapticFeedback.mediumImpact();

      await cameraController.startVideoRecording();

      // Reset recording seconds
      setState(() {
        _recordingSeconds = 0;
        _remainingSeconds = widget.videoDurationLimit ?? 0;
      });

      // Start countdown timer that updates every second (for all recordings)
      _videoCountdownTimer?.cancel();
      _videoCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds = timer.tick;
          if (widget.videoDurationLimit != null && widget.videoDurationLimit! > 0) {
            _remainingSeconds = widget.videoDurationLimit! - timer.tick;
          }
        });
      });

      // Start duration timer if limit is set
      if (widget.videoDurationLimit != null && widget.videoDurationLimit! > 0) {
        _videoDurationTimer?.cancel();

        // Main timer that stops recording
        _videoDurationTimer = Timer(Duration(seconds: widget.videoDurationLimit!), () {
          // Auto-stop recording when duration limit is reached
          _stopVideoRecording();
        });
      }
    } catch (e) {
      // Restore orientation freedom on error
      await SystemChrome.setPreferredOrientations([]);

      // Error is logged in the camera provider, no need for UI notification

      widget.onError?.call('Failed to start recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    final cameraController = ref.read(cameraControllerProvider.notifier);

    try {
      // Cancel duration timers if active
      _videoDurationTimer?.cancel();
      _videoDurationTimer = null;
      _videoCountdownTimer?.cancel();
      _videoCountdownTimer = null;

      setState(() {
        _remainingSeconds = 0;
        _recordingSeconds = 0;
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();

      final videoFile = await cameraController.stopVideoRecording();

      // Restore orientation freedom after recording
      await SystemChrome.setPreferredOrientations([]);

      if (videoFile != null && mounted) {
        // Video saved successfully
        final mediaItem = MediaItem(
          path: videoFile.path,
          type: MediaType.video,
          capturedAt: DateTime.now(),
        );
        widget.onMediaCaptured?.call(mediaItem);
      }
    } catch (e) {
      // Restore orientation freedom on error
      await SystemChrome.setPreferredOrientations([]);

      // Error is logged in the camera provider, no need for UI notification

      widget.onError?.call('Failed to stop recording: $e');
    }
  }

  Widget _buildLandscapeUI(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    return Stack(
      children: [
        // Right-side capture button + mode info below it
        _buildLandscapeRightControls(screenSize, safeArea, cameraState),

        // Left-side controls (flash + switch buttons only)
        _buildLandscapeLeftControls(screenSize, safeArea, cameraState),

        // Mode selector for combined mode (bottom-center)
        if (cameraState.mode == CameraMode.combined) _buildLandscapeModeSelector(screenSize, safeArea),

        // Video timer during recording - positioned above the center
        if (cameraState.isRecording && cameraState.mode == CameraMode.video)
          Positioned(
            right: 16 + safeArea.right,
            top: screenSize.height / 2 - 100, // Above center
            child: _buildVideoCountdown(),
          ),

        // Zoom control
        _buildZoomControl(cameraState),
      ],
    );
  }

  Widget _buildLandscapeRightControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    // Check both our state and the controller's state to be absolutely sure
    final bool isActuallyRecording = cameraState.isRecording || (cameraState.controller?.value.isRecordingVideo ?? false);

// When recording, show stop button centered
    if (isActuallyRecording) {
      return Positioned(
        right: 16 + safeArea.right,
        top: 0,
        bottom: 0,
        child: Center(
          child: _buildCaptureButton(cameraState),
        ),
      );
    }

    // Normal state with gallery, capture, and check buttons
    return Positioned(
      right: 16 + safeArea.right,
      top: 0,
      bottom: 0,
      child: Column(
        // Normal state with all 3 elements
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery button
          _buildGalleryButton(),

          // Capture button
          _buildCaptureButton(cameraState),

          // Check FAB
          _buildCheckFab(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLeftControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    // Hide left controls during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }

    // Custom left side widget
    if (widget.customWidgets?.leftSideWidget != null) {
      return Positioned(
        left: 16 + safeArea.left,
        top: 72 + safeArea.top, // Below back button
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flash and camera controls in a column
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFlashControl(),
                const SizedBox(height: 8),
                if (!cameraState.isRecording) _buildCameraSwitchControl(),
                if (widget.showGridButton) ...[
                  const SizedBox(height: 8),
                  _buildGridControl(),
                ],
              ],
            ),
            const SizedBox(width: 16),
            // Custom widget to the right
            widget.customWidgets!.leftSideWidget!,
          ],
        ),
      );
    }

    // Default: just flash and camera controls
    return Positioned(
      left: 16 + safeArea.left,
      top: 72 + safeArea.top, // Below back button
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFlashControl(),
          const SizedBox(height: 8),
          if (!cameraState.isRecording) _buildCameraSwitchControl(),
          if (widget.showGridButton) ...[
            const SizedBox(height: 8),
            _buildGridControl(),
          ],
        ],
      ),
    );
  }

  Widget _buildLandscapeModeSelector(Size screenSize, EdgeInsets safeArea) {
    final cameraState = ref.watch(cameraControllerProvider);

    // Hide mode selector during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: safeArea.bottom + 16,
      child: Center(
        child: _buildModeSelector(),
      ),
    );
  }

  Widget _buildPortraitUI(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    return Stack(
      children: [
        // Bottom controls row
        _buildPortraitBottomControls(screenSize, safeArea, cameraState),

        // Mode selector for combined mode (above bottom controls)
        if (cameraState.mode == CameraMode.combined) _buildPortraitModeSelector(screenSize, safeArea),

        // Zoom control
        _buildZoomControl(cameraState),

        // Custom left side widget (if provided)
        if (widget.customWidgets?.leftSideWidget != null)
          Positioned(
            left: 16 + safeArea.left,
            top: 72 + safeArea.top, // Position just below back button (16 + 40 + 16)
            child: widget.customWidgets!.leftSideWidget!,
          ),
      ],
    );
  }

  Widget _buildPortraitBottomControls(Size screenSize, EdgeInsets safeArea, CameraState cameraState) {
    return Positioned(
      bottom: 32 + safeArea.bottom,
      left: safeArea.left,
      right: safeArea.right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button - hide during recording
          if (!cameraState.isRecording) _buildGalleryButton() else const SizedBox(width: 60),

          // Main capture button (always show)
          _buildCaptureButton(cameraState),

          // Check FAB - hide during recording
          if (!cameraState.isRecording) _buildCheckFab() else const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildPortraitModeSelector(Size screenSize, EdgeInsets safeArea) {
    final cameraState = ref.watch(cameraControllerProvider);

    // Hide mode selector during recording
    if (cameraState.isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 140 + safeArea.bottom,
      left: 0,
      right: 0,
      child: Center(
        child: _buildModeSelector(),
      ),
    );
  }

  Widget _buildGalleryButton() {
    // Use custom gallery button if provided
    if (widget.customWidgets?.galleryButton != null) {
      return widget.customWidgets!.galleryButton!;
    }

    if (!widget.showGalleryButton) {
      return const SizedBox(width: 60);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          widget.onGalleryPressed?.call();
        },
        child: const Icon(
          Icons.photo_library,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCheckFab() {
    // Use custom check button if provided
    if (widget.customWidgets?.checkButton != null) {
      return widget.customWidgets!.checkButton!;
    }

    if (!widget.showCheckButton) {
      return const SizedBox(width: 60);
    }

    return CircleAvatar(
      backgroundColor: Colors.green,
      radius: 30,
      child: IconButton(
        icon: const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () {
          if (widget.onCheckPressed != null) {
            widget.onCheckPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildVideoCountdown() {
    // Format elapsed time as MM:SS
    final minutes = _recordingSeconds ~/ 60;
    final seconds = _recordingSeconds % 60;
    final elapsedTime = cameralyL10n.recordingDuration('${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');

    // Check if we should show countdown
    final hasLimit = widget.videoDurationLimit != null && widget.videoDurationLimit! > 0;
    final showCountdown = hasLimit && _remainingSeconds <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: showCountdown && _remainingSeconds <= 5 ? Colors.red : Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always show elapsed time
          Text(
            elapsedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Show countdown when approaching limit
          if (showCountdown) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              cameralyL10n.recordingCountdown(_remainingSeconds),
              style: TextStyle(
                color: _remainingSeconds <= 5 ? Colors.white : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoTimerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                cameralyL10n.photoTimerCountdown(_photoTimerCountdown),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControl(CameraState cameraState) {
    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const SizedBox.shrink();
    }

    final orientation = MediaQuery.of(context).orientation;
    final safeArea = MediaQuery.of(context).padding;

    // Position zoom control based on orientation
    if (orientation == Orientation.portrait) {
      // Portrait: above capture button, adjusted for different modes
      double bottomOffset;
      if (cameraState.mode == CameraMode.combined) {
        bottomOffset = 200 + safeArea.bottom; // Higher to avoid mode selector
      } else if (cameraState.mode == CameraMode.video && cameraState.isRecording) {
        bottomOffset = 180 + safeArea.bottom; // Higher to avoid timer overlap
      } else {
        bottomOffset = 140 + safeArea.bottom; // Normal position
      }

      return Positioned(
        bottom: bottomOffset,
        left: 0,
        right: 0,
        child: Center(
          child: CameraZoomControl(
            key: _zoomControlKey,
            currentZoom: cameraState.currentZoom,
            minZoom: cameraState.minZoom,
            maxZoom: cameraState.maxZoom,
            onZoomChanged: (zoom) {
              ref.read(cameraControllerProvider.notifier).setZoomLevel(zoom);
            },
          ),
        ),
      );
    } else {
      // Landscape: on the right side next to capture button
      return Positioned(
        right: 120 + safeArea.right, // Position to the left of the capture button column
        top: 0,
        bottom: 0,
        child: Center(
          child: CameraZoomControl(
            key: _zoomControlKey,
            currentZoom: cameraState.currentZoom,
            minZoom: cameraState.minZoom,
            maxZoom: cameraState.maxZoom,
            onZoomChanged: (zoom) {
              ref.read(cameraControllerProvider.notifier).setZoomLevel(zoom);
            },
          ),
        ),
      );
    }
  }

  Future<void> _showPermissionDialog() async {
    if (_isShowingPermissionDialog || !mounted) return;
    
    setState(() {
      _isShowingPermissionDialog = true;
    });

    // Clear any existing error before showing dialog
    ref.read(cameraControllerProvider.notifier).clearError();

    final permissionType = widget.initialMode == CameraMode.video 
        ? PermissionType.cameraAndMicrophone 
        : PermissionType.camera;
    
    // Check mounted before showing dialog
    if (!mounted) {
      _isShowingPermissionDialog = false;
      return;
    }
    
    // Show dialog only for permanently denied permissions
    // For normal denials, we've already requested automatically
    final dialogResult = await showCameralyPermissionDialog(
      context: context,
      permissionType: permissionType,
      showRequestButton: false, // Never show manual request button
      onOpenSettings: () {
        // Mark that we're going to settings
        _wentToSettings = true;
        // Don't await openAppSettings, just open it
        openAppSettings();
        // Close the dialog immediately
        if (mounted) {
          Navigator.of(context).pop('settings');
        }
      },
    );
    
    // Handle dialog result
    if (dialogResult == 'dismissed' && mounted) {
      // User explicitly closed the dialog, navigate back
      Navigator.of(context).pop();
      return;
    }

    // Check mounted after dialog closes
    if (!mounted) return;
    
    setState(() {
      _isShowingPermissionDialog = false;
    });
    
    // If user went to settings, the app lifecycle handler will take care of reinitializing
    // when the app resumes, so we don't need to do anything here
  }
}

/// Wrapper widget that provides the necessary ProviderScope for CameraScreen
/// This makes the package self-contained and easier to use
class CameraView extends StatelessWidget {
  final CameraMode initialMode;
  final bool showGridButton;
  final bool showGalleryButton;
  final bool showCheckButton;
  final bool captureLocationMetadata;
  final CameraCustomWidgets? customWidgets;
  final int? videoDurationLimit;
  final CameraSettings? settings;
  final Function(MediaItem)? onMediaCaptured;
  final Function()? onGalleryPressed;
  final Function()? onCheckPressed;
  final Function(String)? onError;

  const CameraView({
    super.key,
    required this.initialMode,
    this.showGridButton = false,
    this.showGalleryButton = true,
    this.showCheckButton = true,
    this.captureLocationMetadata = true,
    this.customWidgets,
    this.videoDurationLimit,
    this.settings,
    this.onMediaCaptured,
    this.onGalleryPressed,
    this.onCheckPressed,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: CameraScreen(
        initialMode: initialMode,
        showGridButton: showGridButton,
        showGalleryButton: showGalleryButton,
        showCheckButton: showCheckButton,
        captureLocationMetadata: captureLocationMetadata,
        customWidgets: customWidgets,
        videoDurationLimit: videoDurationLimit,
        settings: settings,
        onMediaCaptured: onMediaCaptured,
        onGalleryPressed: onGalleryPressed,
        onCheckPressed: onCheckPressed,
        onError: onError,
      ),
    );
  }
}
