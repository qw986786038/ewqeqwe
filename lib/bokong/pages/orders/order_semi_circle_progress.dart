import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 约 3/4 圆环进度（订单卡 / 详情摘要）；待上游提供 `AppSemiCircleProgress`。
///
/// 样式：中心白圆文案 + 同色柔光阴影铺到进度弧后 + 灰底轨 + 渐变进度 + 末端白拇指。
class OrderSemiCircleProgress extends StatelessWidget {
  const OrderSemiCircleProgress({
    super.key,
    required this.progress,
    required this.color,
    required this.percent,
    this.size = 64,
  });

  final double progress;
  final Color color;
  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _OrderSemiCircleProgressPainter(
              progress: progress.clamp(0.0, 1.0),
              color: color,
              trackColor: const Color(0xFFE8E8E8),
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: size >= 64 ? 11 : 9,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSemiCircleProgressPainter extends CustomPainter {
  const _OrderSemiCircleProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  /// 约 270° 弧，缺口朝下。
  static const _sweep = math.pi * 1.5;
  static const _gap = math.pi * 0.5;
  // Flutter 角度：从正 x 轴顺时针；底部为 π/2。
  static const _startAngle = math.pi / 2 + _gap / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final innerRadius = radius - stroke / 2;
    final hubRadius = innerRadius * 0.72;

    // 中心同色柔光：先画，铺到进度弧后面。
    canvas.drawCircle(
      center,
      hubRadius * 1.15,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 2.2)
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      center,
      hubRadius * 0.95,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.2)
        ..isAntiAlias = true,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect, _startAngle, _sweep, false, trackPaint);

    if (progress > 0) {
      final progressSweep = _sweep * progress;
      final startColor = Color.lerp(const Color(0xFFFFFFFF), color, 0.35)!;
      // 沿弧分段插值，避免 SweepGradient 在 0°/3 点钟接缝截断。
      const steps = 64;
      for (var i = 0; i < steps; i++) {
        final t0 = i / steps;
        final t1 = (i + 1) / steps;
        final mid = (t0 + t1) / 2;
        final segColor = Color.lerp(startColor, color, mid)!;
        final segStart = _startAngle + progressSweep * t0;
        // 轻微重叠，消除分段缝隙
        final segSweep = progressSweep * (t1 - t0) + 0.015;
        canvas.drawArc(
          rect,
          segStart,
          segSweep,
          false,
          Paint()
            ..color = segColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true,
        );
      }

      final endAngle = _startAngle + progressSweep;
      final tip = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final thumbRadius = stroke * 0.72;

      canvas.drawCircle(
        tip.translate(0, 1.2),
        thumbRadius,
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
          ..isAntiAlias = true,
      );
      canvas.drawCircle(
        tip,
        thumbRadius,
        Paint()
          ..color = Colors.white
          ..isAntiAlias = true,
      );
    }

    // 中心白圆（文字叠在上面）
    canvas.drawCircle(
      center,
      hubRadius,
      Paint()
        ..color = Colors.white
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _OrderSemiCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
