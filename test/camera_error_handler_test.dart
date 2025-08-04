import 'package:flutter_test/flutter_test.dart';
import 'package:cameraly/cameraly.dart';
import 'package:cameraly/src/services/camera_error_handler.dart';
import 'package:camera/camera.dart';

void main() {
  group('CameraErrorHandler Tests', () {
    group('analyzeError', () {
      test('handles CameraAccessDenied exception', () {
        final error = CameraException(
          'CameraAccessDenied',
          'Camera access was denied',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.permissionDenied);
        expect(errorInfo.message, 'Camera access was denied');
        expect(errorInfo.userMessage, 'Camera permission is required to use this feature');
        expect(errorInfo.isRecoverable, isTrue);
        expect(errorInfo.retryDelay, const Duration(milliseconds: 500));
      });
      
      test('handles CameraAccessDeniedWithoutPrompt exception', () {
        final error = CameraException(
          'CameraAccessDeniedWithoutPrompt',
          'Camera access was denied without prompt',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.permissionDenied);
        expect(errorInfo.isRecoverable, isTrue);
      });
      
      test('handles CameraAccessRestricted exception', () {
        final error = CameraException(
          'CameraAccessRestricted',
          'Camera access is restricted',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.permissionDenied);
        expect(errorInfo.isRecoverable, isTrue);
      });
      
      test('handles cameraNotFound exception', () {
        final error = CameraException(
          'cameraNotFound',
          'No camera found on device',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.cameraNotFound);
        expect(errorInfo.message, 'No camera found on device');
        expect(errorInfo.userMessage, 'No camera was found on this device');
        expect(errorInfo.isRecoverable, isFalse);
      });
      
      test('handles noCamerasAvailable exception', () {
        final error = CameraException(
          'noCamerasAvailable',
          'No cameras available',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.cameraNotFound);
        expect(errorInfo.isRecoverable, isFalse);
      });
      
      test('handles cameraInitializationFailed exception', () {
        final error = CameraException(
          'cameraInitializationFailed',
          'Failed to initialize camera',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.initialization);
        expect(errorInfo.message, 'Failed to initialize camera');
        expect(errorInfo.userMessage, 'Failed to start the camera. Please try again.');
        expect(errorInfo.isRecoverable, isTrue);
        expect(errorInfo.retryDelay, const Duration(seconds: 1));
      });
      
      test('handles cameraNotRunning exception', () {
        final error = CameraException(
          'cameraNotRunning',
          'Camera is not running',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.initialization);
        expect(errorInfo.isRecoverable, isTrue);
      });
      
      test('handles videoRecordingFailed exception', () {
        final error = CameraException(
          'videoRecordingFailed',
          'Video recording failed',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.recording);
        expect(errorInfo.message, 'Video recording failed');
        expect(errorInfo.userMessage, 'Failed to capture media. Please try again.');
        expect(errorInfo.isRecoverable, isTrue);
        expect(errorInfo.retryDelay, const Duration(milliseconds: 500));
      });
      
      test('handles imageCaptureFailed exception', () {
        final error = CameraException(
          'imageCaptureFailed',
          'Image capture failed',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.recording);
        expect(errorInfo.isRecoverable, isTrue);
      });
      
      test('handles unknown CameraException', () {
        final error = CameraException(
          'unknownError',
          'An unknown error occurred',
        );
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.unknown);
        expect(errorInfo.message, 'unknownError: An unknown error occurred');
        expect(errorInfo.userMessage, 'Camera error: unknownError');
        expect(errorInfo.isRecoverable, isTrue);
        expect(errorInfo.retryDelay, const Duration(seconds: 1));
      });
      
      test('handles generic error', () {
        final error = Exception('Generic error');
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.unknown);
        expect(errorInfo.message, error.toString());
        expect(errorInfo.userMessage, 'An unexpected error occurred');
        expect(errorInfo.isRecoverable, isTrue);
        expect(errorInfo.retryDelay, const Duration(seconds: 1));
      });
      
      test('handles CameraException with null description', () {
        final error = CameraException('CameraAccessDenied', null);
        
        final errorInfo = CameraErrorHandler.analyzeError(error);
        
        expect(errorInfo.type, CameraErrorType.permissionDenied);
        expect(errorInfo.message, 'Camera access denied');
      });
    });
    
    group('attemptRecovery', () {
      test('attempts recovery for permission denied with callback', () async {
        var callbackCalled = false;
        
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.permissionDenied,
          () {},
          permissionCallback: () async {
            callbackCalled = true;
          },
        );
        
        expect(callbackCalled, isTrue);
        expect(result, isTrue);
      });
      
      test('returns false for permission denied without callback', () async {
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.permissionDenied,
          () {},
        );
        
        expect(result, isFalse);
      });
      
      test('attempts recovery for initialization error', () async {
        var retryCalled = false;
        
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.initialization,
          () {
            retryCalled = true;
          },
        );
        
        expect(retryCalled, isTrue);
        expect(result, isTrue);
      });
      
      test('attempts recovery for recording error', () async {
        var retryCalled = false;
        
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.recording,
          () {
            retryCalled = true;
          },
        );
        
        expect(retryCalled, isTrue);
        expect(result, isTrue);
      });
      
      test('attempts recovery for capture error', () async {
        var retryCalled = false;
        
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.capture,
          () {
            retryCalled = true;
          },
        );
        
        expect(retryCalled, isTrue);
        expect(result, isTrue);
      });
      
      test('returns false for camera not found', () async {
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.cameraNotFound,
          () {},
        );
        
        expect(result, isFalse);
      });
      
      test('attempts recovery for unknown error', () async {
        var retryCalled = false;
        
        final result = await CameraErrorHandler.attemptRecovery(
          CameraErrorType.unknown,
          () {
            retryCalled = true;
          },
        );
        
        expect(retryCalled, isTrue);
        expect(result, isTrue);
      });
    });
    
    group('retryWithBackoff', () {
      test('succeeds on first attempt', () async {
        var attempts = 0;
        
        final result = await CameraErrorHandler.retryWithBackoff(
          operation: () async {
            attempts++;
            return 'success';
          },
        );
        
        expect(result, 'success');
        expect(attempts, 1);
      });
      
      test('retries on recoverable error', () async {
        var attempts = 0;
        
        final result = await CameraErrorHandler.retryWithBackoff(
          operation: () async {
            attempts++;
            if (attempts < 2) {
              throw CameraException('cameraInitializationFailed', 'Test error');
            }
            return 'success';
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
        );
        
        expect(result, 'success');
        expect(attempts, 2);
      });
      
      test('throws after max attempts', () async {
        var attempts = 0;
        
        expect(
          () async => await CameraErrorHandler.retryWithBackoff(
            operation: () async {
              attempts++;
              throw CameraException('cameraInitializationFailed', 'Test error');
            },
            maxAttempts: 3,
            initialDelay: const Duration(milliseconds: 10),
          ),
          throwsA(isA<CameraException>()),
        );
      });
      
      test('throws immediately on non-recoverable error', () async {
        var attempts = 0;
        
        await expectLater(
          () async {
            await CameraErrorHandler.retryWithBackoff(
              operation: () async {
                attempts++;
                throw CameraException('cameraNotFound', 'No camera');
              },
              maxAttempts: 3,
            );
          }(),
          throwsA(isA<CameraException>()),
        );
        
        expect(attempts, 1);
      });
      
      test('applies exponential backoff', () async {
        var attempts = 0;
        final attemptTimes = <DateTime>[];
        
        try {
          await CameraErrorHandler.retryWithBackoff(
            operation: () async {
              attempts++;
              attemptTimes.add(DateTime.now());
              throw CameraException('cameraInitializationFailed', 'Test error');
            },
            maxAttempts: 3,
            initialDelay: const Duration(milliseconds: 100),
          );
        } catch (_) {
          // Expected to fail
        }
        
        // Should have tried 3 times
        expect(attempts, 3);
        expect(attemptTimes.length, 3);
        
        // Verify delays between attempts increase
        if (attemptTimes.length >= 3) {
          final delay1 = attemptTimes[1].difference(attemptTimes[0]);
          final delay2 = attemptTimes[2].difference(attemptTimes[1]);
          
          // Second delay should be longer than first delay (exponential backoff)
          expect(delay2.inMilliseconds, greaterThan(delay1.inMilliseconds));
        }
      });
    });
  });
}