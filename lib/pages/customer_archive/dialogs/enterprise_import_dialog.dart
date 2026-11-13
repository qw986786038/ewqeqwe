import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../services/customer_api.dart';
import 'customer_import_drop_zone.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kLabel = Color(0xFF4E5969);
const _kTitle = Color(0xFF1D2129);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFFF4D4F);

const _kEnterpriseFields = <(String key, String title, double width)>[
  ('fullName', '主体全称', 160),
  ('relationType', '关联关系', 100),
  ('entityNature', '主体性质', 100),
  ('marketScope', '市场范围', 110),
  ('businessTypes', '业务类型', 110),
  ('province', '所在省', 80),
  ('city', '所在市', 80),
  ('address', '详细地址', 140),
  ('legalPerson', '法人', 100),
  ('regAddress', '注册地址', 140),
  ('regPhone', '注册电话', 110),
  ('creditCode', '统一社会信用代码', 160),
  ('registeredCapital', '注册资金', 100),
  ('establishDate', '成立日期', 110),
  ('licenseValidPeriod', '营业执照有效期', 130),
  ('businessScope', '经营范围', 140),
  ('remark', '备注', 120),
];

/// 确认导入 enterprises 字段（空串转 null，与接口样例一致）。
const _kEnterpriseConfirmKeys = <String>[
  'fullName',
  'relationType',
  'entityNature',
  'marketScope',
  'businessTypes',
  'province',
  'city',
  'address',
  'legalPerson',
  'regAddress',
  'regPhone',
  'creditCode',
  'registeredCapital',
  'establishDate',
  'licenseValidPeriod',
  'businessScope',
  'abnormalRecord',
  'penaltyHistory',
  'remark',
  'licenseImagePlaceholder',
];

/// 打开「导入经营主体」弹窗。成功导入并关闭后返回 `true`。
Future<bool> showEnterpriseImportDialog(BuildContext context) {
  final hostContext = context;
    return showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(
        primary: _kPrimary,
        dataGrid: const AppDataGridMetrics(
          rowHeight: 52,
          horizontalPadding: 4,
        ),
      ),
      child: _EnterpriseImportDialog(
        hostContext: hostContext,
        onClose: (ok) => Navigator.of(dialogContext).pop(ok),
      ),
    ),
  ).then((v) => v == true);
}

class _EnterpriseImportDialog extends StatefulWidget {
  const _EnterpriseImportDialog({
    required this.hostContext,
    required this.onClose,
  });

  final BuildContext hostContext;
  final void Function(bool ok) onClose;

  @override
  State<_EnterpriseImportDialog> createState() =>
      _EnterpriseImportDialogState();
}

class _EnterpriseImportDialogState extends State<_EnterpriseImportDialog> {
  final _api = CustomerApi();

  var _stage = _ImportStage.upload;
  var _files = const <AppFileSelection>[];
  var _downloadingTemplate = false;
  var _parsing = false;
  var _confirming = false;
  var _enterprises = <Map<String, dynamic>>[];
  var _rowSeq = 0;

  void _toast(String title, {bool afterClose = false}) {
    final ctx = afterClose ? widget.hostContext : context;
    if (!ctx.mounted) return;
    showHyperToast(ctx, content: Text(title));
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
    throw CustomerApiException('无法读取所选文件');
  }

