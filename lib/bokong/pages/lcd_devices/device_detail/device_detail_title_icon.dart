import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 详情页 [AppDescriptions] 标题区软底图标。
Widget deviceDetailTitleIcon(
  BuildContext context,
  IconData icon, {
  Color? color,
}) {
  final colors = ShadcnTheme.of(context).colorScheme;
  final accent = color ?? colors.primary;
  return AppAvatar.square(
    appearance: AppAvatarAppearance.subtle,
    icon: Icon(icon),
    color: accent,
    size: 24,
    borderRadius: 6,
  );
}
