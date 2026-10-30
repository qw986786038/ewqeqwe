import 'dart:async';

/// 尾部防抖（trailing）：多次调用 [run] 会重置计时，仅在 [duration] 内无新调用后执行回调。
///
/// 在 [State.dispose] 等生命周期中应调用 [cancel]，避免定时器泄漏。
final class Debouncer {
  Debouncer({required this.duration});

  final Duration duration;
  Timer? _timer;

  /// 是否正在等待执行已安排的回调。
  bool get isActive => _timer != null;

  /// 安排执行 [action]；若在 [duration] 内再次 [run]，则取消上一次安排并重新计时。
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      _timer = null;
      action();
    });
  }

  /// 取消防抖中尚未执行的回调。
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
