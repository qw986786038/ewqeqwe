import 'package:flutter/material.dart';
import 'package:yidivination/bokong/utils/ext.dart';

/// 径向渐变圆点，常用于设备在线 / 离线 / 告警等状态指示。
/// [text] 为 null 时仅显示圆点；传入文字时在圆点右侧显示。
class RadialGradientDot extends StatelessWidget {
  const RadialGradientDot({
    super.key,
    required this.centerColor,
    required this.edgeColor,
    this.size = 16,
    this.gradientRadius = 0.5,
    this.borderWidth = 0,
    this.text,
    this.textStyle,
    this.gap = 4,
  });

  const RadialGradientDot.online({
    super.key,
    this.size = 16,
    this.borderWidth = 0,
    this.text,
    this.textStyle,
    this.gap = 4,
  }) : centerColor = const Color(0xff1EC881),
       edgeColor = const Color(0xff33F68B),
       gradientRadius = 0.5;

  const RadialGradientDot.offline({
    super.key,
    this.size = 16,
    this.borderWidth = 0,
    this.text,
    this.textStyle,
    this.gap = 4,
  }) : centerColor = const Color(0xff605F5F),
       edgeColor = const Color(0xffE6E6E6),
       gradientRadius = 0.5;

  const RadialGradientDot.error({
    super.key,
    this.size = 16,
    this.borderWidth = 0,
    this.text,
    this.textStyle,
    this.gap = 4,
  }) : centerColor = const Color(0xffFF5C75),
       edgeColor = const Color(0xffFA889B),
       gradientRadius = 0.5;

  const RadialGradientDot.info({
    super.key,
    this.size = 16,
    this.borderWidth = 0,
    this.text,
    this.textStyle,
    this.gap = 4,
  }) : centerColor = const Color(0xff4197FF),
       edgeColor = const Color(0xff4197FF),
       gradientRadius = 0.5;

  final Color centerColor;
  final Color edgeColor;
  final double size;
  final double gradientRadius;
  final double borderWidth;
  final String? text;
  final TextStyle? textStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.center,
          radius: gradientRadius,
          colors: <Color>[centerColor, edgeColor],
          stops: const <double>[0.0, 1.0],
        ),
        border: BoxBorder.all(color: Colors.white, width: borderWidth),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: size,
            offset: const Offset(3, 0),
          ),
        ],
      ),
    );

    if (text == null) return dot;

    final TextStyle labelStyle =
        (context.theme.textTheme.titleMedium ?? const TextStyle())
            .copyWith(color: centerColor, fontWeight: FontWeight.bold)
            .merge(textStyle);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        dot,
        SizedBox(width: gap),
        Text(text!, style: labelStyle),
      ],
    );
  }
}
