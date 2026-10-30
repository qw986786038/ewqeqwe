import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_ui/lemon_ui.dart';

import 'pages/login_page.dart';

const _kPrimary = Color(0xFF1677FF);
/// 桌面端整体略放大；弹窗用固定逻辑宽高约束，避免跟着显得过大。
const _kDesktopTextScale = 1.12;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '媒花易数',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizationsZh.delegate,
        shad.ShadcnLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _kPrimary),
        useMaterial3: true,
      ),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return HyperDeviceDetector(
          child: child,
          builder: (context, deviceType, child) {
            return HyperTheme(
              data: HyperThemeData.light(seedColor: _kPrimary),
              child: MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(
                    _kDesktopTextScale * mq.textScaler.scale(1),
                  ),
                ),
                // HyperSnackbarHost 用 OverlayPortal，须在 Overlay 之下
                //（不可直接挂在 Navigator 之上的 builder 裸层）。
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => HyperSnackbarHost(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      home: const LoginPage(),
    );
  }
}
