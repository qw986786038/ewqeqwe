import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/ad_property_list_entity.dart';
import 'package:yidivination/bokong/utils/ext.dart';

import 'common_api.dart';

class AdPropertyApi {
  AdPropertyApi._();

  /// 物业列表
  ///
  /// [deviceTab] 设备类型：LCD / LED
  /// [cityIds] 城市 ID 集合，如 `1,2,3`
  /// [districtIds] 行政区域 ID 集合，如 `1,2,3`
  /// [propertyId] 物业 ID
  /// [mediaAddress] 媒体位置
  /// [mediaSize] 媒体尺寸
  /// [isVolume] 是否允许音量：`0` 否，`1` 是
  /// [status] 在线状态：`-1` 全部，`1` 在线，`2` 离线
  /// [kw] 关键字
  /// [page] / [size] 分页
  static Future<AppRespEntity<AdPropertyListDataEntity>> propertyList({
    String? deviceTab,
    String? cityIds,
    String? districtIds,
    int? propertyId,
    String? mediaAddress,
    String? mediaSize,
    String? isVolume,
    int? status,
    String? kw,
    int? page,
    int? size,
  }) {
    final params = <String, dynamic>{
      if (deviceTab != null && deviceTab.isNotEmpty) 'device_tab': deviceTab,
      if (cityIds != null && cityIds.isNotEmpty) 'city_ids': cityIds,
      if (districtIds != null && districtIds.isNotEmpty)
        'district_ids': districtIds,
      if (propertyId != null) 'property_id': propertyId,
      if (mediaAddress != null && mediaAddress.isNotEmpty)
        'media_address': mediaAddress,
      if (mediaSize != null && mediaSize.isNotEmpty) 'media_size': mediaSize,
      if (isVolume != null && isVolume.isNotEmpty) 'is_volume': isVolume,
      if (status != null) 'status': status,
      if (kw != null && kw.isNotEmpty) 'kw': kw,
    }.page(page: page, size: size);
    return CommonApi.get<AdPropertyListDataEntity>(
      '/api/system/ad/v2/property_list/',
      params: params,
    );
  }
}
