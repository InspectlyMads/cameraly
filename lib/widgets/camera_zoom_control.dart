import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZoomLevel {
  final double value;
  final String label;
  
  const ZoomLevel({required this.value, required this.label});
}

class CameraZoomControl extends StatefulWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback? onZoomStart;
  final VoidCallback? onZoomEnd;
  
  const CameraZoomControl({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    this.onZoomStart,
    this.onZoomEnd,
  });

  @override
  State<CameraZoomControl> createState() => _CameraZoomControlState();
}

class _CameraZoomControlState extends State<CameraZoomControl> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isPinching = false;
  bool _isSliderVisible = false;
  bool _isInteractingWithSlider = false;
  double _initialScale = 1.0;
  
  // Define zoom presets based on max zoom
  late List<ZoomLevel> _zoomPresets;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Initialize zoom presets based on device capabilities
    _initializeZoomPresets();
  }
  
  @override
  void didUpdateWidget(CameraZoomControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize presets if zoom range changed
    if (oldWidget.minZoom != widget.minZoom || oldWidget.maxZoom != widget.maxZoom) {
      _initializeZoomPresets();
    }
  }
  
  void _initializeZoomPresets() {
    final presets = <ZoomLevel>[];
    
    // Check for ultra-wide support
    if (widget.minZoom <= 0.6) {
      // Always show .5 for consistency with native camera app
      // Even if controller reports slightly different value
      presets.add(const ZoomLevel(value: 0.5, label: '.5'));
    }
    
    // Always add 1x
    presets.add(const ZoomLevel(value: 1.0, label: '1'));
    
    // Add 2x if supported
    if (widget.maxZoom >= 2.0) {
      presets.add(const ZoomLevel(value: 2.0, label: '2'));
    }
    
    // For higher zoom levels, be more selective based on actual max zoom
    // Only show presets that make sense for the device
    
    // 5x preset for devices with telephoto (Pixel Pro models typically support 5x optical)
    // Show if max zoom is at least 5x
    if (widget.maxZoom >= 5.0) {
      presets.add(const ZoomLevel(value: 5.0, label: '5'));
    }
    
    // Don't show intermediate zoom levels like 8x for typical devices
    // Only show 10x+ for devices with real telephoto capability
    if (widget.maxZoom >= 10.0) {
      presets.add(const ZoomLevel(value: 10.0, label: '10'));
      
      // Only show extreme zoom levels if truly supported
      if (widget.maxZoom >= 20.0) {
        presets.add(const ZoomLevel(value: 20.0, label: '20'));
      }
      
      if (widget.maxZoom >= 30.0) {
        presets.add(const ZoomLevel(value: 30.0, label: '30'));
      }
    }
    
    _zoomPresets = presets;
    
    debugPrint('Zoom presets initialized: ${presets.map((p) => '${p.label}x').join(', ')} (max: ${widget.maxZoom}x)');
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _showSlider() {
    if (!_isSliderVisible) {
      setState(() {
        _isSliderVisible = true;
      });
      _animationController.forward();
      widget.onZoomStart?.call();
    }
  }
  
  void _hideSlider() {
    if (_isSliderVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSliderVisible = false;
          });
        }
      });
      widget.onZoomEnd?.call();
    }
  }
  
  // Find the closest preset to current zoom level
  ZoomLevel? _getActivePreset() {
    if (_zoomPresets.isEmpty) return null;
    
    ZoomLevel closest = _zoomPresets.first;
    double minDiff = (widget.currentZoom - closest.value).abs();
    
    for (final preset in _zoomPresets) {
      final diff = (widget.currentZoom - preset.value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = preset;
      }
    }
    
    // Highlight the closest preset, with a slightly larger threshold for better UX
    return minDiff < 0.2 ? closest : null;
  }
  
  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final safeArea = MediaQuery.of(context).padding;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Important: allows taps to pass through
      onScaleStart: (details) {
        _initialScale = 1.0;
        // Don't show slider yet - wait for actual pinch movement
      },
      onScaleUpdate: (details) {
        // Only consider it a pinch if scale changes significantly from 1.0
        if ((details.scale - 1.0).abs() > 0.05) {
          if (!_isPinching) {
            _isPinching = true;
            _showSlider();
            _initialScale = widget.currentZoom;
          }
          
          // Convert scale to zoom change
          final newZoom = (_initialScale * details.scale)
              .clamp(widget.minZoom, widget.maxZoom);
          widget.onZoomChanged(newZoom);
        }
      },
      onScaleEnd: (_) {
        _isPinching = false;
        // Hide slider after a delay, but only if not interacting with it
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isPinching && !_isInteractingWithSlider) {
            _hideSlider();
          }
        });
      },
      child: Stack(
        children: [
          // Zoom preset buttons - position based on orientation
          if (orientation == Orientation.portrait)
            Positioned(
              bottom: 140 + safeArea.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isSliderVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildZoomButtons(),
                ),
              ),
            )
          else
            Positioned(
              right: 16 + safeArea.right,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isSliderVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildZoomButtons(),
                ),
              ),
            ),
          
          // Zoom slider/ruler - position same as buttons
          if (orientation == Orientation.portrait)
            Positioned(
              bottom: 140 + safeArea.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: _isSliderVisible ? _buildZoomSlider() : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            )
          else
            Positioned(
              right: 16 + safeArea.right,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: _isSliderVisible ? _buildZoomSlider() : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildZoomButtons() {
    final activePreset = _getActivePreset();
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Flex(
        direction: isPortrait ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: _zoomPresets.map((preset) {
          final isActive = activePreset?.value == preset.value;
          
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPortrait ? 2 : 0,
              vertical: isPortrait ? 0 : 2,
            ),
            child: _ZoomButton(
              label: preset.label,
              isActive: isActive,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onZoomChanged(preset.value);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildZoomSlider() {
    // Calculate slider dimensions based on orientation
    final orientation = MediaQuery.of(context).orientation;
    final sliderHeight = 40.0;
    final sliderWidth = orientation == Orientation.portrait ? 280.0 : 40.0;
    
    // Convert zoom to logarithmic scale for better UX
    final logMin = widget.minZoom > 0 ? math.log(widget.minZoom) : 0.0;
    final logMax = math.log(widget.maxZoom);
    final logCurrent = math.log(widget.currentZoom);
    final normalizedValue = (logCurrent - logMin) / (logMax - logMin);
    
    final isPortrait = orientation == Orientation.portrait;
    
    return Container(
      width: isPortrait ? sliderWidth : sliderHeight,
      height: isPortrait ? sliderHeight : sliderWidth,
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 16 : 8,
        vertical: isPortrait ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ruler marks
          CustomPaint(
            size: Size(
              isPortrait ? sliderWidth - 32 : sliderHeight - 16,
              isPortrait ? sliderHeight : sliderWidth - 32,
            ),
            painter: _ZoomRulerPainter(
              minZoom: widget.minZoom,
              maxZoom: widget.maxZoom,
              currentZoom: widget.currentZoom,
              presets: _zoomPresets,
            ),
          ),
          
          // Slider track
          if (isPortrait)
            Positioned(
              left: 0,
              right: 0,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                    elevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  overlayColor: Colors.white.withOpacity(0.3),
                ),
                child: Slider(
                  value: normalizedValue,
                  onChangeStart: (_) {
                    _isInteractingWithSlider = true;
                    _showSlider(); // Keep slider visible during interaction
                  },
                  onChanged: (value) {
                    // Convert back from normalized logarithmic scale
                    final logValue = logMin + (value * (logMax - logMin));
                    final zoom = math.exp(logValue).clamp(widget.minZoom, widget.maxZoom);
                    widget.onZoomChanged(zoom);
                  },
                  onChangeEnd: (_) {
                    _isInteractingWithSlider = false;
                    // Hide slider after interaction ends
                    Future.delayed(const Duration(seconds: 2), () {
                      if (!_isPinching && !_isInteractingWithSlider) {
                        _hideSlider();
                      }
                    });
                  },
                ),
              ),
            )
          else
            // Vertical slider for landscape
            Positioned(
              top: 0,
              bottom: 0,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    overlayColor: Colors.white.withOpacity(0.3),
                  ),
                  child: SizedBox(
                    width: sliderWidth - 32,
                    child: Slider(
                      value: normalizedValue,
                      onChangeStart: (_) {
                        _isInteractingWithSlider = true;
                        _showSlider(); // Keep slider visible during interaction
                      },
                      onChanged: (value) {
                        // Convert back from normalized logarithmic scale
                        final logValue = logMin + (value * (logMax - logMin));
                        final zoom = math.exp(logValue).clamp(widget.minZoom, widget.maxZoom);
                        widget.onZoomChanged(zoom);
                      },
                      onChangeEnd: (_) {
                        _isInteractingWithSlider = false;
                        // Hide slider after interaction ends
                        Future.delayed(const Duration(seconds: 2), () {
                          if (!_isPinching && !_isInteractingWithSlider) {
                            _hideSlider();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          
          // Current zoom indicator
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.currentZoom.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  
  const _ZoomButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ZoomRulerPainter extends CustomPainter {
  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final List<ZoomLevel> presets;
  
  _ZoomRulerPainter({
    required this.minZoom,
    required this.maxZoom,
    required this.currentZoom,
    required this.presets,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;
    
    // Draw ruler marks for each preset
    for (final preset in presets) {
      if (preset.value >= minZoom && preset.value <= maxZoom) {
        // Calculate position using logarithmic scale
        final logMin = minZoom > 0 ? math.log(minZoom) : 0.0;
        final logMax = math.log(maxZoom);
        final logValue = math.log(preset.value);
        final normalizedPos = (logValue - logMin) / (logMax - logMin);
        final x = normalizedPos * size.width;
        
        // Draw tick mark
        canvas.drawLine(
          Offset(x, size.height * 0.3),
          Offset(x, size.height * 0.7),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(_ZoomRulerPainter oldDelegate) {
    return oldDelegate.currentZoom != currentZoom ||
           oldDelegate.minZoom != minZoom ||
           oldDelegate.maxZoom != maxZoom;
  }
}