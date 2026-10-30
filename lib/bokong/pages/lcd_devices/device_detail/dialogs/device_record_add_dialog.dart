import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:path/path.dart' as p;

import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/api/system_file_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_maintain_log_entity.dart';
import 'package:yidivination/bokong/utils/file_content_type.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_upload_dropzone.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../device_detail_controller.dart';

/// 打开维保 / 巡检 / 异常告警「添加记录」弹窗；成功返回 `true`。
Future<bool> showDeviceRecordAddDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
  int type = 1,
  int parentId = 0,
}) async {
  final submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => DeviceRecordAddDialog(
      controller: controller,
      type: type,
      parentId: parentId,
    ),
  ).future;
  return submitted == true;
}

/// 添加记录弹窗：标题 + 上传媒体 + 备注。
///
/// 上游缺口（待回收）：
/// - 建议 `AppFormDialog` 默认「取消 / 保存」
/// - 建议 [AppFilePicker] 支持 `emptyIcon`，回收 [AppUploadDropzone]
class DeviceRecordAddDialog extends StatefulWidget {
  const DeviceRecordAddDialog({
    required this.controller,
    this.type = 1,
    this.parentId = 0,
    super.key,
  });

  final LcdDeviceDetailController controller;
  final int type;
  final int parentId;

  @override
  State<DeviceRecordAddDialog> createState() => _DeviceRecordAddDialogState();
}

class _DeviceRecordAddDialogState extends State<DeviceRecordAddDialog> {
  static const _pathPrefix = 'maintain_log';
  static const _allowedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'mp4',
    'mov',
    'avi',
  ];

  final _form = AppFormController();
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<List<int>> _readBytes(AppFileSelection file) async {
    final path = file.path?.trim();
    if (path == null || path.isEmpty) {
      throw StateError('无法读取文件：${file.name}');
    }
    return File(path).readAsBytes();
  }

  String _fileTypeLabel(String mimeType) {
    if (mimeType.startsWith('video/')) return 'video';
    return 'image';
  }

  Future<List<LcdTerminalMaintainLogFileEntity>> _uploadFiles(
    List<AppFileSelection> files,
  ) async {
    final uploaded = <LcdTerminalMaintainLogFileEntity>[];
    for (final file in files) {
      final bytes = await _readBytes(file);
      final fileName = file.name.trim().isNotEmpty
          ? file.name.trim()
          : p.basename(file.path ?? 'file');
      final mimeType =
          guessContentTypeFromFilename(fileName) ?? 'application/octet-stream';
      final result = await SystemFileApi.presignUploadAndComplete(
        filename: fileName,
        contentType: mimeType,
        bytes: bytes,
        pathPrefix: _pathPrefix,
      );
      final url = result.presign.public_url?.trim();
      if (url == null || url.isEmpty) {
        throw StateError('上传后文件地址为空：$fileName');
      }
      uploaded.add(
        LcdTerminalMaintainLogFileEntity()
          ..url = url
          ..file_name = fileName
          ..file_type = _fileTypeLabel(mimeType)
          ..duration_sec = null,
      );
    }
    return uploaded;
  }

  Future<bool> _submit(Map<String, Object?> values) async {
    final terminalId = widget.controller.device.id;
    if (terminalId == null) {
      showWarn('设备 ID 为空，无法保存');
      return false;
    }
    final title = (values['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      showWarn('请输入标题名称');
      return false;
    }
    final remark = (values['remark'] as String?)?.trim() ?? '';
    final selected =
        (values['files'] as List<AppFileSelection>?) ??
        const <AppFileSelection>[];
    final files = selected.isEmpty
        ? <LcdTerminalMaintainLogFileEntity>[]
        : await _uploadFiles(selected);

    final resp = await LcdApi.terminalMaintainLogCreate(
      param: LcdTerminalMaintainLogCreateEntity()
        ..terminal_id = terminalId
        ..type = widget.type
        ..title = title
        ..remark = remark
        ..parent_id = widget.parentId
        ..files = files,
    );
    if (!resp.isSuccess()) throw resp;
    showComplete(
      resp.msg?.trim().isNotEmpty == true ? resp.msg!.trim() : '保存成功',
    );
    return true;
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: Text(widget.parentId > 0 ? '追加记录' : '添加记录'),
      constraints: const BoxConstraints(maxWidth: 560),
      content: SizedBox(
        width: 520,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AppForm(
            controller: _form,
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  borderWidth: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextFormField(
                        name: 'title',
                        label: '标题名称',
                        required: true,
                        hintText: '请输入内容',
                        validator: AppValidators.required(message: '请输入标题名称'),
                      ),
                      _RecordFilesFormField(
                        name: 'files',
                        label: '上传文件（支持图片、视频）',
                        emptyTitle: '将文件拖到此区域，或点击上传',
                        dropTitle: '将文件拖到此区域，或点击上传',
                        allowedExtensions: _allowedExtensions,
                      ),
                      AppTextAreaFormField(
                        name: 'remark',
                        label: '备注内容',
                        hintText: '请输入内容',
                        expandableHeight: true,
                        minHeight: 120,
                      ),
                    ],
                  ),
                ),
              ],
            ).scroll(),
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: _saving ? null : () => AppOverlay.close(context, false),
          child: const Text('取消'),
        ),
        AppButton.primary(
          loading: _saving,
          loadingLabel: '保存中…',
          // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
          onPressed: _saving
              ? null
              : () {
                  unawaited(_handleSave());
                },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 空态用 [AppUploadDropzone]（与素材添加同一文件夹图标）；有文件后回落 [AppFilePicker]。
class _RecordFilesFormField extends FormField<List<AppFileSelection>> {
  _RecordFilesFormField({
    required String name,
    required String label,
    required String emptyTitle,
    required String dropTitle,
    required List<String> allowedExtensions,
  }) : super(
         initialValue: const [],
         builder: (state) {
           final files = state.value ?? const <AppFileSelection>[];
           return AppFormFieldBinding<List<AppFileSelection>>(
             name: name,
             value: files,
             builder: (context, asyncError) => AppField(
               label: label,
               errorText: state.errorText ?? asyncError,
               child: files.isEmpty
                   ? AppUploadDropzone(
                       emptyTitle: emptyTitle,
                       dropTitle: dropTitle,
                       pickLabel: '选择文件',
                       multiple: true,
                       allowedExtensions: allowedExtensions,
                       onRejected: (message) => showWarn(message),
                       onFilesSelected: (selected) {
                         state.didChange(List<AppFileSelection>.from(selected));
                       },
                     )
                   : AppFilePicker(
                       files: files,
                       multiple: true,
                       allowedExtensions: allowedExtensions,
                       emptyTitle: emptyTitle,
                       dropTitle: dropTitle,
                       pickLabel: '继续添加',
                       onRejected: (message) => showWarn(message),
                       onChanged: (next) {
                         state.didChange(List<AppFileSelection>.from(next));
                       },
                     ),
             ),
           );
         },
       );
}
