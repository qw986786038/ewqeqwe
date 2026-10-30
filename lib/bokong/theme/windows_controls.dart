import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_window_caption.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initWindow() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(1070, 760),
      minimumSize: Size(1070, 760),
      title: "媒花易数",
      center: true,
      // backgroundColor: Colors.white,
      skipTaskbar: false,
      // titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      // if (WindowsVersionHelper.isWindows11()) {
      //   await Window.setEffect(effect: WindowEffect.mica, dark: false);
      // } else {
      //   await Window.setEffect(effect: WindowEffect.acrylic, dark: false);
      // }
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

///windows控制器，全局隐藏键盘
Widget windowsControls(BuildContext context, Widget? child) {
  // if (FluentTheme.of(context).brightness == Brightness.light) {
  //   debounceHelper.debounce(() {
  //     if (WindowsVersionHelper.isWindows11()) {
  //       Window.setEffect(effect: WindowEffect.mica, dark: false);
  //     } else {
  //       Window.setEffect(effect: WindowEffect.acrylic, dark: false);
  //     }
  //   });
  // } else {
  //   debounceHelper.debounce(() {
  //     if (WindowsVersionHelper.isWindows11()) {
  //       Window.setEffect(effect: WindowEffect.mica, dark: true);
  //     } else {
  //       Window.setEffect(effect: WindowEffect.acrylic, dark: true);
  //     }
  //   });
  // }

  return GestureDetector(
    onTap: () {
      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    },
    child: (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
        ? Stack(
            children: [
              child ?? Container(),
              Container(
                margin: const EdgeInsets.only(left: 50),
                height: kWindowCaptionHeight,
                child: const AppWindowCaption(brightness: Brightness.light),
              ),
            ],
          )
        : child ?? Container(),
  );
}
