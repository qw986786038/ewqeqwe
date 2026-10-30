import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/system/area_entity.dart';

import 'common_api.dart';

class SystemApi {
  SystemApi._();

  /// 行政区划列表；省不传 [pcode]，市传省 [code]，区县传市 [code]。
  static Future<AppRespEntity<List<AreaEntity>>> areaList({
    String? pcode,
    int limit = 999,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{'limit': limit};
    if (pcode != null && pcode.isNotEmpty) {
      params['pcode'] = pcode;
    }
    return CommonApi.get<List<AreaEntity>>('/api/system/area/', params: params);
  }
}
