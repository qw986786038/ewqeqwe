import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension StringMd5Ext on String {
  /// UTF-8 编码后的 MD5，十六进制小写字符串。
  String get md5 => md5Hex();

  String md5Hex() => crypto.md5.convert(utf8.encode(this)).toString();
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  bool get isLight => Theme.of(this).brightness == Brightness.light;
}

extension intExt on int? {
  String padZero([int width = 0, String padding = '0']) {
    return toString().padLeft(width, '0');
  }

  String date([String format = "yyyy-MM-dd"]) {
    return DateTime.fromMillisecondsSinceEpoch(
      this ?? DateTime.now().millisecondsSinceEpoch,
    ).format(format);
  }

  String date2([String format = "yyyy-MM-dd HH:mm:ss"]) {
    return DateTime.fromMillisecondsSinceEpoch(
      this ?? DateTime.now().millisecondsSinceEpoch,
    ).format(format);
  }

  String diff() {
    int minutes = (this ?? 0) ~/ (1000 * 60);

    if (minutes > 60 * 24) {
      var d = minutes ~/ (60 * 24);
      var d_m = minutes % (60 * 24);
      var h = d_m ~/ 60;
      return '$d天$h小时';
    } else if (minutes > 60) {
      var h = minutes ~/ 60;
      var m = minutes % 60;
      return '$h小时$m分钟';
    } else {
      return '$minutes分钟';
    }
  }
}

extension ExtensionGlobalKey on GlobalKey<FormState> {
  bool validate() {
    if (currentState?.validate() == true) {
      currentState?.save();
      return true;
    } else {
      return false;
    }
  }
}

/// Map Json扩展方法
extension WidgetExtension on Widget {
  Widget icon(
    Widget icon, {
    double padding = 8,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        icon,
        Container(width: padding),
        Flexible(child: this),
      ],
    );
  }

  Widget trailing(
    Widget icon, {
    double padding = 8,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        this,
        Container(width: padding),
        Flexible(child: icon),
      ],
    );
  }

  Widget endWith(List<Widget> widgets) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: this),
        Container(width: 4),
        ...widgets,
      ],
    );
  }

  Widget rowWith(
    List<Widget> widgets, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [this, ...widgets],
    );
  }

  Widget showBy(bool show) {
    if (show) {
      return this;
    } else {
      return Container();
    }
  }

  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  Widget flexible({bool enable = true, int flex = 1}) {
    return enable ? Flexible(flex: flex, child: this) : this;
  }

  Widget keyListener({ValueChanged<RawKeyEvent>? onkey}) {
    return RawKeyboardListener(
      focusNode: FocusNode(canRequestFocus: false),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyUpEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            // print('>>>>>>>>>点击了确定>>>>>>>>>');
          } else {
            // print('>>>>>>>>>点击了>>${event.logicalKey}>>>>>>>');
          }

          onkey?.call(event);
        }
      },
      child: this,
    );
  }

  Widget width(double width) {
    return SizedBox(width: width, child: this);
  }

  Widget center() {
    return Center(child: this);
  }

  Widget size({double? width, double? height}) {
    return SizedBox(width: width, height: height, child: this);
  }

  Widget clipRRect({double radius = 5}) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: this,
    );
  }
}

extension mapExt on Map<String, dynamic>? {
  Map<String, dynamic> page({int? page, int? size}) {
    var params = this ?? {};
    final int pageNo = page ?? 1;
    params['page'] = pageNo == 0 ? 1 : pageNo;
    params['limit'] = size ?? 20;

    return params;
  }
}

extension NumExt on String? {
  double toDouble({double? def}) {
    return double.tryParse(toString().trim()) ?? def ?? 0.0;
  }

  int toInt() {
    return int.tryParse(toString().trim()) ?? 0;
  }

  // Decimal decimal() {
  //   try {
  //     return Decimal.tryParse(this ?? "0") ?? Decimal.parse("0");
  //   } catch (e) {
  //     return Decimal.parse("0");
  //   }
  // }

  String? toStringWithoutZero() {
    var numStr = this?.contains('.') == true
        ? this?.replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")
        : this;
    return numStr;
  }

  bool toBool() {
    return this?.toLowerCase() == 'true';
  }
}
