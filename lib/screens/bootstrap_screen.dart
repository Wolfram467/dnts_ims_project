import 'dart:ui';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BOOTSTRAP SCREEN: THE DNTS IDENTITY
/// Implements the high-performance initial paint (FCP) using the 
/// institutional logo and technical dot-grid background.
/// ═══════════════════════════════════════════════════════════════════════════

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Technical Dot-Grid Background
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _DotGridPainter(),
              ),
            ),
          ),
          
          // 2. Central Logo Composition
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Line: Main Logo Acronym
                const Text(
                  'DNTS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    height: 1.0,
                    fontFamily: 'sans-serif',
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bottom Line: Full Department Name
                const Text(
                  'Department of Network and Technical Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFamily: 'sans-serif',
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Subtle Progress Indicator to signal "Connection in Progress"
                const SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFE5E7EB),
                    color: Colors.black,
                    minHeight: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DOT GRID PAINTER
/// Renders a subtle, geometric light-grey dot pattern.
/// ═══════════════════════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  // Static cache to share points across potential re-builds during init
  static final Map<Size, List<Offset>> _pointCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const double spacing = 24.0;
    
    // Check cache for this specific viewport size
    final List<Offset> points = _pointCache.putIfAbsent(size, () {
      final List<Offset> generated = [];
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          generated.add(Offset(x, y));
        }
      }
      return generated;
    });
    
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
