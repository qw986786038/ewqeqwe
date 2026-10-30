import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yidivination/bokong/pages/preview/preview_image_view.dart';
import 'package:yidivination/bokong/router/routes.dart';
import 'package:yidivination/bokong/utils/ext.dart';

/// 图片预览页：传入 [imagePath] 展示图片，支持网络、本地文件与 assets。
class ImagePreviewPage extends StatelessWidget {
  const ImagePreviewPage({super.key, required this.imagePath, this.title});

  final String imagePath;
  final String? title;

  /// 通过路由打开图片预览。
  static void open(
    BuildContext context, {
    required String imagePath,
    String? title,
  }) {
    final String path = Uri.encodeComponent(imagePath);
    final String query = title == null || title.isEmpty
        ? 'path=$path'
        : 'path=$path&title=${Uri.encodeComponent(title)}';
    context.push('${Routes.image_preview}?$query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title?.isNotEmpty == true ? title! : '图片预览',
          style: context.theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(child: PreviewImageView(imagePath: imagePath)),
    );
  }
}
