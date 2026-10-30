import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:yidivination/bokong/utils/ext.dart';

/// 侧栏顶部 Logo 演示（临时占位）。
class MenuLogoDemo extends StatelessWidget {
  const MenuLogoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: const DecorationImage(
              image: AssetImage('assets/icon/app_icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '媒花易数',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '智能播控平台',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
