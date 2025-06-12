import 'dart:async';
import 'package:flutter/material.dart';

/// A widget that displays a countdown timer without causing parent rebuilds
class CountdownWidget extends StatefulWidget {
  final int seconds;
  final TextStyle? textStyle;
  final Widget Function(int remaining)? builder;
  
  const CountdownWidget({
    super.key,
    required this.seconds,
    this.textStyle,
    this.builder,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(_remainingSeconds);
    }
    
    return Text(
      _remainingSeconds.toString(),
      style: widget.textStyle ?? const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// A widget that displays elapsed time without causing parent rebuilds
class ElapsedTimeWidget extends StatefulWidget {
  final TextStyle? textStyle;
  final bool showHours;
  
  const ElapsedTimeWidget({
    super.key,
    this.textStyle,
    this.showHours = false,
  });

  @override
  State<ElapsedTimeWidget> createState() => _ElapsedTimeWidgetState();
}

class _ElapsedTimeWidgetState extends State<ElapsedTimeWidget> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }
  
  String _formatTime() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    if (widget.showHours && hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(),
      style: widget.textStyle ?? const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// A widget that shows countdown from a limit
class CountdownFromLimitWidget extends StatefulWidget {
  final int limitSeconds;
  final TextStyle? textStyle;
  final Color? warningColor;
  final int warningThreshold;
  
  const CountdownFromLimitWidget({
    super.key,
    required this.limitSeconds,
    this.textStyle,
    this.warningColor = Colors.red,
    this.warningThreshold = 10,
  });

  @override
  State<CountdownFromLimitWidget> createState() => _CountdownFromLimitWidgetState();
}

class _CountdownFromLimitWidgetState extends State<CountdownFromLimitWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.limitSeconds;
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      }
    });
  }
  
  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final isWarning = _remainingSeconds <= widget.warningThreshold;
    
    return Text(
      _formatTime(),
      style: (widget.textStyle ?? const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      )).copyWith(
        color: isWarning ? widget.warningColor : null,
      ),
    );
  }
}