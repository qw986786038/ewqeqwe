import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// macOS 风格弹簧曲线（easeOutBack 变体，全程 0→1 且终点轻微过冲）。
class MacSpringCurve extends Curve {
  const MacSpringCurve({this.overshoot = 0.92});

  /// 回弹强度，约 0.8~1.2。
  final double overshoot;

  @override
  double transform(double t) {
    final double s = overshoot;
    final double t1 = t - 1.0;
    return 1.0 + (s + 1.0) * t1 * t1 * t1 + s * t1 * t1;
  }
}

/// 桌面端使用 mac 风格过渡；移动端保持略快、位移更小的变体。
bool _useMacLikeTransition() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// 当前平台路由过渡时长（供页面延后重任务使用，避免与动画抢主线程）。
Duration get routeTransitionDuration {
  return Duration(milliseconds: _useMacLikeTransition() ? 420 : 300);
}

/// 列表等内容短延迟（略晚于路由动画，减轻切换卡顿；可按效果调整）。
const Duration contentLoadShortDelay = Duration(milliseconds: 120);

/// 路由过渡结束后再执行（如列表请求、WebView 初始化）。
void scheduleAfterRouteTransition(VoidCallback action) {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    Future<void>.delayed(routeTransitionDuration, action);
  });
}

/// 路由页切换：macOS 风格弹簧滑入（右 → 左，轻微过冲）。
Page<void> slideFromRightRoutePage({
  required GoRouterState state,
  required Widget child,
}) {
  final bool macLike = _useMacLikeTransition();
  final Duration duration = routeTransitionDuration;
  const MacSpringCurve spring = MacSpringCurve();

  return CustomTransitionPage<void>(
    key: ValueKey<String>(state.uri.toString()),
    // 根页面统一包 Scaffold，切换时不透出下层内容。
    child: Scaffold(body: child),
    transitionDuration: duration,
    reverseTransitionDuration: Duration(milliseconds: macLike ? 340 : 260),
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<double> enter = CurvedAnimation(
            parent: animation,
            curve: macLike ? spring : Curves.easeOutBack,
          );

          final Animation<Offset> slideIn = Tween<Offset>(
            begin: Offset(macLike ? 0.05 : 0.04, 0),
            end: Offset.zero,
          ).animate(enter);

          final Animation<double> fadeIn = Tween<double>(begin: 0.88, end: 1)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: macLike ? spring : Curves.easeOut,
                ),
              );

          return RepaintBoundary(
            child: SlideTransition(
              position: slideIn,
              child: FadeTransition(opacity: fadeIn, child: child),
            ),
          );
        },
  );
}
