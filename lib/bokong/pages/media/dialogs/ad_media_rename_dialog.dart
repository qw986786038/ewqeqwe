import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 修改素材名称（仅标题）。
Future<void> showAdMediaRenameDialog(
  BuildContext context, {
  required AdMediaController controller,
  required AdMediaEntity item,
}) {
  final int? id = item.id;
  if (id == null) {
    showWarn('素材 ID 无效');
    return Future.value();
  }
  final String initialTitle = item.title?.trim().isNotEmpty == true
      ? item.title!.trim()
      : (item.media_no ?? '');
  return showAppWindowDialog<void>(
    context: context,
    builder: (dialogContext) => _AdMediaRenameDialog(
      initialTitle: initialTitle,
      onSubmit: (title) async {
        final message = await controller.renameMedia(item: item, title: title);
        showComplete(message);
        if (dialogContext.mounted) {
          AppOverlay.close<void>(dialogContext);
        }
      },
      onCancel: () => AppOverlay.close<void>(dialogContext),
    ),
  ).future;
}

class _AdMediaRenameDialog extends StatefulWidget {
  const _AdMediaRenameDialog({
    required this.initialTitle,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialTitle;
  final Future<void> Function(String title) onSubmit;
  final VoidCallback onCancel;

  @override
  State<_AdMediaRenameDialog> createState() => _AdMediaRenameDialogState();
}

class _AdMediaRenameDialogState extends State<_AdMediaRenameDialog> {
  final _form = AppFormController();
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _form.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppForm(
      controller: _form,
      child: AppFormDialog(
        title: const Text('修改名称'),
        constraints: const BoxConstraints(maxWidth: 420),
        content: AppCard(
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: AppFieldScope.horizontal(
            labelWidth: 56,
            child: AppTextFormField(
              name: 'title',
              label: '名称',
              required: true,
              controller: _titleController,
            ),
          ),
        ),
        actions: [
          AppButton.outline(
            onPressed: widget.onCancel,
            child: const Text('取消'),
          ),
          AppButton.primary(
            onPressed: () => _form.submit((values) async {
              final title =
                  (values['title'] as String?)?.trim() ??
                  _titleController.text.trim();
              if (title.isEmpty) {
                showWarn('名称不可为空');
                return;
              }
              await widget.onSubmit(title);
            }),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
