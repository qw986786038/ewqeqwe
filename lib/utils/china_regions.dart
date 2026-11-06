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

  /// 截到「省 → 市」：去掉区县。
  /// 直辖市下的「市辖区/县」保留展示，取值仍用省名（与勾选省级等价）。
  static List<AppCascadeOption<String>> toProvinceCity(
    List<AppCascadeOption<String>> provinces,
  ) {
    const municipal = {'市辖区', '县'};
    return [
      for (final p in provinces)
        AppCascadeOption<String>(
          value: p.value,
          label: p.label,
          children: [
            for (final c in p.children)
              if (municipal.contains(c.label))
                AppCascadeOption<String>(value: p.value, label: c.label)
              else
                AppCascadeOption<String>(value: c.value, label: c.label),
          ],
        ),
    ];
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
