import 'package:flutter/material.dart';
import 'dart:async';

class VideoRecordingOverlay extends StatefulWidget {
  const VideoRecordingOverlay({super.key});

  @override
  State<VideoRecordingOverlay> createState() => _VideoRecordingOverlayState();
}

class _VideoRecordingOverlayState extends State<VideoRecordingOverlay> {
  Timer? _timer;
  Duration _duration = Duration.zero;

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
      setState(() {
        _duration = Duration(seconds: timer.tick);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recording dot with pulsing animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.5),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart animation
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'REC ${_formatDuration(_duration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}