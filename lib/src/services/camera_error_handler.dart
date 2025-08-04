import 'package:camera/camera.dart';

enum CameraErrorType {
  permissionDenied,
  cameraNotFound,
  initialization,
  recording,
  capture,
  unknown,
}

class CameraErrorInfo {
  final CameraErrorType type;
  final String message;
  final String? userMessage;
  final bool isRecoverable;
  final Duration? retryDelay;

  const CameraErrorInfo({
    required this.type,
    required this.message,
    this.userMessage,
    this.isRecoverable = true,
    this.retryDelay,
  });
}

class CameraErrorHandler {

  /// Analyze error and return detailed error info
  static CameraErrorInfo analyzeError(Object error) {
    if (error is CameraException) {
      return _analyzeCameraException(error);
    }

    // Generic error
    return CameraErrorInfo(
      type: CameraErrorType.unknown,
      message: error.toString(),
      userMessage: 'An unexpected error occurred',
      isRecoverable: true,
      retryDelay: const Duration(seconds: 1),
    );
  }

  static CameraErrorInfo _analyzeCameraException(CameraException error) {


    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return CameraErrorInfo(
          type: CameraErrorType.permissionDenied,
          message: error.description ?? 'Camera access denied',
          userMessage: 'Camera permission is required to use this feature',
          isRecoverable: true,
          retryDelay: const Duration(milliseconds: 500),
        );

      case 'cameraNotFound':
      case 'noCamerasAvailable':
        return CameraErrorInfo(
          type: CameraErrorType.cameraNotFound,
          message: error.description ?? 'No camera found',
          userMessage: 'No camera was found on this device',
          isRecoverable: false,
        );

      case 'cameraInitializationFailed':
      case 'cameraNotRunning':
        return CameraErrorInfo(
          type: CameraErrorType.initialization,
          message: error.description ?? 'Failed to initialize camera',
          userMessage: 'Failed to start the camera. Please try again.',
          isRecoverable: true,
          retryDelay: const Duration(seconds: 1),
        );

      case 'videoRecordingFailed':
      case 'imageCaptureFailed':
        return CameraErrorInfo(
          type: CameraErrorType.recording,
          message: error.description ?? 'Recording failed',
          userMessage: 'Failed to capture media. Please try again.',
          isRecoverable: true,
          retryDelay: const Duration(milliseconds: 500),
        );

      default:
        return CameraErrorInfo(
          type: CameraErrorType.unknown,
          message: '${error.code}: ${error.description}',
          userMessage: 'Camera error: ${error.code}',
          isRecoverable: true,
          retryDelay: const Duration(seconds: 1),
        );
    }
  }

  /// Get recovery action for specific error type
  static Future<bool> attemptRecovery(
    CameraErrorType errorType,
    Function() retryCallback, {
    Function()? permissionCallback,
  }) async {
    switch (errorType) {
      case CameraErrorType.permissionDenied:
        if (permissionCallback != null) {
          await permissionCallback();
          return true;
        }
        return false;

      case CameraErrorType.initialization:
      case CameraErrorType.recording:
      case CameraErrorType.capture:
        // Retry with delay
        await Future.delayed(const Duration(seconds: 1));
        await retryCallback();
        return true;

      case CameraErrorType.cameraNotFound:
        // Not recoverable
        return false;

      case CameraErrorType.unknown:
        // Try once more
        await Future.delayed(const Duration(seconds: 2));
        await retryCallback();
        return true;
    }
  }

  /// Implement exponential backoff for retries
  static Future<T?> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        final errorInfo = analyzeError(e);
        
        if (!errorInfo.isRecoverable || attempt == maxAttempts - 1) {
          rethrow;
        }

        final delay = initialDelay * (attempt + 1);

        await Future.delayed(delay);
      }
    }
    return null;
  }
}