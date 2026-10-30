import 'package:flutter/material.dart';
import 'package:yidivination/bokong/utils/ext.dart';

class CircleWidget extends StatelessWidget {
  const CircleWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderColor,
    this.child,
  });

  final double width;
  final double height;
  final Color? borderColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Color(0xffBABABA),
          width: 1.5,
        ), // 边框
      ),
      child: ClipOval(child: child),
    );
  }
}
