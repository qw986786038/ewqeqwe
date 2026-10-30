import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/user/user_entity.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yidivination/bokong/api/login_api.dart';
import 'package:yidivination/bokong/http/auth_token.dart';
import 'package:yidivination/bokong/http/bokong_auto_auth.dart';
import 'package:yidivination/bokong/http/sp.dart';

import 'package:yidivination/bokong/utils/ext.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../../constant.dart';

class LoginController extends LxController {
  final form = AppFormController();

  Rx<UserEntity> user = Rx(UserEntity());
  RxBool rememberPwd = RxBool(false);

  Position? position;

  UserEntity params = UserEntity();

  RxString userName = RxString(BokongAutoAuth.username);
  RxString password = RxString(BokongAutoAuth.password);

  /// 进入播控后正在无感自动登录。
  final autoLoggingIn = true.obs;

  @override
  void onInit() {
    user.value = JsonMapper.fromJson<UserEntity>(
      Sp.get(Constant.SP_USER) ?? '{}',
    )!;
    rememberPwd.value = Sp.get(Constant.SP_REMEMBER_PWD) ?? false;
    super.onInit();
  }

  @override
  void onDispose() {
    form.dispose();
    super.onDispose();
  }

  /// 无感自动登录（不弹提示）。成功返回 `true`。
  Future<bool> autoLogin() async {
    autoLoggingIn.value = true;
    try {
      final ok = await BokongAutoAuth.loginSilently();
      if (ok) {
        await Future.delayed(const Duration(milliseconds: 300));
        windowManager.maximize();
      }
      return ok;
    } finally {
      autoLoggingIn.value = false;
    }
  }

  /// 表单登录；暂不校验验证码。成功返回 `true`。
  Future<bool> login() async {
    try {
      return await form.submit((values) async {
        final rawPassword = values['password'] as String? ?? '';
        params.username = values['username'] as String?;
        params.password = rawPassword.md5Hex();
        params.captcha = null;
        params.captchaKey = null;
        userName.value = params.username ?? '';
        password.value = rawPassword;
        rememberPwd.value = values['remember'] as bool? ?? false;

        final value = await LoginApi.login(
          params: json.decode(JsonMapper.serialize(params)),
        );
        final tmp = value.data;

        if (tmp?.access?.isNotEmpty == true) {
          await AuthToken.saveTokens(
            access: tmp!.access!,
            refresh: tmp.refresh,
          );
        }

        if (rememberPwd.value) {
          await Sp.set(Constant.SP_USERNAME, userName.value);
          await Sp.set(Constant.SP_PASSWORD, password.value);
        }

        await Sp.set(Constant.SP_REMEMBER_PWD, rememberPwd.value);

        if (tmp != null) {
          user.value = tmp;
          await Sp.set(Constant.SP_USER, JsonMapper.serialize(tmp));
        }

        await Future.delayed(const Duration(milliseconds: 300));
        windowManager.maximize();
      });
    } catch (e) {
      showError(e is AppRespEntity ? e.msg : e);
      return false;
    }
  }
}
