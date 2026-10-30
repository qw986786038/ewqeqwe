import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_js/lemon_js.dart';
import 'package:lemon_js_ui/lemon_js_ui.dart';
import 'package:lemon_js_ui_video_player/lemon_js_ui_video_player.dart';
import 'package:yidivination/bokong/pages/preview/preview_dialog_layout.dart';

final _pluginFeatures = <JsFeatures>[AxiosFeatures()];

final _pluginUiPlugins = <JsUiPlugin>[JsUiVideoPlayerPlugin.plugin];

/// 大屏插件设计分辨率（竖屏 9:16）。
const Size _pluginDesignSize = Size(675, 1200);

/// 使用 lemon_js_ui 预览插件（`.mjs`）。
class PreviewPluginView extends StatefulWidget {
  const PreviewPluginView({super.key, required this.path});

  final String path;

  @override
  State<PreviewPluginView> createState() => _PreviewPluginViewState();
}

class _PreviewPluginViewState extends State<PreviewPluginView> {
  late final JsUiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JsUiController(
      devOptions: JsUiDevOptions.release,
      onConsole: _onConsole,
    );
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    super.dispose();
  }

  void _onConsole(JsConsoleEvent event) {
    debugPrint('[plugin.console/${event.level.name}] ${event.text}');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: _scaleToDesign(_buildView(_controller)),
    );
  }

  Widget _scaleToDesign(Widget child) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _pluginDesignSize.width,
          height: _pluginDesignSize.height,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: _pluginDesignSize),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildView(JsUiController controller) {
    final String path = widget.path.trim();
    final Uri? uri = Uri.tryParse(path);
    final String resourcePath =
        (uri != null && uri.path.isNotEmpty ? uri.path : path).toLowerCase();
    final bool isMjs = resourcePath.endsWith('.mjs');

    Widget loadingBuilder(BuildContext context) =>
        const Center(child: CircularProgressIndicator());
    Widget errorBuilder(BuildContext context, JsUiError error) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '$error',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (!isMjs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '无法预览该插件：仅支持 .mjs 模块',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return JsUiView.network(
        url: uri,
        controller: controller,
        uiPlugins: _pluginUiPlugins,
        features: _pluginFeatures,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
      );
    }
    if (path.startsWith('assets/')) {
      return JsUiView.asset(
        path: path,
        controller: controller,
        uiPlugins: _pluginUiPlugins,
        features: _pluginFeatures,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
      );
    }
    return JsUiView.file(
      path: path,
      controller: controller,
      uiPlugins: _pluginUiPlugins,
      features: _pluginFeatures,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}

/// 弹窗预览插件。
Future<void> showPluginPreviewDialog({
  required BuildContext context,
  required String path,
  String? title,
}) {
  return showPreviewDialog(
    context: context,
    title: title?.isNotEmpty == true ? title! : '插件预览',
    child: PreviewPluginView(path: path),
  );
}
