import 'package:flutter/widgets.dart';

/// 纵向滚动接近底部时触发 [onLoadMore]，用于网格 / 表格无限滚动。
///
/// 重复触发由调用方（Controller 的 loading / 末页判断）拦截。
///
/// 待上游：卡片网格与 `AppDataGrid.local` 暂无触底回调一等 API（如 `onEndReached`）。
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = 200,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  /// 距底部小于该像素即触发。
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical && metrics.maxScrollExtent > 0 && metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
