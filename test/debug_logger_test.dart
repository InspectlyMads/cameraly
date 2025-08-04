import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:cameraly/src/utils/debug_logger.dart';

void main() {
  group('DebugLogger Tests', () {
    test('DebugLogger has static methods', () {
      // Verify that all static methods exist and can be called
      expect(() => DebugLogger.log('test'), returnsNormally);
      expect(() => DebugLogger.error('test'), returnsNormally);
      expect(() => DebugLogger.warning('test'), returnsNormally);
      expect(() => DebugLogger.success('test'), returnsNormally);
      expect(() => DebugLogger.info('test'), returnsNormally);
    });
    
    test('DebugLogger.log accepts tag parameter', () {
      expect(() => DebugLogger.log('test message', tag: 'TEST'), returnsNormally);
    });
    
    test('DebugLogger.error accepts all parameters', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      
      expect(
        () => DebugLogger.error(
          'Error occurred',
          tag: 'ERROR_TEST',
          error: error,
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });
    
    test('DebugLogger.warning accepts tag parameter', () {
      expect(() => DebugLogger.warning('Warning message', tag: 'WARN'), returnsNormally);
    });
    
    test('DebugLogger.success accepts tag parameter', () {
      expect(() => DebugLogger.success('Success message', tag: 'SUCCESS'), returnsNormally);
    });
    
    test('DebugLogger.info accepts tag parameter', () {
      expect(() => DebugLogger.info('Info message', tag: 'INFO'), returnsNormally);
    });
    
    test('DebugLogger methods handle null tag gracefully', () {
      expect(() => DebugLogger.log('test'), returnsNormally);
      expect(() => DebugLogger.error('test'), returnsNormally);
      expect(() => DebugLogger.warning('test'), returnsNormally);
      expect(() => DebugLogger.success('test'), returnsNormally);
      expect(() => DebugLogger.info('test'), returnsNormally);
    });
    
    test('DebugLogger.error handles null error and stackTrace', () {
      expect(
        () => DebugLogger.error('Error message', tag: 'TEST'),
        returnsNormally,
      );
    });
    
    testWidgets('DebugLogger output verification', (WidgetTester tester) async {
      // Capture debug output
      final List<String> logs = [];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      
      // Test different log levels
      DebugLogger.log('Normal log');
      DebugLogger.log('Tagged log', tag: 'TAG');
      DebugLogger.error('Error log');
      DebugLogger.warning('Warning log');
      DebugLogger.success('Success log');
      DebugLogger.info('Info log');
      
      // Verify output format
      if (kDebugMode) {
        expect(logs, contains('Normal log'));
        expect(logs, contains('[TAG] Tagged log'));
        expect(logs.any((log) => log.contains('❌ Error log')), isTrue);
        expect(logs.any((log) => log.contains('⚠️ Warning log')), isTrue);
        expect(logs.any((log) => log.contains('✅ Success log')), isTrue);
        expect(logs.any((log) => log.contains('📍 Info log')), isTrue);
      } else {
        // In release mode, logs should be empty
        expect(logs, isEmpty);
      }
      
      // Reset debugPrint
      debugPrint = debugPrintSynchronously;
    });
    
    test('DebugLogger only logs in debug mode', () {
      // This test verifies that _enableLogs is based on kDebugMode
      // The actual logging behavior depends on whether tests run in debug or release mode
      
      final List<String> logs = [];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      
      DebugLogger.log('Test message');
      
      if (kDebugMode) {
        expect(logs, isNotEmpty);
      } else {
        expect(logs, isEmpty);
      }
      
      // Reset debugPrint
      debugPrint = debugPrintSynchronously;
    });
  });
}