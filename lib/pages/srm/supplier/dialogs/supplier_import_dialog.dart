import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../../services/srm_supplier_api.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kLabel = Color(0xFF4E5969);
const _kBarrier = Color(0x99000000);

/// 打开「导入供应商」弹窗。成功导入并关闭后返回 `true`。
Future<bool> showSupplierImportDialog(BuildContext context) {
  final hostContext = context;
  return AppDialog.show<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: _kBarrier,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _SupplierImportDialog(
        hostContext: hostContext,
        onClose: (ok) => AppOverlay.close<bool>(dialogContext, ok),
      ),
    ),
  ).future.then((v) => v == true);
}

class _SupplierImportDialog extends StatefulWidget {
  const _SupplierImportDialog({
    required this.hostContext,
    required this.onClose,
  });

  final BuildContext hostContext;
  final void Function(bool ok) onClose;

  @override
  State<_SupplierImportDialog> createState() => _SupplierImportDialogState();
}

class _SupplierImportDialogState extends State<_SupplierImportDialog> {
  final _api = SrmSupplierApi();

  var _files = const <AppFileSelection>[];
  var _uploading = false;
  var _downloadingTemplate = false;

  void _toast(String title, {bool afterClose = false}) {
    final ctx = afterClose ? widget.hostContext : context;
    if (!ctx.mounted) return;
    AppToast.show(context: ctx, title: title);
  }

  Future<Uint8List> _readBytes(AppFileSelection file) async {
    final path = file.path?.trim();
    if (path != null && path.isNotEmpty) {
      return File(path).readAsBytes();
    }
    final data = file.data;
    if (data != null) {
      try {
        final raw = await (data as dynamic).readAsBytes();
        if (raw is Uint8List) return raw;
        if (raw is List<int>) return Uint8List.fromList(raw);
      } catch (_) {}
    }
    throw SrmSupplierApiException('无法读取所选文件');
  }

  Future<void> _downloadTemplate() async {
    if (_downloadingTemplate || _uploading) return;
    setState(() => _downloadingTemplate = true);
    try {
      final file = await _api.downloadImportTemplate();
      if (!mounted) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: '保存导入模板',
        fileName: file.fileName,
        bytes: file.bytes,
        mimeType: 'application/vnd.ms-excel',
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );
      if (!mounted) return;
      if (saved == null) return;
      _toast('模板已保存');
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _downloadingTemplate = false);
    }
  }

  Future<void> _onFilesChanged(List<AppFileSelection> next) async {
    setState(() => _files = next);
    if (next.isEmpty || _uploading) return;
    final file = next.first;
    setState(() => _uploading = true);
    try {
      final bytes = await _readBytes(file);
      final count = await _api.importExcel(bytes: bytes, fileName: file.name);
      if (!mounted) return;
      widget.onClose(true);
      _toast('成功导入 $count 条', afterClose: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _files = const [];
        _uploading = false;
      });
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      title: const Text('导入供应商'),
      constraints: const BoxConstraints(minWidth: 520, maxWidth: 560),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '请先下载模板，按表头格式填写后再上传',
                  style: TextStyle(fontSize: 13, color: _kLabel),
                ),
              ),
              AppButton.link(
                onPressed: _downloadingTemplate || _uploading
                    ? null
                    : _downloadTemplate,
                child: Text(
                  _downloadingTemplate ? '下载中…' : '下载导入模板',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppFilePicker(
            files: _files,
            multiple: false,
            maxFiles: 1,
            enabled: !_uploading,
            allowedExtensions: const ['xls', 'xlsx'],
            emptyTitle: '将文件拖到此处，或点击上传',
            dropTitle: '松开以上传文件',
            pickLabel: '点击上传',
            dialogTitle: '选择供应商导入文件',
            onRejected: (message) => _toast(message),
            onChanged: _onFilesChanged,
          ),
          if (_uploading) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  '正在导入…',
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            '· 仅单 sheet「供应商主信息」建档；含经营主体、营业执照、合同与结算、能力概况等字段。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            '· 银行账户、开票信息、联系人、品类明细、我方对接人请导入后在编辑页补充。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            '· 红色 * 为必填；附件（Logo、执照、合同模板等）本次不导入。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
        ],
      ),
      actions: [
        AppButton.outline(
          onPressed: _uploading ? null : () => widget.onClose(false),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
