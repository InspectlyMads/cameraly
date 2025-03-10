import 'package:flutter/material.dart';

class RecordingTimer extends StatelessWidget {
  const RecordingTimer({
    super.key,
    required this.duration,
    required this.maxDuration,
    this.showProgressBar = true,
  });

  final Duration duration;
  final Duration? maxDuration;
  final bool showProgressBar;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hasMaxDuration = maxDuration != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.4 * 255).round()),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasMaxDuration ? '${_formatDuration(duration)} / ${_formatDuration(maxDuration!)}' : _formatDuration(duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        if (showProgressBar && hasMaxDuration) ...[
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.4 * 255).round()),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: duration.inMilliseconds / maxDuration!.inMilliseconds,
              child: Container(
                decoration: BoxDecoration(
                  color: duration.inSeconds > (maxDuration!.inSeconds * 0.8) ? Colors.red : Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
