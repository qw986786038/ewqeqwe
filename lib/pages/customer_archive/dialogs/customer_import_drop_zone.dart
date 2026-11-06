import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);

/// 导入弹窗上传区：拖拽 + 蓝色「点击上传」文字按钮（对齐网页端样式）。
class CustomerImportDropZone extends StatefulWidget {
  const CustomerImportDropZone({
    super.key,
    required this.files,
    required this.onChanged,
    this.enabled = true,
    this.dialogTitle = '选择导入文件',
    this.onRejected,
  });

  final List<AppFileSelection> files;
  final ValueChanged<List<AppFileSelection>> onChanged;
  final bool enabled;
  final String dialogTitle;
  final ValueChanged<String>? onRejected;

  @override
  State<CustomerImportDropZone> createState() => _CustomerImportDropZoneState();
}

class _CustomerImportDropZoneState extends State<CustomerImportDropZone> {
  var _dragging = false;

  Future<void> _pick() async {
    if (!widget.enabled) return;
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: widget.dialogTitle,
        type: FileType.custom,
        allowedExtensions: const ['xls', 'xlsx'],
      );
      if (!mounted || file == null) return;
      widget.onChanged([
        AppFileSelection(
          name: file.name,
          path: file.path,
          size: await file.length(),
          extension: _ext(file.name),
          data: file.xFile,
        ),
      ]);
    } catch (_) {
      widget.onRejected?.call('无法选择文件，请重试');
    }
  }

  Future<void> _onDrop(List<dynamic> files) async {
    if (!widget.enabled || files.isEmpty) return;
    final first = files.first;
    final name = first.name as String;
    final ext = _ext(name)?.toLowerCase();
    if (ext != 'xls' && ext != 'xlsx') {
      widget.onRejected?.call('仅支持 .xls / .xlsx 文件');
      return;
    }
    try {
      final size = await first.length() as int;
      if (!mounted) return;
      widget.onChanged([
        AppFileSelection(
          name: name,
          path: first.path as String?,
          size: size,
          extension: ext,
          data: first,
        ),
      ]);
    } catch (_) {
      widget.onRejected?.call('无法读取文件 $name');
    }
  }

  String? _ext(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return null;
    return name.substring(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.files.isNotEmpty ? widget.files.first : null;
    return DropTarget(
      onDragEntered: (_) {
        if (widget.enabled) setState(() => _dragging = true);
      },
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        unawaited(_onDrop(details.files));
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? _pick : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: _dragging ? const Color(0xFFF5F7FA) : Colors.transparent,
              border: Border.all(
                color: _dragging ? _kPrimary : _kBorder,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 36,
                  color: _dragging ? _kPrimary : _kMuted,
                ),
                const SizedBox(height: 10),
                if (selected != null)
                  Text(
                    selected.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _kLabel),
                  )
                else if (_dragging)
                  const Text(
                    '松开以上传文件',
                    style: TextStyle(fontSize: 13, color: _kLabel),
                  )
                else
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: _kLabel),
                      children: [
                        const TextSpan(text: '将文件拖到此处，或'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: AppInkWell(
                            onPressed: widget.enabled ? _pick : null,
                            child: const Text(
                              '点击上传',
                              style: TextStyle(
                                fontSize: 13,
                                color: _kPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
