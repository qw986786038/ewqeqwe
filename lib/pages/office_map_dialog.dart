import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:webview_all/webview_all.dart';
import 'package:yidivination/bokong/webview/webview_platform.dart';
import 'package:yidivination/bokong/widget/amap/amap_config.dart';

const _kMuted = Color(0xFF8C8C8C);
const _kTitle = Color(0xFF1D2129);
const _kBorder = Color(0xFFE5E6EB);

/// 打开「{姓名} · 办公地图」弹窗（高德 JS SDK 地理编码 + 地图瓦片）。
Future<void> showOfficeMapDialog(
  BuildContext context, {
  required String personName,
  required String address,
  String? companyName,
  String? city,
  double? longitude,
  double? latitude,
}) {
  final name = personName.trim().isEmpty ? '联系人' : personName.trim();
  final addr = address.trim();
  return showHyperDialog<void>(
    context: context,
    builder: (dialogContext) => _OfficeMapDialog(
      title: '$name · 办公地图',
      address: addr,
      companyName: (companyName ?? '').trim(),
      city: (city ?? '').trim(),
      longitude: longitude,
      latitude: latitude,
    ),
  );
}

/// 打开高德导航 / 搜索（桌面端用系统浏览器）。
Future<void> openAmapNavigation(
  BuildContext context, {
  required String address,
  String? name,
  double? longitude,
  double? latitude,
}) async {
  final addr = address.trim();
  if (addr.isEmpty && (longitude == null || latitude == null)) {
    showHyperToast(context, content: const Text('暂无地址可导航'));
    return;
  }
  final label = (name ?? '').trim().isNotEmpty
      ? name!.trim()
      : (addr.isNotEmpty ? addr : '目的地');
  final Uri uri;
  if (longitude != null && latitude != null) {
    uri = Uri.parse(
      'https://uri.amap.com/navigation?to=$longitude,$latitude,${Uri.encodeComponent(label)}&mode=car&coordinate=gaode&callnative=1',
    );
  } else {
    uri = Uri.parse(
      'https://uri.amap.com/search?keyword=${Uri.encodeComponent(addr)}&callnative=1',
    );
  }
  final url = uri.toString();
  try {
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [url]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [url]);
    } else {
      showHyperToast(context, content: const Text('当前平台暂不支持打开导航'));
    }
  } catch (e) {
    if (!context.mounted) return;
    showHyperToast(context, content: Text('打开导航失败：$e'));
  }
}

/// 嵌入式高德办公地图（详情卡 / 弹窗共用）。
class OfficeAmapView extends StatefulWidget {
  const OfficeAmapView({
    super.key,
    this.address = '',
    this.city = '',
    this.longitude,
    this.latitude,
    this.showZoomControl = true,
    this.onLocationReady,
  });

  final String address;
  final String city;
  final double? longitude;
  final double? latitude;
  final bool showZoomControl;
  final void Function(double lng, double lat)? onLocationReady;

  @override
  State<OfficeAmapView> createState() => OfficeAmapViewState();
}

class OfficeAmapViewState extends State<OfficeAmapView> {
  WebViewController? _controller;
  String? _loadError;
  var _loading = true;
  double? lng;
  double? lat;

