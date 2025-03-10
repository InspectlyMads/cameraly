import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../cameraly_controller.dart';
import '../../types/camera_mode.dart';
import '../models/cameraly_overlay_state.dart';

class CameralyOverlayController extends ChangeNotifier {
  CameralyOverlayController({
    required this.controller,
    required this.maxVideoDuration,
    this.onStateChanged,
  }) {
    _initialize();
  }

  final CameralyController controller;
  final Duration? maxVideoDuration;
  final Function(CameralyOverlayState)? onStateChanged;

  bool _isFrontCamera = false;
  bool _isVideoMode = false;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.auto;
  bool _torchEnabled = false;
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  double _currentZoom = 1.0;
  bool _showZoomSlider = false;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  Timer? _focusTimer;
  Timer? _zoomSliderTimer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingLimitTimer;
  final ImagePicker _imagePicker = ImagePicker();

  bool get isFrontCamera => _isFrontCamera;
  bool get isVideoMode => _isVideoMode;
  bool get isRecording => _isRecording;
  FlashMode get flashMode => _flashMode;
  bool get torchEnabled => _torchEnabled;
  Offset? get focusPoint => _focusPoint;
  bool get showFocusCircle => _showFocusCircle;
  double get currentZoom => _currentZoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  bool get showZoomSlider => _showZoomSlider;
  Duration get recordingDuration => _recordingDuration;
  bool get hasVideoDurationLimit => maxVideoDuration != null;

  void _initialize() {
    _flashMode = controller.settings.flashMode;
    _isFrontCamera = controller.description.lensDirection == CameraLensDirection.front;
    _torchEnabled = false;

    switch (controller.settings.cameraMode) {
      case CameraMode.photoOnly:
        _isVideoMode = false;
        break;
      case CameraMode.videoOnly:
        _isVideoMode = true;
        break;
      case CameraMode.both:
        break;
    }

    controller.addListener(_handleControllerUpdate);
    _initializeValues();
    _notifyStateChanged();
  }

  Future<void> _initializeValues() async {
    _currentZoom = controller.value.zoomLevel;
    _minZoom = await controller.getMinZoomLevel();
    _maxZoom = await controller.getMaxZoomLevel();
  }

