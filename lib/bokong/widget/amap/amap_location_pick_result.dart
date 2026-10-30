import 'package:flutter/foundation.dart';

/// 地图选点结果。
@immutable
class AmapLocationPickResult {
  const AmapLocationPickResult({
    required this.address,
    required this.longitude,
    required this.latitude,
    this.province,
    this.city,
    this.district,
  });

  final String address;
  final double longitude;
  final double latitude;

  /// 逆地理编码 · 省
  final String? province;

  /// 逆地理编码 · 市（直辖市时可能与 [province] 相同）
  final String? city;

  /// 逆地理编码 · 区县
  final String? district;

  factory AmapLocationPickResult.fromJson(Map<String, dynamic> json) {
    return AmapLocationPickResult(
      address: (json['address'] as String?)?.trim() ?? '',
      longitude: _readDouble(json['lng']),
      latitude: _readDouble(json['lat']),
      province: _readString(json['province']),
      city: _readString(json['city']),
      district: _readString(json['district']),
    );
  }

  bool get isValid => address.trim().isNotEmpty && hasCoordinates;

  bool get hasCoordinates =>
      longitude.isFinite &&
      latitude.isFinite &&
      (longitude != 0 || latitude != 0);

  bool get hasRegion =>
      [province, city, district].any((part) => part?.trim().isNotEmpty == true);

  /// 省 / 市 / 区县展示文案（去重）。
  String? get regionLabel {
    final parts = <String>[];
    void add(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      if (!parts.contains(text)) parts.add(text);
    }

    add(province);
    add(city);
    add(district);
    return parts.isEmpty ? null : parts.join(' / ');
  }

  static String? _readString(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
