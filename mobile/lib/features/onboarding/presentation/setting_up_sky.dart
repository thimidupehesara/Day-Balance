import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Procedural artwork: no network assets, frame timers, or generated bitmaps.
class SettingUpSkyPainter extends CustomPainter {
  final Animation<double> animation;
  final double horizon;
  final bool reduceMotion;

  SettingUpSkyPainter({
    required this.animation,
    required this.horizon,
    required this.reduceMotion,
  }) : super(repaint: reduceMotion ? null : animation);

  static double _ease(double v) {
    v = v.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  /// Both bodies share one arc and the same speed across the sky.
  static Offset orbit(double phase, double width, double horizon) {
    final p = phase.clamp(0.0, 1.0);
    return Offset(
      width * (1 / 6 + p * 2 / 3),
      horizon + 9 - math.sin(p * math.pi) * horizon * .53,
    );
  }

  static final _stars = _points(70, 217);
  static final _craters = _points(85, 981);
  static List<(double, double, double)> _points(int count, int seed) {
    final random = math.Random(seed);
    return List.generate(
      count,
      (_) => (random.nextDouble(), random.nextDouble(), random.nextDouble()),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = reduceMotion ? .75 : animation.value;
    final w = size.width, h = horizon;
    final night = _ease((t - .36) / .22);
    final skyPhase = (t < .5 ? t * 1.5 : .75 + (t - .5) * .5) * 4;
    final index = math.min(3, skyPhase.floor());
    final colors = List.generate(
      4,
      (j) => Color.lerp(
        AppColors.setupSkies[index][j],
        AppColors.setupSkies[index + 1][j],
        _ease(skyPhase - index),
      )!,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.setupBackground,
    );
    final skyRect = Rect.fromLTWH(0, 0, w, h + 80);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0, .45, .85, 1],
        ).createShader(skyRect),
    );
    for (final star in _stars) {
      canvas.drawCircle(
        Offset(star.$1 * w, h * (.33 + star.$2 * .55)),
        .4 + star.$3 * .8,
        Paint()
          ..color = AppColors.starGlow.withValues(
            alpha: night * (.15 + star.$3 * .55),
          ),
      );
    }
    final sun = orbit(t / .5, w, h);
    final moon = orbit((t - .5) / .5, w, h);
    // Clip before drawing hills so bodies disappear naturally at the horizon.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    if (t <= .52) _sun(canvas, sun, 1 - _ease((t - .48) / .04));
    if (t >= .5) _moon(canvas, moon, _ease((t - .5) / .035));
    canvas.restore();

    final ridge = Path()
      ..moveTo(0, h)
      ..cubicTo(w * .13, h - 21, w * .18, h - 7, w * .31, h - 16)
      ..cubicTo(w * .46, h - 30, w * .59, h + 1, w * .72, h - 16)
      ..cubicTo(w * .85, h - 34, w * .95, h - 15, w, h - 21)
      ..lineTo(w, h + 80)
      ..lineTo(0, h + 80)
      ..close();
    canvas.drawPath(
      ridge,
      Paint()
        ..color = Color.lerp(
          AppColors.setupRidgeDay,
          AppColors.setupRidgeNight,
          night,
        )!,
    );
    final sea = Rect.fromLTWH(0, h, w, 190);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(AppColors.setupSeaDay, AppColors.setupSeaNight, night)!,
            AppColors.setupSeaDeep,
          ],
        ).createShader(sea),
    );
    final body = t >= .5 ? moon : sun;
    final strength = math
        .sin((t < .5 ? t / .5 : (t - .5) / .5) * math.pi)
        .clamp(0.0, 1.0);
    for (var j = 0; j < 40; j++) {
      final spread = 4 + j * .65;
      final x = body.dx + math.sin(j * 12.3 + t * 7) * spread - spread / 2;
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          h + 3 + j * 3.1,
          spread * (1.2 + math.sin(j * 2) * .6),
          .65,
        ),
        Paint()
          ..color = (t >= .5 ? AppColors.setupMoonLight : AppColors.setupSunMid)
              .withValues(
                alpha: strength * (t >= .5 ? .12 : .25) * (1 - j / 45),
              ),
      );
    }
    final shore = Path()
      ..moveTo(0, h + 33)
      ..cubicTo(w * .15, h + 24, w * .19, h + 57, w * .35, h + 63)
      ..cubicTo(w * .56, h + 73, w * .71, h + 81, w, h + 49)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(shore, Paint()..color = AppColors.setupShore);
    final fade = Rect.fromLTWH(0, h + 27, w, math.max(1, size.height - h - 27));
    canvas.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.setupMist.withValues(alpha: 0),
            AppColors.setupMist,
            AppColors.setupBackground,
          ],
          stops: const [0, .32, 1],
        ).createShader(fade),
    );
  }

  void _halo(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _sun(Canvas canvas, Offset center, double opacity) {
    _halo(canvas, center, 120, AppColors.setupSunMid, opacity * .38);
    _halo(canvas, center, 65, AppColors.setupSunEdge, opacity * .5);
    final rect = Rect.fromCircle(center: center, radius: 24);
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.3),
          radius: .7,
          colors: [
            AppColors.setupSunCore,
            AppColors.setupSunMid,
            AppColors.setupSunEdge,
          ].map((c) => c.withValues(alpha: opacity)).toList(),
          stops: const [0, .78, 1],
        ).createShader(rect),
    );
  }

  void _moon(Canvas canvas, Offset center, double opacity) {
    _halo(canvas, center, 86, AppColors.setupMoonHalo, opacity * .2);
    final rect = Rect.fromCircle(center: center, radius: 24);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.5, -.4),
          radius: .95,
          colors: [
            AppColors.setupMoonLight,
            AppColors.setupMoonMid,
            AppColors.setupMoonShade,
          ].map((c) => c.withValues(alpha: opacity)).toList(),
          stops: const [0, .55, 1],
        ).createShader(rect),
    );
    for (final crater in _craters) {
      final radius = 1 + crater.$3 * 5;
      canvas.drawOval(
        Rect.fromCenter(
          center:
              center +
              Offset((crater.$1 * 2 - 1) * 24, (crater.$2 * 2 - 1) * 24),
          width: radius * 2,
          height: radius * 1.44,
        ),
        Paint()
          ..color = AppColors.setupCrater.withValues(
            alpha: opacity * (.05 + crater.$3 * .12),
          ),
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.setupBackground.withValues(alpha: 0),
            AppColors.setupBackground.withValues(alpha: 0),
            AppColors.setupBackground.withValues(alpha: opacity * .67),
          ],
          stops: const [0, .65, 1],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SettingUpSkyPainter oldDelegate) =>
      oldDelegate.horizon != horizon ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.animation != animation;
}
