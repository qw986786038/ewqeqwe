import 'dart:io' show Platform;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:media_kit/media_kit.dart';
import 'package:toastification/toastification.dart';
import 'package:yidivination/bokong/router/routes.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/theme/windows_controls.dart';
import 'package:yidivination/bokong/webview/webview_platform.dart';

import 'http/sp.dart';
import 'mapper.mapper.g.dart';

const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
  PointerDeviceKind.trackpad,
};

bool _bokongInitialized = false;

/// 播控模块启动前初始化（与主软件入口分离，可重复调用）。
Future<void> ensureBokongInitialized() async {
  if (_bokongInitialized) return;
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  initializeJsonMapper();
  await Sp.init();
  await initWindow();
  await _initMacOSFilePicker();
  await initWebViewPlatform();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _bokongInitialized = true;
}

/// macOS 沙盒 entitlement 在 ad-hoc 签名下可能无法被运行时读取，
/// 导致 file_picker 误报 ENTITLEMENT_NOT_FOUND；启动时跳过该校验。
Future<void> _initMacOSFilePicker() async {
  if (!Platform.isMacOS) return;
  await FilePicker.skipEntitlementsChecks();
}

/// 播控独立应用壳：自带路由与登录，暂不与主软件共用账号。
class BokongApp extends StatefulWidget {
  const BokongApp({super.key});

  @override
  State<BokongApp> createState() => _BokongAppState();
}

class _BokongAppState extends State<BokongApp> {
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: const ToastificationConfig(
        maxToastLimit: 3,
      ),
      child: LemonApp(
        child: MaterialApp.router(
          title: '播控',
          locale: const Locale('zh', 'CN'),
          supportedLocales: const <Locale>[
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (BuildContext context, Widget? child) {
            final MediaQueryData mq = MediaQuery.of(context);
            return AppShadcnScope.builder(
              config: AppThemes.config,
              locale: const Locale('zh', 'CN'),
            )(
              context,
              MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(0.875 * mq.textScaler.scale(1)),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: true,
            dragDevices: _kTouchLikeDeviceTypes,
          ),
          theme: AppThemes.light,
          routerConfig: Routes.routes,
        ),
      ),
    );
  }
}
