import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'home_controller.dart';

const _kBorder = Color(0xFFE5E6EB);
const _kText = Color(0xFF4E5969);

/// 与客户档案顶栏一致：后退 / 前进 + `当前位置 / 模块 / 页面`。
class LocationBreadcrumb extends StatelessWidget {
  const LocationBreadcrumb({super.key, required this.segments});

  /// 模块与页面，不含「当前位置」。
  final List<String> segments;

  void _goBack(BuildContext context) {
    try {
      final ok = context.lx.find<HomeController>().goSideMenuBack();
      if (!ok && context.mounted) {
        AppToast.show(context: context, title: '无法返回上一页');
      }
    } catch (_) {
      if (!context.mounted) return;
      AppToast.show(context: context, title: '无法返回上一页');
    }
  }

  void _goForward(BuildContext context) {
    try {
      final ok = context.lx.find<HomeController>().goSideMenuForward();
      if (!ok && context.mounted) {
        AppToast.show(context: context, title: '已是最新位置');
      }
    } catch (_) {
      if (!context.mounted) return;
      AppToast.show(context: context, title: '已是最新位置');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _NavIconBtn(
            icon: Icons.chevron_left,
            tooltip: '向后',
            onPressed: () => _goBack(context),
          ),
          const SizedBox(width: 2),
          _NavIconBtn(
            icon: Icons.chevron_right,
            tooltip: '向前',
            onPressed: () => _goForward(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '当前位置 / ${segments.join(' / ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kText),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF7F8FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _kBorder),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 18, color: _kText),
          ),
        ),
      ),
    );
  }
}
