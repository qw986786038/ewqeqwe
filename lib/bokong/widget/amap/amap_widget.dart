import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yidivination/bokong/webview/webview_platform.dart';
import 'package:webview_all/webview_all.dart';

import 'amap_config.dart';
import 'amap_map_styles.dart';
import 'amap_marker.dart';

export 'amap_marker.dart';

/// 高德页内由 Flutter `runJavaScript` 调用的全局函数名。
const String _kJsAddMarkersFn = 'flutterMapAddMarkers';

/// JS → Flutter：选中标记锚点像素坐标（地图容器内）。
const String _kHandlerMarkerAnchor = 'onMarkerAnchor';

/// JS → Flutter：点击地图标记后回调。
const String _kHandlerMarkerTap = 'onMarkerTap';

/// Flutter → JS：同步明暗主题（弹层 CSS + 底图 mapStyle）。
const String _kJsApplyThemeFn = 'flutterMapApplyTheme';

class AmapWidget extends StatefulWidget {
  const AmapWidget({
    super.key,
    this.markers,
    this.onMarkerTap,
    this.onMarkerAnchor,
    this.grantWebViewGeolocation = true,
    this.requestNativeLocationPermission = true,
    this.appBarTitle = '高德地图 · Flutter 联动',

    /// 嵌入页面时为 true，避免嵌套 [Scaffold] 引发布局/释放问题。
    this.embedded = false,
    this.suppressMarkerModal = false,
    this.markerStyle = AmapMarkerStyle.pin,
    this.showZoomControl = true,
  });

  /// 为 null 时不展示标记（不使用内置默认点）。
  final List<AmapMarker>? markers;

  /// 标记被点击时回调到控件外部（与页内弹窗并行）。
  final ValueChanged<AmapMarkerTapPayload>? onMarkerTap;

  /// 选中标记在地图容器内的锚点（拖拽/缩放后会更新）。
  final ValueChanged<AmapMarkerAnchor>? onMarkerAnchor;

  /// 为 true 时不弹出页内 HTML 详情层，仅回调 [onMarkerTap]（地图页 Flutter 自绘详情卡）。
  final bool suppressMarkerModal;

  /// 标记外观；设备管理统一用默认 [AmapMarkerStyle.pin]。
  final AmapMarkerStyle markerStyle;

  /// 是否显示右下角缩放（+/-）工具条。小窗口预览可关。
  final bool showZoomControl;

  /// WebView 内 JS 使用 `navigator.geolocation` 时，是否在 Android 定位权限弹窗中放行。
  final bool grantWebViewGeolocation;

  /// 是否在 Android/iOS 上预先请求系统定位权限，便于 WebView 内定位可用。
  final bool requestNativeLocationPermission;

  final String appBarTitle;

  final bool embedded;

  static const List<AmapMarker> defaultMarkers = <AmapMarker>[
    AmapMarker(
      id: 'screen1',
      longitude: 117.024,
      latitude: 36.666,
      title: '大屏1',
      description: '这是大屏的描述信息，这里占位',
    ),
    AmapMarker(
      id: 'screen2',
      longitude: 117.016,
      latitude: 36.6705,
      title: '大屏2',
      description: '这是大屏的描述信息，这里占位',
    ),
    AmapMarker(
      id: 'screen3',
      longitude: 117.019,
      latitude: 36.664,
      title: '大屏3',
      description: '这是大屏的描述信息，这里占位',
    ),
    AmapMarker(
      id: 'screen4',
      longitude: 117.037173,
      latitude: 36.671451,
      title: '大屏4',
      description: '这是大屏的描述信息，这里占位',
    ),
    AmapMarker(
      id: 'screen5',
      longitude: 117.0175,
      latitude: 36.6665,
      title: '大屏5',
      description: '这是大屏的描述信息，这里占位',
    ),
  ];

  @override
  State<AmapWidget> createState() => _AmapWidgetState();
}

class _AmapWidgetState extends State<AmapWidget> {
  WebViewController? webViewController;
  double progress = 0;

  String? _pageHtml;
  String? _loadHtmlError;

  bool _webViewRetrying = false;

