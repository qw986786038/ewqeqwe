import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_android/webview_all_android.dart';
import 'package:webview_all_windows/webview_all_windows.dart';

import 'webview_stub_dirs.dart'
    if (dart.library.io) 'webview_io_dirs.dart'
    as webview_dirs;

/// Windows WebView2 是否已成功初始化；其它平台视为就绪。
bool _windowsWebViewReady = false;

/// 合并并发初始化，避免重复调用 [WindowsWebViewController.initializeEnvironment]。
Future<void>? _windowsInitFuture;

/// WebView2 初始化失败时的说明（Release 也可在界面展示）。
String? webViewInitError;

/// Windows 是否已成功初始化 WebView2；其它非 Web 平台恒为 true。
bool get isWebView2Ready {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.windows) return true;
  return _windowsWebViewReady;
}

/// 在 [runApp] 之前调用：Android 调试、Windows WebView2 用户数据目录等。
Future<void> initWebViewPlatform() async {
  webViewInitError = null;
  if (kIsWeb) {
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    await AndroidWebViewController.enableDebugging(kDebugMode);
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.windows) {
    await _initWindowsWebView2();
  }
}

/// 地图等首次使用时若启动阶段失败，可再试一次。
Future<void> retryInitWebViewPlatform() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
  if (_windowsWebViewReady) return;
  await _initWindowsWebView2();
}

/// Android 定位权限弹窗、媒体手势等平台扩展。
Future<void> applyAndroidWebViewExtras(
  WebViewController controller, {
  bool grantGeolocation = true,
}) async {
  if (controller.platform is! AndroidWebViewController) return;
  final AndroidWebViewController android =
      controller.platform as AndroidWebViewController;
  await android.setMediaPlaybackRequiresUserGesture(false);
  await android.setGeolocationPermissionsPromptCallbacks(
    onShowPrompt: (GeolocationPermissionsRequestParams request) async {
      return GeolocationPermissionsResponse(
        allow: grantGeolocation,
        retain: false,
      );
    },
  );
}

/// 创建带 Windows 弹窗策略的 [WebViewController]（禁止独立弹窗 HWND）。
WebViewController createAppWebViewController({
  void Function(WebViewPermissionRequest request)? onPermissionRequest,
}) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    return WebViewController.fromPlatformCreationParams(
      const WindowsWebViewControllerCreationParams(
        popupWindowPolicy: WindowsPopupWindowPolicy.deny,
      ),
      onPermissionRequest: onPermissionRequest,
    );
  }
  return WebViewController(onPermissionRequest: onPermissionRequest);
}

/// 释放 WebView，避免 Windows 上残留 Intermediate D3D 命中层。
Future<void> disposeAppWebViewController(WebViewController? controller) async {
  if (controller == null) return;
  try {
    final Object platform = controller.platform;
    if (platform is WindowsWebViewController) {
      await platform.dispose();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[webview] dispose failed: $e');
    }
  }
}

Future<String> _resolveWebView2UserDataFolder() async {
  try {
    final Directory support = await getApplicationSupportDirectory();
    return p.join(support.path, 'smart_admin', 'webview_all', 'webview2');
  } catch (_) {
    final String base =
        Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        '.';
    return p.join(base, 'SmartAdmin', 'webview2');
  }
}

bool _isEnvironmentAlreadyInitialized(Object error) {
  if (error is PlatformException) {
    return error.code == 'environment_already_initialized';
  }
  return error.toString().contains('environment_already_initialized');
}

Future<void> _initWindowsWebView2() async {
  if (_windowsWebViewReady) return;
  if (_windowsInitFuture != null) {
    await _windowsInitFuture;
    return;
  }

  _windowsInitFuture = _doInitWindowsWebView2();
  try {
    await _windowsInitFuture;
  } finally {
    _windowsInitFuture = null;
  }
}

Future<void> _doInitWindowsWebView2() async {
  webViewInitError = null;
  final String? version = await WindowsWebViewController.getWebViewVersion();
  if (version == null) {
    _windowsWebViewReady = false;
    webViewInitError =
        '未检测到 WebView2 运行时，请安装 Microsoft Edge WebView2 Runtime 后重试。';
    if (kDebugMode) {
      debugPrint('[webview] $webViewInitError');
    }
    return;
  }

  try {
    final String folder = await _resolveWebView2UserDataFolder();
    await webview_dirs.ensureWebViewUserDataDirectory(folder);
    await WindowsWebViewController.initializeEnvironment(userDataPath: folder);
    _windowsWebViewReady = true;
  } catch (e, st) {
    // 热重载后 Dart 状态重置，但进程内 WebView2 环境仍在；视为已就绪。
    if (_isEnvironmentAlreadyInitialized(e)) {
      _windowsWebViewReady = true;
      webViewInitError = null;
      if (kDebugMode) {
        debugPrint('[webview] WebView2 环境已初始化，跳过重复 initializeEnvironment');
      }
      return;
    }
    _windowsWebViewReady = false;
    webViewInitError = 'WebView2 初始化失败：$e';
    if (kDebugMode) {
      debugPrint(
        '[webview] WindowsWebViewController.initializeEnvironment 失败: $e\n$st',
      );
    }
  }
}
