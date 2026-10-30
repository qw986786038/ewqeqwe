import 'package:yidivination/bokong/api/system_api.dart';
import 'package:yidivination/bokong/entity/system/area_entity.dart';
import 'package:yidivination/bokong/widget/amap/amap_location_pick_result.dart';

/// 地图选点解析出的 city / district，与接口字典 id 对齐后的结果。
class LcdDevicesResolvedArea {
  const LcdDevicesResolvedArea({
    this.provinceName,
    this.cityName,
    this.cityId,
    this.districtName,
    this.districtId,
  });

  final String? provinceName;
  final String? cityName;
  final int? cityId;
  final String? districtName;
  final int? districtId;

  bool get isComplete => cityId != null && districtId != null;

  String? get displayLabel {
    final parts = <String>[];
    void add(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      if (!parts.contains(text)) parts.add(text);
    }

    add(provinceName);
    add(cityName);
    add(districtName);
    return parts.isEmpty ? null : parts.join(' / ');
  }
}

/// 根据地图逆地理编码的省 / 市 / 区县名称，匹配 [SystemApi.areaList] 字典 id。
Future<LcdDevicesResolvedArea?> lcdDevicesResolveAreaFromPick(
  AmapLocationPickResult pick,
) async {
  final cityName = pick.city?.trim();
  final districtName = pick.district?.trim();
  if ((cityName == null || cityName.isEmpty) &&
      (districtName == null || districtName.isEmpty)) {
    return null;
  }

  final provinces = (await SystemApi.areaList()).data ?? const <AreaEntity>[];
  for (final province in provinces) {
    final provinceCode = province.code;
    if (provinceCode == null || provinceCode.isEmpty) continue;

    final cities =
        (await SystemApi.areaList(pcode: provinceCode)).data ??
        const <AreaEntity>[];
    final matchedCity = _findArea(cities, cityName);
    if (matchedCity == null || matchedCity.code == null) continue;

    final districts =
        (await SystemApi.areaList(pcode: matchedCity.code!)).data ??
        const <AreaEntity>[];
    final matchedDistrict = _findArea(districts, districtName);
    if (matchedDistrict == null) {
      return LcdDevicesResolvedArea(
        provinceName: pick.province,
        cityName: matchedCity.name,
        cityId: _areaId(matchedCity.code),
      );
    }

    return LcdDevicesResolvedArea(
      provinceName: pick.province,
      cityName: matchedCity.name,
      cityId: _areaId(matchedCity.code),
      districtName: matchedDistrict.name,
      districtId: _areaId(matchedDistrict.code),
    );
  }

  return null;
}

int? _areaId(String? code) => int.tryParse(code ?? '');

AreaEntity? _findArea(List<AreaEntity> areas, String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final target = name.trim();

  for (final area in areas) {
    if (_matchesAreaName(area.name, target)) return area;
  }
  for (final area in areas) {
    final areaName = area.name?.trim() ?? '';
    if (areaName.isEmpty) continue;
    if (areaName.contains(target) || target.contains(areaName)) return area;
  }
  return null;
}

bool _matchesAreaName(String? areaName, String target) {
  final name = areaName?.trim() ?? '';
  if (name.isEmpty) return false;
  if (name == target) return true;

  final normalizedArea = _stripAdminSuffix(name);
  final normalizedTarget = _stripAdminSuffix(target);
  return normalizedArea == normalizedTarget;
}

String _stripAdminSuffix(String value) {
  const suffixes = ['特别行政区', '自治区', '自治州', '地区', '盟', '省', '市', '区', '县'];
  for (final suffix in suffixes) {
    if (value.endsWith(suffix) && value.length > suffix.length) {
      return value.substring(0, value.length - suffix.length);
    }
  }
  return value;
}