  List<AmapMarker> get _effectiveMarkers =>
      widget.markers ?? const <AmapMarker>[];

  String _markersSignature(List<AmapMarker> list) => list
      .map(
        (AmapMarker e) =>
            '${e.resolvedId}:${e.longitude}:${e.latitude}:${e.title}:${e.initial}:${e.accentColor}:${e.online}:${e.selected}:${e.region}:${e.building}:${e.mediaAddress}:${e.statusLabel}:${e.propertyName}:${e.operationStatus}:${e.soundOn}',
      )
      .join('|');

  bool get _canUseWebView {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return isWebView2Ready;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.requestNativeLocationPermission) {
      _primeNativeLocationPermission();
    }
    _bootstrap();
  }

  @override
  void dispose() {
    final WebViewController? controller = webViewController;
    webViewController = null;
    unawaited(disposeAppWebViewController(controller));
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_canUseWebView && defaultTargetPlatform == TargetPlatform.windows) {
      setState(() => _webViewRetrying = true);
      await retryInitWebViewPlatform();
      if (!mounted) return;
      setState(() => _webViewRetrying = false);
    }
    if (_canUseWebView) {
      await _loadMapHtml();
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
      final PermissionStatus s = await Permission.locationWhenInUse.status;
      if (!s.isGranted) {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {
      // 忽略：部分桌面/模拟器无定位能力
    }
  }

  @override
  void didUpdateWidget(covariant AmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final WebViewController? c = webViewController;
    if (c == null) return;
    final markersChanged =
        _markersSignature(_markersFor(oldWidget)) !=
        _markersSignature(_markersFor(widget));
    final styleChanged =
        oldWidget.markerStyle != widget.markerStyle ||
        oldWidget.suppressMarkerModal != widget.suppressMarkerModal;
    if (markersChanged || styleChanged) {
      _pushMarkersToWeb(c);
    }
  }

  List<AmapMarker> _markersFor(AmapWidget w) =>
      w.markers ?? const <AmapMarker>[];

  Future<void> _loadMapHtml() async {
    try {
      final String template = await rootBundle.loadString(
        'assets/web/amap_map.html',
      );
      final String securityHtml = securityJsCode.isEmpty
          ? ''
          : '<script>window._AMapSecurityConfig = {securityJsCode:${jsonEncode(securityJsCode)}};</script>';
      final String html = template
          .replaceAll('__AMAP_KEY__', webJsApiKey)
          .replaceAll('__SECURITY_BLOCK__', securityHtml)
          .replaceAll(
            '__SHOW_ZOOM_CONTROL__',
            widget.showZoomControl ? 'true' : 'false',
          );
      if (!mounted) return;
      setState(() {
        _pageHtml = html;
        _loadHtmlError = null;
      });
      await _ensureController(html);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadHtmlError = '地图资源加载失败：$e';
        _pageHtml = null;
        webViewController = null;
      });
    }
  }

  Future<void> _ensureController(String html) async {
    if (webViewController != null) return;
    final WebViewController controller = createAppWebViewController(
      onPermissionRequest: (WebViewPermissionRequest request) =>
          request.grant(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.addJavaScriptChannel(
      _kHandlerMarkerTap,
      onMessageReceived: (JavaScriptMessage message) {
        final Map<String, dynamic>? p = _parseMarkerMessage(message.message);
        if (p == null) return;
        widget.onMarkerTap?.call(AmapMarkerTapPayload.fromJson(p));
      },
    );
    await controller.addJavaScriptChannel(
      _kHandlerMarkerAnchor,
      onMessageReceived: (JavaScriptMessage message) {
        final Map<String, dynamic>? p = _parseMarkerMessage(message.message);
        if (p == null) return;
        final anchor = AmapMarkerAnchor.fromJson(p);
        if (anchor.id.isEmpty) {
          widget.onMarkerAnchor?.call(
            const AmapMarkerAnchor(id: '', x: 0, y: 0),
          );
          return;
        }
        widget.onMarkerAnchor?.call(anchor);
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (_) => NavigationDecision.navigate,
        onPageFinished: (_) async {
          if (!mounted) return;
          // macOS WKWebView 的 onProgress 常达不到 100；进度条若叠在地图上会挡住原生命中。
          setState(() => progress = 1.0);
          await _pushThemePayloadToWeb(controller, _mapThemePayload);
          if (!mounted) return;
          await _pushMarkersToWeb(controller);
        },
        onProgress: (int progressValue) {
          if (!mounted) return;
          final next = progressValue / 100;
          if (next <= progress) return;
          setState(() => progress = next);
        },
        onWebResourceError: (WebResourceError error) {
          if (kDebugMode) {
            debugPrint('[amap] WebView error: ${error.description}');
          }
        },
      ),
    );
    await controller.setOnConsoleMessage((
      JavaScriptConsoleMessage consoleMessage,
    ) {
      if (kDebugMode) {
        debugPrint(
          '[amap] ${consoleMessage.level.name}: ${consoleMessage.message}',
        );
      }
    });
    await applyAndroidWebViewExtras(
      controller,
      grantGeolocation: widget.grantWebViewGeolocation,
    );
    await controller.loadHtmlString(html, baseUrl: 'https://local.map.demo/');
    if (!mounted) return;
    setState(() => webViewController = controller);
  }

  Map<String, dynamic>? _parseMarkerMessage(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static const Map<String, String> _mapThemePayload = <String, String>{
    'brightness': 'light',
    'mapStyle': AmapMapStyles.forApp,
  };

  Future<void> _pushThemePayloadToWeb(
    WebViewController controller,
    Map<String, String> themePayload,
  ) async {
    final String jsonTheme = jsonEncode(themePayload);
    final String source =
        '''
(function(){
  window.__pendingTheme = $jsonTheme;
  if (typeof window.$_kJsApplyThemeFn === 'function') {
    window.$_kJsApplyThemeFn(window.__pendingTheme);
  }
})();
''';
    await controller.runJavaScript(source);
  }

  Future<void> _pushMarkersToWeb(WebViewController controller) async {
    final List<Map<String, Object>> list = _effectiveMarkers
        .map((AmapMarker m) => m.toWebMap())
        .toList();
    final String jsonList = jsonEncode(list);
    final String suppressModal = widget.suppressMarkerModal ? 'true' : 'false';
    final String markerStyle = jsonEncode(widget.markerStyle.name);
    final String source =
        '''
(function(){
  window.__amapSuppressMarkerModal = $suppressModal;
  window.__amapMarkerStyle = $markerStyle;
  window.__pendingMarkerList = $jsonList;
  if (window.__amapMapReady === 1 && typeof window.$_kJsAddMarkersFn === 'function') {
    window.$_kJsAddMarkersFn(window.__pendingMarkerList);
  }
})();
''';
    await controller.runJavaScript(source);
  }

  Widget _buildUnavailable(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static final Set<Factory<OneSequenceGestureRecognizer>>
  _mapGestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  Widget _buildMapStack() {
    final WebViewController controller = webViewController!;
    final WebViewWidget webView = WebViewWidget(
      controller: controller,
      // 嵌入滚动/弹层时争抢手势；macOS 上该参数目前是空实现，但仍保留给其它平台。
      gestureRecognizers: _mapGestureRecognizers,
    );
    if (progress >= 1.0) return webView;
    // 进度条只占顶边，避免整层叠在 WebView 上（macOS 会挡住地图拖动/点击）。
    return Stack(
      fit: StackFit.expand,
      children: [
        webView,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 3,
          child: LinearProgressIndicator(value: progress > 0 ? progress : null),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_webViewRetrying ||
        (_pageHtml == null && _loadHtmlError == null && _canUseWebView) ||
        (_pageHtml != null &&
            webViewController == null &&
            _loadHtmlError == null)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadHtmlError != null) {
      return _buildUnavailable(context, _loadHtmlError!);
    }
    if (!_canUseWebView) {
      return _buildUnavailable(
        context,
        webViewInitError ?? '当前环境无法加载地图（WebView2 未就绪）',
      );
    }
    return _buildMapStack();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _buildBody(context);
    if (widget.embedded) {
      return body;
    }
    return Scaffold(body: body);
  }
}
