import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 地图标记外观：列表 / 详情 / 预览统一用钉标。
enum AmapMarkerStyle {
  /// 色块 + 三角钉标（默认）。
  pin,

  /// 中心涟漪圆点（遗留，业务侧已统一为 [pin]）。
  dot,
}

/// 高德 Web 地图标记（字段与 `assets/web/amap_map.html` 一致）。
@immutable
class AmapMarker {
  const AmapMarker({
    required this.longitude,
    required this.latitude,
    this.id,
    this.title = '',
    this.description = '',
    this.initial = '?',
    this.accentColor = const Color(0xFF098292),
    this.online = false,
    this.selected = false,
    this.region = '',
    this.building = '',
    this.mediaAddress = '',
    this.statusLabel = '',
    this.propertyName = '',
    this.operationStatus = '',
    this.soundOn = false,
  });

  final double longitude;
  final double latitude;
  final String? id;
  final String title;
  final String description;

  /// 标记上显示的首字母。
  final String initial;

  /// 首字母方块背景色。
  final Color accentColor;

  /// 是否在线（保留字段，样式暂与 accent 统一）。
  final bool online;

  /// 是否为当前选中标记（高亮显示，并在地图内显示详情气泡）。
  final bool selected;

  /// 选中气泡：行政区。
  final String region;

  /// 选中气泡：楼栋标签。
  final String building;

  /// 选中气泡：点位/媒体地址。
  final String mediaAddress;

  /// 选中气泡：状态文案（在线/离线/异常）。
  final String statusLabel;

  /// 选中气泡：物业名称（为空时气泡首行回退到 [region]）。
  final String propertyName;

  /// 选中气泡：运营状态徽标文案（如「执行中」）；为空时不显示。
  final String operationStatus;

  /// 选中气泡：是否有声。
  final bool soundOn;

  String get resolvedId => id ?? '${longitude}_$latitude';

  static String _colorHex(Color color) {
    final v = color.toARGB32() & 0xFFFFFF;
    return v.toRadixString(16).padLeft(6, '0');
  }

  Map<String, Object> toWebMap() => <String, Object>{
    'id': resolvedId,
    'lng': longitude,
    'lat': latitude,
    'title': title,
    'desc': description,
    'initial': initial,
    'accent': _colorHex(accentColor),
    'online': online,
    'selected': selected,
    'region': region,
    'building': building,
    'mediaAddress': mediaAddress,
    'statusLabel': statusLabel,
    'propertyName': propertyName,
    'operationStatus': operationStatus,
    'soundOn': soundOn,
  };
}

/// 标记点击后由 JS 经 `JavaScriptChannel` 传到 Flutter。
@immutable
class AmapMarkerTapPayload {
  const AmapMarkerTapPayload({
    required this.id,
    required this.title,
    required this.description,
    required this.longitude,
    required this.latitude,
    this.anchorX,
    this.anchorY,
    this.mapWidth,
    this.mapHeight,
    this.doubleTap = false,
  });

  final String id;
  final String title;
  final String description;
  final double longitude;
  final double latitude;

  /// 点击时标记在地图容器内的像素坐标（可选）。
  final double? anchorX;
  final double? anchorY;
  final double? mapWidth;
  final double? mapHeight;

  /// 是否为双击（打开详情）。
  final bool doubleTap;

  bool get hasAnchor {
    final x = anchorX;
    final y = anchorY;
    return x != null && y != null && (x > 0 || y > 0);
  }

  AmapMarkerAnchor? get anchorOrNull {
    if (!hasAnchor) return null;
    return AmapMarkerAnchor(
      id: id,
      x: anchorX!,
      y: anchorY!,
      mapWidth: mapWidth ?? 0,
      mapHeight: mapHeight ?? 0,
    );
  }

  factory AmapMarkerTapPayload.fromJson(Map<String, dynamic> json) {
    final x = _readDoubleOrNull(json['x']);
    final y = _readDoubleOrNull(json['y']);
    return AmapMarkerTapPayload(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['desc'] as String?) ?? '',
      longitude: _readDouble(json['lng']),
      latitude: _readDouble(json['lat']),
      anchorX: x,
      anchorY: y,
      mapWidth: _readDoubleOrNull(json['mapW']),
      mapHeight: _readDoubleOrNull(json['mapH']),
      doubleTap: json['dbl'] == true,
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _readDoubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// 选中标记在地图容器内的锚点像素（用于 Flutter 详情卡跟随）。
@immutable
class AmapMarkerAnchor {
  const AmapMarkerAnchor({
    required this.id,
    required this.x,
    required this.y,
    this.mapWidth = 0,
    this.mapHeight = 0,
  });

  final String id;
  final double x;
  final double y;

  /// JS 侧地图容器宽高，用于与 Flutter 约束对齐缩放。
  final double mapWidth;
  final double mapHeight;

  factory AmapMarkerAnchor.fromJson(Map<String, dynamic> json) {
    return AmapMarkerAnchor(
      id: (json['id'] as String?) ?? '',
      x: _readDouble(json['x']),
      y: _readDouble(json['y']),
      mapWidth: _readDouble(json['mapW']),
      mapHeight: _readDouble(json['mapH']),
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