  Future<void> _downloadTemplate() async {
    if (_downloadingTemplate || _parsing || _confirming) return;
    setState(() => _downloadingTemplate = true);
    try {
      final file = await _api.downloadEnterpriseImportTemplate();
      if (!mounted) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: '保存导入经营主体模板',
        fileName: file.fileName,
        bytes: file.bytes,
        mimeType: 'application/vnd.ms-excel',
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );
      if (!mounted || saved == null) return;
      _toast('模板已保存');
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _downloadingTemplate = false);
    }
  }

  Future<void> _onFilesChanged(List<AppFileSelection> next) async {
    setState(() => _files = next);
    if (next.isEmpty || _parsing || _confirming) return;
    final file = next.first;
    setState(() => _parsing = true);
    try {
      final bytes = await _readBytes(file);
      final list = await _api.previewEnterpriseImport(
        bytes: bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _files = const [];
          _parsing = false;
        });
        _toast('未解析到经营主体数据，请检查模板内容');
        return;
      }
      setState(() {
        _rowSeq = 0;
        _enterprises = [
          for (final item in list)
            {
              ...Map<String, dynamic>.from(item),
              '_rowId': _nextRowId(),
            },
        ];
        _stage = _ImportStage.preview;
        _parsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _files = const [];
        _parsing = false;
      });
      _toast(e.toString());
    }
  }

  Future<void> _confirm() async {
    if (_confirming || _enterprises.isEmpty) return;
    setState(() => _confirming = true);
    try {
      // POST .../importEnterprise/confirm → { "enterprises": [ ... ] }
      final payload = [
        for (final e in _enterprises) _enterpriseConfirmRow(e),
      ];
      await _api.confirmEnterpriseImport(payload);
      if (!mounted) return;
      widget.onClose(true);
      _toast('经营主体导入成功（${_enterprises.length} 条）', afterClose: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      _toast(e.toString());
    }
  }

  Map<String, dynamic> _enterpriseConfirmRow(Map<String, dynamic> row) {
    return {
      for (final key in _kEnterpriseConfirmKeys) key: _nullIfEmpty(row[key]),
    };
  }

  Object? _nullIfEmpty(Object? raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }
    if (raw is Iterable) {
      final parts = <String>[
        for (final e in raw)
          if (e != null && '$e'.trim().isNotEmpty) '$e'.trim(),
      ];
      return parts.isEmpty ? null : parts.join(',');
    }
    final s = '$raw'.trim();
    return s.isEmpty ? null : s;
  }

  String _nextRowId() {
    _rowSeq += 1;
    return 'e_$_rowSeq';
  }

  void _addRow() {
    if (_confirming) return;
    // AppDataGrid 仅在 rows 引用变化时刷新，必须换新 List。
    setState(() {
      _enterprises = [
        ..._enterprises,
        <String, dynamic>{'_rowId': _nextRowId()},
      ];
    });
  }

  void _removeRow(Map<String, dynamic> row) {
    if (_confirming) return;
    setState(() {
      _enterprises = [
        for (final e in _enterprises)
          if (!identical(e, row)) e,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _ImportStage.preview) {
      return HyperDialog(
        title: const Text('导入经营主体预览'),
        scrollable: false,
        style: const HyperDialogStyle(maxWidth: 1120),
        content: SizedBox(
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildGrid()),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: HyperButton.text(
                  onPressed: _confirming ? null : _addRow,
                  label: const Text(
                    '+ 添加一行',
                    style: TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          HyperButton.outlined(
            onPressed: _confirming ? null : () => widget.onClose(false),
            label: const Text('取消'),
          ),
          HyperButton.filled(
            onPressed: _confirming ? null : _confirm,
            label: Text(_confirming ? '导入中…' : '确认导入'),
          ),
        ],
      );
    }

    return HyperDialog(
      title: const Text('导入经营主体'),
      scrollable: false,
      style: const HyperDialogStyle(maxWidth: 560),
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
              AppInkWell(
                onPressed: _downloadingTemplate || _parsing
                    ? null
                    : _downloadTemplate,
                child: Text(
                  _downloadingTemplate ? '下载中…' : '下载导入模板',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomerImportDropZone(
            files: _files,
            enabled: !_parsing,
            dialogTitle: '选择经营主体导入文件',
            onRejected: _toast,
            onChanged: _onFilesChanged,
          ),
          if (_parsing) ...[
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
                  '正在解析预览…',
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            '· 模板仅含经营主体信息，不含品牌简称。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            '· 「主体全称」为必填。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            '· 「营业执照照片」可插入单元格，导入后将自动上传并 OCR 识别。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
        ],
      ),
      actions: [
        HyperButton.outlined(
          onPressed: _parsing ? null : () => widget.onClose(false),
          label: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppDataGrid<Map<String, dynamic>>.local(
          rows: _enterprises,
          rowKey: (row) => row['_rowId'] ?? identityHashCode(row),
          height: null,
          shrinkWrap: false,
          sortable: false,
          showFilters: false,
          empty: const Center(
            child: Text('暂无预览数据，可点击下方添加', style: TextStyle(color: _kMuted)),
          ),
          columns: [
            for (final f in _kEnterpriseFields)
              AppDataGridColumn(
                id: f.$1,
                title: f.$2,
                width: f.$3,
                alignment: Alignment.centerLeft,
                titleAlignment: Alignment.centerLeft,
                value: (row) => '${row[f.$1] ?? ''}',
                cellBuilder: (context, row, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: TextFormField(
                    initialValue: row[f.$1]?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: _kTitle,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _kPrimary),
                      ),
                    ),
                    onChanged: (v) => row[f.$1] = v,
                  ),
                ),
              ),
            AppDataGridColumn(
              id: 'actions',
              title: '操作',
              width: 72,
              value: (_) => '',
              cellBuilder: (context, row, _) => HyperButton.text(
                onPressed: _confirming ? null : () => _removeRow(row),
                label: const Text(
                  '删除',
                  style: TextStyle(color: _kDanger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImportStage { upload, preview }
