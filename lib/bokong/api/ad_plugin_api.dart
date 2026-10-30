import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_plugin_entity.dart';
import 'package:yidivination/bokong/utils/ext.dart';

import 'common_api.dart';

class AdPluginApi {
  AdPluginApi._();

  /// 插件列表（筛选条件放 [param]）
  static Future<AppRespEntity<List<AdPluginEntity>>> list({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<AdPluginEntity>>(
      '/api/system/ad/plugin/',
      params: params,
    );
  }

  /// 新增插件
  static Future<AppRespEntity<AdPluginEntity>> create({
    required Map<String, dynamic> params,
  }) {
    return CommonApi.post<AdPluginEntity>(
      '/api/system/ad/plugin/',
      params: params,
    );
  }
}
