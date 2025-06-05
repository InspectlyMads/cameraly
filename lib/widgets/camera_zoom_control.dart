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
  State<CameraZoomControl> createState() => CameraZoomControlState();
}

// Export the state class so parent can control it
class CameraZoomControlState extends State<CameraZoomControl> 
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
      presets.add(const ZoomLevel(value: 0.5, label: '.5'));
    }
    
    // Always add 1x
    presets.add(const ZoomLevel(value: 1.0, label: '1'));
    
    // Add 2x if supported
    if (widget.maxZoom >= 2.0) {
      presets.add(const ZoomLevel(value: 2.0, label: '2'));
    }
    
    // 5x preset for devices with telephoto
    if (widget.maxZoom >= 5.0) {
      presets.add(const ZoomLevel(value: 5.0, label: '5'));
    }
    
    // Only show 10x+ for devices with real telephoto capability
    if (widget.maxZoom >= 10.0) {
      presets.add(const ZoomLevel(value: 10.0, label: '10'));
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
    
    // Highlight the closest preset
    return minDiff < 0.2 ? closest : null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Zoom preset buttons
        AnimatedOpacity(
          opacity: _isSliderVisible ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _buildZoomButtons(),
        ),
        
        // Zoom slider/ruler
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _isSliderVisible ? _buildZoomSlider() : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
  
  // Public methods for external control
  void showSlider() {
    _showSlider();
  }
  
  void setPinching(bool isPinching) {
    _isPinching = isPinching;
    if (!isPinching) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isPinching && !_isInteractingWithSlider) {
          _hideSlider();
        }
      });
    }
  }
  
  Widget _buildZoomButtons() {
    final activePreset = _getActivePreset();
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 4 : 2,
        vertical: isPortrait ? 4 : 2,
      ),
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
              vertical: isPortrait ? 0 : 1,
            ),
            child: _ZoomButton(
              label: preset.label,
              isActive: isActive,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onZoomChanged(preset.value);
              },
              isPortrait: isPortrait,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildZoomSlider() {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    
    // Convert zoom to logarithmic scale for better UX
    final logMin = widget.minZoom > 0 ? math.log(widget.minZoom) : 0.0;
    final logMax = math.log(widget.maxZoom);
    final logCurrent = math.log(widget.currentZoom);
    final normalizedValue = (logCurrent - logMin) / (logMax - logMin);
    
    if (isPortrait) {
      // Portrait: horizontal slider
      return _buildHorizontalSlider(normalizedValue, logMin, logMax);
    } else {
      // Landscape: vertical slider
      return _buildVerticalSlider(normalizedValue, logMin, logMax);
    }
  }
  
  Widget _buildHorizontalSlider(double value, double logMin, double logMax) {
    return Container(
      width: 280,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Slider
          SliderTheme(
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
              value: value,
              onChangeStart: (_) {
                _isInteractingWithSlider = true;
                _showSlider();
              },
              onChanged: (newValue) {
                final logValue = logMin + (newValue * (logMax - logMin));
                final zoom = math.exp(logValue).clamp(widget.minZoom, widget.maxZoom);
                widget.onZoomChanged(zoom);
              },
              onChangeEnd: (_) {
                _isInteractingWithSlider = false;
                Future.delayed(const Duration(seconds: 2), () {
                  if (!_isPinching && !_isInteractingWithSlider) {
                    _hideSlider();
                  }
                });
              },
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
  
  Widget _buildVerticalSlider(double value, double logMin, double logMax) {
    return Container(
      width: 40,
      height: 280,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical slider
          RotatedBox(
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
                width: 280 - 32,
                child: Slider(
                  value: value,
                  onChangeStart: (_) {
                    _isInteractingWithSlider = true;
                    _showSlider();
                  },
                  onChanged: (newValue) {
                    final logValue = logMin + (newValue * (logMax - logMin));
                    final zoom = math.exp(logValue).clamp(widget.minZoom, widget.maxZoom);
                    widget.onZoomChanged(zoom);
                  },
                  onChangeEnd: (_) {
                    _isInteractingWithSlider = false;
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
          
          // Current zoom indicator for vertical
          Positioned(
            left: 0,
            top: 0,
            child: RotatedBox(
              quarterTurns: 1,
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
  final bool isPortrait;
  
  const _ZoomButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isPortrait,
  });
  
  @override
  Widget build(BuildContext context) {
    // Smaller buttons in landscape mode
    final size = isPortrait ? 36.0 : 30.0;
    final fontSize = isPortrait ? 14.0 : 12.0;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontSize: fontSize,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}