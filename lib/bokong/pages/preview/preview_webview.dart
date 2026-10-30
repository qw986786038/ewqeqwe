import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/constant.dart';
import 'package:yidivination/bokong/pages/preview/preview_dialog_layout.dart';
import 'package:yidivination/bokong/utils/CustomBase64.dart';
import 'package:yidivination/bokong/webview/webview_platform.dart';
import 'package:webview_all/webview_all.dart';

enum PreviewWebTargetKind { network, file, asset }

class PreviewWebTarget {
  const PreviewWebTarget._(this.kind, {this.url, this.filePath, this.asset});

  final PreviewWebTargetKind kind;
  final String? url;
  final String? filePath;
  final String? asset;

  factory PreviewWebTarget.parse(String raw) {
    final String path = raw.trim();
    if (path.isEmpty) {
      throw ArgumentError('url 不能为空');
    }

    if (path.startsWith('assets/')) {
      return PreviewWebTarget._(PreviewWebTargetKind.asset, asset: path);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return PreviewWebTarget._(PreviewWebTargetKind.network, url: path);
    }

    if (path.startsWith('file://')) {
      return PreviewWebTarget._(
        PreviewWebTargetKind.file,
        filePath: Uri.parse(path).toFilePath(),
      );
    }

    if (path.startsWith('/')) {
      final String base = Constant.baseUrl.endsWith('/')
          ? Constant.baseUrl.substring(0, Constant.baseUrl.length - 1)
          : Constant.baseUrl;
      return PreviewWebTarget._(
        PreviewWebTargetKind.network,
        url: '$base$path',
      );
    }

    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path)) {
      return PreviewWebTarget._(PreviewWebTargetKind.file, filePath: path);
    }

    return PreviewWebTarget._(PreviewWebTargetKind.network, url: path);
  }
}

/// 使用 webview_all 展示网页内容。
class PreviewWebView extends StatefulWidget {
  const PreviewWebView({
    super.key,
    required this.url,
    this.fitViewport = false,
    this.deviceNo,
  });

  final String url;

  /// 侧边栏等内嵌场景：隐藏滚动条，并尽量缩放内容以适配可视区域。
  final bool fitViewport;

  /// 设备编号：注入 `window.getScreenNo()`（CustomBase64，对齐终端播放器）。
  final String? deviceNo;

  @override
  State<PreviewWebView> createState() => _PreviewWebViewState();
}

class _PreviewWebViewState extends State<PreviewWebView> {
  static const _screenNoPrompt = '__palsmon_getScreenNo__';

  WebViewController? _controller;
  int _progress = 0;
  bool _loading = true;
  bool _retrying = false;
  bool _initFailed = false;

  bool get _canUseWebView {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return isWebView2Ready;
    }
    return true;
  }

  String get _encodedScreenNo {
    final no = widget.deviceNo?.trim() ?? '';
    if (no.isEmpty) return '';
    return CustomBase64.encode(utf8.encode(no));
  }

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  @override
  void initState() {
    super.initState();
    if (_canUseWebView) {
      _setupController();
    }
  }

  @override
  void didUpdateWidget(covariant PreviewWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceNo == widget.deviceNo) return;
    final controller = _controller;
    if (controller == null) return;
    unawaited(_injectNativeApi(controller));
  }

  @override
  void dispose() {
    final WebViewController? controller = _controller;
    _controller = null;
    unawaited(disposeAppWebViewController(controller));
    super.dispose();
  }

  Future<void> _retryInit() async {
    setState(() {
      _retrying = true;
      _initFailed = false;
    });
    await retryInitWebViewPlatform();
    if (!mounted) return;
    setState(() => _retrying = false);
    if (_canUseWebView) {
      await _setupController();
    }
  }

  Future<void> _setupController() async {
    try {
      final WebViewController controller = createAppWebViewController(
        onPermissionRequest: (WebViewPermissionRequest request) =>
            request.grant(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.enableZoom(false);
      try {
        await controller.setVerticalScrollBarEnabled(false);
        await controller.setHorizontalScrollBarEnabled(false);
      } catch (_) {}
      try {
        await controller.setOnJavaScriptTextInputDialog((request) async {
          if (request.message == _screenNoPrompt) {
            return _encodedScreenNo;
          }
          return request.defaultText ?? '';
        });
      } catch (_) {}
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loading = true);
            unawaited(_injectNativeApi(controller));
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
            unawaited(() async {
              await _injectNativeApi(controller);
              await _applyFitViewport(controller);
            }());
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onProgress: (int value) {
            if (!mounted) return;
            setState(() {
              _progress = value;
              if (value >= 100) _loading = false;
            });
          },
        ),
      );
      await applyAndroidWebViewExtras(controller, grantGeolocation: false);
      await _loadContent(controller);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _controller = null;
        _initFailed = true;
        _loading = false;
      });
      if (kDebugMode) {
        debugPrint('[webview] PreviewWebView 初始化失败: $e');
      }
    }
  }

  Future<void> _loadContent(WebViewController controller) async {
    final PreviewWebTarget target = PreviewWebTarget.parse(widget.url);
    switch (target.kind) {
      case PreviewWebTargetKind.network:
        await controller.loadRequest(Uri.parse(target.url!));
      case PreviewWebTargetKind.file:
        await controller.loadFile(target.filePath!);
      case PreviewWebTargetKind.asset:
        await controller.loadFlutterAsset(target.asset!);
    }
  }

  /// 对齐终端播放器：页面通过 `window.getScreenNo()` 取设备码（CustomBase64）。
  Future<void> _injectNativeApi(WebViewController controller) async {
    final encoded = jsonEncode(_encodedScreenNo);
    try {
      await controller.runJavaScript('''
(function() {
  window.getScreenNo = function() {
    return $encoded;
  };
})();
''');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[webview] getScreenNo 注入失败: $e');
      }
    }
  }

  Future<void> _applyFitViewport(WebViewController controller) async {
    if (!widget.fitViewport) return;
    try {
      await controller.runJavaScript('''
(function () {
  var doc = document.documentElement;
  var body = document.body;
  if (!body) return;
  doc.style.overflow = 'hidden';
  body.style.overflow = 'hidden';
  body.style.margin = '0';
  var sw = Math.max(doc.scrollWidth || 0, body.scrollWidth || 0, 1);
  var sh = Math.max(doc.scrollHeight || 0, body.scrollHeight || 0, 1);
  var scale = Math.min(window.innerWidth / sw, window.innerHeight / sh);
  if (scale > 0 && scale < 1) {
    body.style.transformOrigin = '0 0';
    body.style.transform = 'scale(' + scale + ')';
    body.style.width = (100 / scale) + '%';
  }
})();
''');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[webview] fitViewport 注入失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_retrying) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canUseWebView || _initFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                webViewInitError ?? 'WebView 未就绪，无法预览网页',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (defaultTargetPlatform == TargetPlatform.windows) ...[
                const SizedBox(height: 16),
                AppButton.primary(
                  child: const Text('重试'),
                  onPressed: _retryInit,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final WebViewController? controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          controller: controller,
          gestureRecognizers: _gestureRecognizers,
        ),
        if (_loading && _progress < 100)
          Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}

/// 弹窗预览网页。
Future<void> showWebPreviewDialog({
  required BuildContext context,
  required String url,
  String? title,
  String? deviceNo,
}) {
  return showPreviewDialog(
    context: context,
    title: title?.isNotEmpty == true ? title! : '网页预览',
    child: PreviewWebView(url: url, deviceNo: deviceNo),
  );
}
