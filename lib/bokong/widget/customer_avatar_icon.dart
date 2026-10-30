import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/theme/theme.dart';

/// 客户默认头像（订单列表 / 详情）。
class CustomerAvatarIcon extends StatelessWidget {
  const CustomerAvatarIcon({super.key, this.size = 32, this.borderRadius});

  static const asset = 'assets/images/customer_avatar_icon.png';

  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size <= 32 ? 6 : 16);
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => AppAvatar.square(
          appearance: AppAvatarAppearance.soft,
          color: kBrandPrimary,
          icon: const Icon(AppLucideIcons.user),
          size: size,
          borderRadius: radius.topLeft.x,
        ),
      ),
    );
  }
}