  void _handleControllerUpdate() {
    final value = controller.value;

    if (value.isRecordingVideo != _isRecording) {
      _isRecording = value.isRecordingVideo;
      if (_isRecording) {
        _startRecordingTimer();
        if (hasVideoDurationLimit) {
          _startRecordingLimitTimer();
        }
      } else {
        _stopRecordingTimer();
        _recordingLimitTimer?.cancel();
      }
      _notifyStateChanged();
      notifyListeners();
    }

    if (value.zoomLevel != _currentZoom) {
      _currentZoom = value.zoomLevel;
      if (!_showZoomSlider) {
        _showZoomSlider = true;
      }
      _zoomSliderTimer?.cancel();
      _zoomSliderTimer = Timer(const Duration(seconds: 3), () {
        _showZoomSlider = false;
        notifyListeners();
      });
      notifyListeners();
    }

    if (value.focusPoint != null && (value.focusPoint != _focusPoint || !_showFocusCircle)) {
      _focusPoint = value.focusPoint;
      _showFocusCircle = true;
      _focusTimer?.cancel();
      _focusTimer = Timer(const Duration(seconds: 2), () {
        _showFocusCircle = false;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration = Duration(seconds: timer.tick);
      _notifyStateChanged();
      notifyListeners();
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingDuration = Duration.zero;
  }

  void _startRecordingLimitTimer() {
    _recordingLimitTimer?.cancel();
    _recordingLimitTimer = Timer(maxVideoDuration!, () {
      if (_isRecording) {
        stopVideoRecording();
      }
    });
  }

  void _notifyStateChanged() {
    if (onStateChanged != null) {
      final state = CameralyOverlayState(
        isRecording: _isRecording,
        isVideoMode: _isVideoMode,
        isFrontCamera: _isFrontCamera,
        flashMode: _flashMode,
        torchEnabled: _torchEnabled,
        recordingDuration: _recordingDuration,
      );
      onStateChanged!(state);
    }
  }

  Future<void> toggleRecording() async {
    try {
      if (_isRecording) {
        await stopVideoRecording();
      } else {
        await startVideoRecording();
      }
    } catch (e) {
      debugPrint('Error toggling recording: $e');
      rethrow;
    }
  }

  Future<void> startVideoRecording() async {
    final currentTorchState = _torchEnabled;
    await controller.startVideoRecording();
    if (currentTorchState && !_isFrontCamera) {
      await controller.setFlashMode(FlashMode.torch);
    }
  }

  Future<XFile> stopVideoRecording() async {
    return await controller.stopVideoRecording();
  }

  Future<XFile> takePicture() async {
    try {
      if (!_isFrontCamera) {
        await controller.setFlashMode(_flashMode);
      }
      return await controller.takePicture();
    } catch (e) {
      debugPrint('Error taking picture: $e');
      rethrow;
    }
  }

  Future<void> switchCamera() async {
    try {
      final newController = await controller.switchCamera();
      if (newController != null) {
        final previousFlashMode = _flashMode;
        final previousTorchEnabled = _torchEnabled;

        _isFrontCamera = newController.description.lensDirection == CameraLensDirection.front;

        if (_isFrontCamera) {
          _flashMode = FlashMode.off;
          _torchEnabled = false;
        } else {
          _flashMode = previousFlashMode;
          _torchEnabled = previousTorchEnabled;
          await controller.setFlashMode(_flashMode);
        }

        _notifyStateChanged();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
      rethrow;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    await controller.setFlashMode(mode);
    _flashMode = mode;
    _notifyStateChanged();
    notifyListeners();
  }

  Future<void> toggleTorch() async {
    final newTorchState = !_torchEnabled;
    await controller.setFlashMode(newTorchState ? FlashMode.torch : FlashMode.off);
    _torchEnabled = newTorchState;
    _notifyStateChanged();
    notifyListeners();
  }

  void setVideoMode(bool isVideo) {
    _isVideoMode = isVideo;
    if (!_isFrontCamera) {
      controller.setFlashMode(_flashMode);
    }
    _torchEnabled = false;
    _notifyStateChanged();
    notifyListeners();
  }

  Future<List<XFile>> pickMedia({bool allowMultiple = true}) async {
    try {
      List<XFile> selectedMedia = [];

      switch (controller.settings.cameraMode) {
        case CameraMode.photoOnly:
          if (allowMultiple) {
            selectedMedia = await _imagePicker.pickMultiImage();
          } else {
            final image = await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) selectedMedia = [image];
          }
          break;

        case CameraMode.videoOnly:
          final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
          if (video != null) selectedMedia = [video];
          break;

        case CameraMode.both:
          if (allowMultiple) {
            selectedMedia = await _imagePicker.pickMultipleMedia();
          } else {
            final media = await _imagePicker.pickMedia();
            if (media != null) selectedMedia = [media];
          }
          break;
      }

      return selectedMedia;
    } catch (e) {
      debugPrint('Error picking media: $e');
      rethrow;
    }
  }

  Future<void> setZoomLevel(double zoom) async {
    try {
      await controller.setZoomLevel(zoom);
      _currentZoom = zoom;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
      rethrow;
    }
  }

  void toggleZoomSlider() {
    _showZoomSlider = !_showZoomSlider;
    if (_showZoomSlider) {
      _zoomSliderTimer?.cancel();
      _zoomSliderTimer = Timer(const Duration(seconds: 3), () {
        _showZoomSlider = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    _focusTimer?.cancel();
    _zoomSliderTimer?.cancel();
    _recordingTimer?.cancel();
    _recordingLimitTimer?.cancel();
    super.dispose();
  }
}
