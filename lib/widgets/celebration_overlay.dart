import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─── Public API ───────────────────────────────────────────────────────────────

class CelebrationOverlay {
  static void show(BuildContext context, Offset origin) {
    // Haptic fires immediately
    HapticFeedback.lightImpact();

    // Walk up the tree to find the nearest Overlay — safe even inside
    // Dismissible / ListView / Scaffold contexts
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    bool removed = false;

    entry = OverlayEntry(
      builder: (_) => _CelebrationWidget(
        origin: origin,
        onDone: () {
          if (!removed) {
            removed = true;
            entry.remove();
          }
        },
      ),
    );
    overlay.insert(entry);
  }
}

// ─── Particle ─────────────────────────────────────────────────────────────────

enum _Shape { rect, circle, ribbon }

class _Particle {
  double x, y;
  double vx, vy;
  double rotation;
  double rotSeed;
  Color color;
  double w, h;
  _Shape shape;
  double opacity = 1.0;   // field init — no constructor default needed

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotSeed,
    required this.color,
    required this.w,
    required this.h,
    required this.shape,
  });
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class _CelebrationWidget extends StatefulWidget {
  final Offset origin;
  final VoidCallback onDone;
  const _CelebrationWidget({required this.origin, required this.onDone});

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  double _lastT = 0.0;

  static const _colours = [
    AppColors.primary,
    AppColors.priorityLow,
    AppColors.priorityMedium,
    AppColors.overdueRed,
    Color(0xFFFFD60A),
    Color(0xFF00C7BE),
    Color(0xFFBF5AF2),
  ];

  static const double _gravity   = 780.0;
  static const double _drag      = 0.97;
  static const double _totalSecs = 1.6;
  static const double _fadeStart = 1.1;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalSecs * 1000).round()),
    )
      ..addListener(_tick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          widget.onDone();
        }
      })
      ..forward();
  }

  List<_Particle> _buildParticles() {
    final rng = math.Random();
    return List.generate(52, (i) {
      final angle = -math.pi * 0.9 + rng.nextDouble() * math.pi * 0.8;
      final speed = 160.0 + rng.nextDouble() * 380.0;
      final shape = _Shape.values[rng.nextInt(_Shape.values.length)];
      final base  = 5.0 + rng.nextDouble() * 7.0;
      return _Particle(
        x: widget.origin.dx,
        y: widget.origin.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        rotation: rng.nextDouble() * math.pi * 2,
        rotSeed: (rng.nextDouble() - 0.5) * 12.0,
        color: _colours[rng.nextInt(_colours.length)],
        w: shape == _Shape.ribbon ? base * 0.5 : base,
        h: shape == _Shape.ribbon ? base * 2.2 : base,
        shape: shape,
      );
    });
  }

  void _tick() {
    final t  = _ctrl.value * _totalSecs;
    final dt = (t - _lastT).clamp(0.0, 0.05);
    _lastT   = t;

    for (final p in _particles) {
      p.x  += p.vx * dt;
      p.y  += p.vy * dt;
      p.vy += _gravity * dt;
      p.vx *= _drag;
      p.rotation += p.rotSeed * dt;
      if (t > _fadeStart) {
        p.opacity = (1.0 - (t - _fadeStart) / (_totalSecs - _fadeStart))
            .clamp(0.0, 1.0);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value * _totalSecs;

    final rippleT       = (t / 0.5).clamp(0.0, 1.0);
    final rippleRadius  = rippleT * 72.0;
    final rippleOpacity = (1.0 - rippleT) * 0.7;

    // Spring checkmark: grows to 1.25× then settles to 1.0×
    final ckT     = (t / 0.4).clamp(0.0, 1.0);
    final ckScale = ckT < 0.7
        ? Curves.easeOut.transform((ckT / 0.7).clamp(0.0, 1.0)) * 1.25
        : 1.25 - 0.25 * Curves.easeIn.transform(((ckT - 0.7) / 0.3).clamp(0.0, 1.0));
    final ckOpacity =
        t < 0.6 ? 1.0 : (1.0 - (t - 0.6) / 0.3).clamp(0.0, 1.0);

    return IgnorePointer(
      child: CustomPaint(
        painter: _CelebrationPainter(
          particles:     _particles,
          origin:        widget.origin,
          rippleRadius:  rippleRadius,
          rippleOpacity: rippleOpacity,
          ckScale:       ckScale,
          ckOpacity:     ckOpacity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _CelebrationPainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset origin;
  final double rippleRadius;
  final double rippleOpacity;
  final double ckScale;
  final double ckOpacity;

  const _CelebrationPainter({
    required this.particles,
    required this.origin,
    required this.rippleRadius,
    required this.rippleOpacity,
    required this.ckScale,
    required this.ckOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Ripple ring
    if (rippleRadius > 0 && rippleOpacity > 0) {
      canvas.drawCircle(
        origin,
        rippleRadius,
        Paint()
          ..color = AppColors.priorityLow.withValues(alpha: rippleOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
      canvas.drawCircle(
        origin,
        rippleRadius * 0.6,
        Paint()
          ..color =
              AppColors.priorityLow.withValues(alpha: rippleOpacity * 0.15),
      );
    }

    // ── Checkmark drawn with Path (no TextPainter / icon font needed)
    if (ckScale > 0 && ckOpacity > 0) {
      final sz    = 13.0 * ckScale;
      final paint = Paint()
        ..color      = AppColors.priorityLow.withValues(alpha: ckOpacity)
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 2.5 * ckScale
        ..strokeCap  = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()
        ..moveTo(origin.dx - sz * 0.45, origin.dy)
        ..lineTo(origin.dx - sz * 0.05, origin.dy + sz * 0.4)
        ..lineTo(origin.dx + sz * 0.5,  origin.dy - sz * 0.4);

      canvas.drawPath(path, paint);
    }

    // ── Confetti particles
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.opacity <= 0) continue;
      paint.color = p.color.withValues(alpha: p.opacity);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      switch (p.shape) {
        case _Shape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
              const Radius.circular(1.5),
            ),
            paint,
          );
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, p.w / 2, paint);
        case _Shape.ribbon:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
              const Radius.circular(1),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => true;
}