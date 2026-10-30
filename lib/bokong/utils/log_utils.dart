import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yidivination/bokong/utils/ext.dart';

class Log {
  ///日志文件
  static File? _logFile;

  static void _init() {
    var fileName = DateTime.now().millisecondsSinceEpoch.date();

    var dir = Directory("./log");

    if (!dir.existsSync()) {
      dir.createSync();
    }
    _logFile = File("./log/$fileName.log");
  }

  static void i(dynamic info) {
    _init();

    if (kDebugMode) {
      print(info);
    }
    _logFile?.writeAsStringSync(
      "${DateTime.now().millisecondsSinceEpoch.date2()}>>i>>>$info",
      mode: FileMode.append,
      flush: true,
      encoding: utf8,
    );
    _logFile?.writeAsStringSync(
      "\n",
      mode: FileMode.append,
      flush: true,
      encoding: utf8,
    );
  }
}
