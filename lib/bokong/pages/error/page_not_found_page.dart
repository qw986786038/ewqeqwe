import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart' hide AppText;
import 'package:yidivination/bokong/router/routes.dart';
import 'package:yidivination/bokong/utils/ext.dart';

class PageNotFoundPage extends StatelessWidget {
  const PageNotFoundPage({super.key, this.fromPath});

  final String? fromPath;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final String? path = fromPath?.trim();
    final bool showPath = path != null && path.isNotEmpty;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/page_not_found.png',
                  width: 400,
                  fit: BoxFit.contain,
                ),
                Text(
                  '此页面已被UFO盗取，请返回主页',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(10),
                if (showPath) ...[
                  const Gap(8),
                  Text(
                    '地址：$path',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Gap(28),
                AppButton.primary(
                  child: const Text('返回首页'),
                  onPressed: () => context.go(Routes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
