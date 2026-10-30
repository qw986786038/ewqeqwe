import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_category_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_filter_options_entity.dart';
import 'package:yidivination/bokong/utils/ext.dart';

import 'common_api.dart';

class AdMediaApi {
  AdMediaApi._();

  /// 素材库左侧内容分类树（可按 [customerId] 筛选）
  static Future<AppRespEntity<AdContentCategoryEntity>> contentCategory({
    int? customerId,
    Map<String, dynamic>? param,
  }) {
    final params = <String, dynamic>{...?param};
    if (customerId != null) {
      params['customer_id'] = customerId;
    }
    return CommonApi.get<AdContentCategoryEntity>(
      '/api/system/ad/v2/content_category/',
      params: params.isEmpty ? null : params,
    );
  }

  /// 素材库列表筛选选项
  static Future<AppRespEntity<AdMediaFilterOptionsEntity>> filterOptions() {
    return CommonApi.get<AdMediaFilterOptionsEntity>(
      '/api/system/ad/media/filter_options/',
    );
  }

  /// 素材库列表（筛选条件放 [param]，如 `is_delete`、`customer_id`、`title`）
  static Future<AppRespEntity<List<AdMediaEntity>>> list({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<AdMediaEntity>>(
      '/api/system/ad/media/',
      params: params,
    );
  }

  /// 素材库回收站列表（ShowDoc 1513）
  ///
  /// [param] 可传 `kw`（关键字）；`type`：全部 0 / 图片 1 / 视频 2 / 文件 3（默认 0）。
  static Future<AppRespEntity<List<AdMediaEntity>>> recyclerList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    params['type'] ??= 0;
    return CommonApi.get<List<AdMediaEntity>>(
      '/api/system/ad/media/recycler_list/',
      params: params,
    );
  }

  /// 彻底删除回收站素材（ShowDoc 1517）
  static Future<AppRespEntity<dynamic>> recyclerDelete({required int mediaId}) {
    return CommonApi.post<dynamic>(
      '/api/system/ad/media/recycler_del/',
      params: {'media_id': mediaId},
    );
  }

  /// 还原回收站素材（ShowDoc 1518）；[mediaIds] 为逗号分隔，如 `1,2,3`。
  static Future<AppRespEntity<dynamic>> recyclerRestore({
    required String mediaIds,
  }) {
    return CommonApi.post<dynamic>(
      '/api/system/ad/media/recycler_restore/',
      params: {'media_ids': mediaIds},
    );
  }

  /// 清空回收站（ShowDoc 1516）
  static Future<AppRespEntity<dynamic>> recyclerClear() {
    return CommonApi.post<dynamic>('/api/system/ad/media/recycler_clear/');
  }

  /// 更新素材库素材
  static Future<AppRespEntity<AdMediaEntity>> update({
    required int id,
    required Map<String, dynamic> params,
  }) {
    return CommonApi.put<AdMediaEntity>(
      '/api/system/ad/media/$id/',
      params: params,
    );
  }

  /// 删除素材库素材
  static Future<AppRespEntity<String>> delete({required int id}) {
    return CommonApi.delete<String>('/api/system/ad/media/$id/');
  }

  /// 新增素材库素材
  static Future<AppRespEntity<AdMediaEntity>> create({
    required Map<String, dynamic> params,
  }) {
    return CommonApi.post<AdMediaEntity>(
      '/api/system/ad/media/',
      params: params,
    );
  }
}
