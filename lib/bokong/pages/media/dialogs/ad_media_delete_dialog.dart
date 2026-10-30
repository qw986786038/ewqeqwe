import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 确认并删除素材。
Future<void> showAdMediaDeleteDialog(
  BuildContext context, {
  required AdMediaController controller,
  required AdMediaEntity item,
}) {
  final int? id = item.id;
  if (id == null) {
    showWarn('素材 ID 无效');
    return Future.value();
  }
  final String title = item.title?.trim().isNotEmpty == true
      ? item.title!.trim()
      : (item.media_no ?? '-');
  return showAppWindowDialog<void>(
    context: context,
    builder: (dialogContext) => AppDeleteConfirmAlertDialog(
      title: const Text('删除素材'),
      content: Text('确定要删除「$title」吗？此操作不可撤销。'),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<void>(dialogContext),
          child: const Text('取消'),
        ),
        AppButton.destructive(
          onPressed: () async {
            try {
              final message = await controller.deleteMedia(id);
              showComplete(message);
              if (dialogContext.mounted) {
                AppOverlay.close<void>(dialogContext);
              }
            } catch (e) {
              if (e is AppRespEntity) {
                showError(e.msg ?? e.info());
              } else if (e is AppException) {
                showError(e.msg ?? '$e');
              } else {
                showError('$e');
              }
            }
          },
          child: const Text('删除'),
        ),
      ],
    ),
  ).future;
}
