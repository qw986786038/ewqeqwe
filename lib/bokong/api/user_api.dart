import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/user/user_entity.dart';

import 'common_api.dart';

class UserApi {
  UserApi._();

  /// 当前登录用户信息
  static Future<AppRespEntity<UserEntity>> userInfo() {
    return CommonApi.get<UserEntity>('/api/system/user/user_info/');
  }
}