  bool get _canUseWebView {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return isWebView2Ready;
    }
    return true;
  }

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestures =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      };

  @override
  void initState() {
    super.initState();
    lng = widget.longitude;
    lat = widget.latitude;
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant OfficeAmapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final addressChanged = oldWidget.address != widget.address;
    final cityChanged = oldWidget.city != widget.city;
    final lngChanged = oldWidget.longitude != widget.longitude;
    final latChanged = oldWidget.latitude != widget.latitude;
    if (addressChanged || cityChanged || lngChanged || latChanged) {
      unawaited(disposeAppWebViewController(_controller));
      _controller = null;
      setState(() {
        _loading = true;
        _loadError = null;
        lng = widget.longitude;
        lat = widget.latitude;
      });
      _bootstrap();
    }
  }

  @override
  void dispose() {
    final c = _controller;
    _controller = null;
    unawaited(disposeAppWebViewController(c));
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_canUseWebView && defaultTargetPlatform == TargetPlatform.windows) {
      await retryInitWebViewPlatform();
      if (!mounted) return;
      setState(() {});
    }
    if (!_canUseWebView) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '当前环境无法加载地图（WebView2 未就绪）';
        });
      }
      return;
    }
    final addr = widget.address.trim();
    final hasCoord = widget.longitude != null && widget.latitude != null;
    if (!hasCoord && addr.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '暂无办公地址';
        });
      }
      return;
    }
    try {
      final html = await _buildHtml();
      if (!mounted) return;
      await _setupController(html);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '地图资源加载失败：$e';
      });
    }
  }

  Future<String> _buildHtml() async {
    final template = await rootBundle.loadString(
      'assets/web/amap_office_map.html',
    );
    final securityHtml = securityJsCode.isEmpty
        ? ''
        : '<script>window._AMapSecurityConfig = {securityJsCode:${jsonEncode(securityJsCode)}};</script>';
    final lng = widget.longitude;
    final lat = widget.latitude;
    return template
        .replaceAll('__AMAP_KEY__', webJsApiKey)
        .replaceAll('__SECURITY_BLOCK__', securityHtml)
        .replaceAll('__ADDRESS_JSON__', jsonEncode(widget.address.trim()))
        .replaceAll('__CITY_JSON__', jsonEncode(widget.city.trim()))
        .replaceAll(
          '__LNG_JSON__',
          lng == null ? 'null' : jsonEncode(lng),
        )
        .replaceAll(
          '__LAT_JSON__',
          lat == null ? 'null' : jsonEncode(lat),
        )
        .replaceAll('__SHOW_ZOOM__', widget.showZoomControl ? 'true' : 'false');
  }

  Future<void> _setupController(String html) async {
    final controller = createAppWebViewController(
      onPermissionRequest: (request) => request.grant(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.addJavaScriptChannel(
      'onOfficeMapReady',
      onMessageReceived: (message) {
        try {
          final decoded = jsonDecode(message.message);
          if (decoded is! Map) return;
          final map = Map<String, dynamic>.from(decoded);
          if (map['ok'] == true) {
            final nextLng = _asDouble(map['lng']);
            final nextLat = _asDouble(map['lat']);
            if (!mounted || nextLng == null || nextLat == null) return;
            setState(() {
              lng = nextLng;
              lat = nextLat;
            });
            widget.onLocationReady?.call(nextLng, nextLat);
          }
        } catch (_) {}
      },
    );
    await controller.setNavigationDelegate(NavigationDelegate());
    await applyAndroidWebViewExtras(controller, grantGeolocation: false);
    await controller.loadHtmlString(
      html,
      baseUrl: 'https://local.map.office/',
    );
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  static double? _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Color(0xFFF5F7FA),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_loadError != null) {
      return ColoredBox(
        color: const Color(0xFFF5F7FA),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: Color(0xFFF5F7FA),
        child: Center(
          child: Text(
            '地图未就绪',
            style: TextStyle(fontSize: 12, color: _kMuted),
          ),
        ),
      );
    }
    return WebViewWidget(
      controller: controller,
      gestureRecognizers: _gestures,
    );
  }
}

class _OfficeMapDialog extends StatefulWidget {
  const _OfficeMapDialog({
    required this.title,
    required this.address,
    required this.companyName,
    required this.city,
    this.longitude,
    this.latitude,
  });

  final String title;
  final String address;
  final String companyName;
  final String city;
  final double? longitude;
  final double? latitude;

  @override
  State<_OfficeMapDialog> createState() => _OfficeMapDialogState();
}

class _OfficeMapDialogState extends State<_OfficeMapDialog> {
  final _mapKey = GlobalKey<OfficeAmapViewState>();
  double? _lng;
  double? _lat;

  @override
  void initState() {
    super.initState();
    _lng = widget.longitude;
    _lat = widget.latitude;
  }

  Future<void> _copyAddress() async {
    final text = widget.address.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showHyperToast(context, content: const Text('已复制地址'));
  }

  Future<void> _navigate() async {
    final state = _mapKey.currentState;
    await openAmapNavigation(
      context,
      address: widget.address,
      name: widget.companyName.isNotEmpty ? widget.companyName : null,
      longitude: state?.lng ?? _lng,
      latitude: state?.lat ?? _lat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.companyName;
    final address = widget.address;

    return HyperDialog(
      title: Text(widget.title),
      scrollable: false,
      style: const HyperDialogStyle(maxWidth: 720),
      content: SizedBox(
        height: 460,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OfficeAmapView(
                  key: _mapKey,
                  address: address,
                  city: widget.city,
                  longitude: widget.longitude,
                  latitude: widget.latitude,
                  onLocationReady: (lng, lat) {
                    setState(() {
                      _lng = lng;
                      _lat = lat;
                    });
                  },
                ),
                if (company.isNotEmpty || address.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (company.isNotEmpty)
                              Text(
                                company,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTitle,
                                ),
                              ),
                            if (company.isNotEmpty && address.isNotEmpty)
                              const SizedBox(height: 4),
                            if (address.isNotEmpty)
                              Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        HyperButton.outlined(
          onPressed: address.isEmpty ? null : _copyAddress,
          label: const Text('复制地址'),
        ),
        HyperButton.filled(
          onPressed: address.isEmpty && _lng == null ? null : _navigate,
          label: const Text('导航到访'),
        ),
      ],
    );
  }
}
