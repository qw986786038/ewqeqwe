import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:yidivination/bokong/constant.dart';
import 'package:yidivination/bokong/pages/preview/preview_dialog_layout.dart';

enum PreviewImageKind { network, file, asset }

class PreviewImageSource {
  const PreviewImageSource._(this.kind, {this.url, this.file, this.asset});

  final PreviewImageKind kind;
  final String? url;
  final File? file;
  final String? asset;

  factory PreviewImageSource.parse(String raw) {
    final String path = raw.trim();
    if (path.isEmpty) {
      throw ArgumentError('imagePath 不能为空');
    }

    if (path.startsWith('assets/')) {
      return PreviewImageSource._(PreviewImageKind.asset, asset: path);
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return PreviewImageSource._(PreviewImageKind.network, url: path);
    }

    if (path.startsWith('file://')) {
      return PreviewImageSource._(
        PreviewImageKind.file,
        file: File.fromUri(Uri.parse(path)),
      );
    }

    if (path.startsWith('/')) {
      final String base = Constant.baseUrl.endsWith('/')
          ? Constant.baseUrl.substring(0, Constant.baseUrl.length - 1)
          : Constant.baseUrl;
      return PreviewImageSource._(PreviewImageKind.network, url: '$base$path');
    }

    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path)) {
      return PreviewImageSource._(PreviewImageKind.file, file: File(path));
    }

    return PreviewImageSource._(PreviewImageKind.file, file: File(path));
  }
}

/// 使用 extended_image 展示图片（不含缩放/滚轮手势）。
class PreviewImageView extends StatelessWidget {
  const PreviewImageView({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final PreviewImageSource source = PreviewImageSource.parse(imagePath);

    return switch (source.kind) {
      PreviewImageKind.network => ExtendedImage.network(
        source.url!,
        fit: BoxFit.contain,
        loadStateChanged: _loadStateChanged,
      ),
      // 用 FileImage 避开 ExtendedImage.file 与 dart:io File 的类型冲突
      //（extended_image_library 在 web/js_interop 下导出的是另一套 File）。
      PreviewImageKind.file => ExtendedImage(
        image: FileImage(source.file!),
        fit: BoxFit.contain,
        loadStateChanged: _loadStateChanged,
      ),
      PreviewImageKind.asset => ExtendedImage.asset(
        source.asset!,
        fit: BoxFit.contain,
        loadStateChanged: _loadStateChanged,
      ),
    };
  }

  Widget? _loadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadState.completed:
        return null;
      case LoadState.failed:
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.black38,
            size: 64,
          ),
        );
    }
  }
}

/// 弹窗预览图片。
Future<void> showImagePreviewDialog({
  required BuildContext context,
  required String imagePath,
  String? title,
}) {
  return showPreviewDialog(
    context: context,
    title: title?.isNotEmpty == true ? title! : '图片预览',
    child: PreviewImageView(imagePath: imagePath),
  );
}
