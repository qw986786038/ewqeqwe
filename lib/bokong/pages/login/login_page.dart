import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/router/routes.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';

import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<LoginController>(LoginController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  var _autoStarted = false;

  LoginController get _c => context.lx.find<LoginController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoStarted) return;
    _autoStarted = true;
    _runAutoLogin();
  }

  Future<void> _runAutoLogin() async {
    final ok = await _c.autoLogin();
    if (ok && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/login_background.png', fit: BoxFit.cover),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Obx(() {
            // 无感登录中：只留背景，不提示、不转圈。
            if (c.autoLoggingIn.value) {
              return const SizedBox.shrink();
            }
            return AppCard.elevated(
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: 48,
                vertical: 48,
              ),
              child: AppForm(
                controller: c.form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppText.h1('媒花易数', textAlign: TextAlign.center),
                    AppTextFormField(
                      name: 'username',
                      label: '账号',
                      required: true,
                      hintText: '请输入账号',
                      initialValue: c.userName.value,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: AppValidators.required(message: '不可为空'),
                    ),
                    AppTextFormField.password(
                      name: 'password',
                      label: '密码',
                      required: true,
                      hintText: '请输入密码',
                      initialValue: c.password.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[^\u4e00-\u9fa5]'),
                        ),
                      ],
                      validator: AppValidators.required(message: '不可为空'),
                    ),
                    AppCheckboxFormField(
                      name: 'remember',
                      initialValue: c.rememberPwd.value,
                      controlLabel: const Text('记住密码'),
                      onChanged: (value) => c.rememberPwd.value = value,
                    ),
                    AppButton.primary(
                      loadingLabel: '登录中',
                      onPressed: () => _submit(context, c),
                      child: const Text('登录'),
                    ),
                  ],
                ),
              ),
            ).width(400).center();
          }),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context, LoginController c) async {
    final ok = await c.login();
    if (ok && context.mounted) context.go(Routes.home);
  }
}
