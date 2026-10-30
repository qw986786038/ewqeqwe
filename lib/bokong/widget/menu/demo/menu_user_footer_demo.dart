import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 侧栏底部用户信息演示（临时占位）。
class MenuUserFooterDemo extends StatelessWidget {
  const MenuUserFooterDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_outline,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '管理员',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@smartadmin.com',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
