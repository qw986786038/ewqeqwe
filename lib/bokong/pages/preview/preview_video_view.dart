import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:yidivination/bokong/constant.dart';
import 'package:yidivination/bokong/pages/preview/preview_dialog_layout.dart';

enum PreviewVideoKind { network, file, asset }

class PreviewVideoSource {
  const PreviewVideoSource._(this.kind, {this.url, this.filePath, this.asset});

  final PreviewVideoKind kind;
  final String? url;
  final String? filePath;
  final String? asset;

  factory PreviewVideoSource.parse(String raw) {
    final String path = raw.trim();
    if (path.isEmpty) {
      throw ArgumentError('videoPath 不能为空');
    }

    if (path.startsWith('assets/')) {
      return PreviewVideoSource._(PreviewVideoKind.asset, asset: path);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return PreviewVideoSource._(PreviewVideoKind.network, url: path);
    }

    if (path.startsWith('file://')) {
      return PreviewVideoSource._(
        PreviewVideoKind.file,
        filePath: Uri.parse(path).toFilePath(),
      );
    }

    if (path.startsWith('/')) {
      final String base = Constant.baseUrl.endsWith('/')
          ? Constant.baseUrl.substring(0, Constant.baseUrl.length - 1)
          : Constant.baseUrl;
      return PreviewVideoSource._(PreviewVideoKind.network, url: '$base$path');
    }

    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path)) {
      return PreviewVideoSource._(PreviewVideoKind.file, filePath: path);
    }

    return PreviewVideoSource._(PreviewVideoKind.network, url: path);
  }

  Media toMedia() {
    return switch (kind) {
      PreviewVideoKind.network => Media(url!),
      PreviewVideoKind.file => Media(Uri.file(filePath!).toString()),
      PreviewVideoKind.asset => Media('asset:///$asset'),
    };
  }
}

/// 使用 media_kit 播放视频/直播预览。
class PreviewVideoView extends StatefulWidget {
  const PreviewVideoView({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<PreviewVideoView> createState() => _PreviewVideoViewState();
}

class _PreviewVideoViewState extends State<PreviewVideoView> {
  late final Player _player;
  late final VideoController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.stream.error.listen((String message) {
      if (!mounted) return;
      setState(() => _error = message);
    });
    _open();
  }

  Future<void> _open() async {
    try {
      final Media media = PreviewVideoSource.parse(widget.videoPath).toMedia();
      await _player.open(media);
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _player.playOrPause,
      child: Video(
        controller: _controller,
        fit: BoxFit.contain,
        controls: NoVideoControls,
      ),
    );
  }
}

/// 弹窗预览视频。
Future<void> showVideoPreviewDialog({
  required BuildContext context,
  required String videoPath,
  String? title,
}) {
  return showPreviewDialog(
    context: context,
    title: title?.isNotEmpty == true ? title! : '视频预览',
    child: PreviewVideoView(videoPath: videoPath),
  );
}
