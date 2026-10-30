/// 高德 JS API [mapStyle] 内置样式 ID。
///
/// 文档：https://lbs.amap.com/api/javascript-api-v2/guide/map/map-style
abstract final class AmapMapStyles {
  static const String normal = 'amap://styles/normal';
  static const String grey = 'amap://styles/grey';
  static const String whitesmoke = 'amap://styles/whitesmoke';
  static const String light = 'amap://styles/light';
  static const String graffiti = 'amap://styles/graffiti';

  /// 应用默认底图样式。
  static const String forApp = normal;
}
