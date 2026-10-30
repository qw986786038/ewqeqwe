import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/pages/media/ad_media_upload.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/widget/app_upload_dropzone.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 添加素材 ·「上传」Tab。
class AdMediaAddUploadTab extends StatelessWidget {
  const AdMediaAddUploadTab({
    required this.durationSeconds,
    required this.onFilePicked,
    super.key,
  });

  final int durationSeconds;
  final ValueChanged<AdMediaPickedFile> onFilePicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UploadFormField(
          durationSeconds: durationSeconds,
          onFilePicked: onFilePicked,
          validator: (value) => value == null ? '请上传片源' : null,
        ),
        AppSwitchFormField(
          name: 'pushCloud',
          label: '推送云端',
          controlLabel: const Text('是'),
          initialValue: false,
        ),
      ],
    );
  }
}

class _UploadFormField extends FormField<AdMediaPickedFile> {
  _UploadFormField({
    required int durationSeconds,
    this.onFilePicked,
    super.validator,
  }) : _durationSeconds = durationSeconds,
       super(builder: _buildField);

  final int _durationSeconds;
  final ValueChanged<AdMediaPickedFile>? onFilePicked;

  static Widget _buildField(FormFieldState<AdMediaPickedFile> field) {
    final state = field as _UploadFormFieldState;
    final widget = state.widget;
    final picked = field.value;

    Future<void> uploadFromSelection(List<AppFileSelection> files) async {
      if (files.isEmpty || state._uploading) return;
      final String? path = files.first.path;
      if (path == null || path.isEmpty) {
        showWarn('无法读取文件路径');
        return;
      }
      state._setUploading(true);
      try {
        final file = await AdMediaPickedFile.loadUploadAndParse(path);
        field.didChange(file);
        widget.onFilePicked?.call(file);
      } catch (e) {
        showError('$e');
      } finally {
        state._setUploading(false);
      }
    }

    final List<AppFileSelection> pickerFiles = picked == null
        ? const <AppFileSelection>[]
        : <AppFileSelection>[
            AppFileSelection(
              name: picked.fileName,
              path: picked.localPath,
              size: picked.fileSizeBytes,
              extension: picked.fileFormat.toLowerCase(),
            ),
          ];

    return AppFormFieldBinding<AdMediaPickedFile>(
      name: 'file',
      value: field.value,
      builder: (context, asyncError) => AppField(
        label: '上传片源',
        required: true,
        errorText: field.errorText ?? asyncError,
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state._uploading)
              const SizedBox(
                height: 140,
                child: Center(child: AppCircularProgressIndicator()),
              )
            else if (picked == null)
              AppUploadDropzone(
                emptyTitle: '点击上传图片、视频或音频',
                dropTitle: '拖放文件到这里',
                pickLabel: '选择文件',
                dialogTitle: '选择片源',
                allowedExtensions: kAdMediaUploadExtensions,
                enabled: field.widget.enabled,
                onRejected: (message) => showWarn(message),
                onFilesSelected: uploadFromSelection,
              )
            else
              AppFilePicker(
                files: pickerFiles,
                onChanged: (files) {
                  if (files.isEmpty) {
                    field.didChange(null);
                    return;
                  }
                  if (picked != null && files.first.path == picked.localPath) {
                    return;
                  }
                  uploadFromSelection(files);
                },
                multiple: false,
                maxFiles: 1,
                enabled: field.widget.enabled,
                allowedExtensions: kAdMediaUploadExtensions,
                emptyTitle: '点击上传图片、视频或音频',
                dropTitle: '拖放文件到这里',
                pickLabel: picked == null ? '选择文件' : '重新上传',
                dialogTitle: '选择片源',
                onRejected: (message) => showWarn(message),
              ),
            if (picked != null && !state._uploading)
              AppCard(
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (picked.isImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(picked.localPath),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    AppDescriptions(
                      layout: AppDescriptionLayout.horizontal,
                      columns: 1,
                      labelWidth: 72,
                      items: [
                        AppDescriptionItem(
                          label: const Text('文件名'),
                          value: Text(picked.fileName),
                        ),
                        AppDescriptionItem(
                          label: const Text('文件路径'),
                          value: Text(picked.publicUrl ?? '-'),
                        ),
                        AppDescriptionItem(
                          label: const Text('媒体类型'),
                          value: Text(adMediaTypeLabel(picked.mediaType)),
                        ),
                        AppDescriptionItem(
                          label: const Text('文件格式'),
                          value: Text(picked.fileFormat),
                        ),
                        AppDescriptionItem(
                          label: const Text('文件大小'),
                          value: Text(
                            AdMediaPickedFile.formatFileSize(
                              picked.fileSizeBytes,
                            ),
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('播放时长'),
                          value: Text(
                            adMediaDurationLabel(widget._durationSeconds),
                          ),
                        ),
                        if (picked.width != null && picked.height != null) ...[
                          AppDescriptionItem(
                            label: const Text('内容宽度'),
                            value: Text('${picked.width} px'),
                          ),
                          AppDescriptionItem(
                            label: const Text('内容高度'),
                            value: Text('${picked.height} px'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  FormFieldState<AdMediaPickedFile> createState() => _UploadFormFieldState();
}

class _UploadFormFieldState extends FormFieldState<AdMediaPickedFile> {
  bool _uploading = false;

  @override
  _UploadFormField get widget => super.widget as _UploadFormField;

  void _setUploading(bool value) {
    if (_uploading == value) return;
    setState(() => _uploading = value);
  }
}
