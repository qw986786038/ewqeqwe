import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 本地省市区三级数据（`assets/data/china_regions.json`）。
/// value / label 均为中文地名，提交接口直接传文字。
class ChinaRegions {
  ChinaRegions._();

  static List<AppCascadeOption<String>>? _cache;

  static Future<List<AppCascadeOption<String>>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/china_regions.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _cache = const [];
      return _cache!;
    }
    _cache = _parseList(decoded);
    return _cache!;
  }

  static List<AppCascadeOption<String>> _parseList(List<dynamic> list) {
    final out = <AppCascadeOption<String>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final value = (map['value'] ?? map['label'] ?? '').toString().trim();
      final label = (map['label'] ?? map['value'] ?? '').toString().trim();
      if (value.isEmpty || label.isEmpty) continue;
      final childrenRaw = map['children'];
      final children = childrenRaw is List
          ? _parseList(childrenRaw)
          : const <AppCascadeOption<String>>[];
      out.add(
        AppCascadeOption<String>(
          value: value,
          label: label,
          children: children,
        ),
      );
    }
    return out;
  }
}
