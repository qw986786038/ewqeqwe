import 'package:yidivination/bokong/entity/app_resp_entity.dart';

import '../entity/user/captcha_entity.dart';
import '../entity/user/user_entity.dart';
import 'common_api.dart';

class LoginApi {
  //登录
  static Future<AppRespEntity<UserEntity>> login({
    Map<String, dynamic>? params,
  }) {
    return CommonApi.postForm<UserEntity>("/api/login/", params: params);
  }

  static Future<AppRespEntity<CaptchaEntity>> captcha({
    Map<String, dynamic>? params,
  }) {
    return CommonApi.get<CaptchaEntity>("/api/captcha/", params: params);
  }
}
