import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yidivination/bokong/webview/webview_platform.dart';
import 'package:webview_all/webview_all.dart';

import 'amap_config.dart';
import 'amap_location_pick_result.dart';

const String _kHandlerLocationChanged = 'onLocationChanged';
const String _kJsInitPickerFn = 'flutterMapInitPicker';

/// 地图选点 WebView（搜索 + 点击选点 + 逆地理编码）。
class AmapLocationPickerWidget extends StatefulWidget {
  const AmapLocationPickerWidget({
    super.key,
    this.initial,
    this.city,
    this.onChanged,
  });

  final AmapLocationPickResult? initial;
  final String? city;
  final ValueChanged<AmapLocationPickResult>? onChanged;

  @override
  State<AmapLocationPickerWidget> createState() =>
      AmapLocationPickerWidgetState();
}

class AmapLocationPickerWidgetState extends State<AmapLocationPickerWidget> {
  WebViewController? _controller;
  String? _loadError;
  bool _loading = true;

  AmapLocationPickResult? _current;

  AmapLocationPickResult? get current => _current;

  bool get hasSelection => _current?.isValid == true;

  bool get _canUseWebView {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return isWebView2Ready;
    }
    return true;
  }

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _primeNativeLocationPermission();
    _bootstrap();
  }

  @override
  void dispose() {
    final WebViewController? controller = _controller;
    _controller = null;
    unawaited(disposeAppWebViewController(controller));
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_canUseWebView && defaultTargetPlatform == TargetPlatform.windows) {
      await retryInitWebViewPlatform();
      if (!mounted) return;
      setState(() {});
    }
    if (!_canUseWebView) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final String html = await _loadPickerHtml();
      if (!mounted) return;
      await _setupController(html);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '地图资源加载失败：$e';
        _loading = false;
      });
    }
  }

  Future<void> _primeNativeLocationPermission() async {
    if (kIsWeb) return;
    if (!const <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ].contains(defaultTargetPlatform)) {
      return;
    }
    try {
      final PermissionStatus status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {}
  }

  Future<String> _loadPickerHtml() async {
    final String template = await rootBundle.loadString(
      'assets/web/amap_picker_map.html',
    );
    final String securityHtml = securityJsCode.isEmpty
        ? ''
        : '<script>window._AMapSecurityConfig = {securityJsCode:${jsonEncode(securityJsCode)}};</script>';
    return template
        .replaceAll('__AMAP_KEY__', webJsApiKey)
        .replaceAll('__SECURITY_BLOCK__', securityHtml);
  }

  Future<void> _setupController(String html) async {
    final WebViewController controller = createAppWebViewController(
      onPermissionRequest: (WebViewPermissionRequest request) =>
          request.grant(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.addJavaScriptChannel(
      _kHandlerLocationChanged,
      onMessageReceived: (JavaScriptMessage message) {
        final Map<String, dynamic>? payload = _parseMessage(message.message);
        if (payload == null) return;
        final AmapLocationPickResult next = AmapLocationPickResult.fromJson(
          payload,
        );
        if (!next.hasCoordinates || !mounted) return;
        _current = next;
        widget.onChanged?.call(next);
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) async {
          await _pushInitToWeb(controller);
          await _resizeMap(controller);
        },
      ),
    );
    await applyAndroidWebViewExtras(controller, grantGeolocation: true);
    await controller.loadHtmlString(html, baseUrl: 'https://local.map.picker/');
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  Map<String, dynamic>? _parseMessage(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> _pushInitToWeb(WebViewController controller) async {
    final Map<String, Object?> payload = <String, Object?>{
      'city': widget.city,
      if (widget.initial != null) ...<String, Object?>{
        'lng': widget.initial!.longitude,
        'lat': widget.initial!.latitude,
        'address': widget.initial!.address,
      },
    };
    final String jsonPayload = jsonEncode(payload);
    final String source =
        '''
(function(){
  window.__pendingPickerInit = $jsonPayload;
  if (window.__amapPickerReady === 1 && typeof window.$_kJsInitPickerFn === 'function') {
    window.$_kJsInitPickerFn(window.__pendingPickerInit);
    window.__pendingPickerInit = null;
  }
})();
''';
    await controller.runJavaScript(source);
  }

  Future<void> _resizeMap(WebViewController controller) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await controller.runJavaScript(
      'if (typeof window.flutterMapResize === "function") window.flutterMapResize();',
    );
  }

  Future<void> searchByKeyword(String keyword) async {
    final WebViewController? controller = _controller;
    final text = keyword.trim();
    if (controller == null || text.isEmpty) return;
    await controller.runJavaScript(
      'if (typeof window.flutterMapSearch === "function") window.flutterMapSearch(${jsonEncode(text)});',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canUseWebView) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppText.body(
            webViewInitError ?? '当前环境无法加载地图（WebView2 未就绪）',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Center(child: AppText.body(_loadError!));
    }

    final WebViewController? controller = _controller;
    if (_loading || controller == null) {
      return const Center(child: AppCircularProgressIndicator());
    }

    return WebViewWidget(
      controller: controller,
      gestureRecognizers: _gestureRecognizers,
    );
  }
}
