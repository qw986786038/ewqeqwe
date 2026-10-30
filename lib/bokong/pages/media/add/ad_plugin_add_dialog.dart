import 'dart:async';
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/api/ad_plugin_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/widget/message.dart';

const List<AppOption<int>> _pluginTypeOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '天气'),
  AppOption<int>(value: 2, label: '股票'),
  AppOption<int>(value: 3, label: '贵金属'),
  AppOption<int>(value: 4, label: '汇率'),
];

const List<String> _kPluginPreviewImageExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
];

/// 打开「新增插件」弹窗；创建成功返回 `true`。
Future<bool> showAdPluginAddDialog({required BuildContext context}) async {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.55).clamp(360.0, 560.0);
  final bool? submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(560, initialHeight),
    builder: (dialogContext) => const _AdPluginAddDialog(),
  ).future;
  return submitted == true;
}

class _AdPluginAddDialog extends StatefulWidget {
  const _AdPluginAddDialog();

  @override
  State<_AdPluginAddDialog> createState() => _AdPluginAddDialogState();
}

class _AdPluginAddDialogState extends State<_AdPluginAddDialog> {
  final AppFormController _form = AppFormController();
  String? _previewUrl;
  bool _uploading = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _uploadPreview() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _kPluginPreviewImageExtensions,
      );
      final String? path = file?.path;
      if (path == null || path.isEmpty) return;
      final AdMediaPickedFile uploaded =
          await AdMediaPickedFile.loadUploadAndParse(path);
      if (!uploaded.isImage) {
        throw StateError('请上传图片文件');
      }
      final String? url = uploaded.publicUrl?.trim();
      if (url == null || url.isEmpty) {
        throw StateError('上传后图片地址为空');
      }
      setState(() => _previewUrl = url);
    } on StateError catch (e) {
      if (e.message == 'cancelled') return;
      showError('$e');
    } catch (e) {
      showError('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<bool> _submit(Map<String, Object?> values) async {
    final String name = (values['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      showWarn('请输入插件名称');
      return false;
    }
    final String url = (values['url'] as String?)?.trim() ?? '';
    final String? urlError = validateAdMediaUrl(url);
    if (urlError != null) {
      showWarn(urlError);
      return false;
    }

    final resp = await AdPluginApi.create(
      params: <String, dynamic>{
        'name': name,
        'type': values['type'] as int? ?? 1,
        'content': url,
        'prview_url': _previewUrl?.trim() ?? '',
      },
    );
    if (!resp.isSuccess()) throw resp;
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '添加成功');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      title: const Text('新增插件'),
      constraints: const BoxConstraints(minWidth: 520, maxWidth: 560),
      content: AppForm(
        controller: _form,
        child: AppCard(
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextFormField(
                name: 'name',
                label: '插件名称',
                required: true,
                hintText: '请输入插件名称',
                validator: AppValidators.required(message: '请输入插件名称'),
              ),
              AppRadioGroupFormField<int>(
                name: 'type',
                label: '插件类型',
                required: true,
                initialValue: 1,
                options: _pluginTypeOptions,
              ),
              AppTextFormField(
                name: 'url',
                label: 'URL',
                required: true,
                hintText: '例(https://www.palsmon.com/)',
                keyboardType: TextInputType.url,
                validator: validateAdMediaUrl,
              ),
              AppField(
                label: '预览图',
                child: Row(
                  spacing: 12,
                  children: [
                    AppButton.primary(
                      loading: _uploading,
                      // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
                      onPressed: _uploading
                          ? null
                          : () {
                              unawaited(_uploadPreview());
                            },
                      child: const Text('上传图片'),
                    ),
                    if (_previewUrl != null && _previewUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ExtendedImage.network(
                          _previewUrl!,
                          width: 72,
                          height: 48,
                          fit: BoxFit.cover,
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState ==
                                LoadState.failed) {
                              return const SizedBox(
                                width: 72,
                                height: 48,
                                child: Icon(AppLucideIcons.imageOff, size: 20),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<bool>(context, false),
          child: const Text('关闭'),
        ),
        AppButton.primary(
          onPressed: () async {
            try {
              var submitted = false;
              await _form.submit((values) async {
                submitted = await _submit(values);
              });
              if (submitted && mounted) {
                await AppOverlay.close<bool>(context, true);
              }
            } catch (e) {
              if (e is AppRespEntity) {
                showError(e.msg);
              } else {
                showError('$e');
              }
            }
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
