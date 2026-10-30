import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lemon_x/lemon_x.dart';

mixin RefreshMixin<T> {
  ///刷新用的Key
  final RxDouble _refreshKey = RxDouble(0.0);

  ///当前选中的值
  final Rx<T?> _current = Rx(null);

  ///刷新
  void refresh({bool cleanCurrent = true}) {
    if (cleanCurrent) {
      current = null;
    }
    refreshKey = Random().nextDouble();
  }

  @protected
  double get refreshKey {
    return _refreshKey.value;
  }

  @protected
  set refreshKey(double newValue) {
    if (_refreshKey.value == newValue) return;
    _refreshKey.value = newValue;
  }

  Rx<T?> get rxCurrent {
    return _current;
  }

  T? get current {
    return _current.value;
  }

  set current(T? newValue) {
    // _current.value = null;
    // if (_current.value == newValue) return;
    Future.delayed(
      const Duration(milliseconds: 50),
    ).then((value) => _current.value = newValue);
  }
}

extension RefreshExt on RefreshMixin {
  Widget obx(NotifierBuilder widget) {
    return Obx(() => widget(refreshKey));
  }
}

typedef NotifierBuilder<T> = Widget Function(T key);
