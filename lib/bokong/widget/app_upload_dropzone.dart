import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 上传空态拖放区：文件夹上传图 + 文案 + 选择按钮。
///
/// 待上游回收：建议 [AppFilePicker] 支持 `emptyIcon`，回收本组件。
class AppUploadDropzone extends StatefulWidget {
  const AppUploadDropzone({
    super.key,
    required this.onFilesSelected,
    this.emptyTitle = '点击上传图片、视频或音频',
    this.dropTitle = '拖放文件到这里',
    this.pickLabel = '选择文件',
    this.dialogTitle,
    this.allowedExtensions,
    this.multiple = false,
    this.enabled = true,
    this.onRejected,
  });

  static const iconAsset = 'assets/images/file_upload_icon.png';

  final ValueChanged<List<AppFileSelection>> onFilesSelected;
  final String emptyTitle;
  final String dropTitle;
  final String pickLabel;
  final String? dialogTitle;
  final List<String>? allowedExtensions;
  final bool multiple;
  final bool enabled;
  final ValueChanged<String>? onRejected;

  @override
  State<AppUploadDropzone> createState() => _AppUploadDropzoneState();
}

class _AppUploadDropzoneState extends State<AppUploadDropzone> {
  bool _dragging = false;
  String? _rejectionMessage;

  Set<String>? get _normalizedExtensions {
    final extensions = widget.allowedExtensions;
    if (extensions == null || extensions.isEmpty) return null;
    return extensions
        .map((value) => value.replaceFirst('.', '').toLowerCase())
        .toSet();
  }

  String? _extensionOf(String name) {
    final index = name.lastIndexOf('.');
    if (index <= 0 || index >= name.length - 1) return null;
    return name.substring(index + 1).toLowerCase();
  }

  String? _validateFile(AppFileSelection file) {
    final extensions = _normalizedExtensions;
    final extension = (file.extension ?? _extensionOf(file.name))
        ?.toLowerCase();
    if (extensions != null && !extensions.contains(extension)) {
      return '不支持文件 ${file.name} 的格式';
    }
    return null;
  }

  void _reject(String message) {
    if (!mounted) return;
    if (_rejectionMessage != message) {
      setState(() => _rejectionMessage = message);
    }
    widget.onRejected?.call(message);
  }

  void _clearRejection() {
    if (_rejectionMessage != null) {
      setState(() => _rejectionMessage = null);
    }
  }

  Future<AppFileSelection> _fromPlatformFile(PlatformFile file) async {
    return AppFileSelection(
      name: file.name,
      path: file.path,
      size: await file.length(),
      extension: _extensionOf(file.name),
      data: file.xFile,
    );
  }

  Future<void> _pick() async {
    try {
      final extensions = _normalizedExtensions;
      final type = extensions == null ? FileType.any : FileType.custom;
      final allowedExtensions = extensions?.toList();
      final List<AppFileSelection> selected;
      if (widget.multiple) {
        final files = await FilePicker.pickFiles(
          allowedExtensions: allowedExtensions,
          dialogTitle: widget.dialogTitle,
          type: type,
        );
        selected = [for (final file in files) await _fromPlatformFile(file)];
      } else {
        final file = await FilePicker.pickFile(
          allowedExtensions: allowedExtensions,
          dialogTitle: widget.dialogTitle,
          type: type,
        );
        selected = file == null ? const [] : [await _fromPlatformFile(file)];
      }
      if (!mounted) return;
      _accept(selected);
    } catch (_) {
      if (mounted) _reject('无法选择文件，请重试');
    }
  }

  Future<void> _drop(List<XFile> files) async {
    final selected = <AppFileSelection>[];
    String? rejection;
    for (final file in files) {
      try {
        selected.add(
          AppFileSelection(
            name: file.name,
            path: file.path,
            size: await file.length(),
            extension: _extensionOf(file.name),
            data: file,
          ),
        );
      } catch (_) {
        rejection ??= '无法读取文件 ${file.name}';
      }
    }
    if (!mounted) return;
    _accept(selected, rejection: rejection);
  }

  void _accept(List<AppFileSelection> incoming, {String? rejection}) {
    if (incoming.isEmpty) {
      if (rejection != null) _reject(rejection);
      return;
    }
    final accepted = <AppFileSelection>[];
    for (final file in incoming) {
      final error = _validateFile(file);
      if (error != null) {
        rejection ??= error;
        continue;
      }
      accepted.add(file);
      if (!widget.multiple) break;
    }
    if (accepted.isEmpty) {
      if (rejection != null) _reject(rejection);
      return;
    }
    if (rejection != null) {
      _reject(rejection);
    } else {
      _clearRejection();
    }
    widget.onFilesSelected(List.unmodifiable(accepted));
  }

  Widget? _buildRejection(Color destructive) {
    final message = _rejectionMessage;
    if (message == null) return null;
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: destructive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadcnTheme.of(context);
    final colors = theme.colorScheme;

    final dropzone = DecoratedBox(
      decoration: BoxDecoration(
        color: !widget.enabled
            ? colors.muted.withValues(alpha: 0.55)
            : _dragging
            ? colors.muted
            : null,
        border: Border.all(color: _dragging ? colors.primary : colors.border),
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      child: AppEmpty(
        icon: Image.asset(
          AppUploadDropzone.iconAsset,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        title: Text(
          _dragging ? widget.dropTitle : widget.emptyTitle,
          style: const TextStyle(),
        ),
        description: _buildRejection(colors.destructive),
        action: AppButton.outline(
          onPressed: widget.enabled ? _pick : null,
          child: Text(widget.pickLabel),
        ),
      ),
    );

    if (!widget.enabled) return dropzone;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        unawaited(_drop(details.files));
      },
      child: dropzone,
    );
  }
}
