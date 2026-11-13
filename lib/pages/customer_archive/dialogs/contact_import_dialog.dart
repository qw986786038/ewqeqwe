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

const _kContactFields = <(String key, String title, double width)>[
  ('name', '姓名', 100),
  ('nameEn', 'Name', 100),
  ('gender', '性别', 88),
  ('ageDesc', '年龄段', 88),
  ('relatedEnterprise', '关联企业', 140),
  ('city', '所在城市', 100),
  ('address', '详细地址', 140),
  ('deptTitle', '部门/职位', 110),
  ('jobDesc', '职能描述', 110),
  ('marketScope', '负责市场范围', 120),
  ('responsibleBrands', '负责品牌', 110),
  ('tenure', '在职时间', 90),
  ('phones', '手机号', 110),
  ('tel', '电话', 100),
  ('emails', '邮箱', 140),
  ('remark', '备注', 120),
];

/// 确认导入 contacts 字段（不含嵌套 superiors/subordinates）。
const _kContactConfirmKeys = <String>[
  'name',
  'nameEn',
  'gender',
  'ageDesc',
  'relatedEnterprise',
  'city',
  'address',
  'deptTitle',
  'jobDesc',
  'marketScope',
  'responsibleBrands',
  'tenure',
  'phones',
  'tel',
  'emails',
  'remark',
];

const _kRelFields = <(String key, String title, double width)>[
  ('contactName', '主联系人姓名', 110),
  ..._kContactFields,
];

/// 打开「导入联系人」弹窗。成功导入并关闭后返回 `true`。
Future<bool> showContactImportDialog(BuildContext context) {
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
      child: _ContactImportDialog(
        hostContext: hostContext,
        onClose: (ok) => Navigator.of(dialogContext).pop(ok),
      ),
    ),
  ).then((v) => v == true);
}

class _ContactImportDialog extends StatefulWidget {
  const _ContactImportDialog({
    required this.hostContext,
    required this.onClose,
  });

  final BuildContext hostContext;
  final void Function(bool ok) onClose;

  @override
  State<_ContactImportDialog> createState() => _ContactImportDialogState();
}

class _ContactImportDialogState extends State<_ContactImportDialog> {
  final _api = CustomerApi();

  var _stage = _ImportStage.upload;
  var _files = const <AppFileSelection>[];
  var _downloadingTemplate = false;
  var _parsing = false;
  var _confirming = false;
  var _previewTab = 0;
  var _contacts = <Map<String, dynamic>>[];
  var _superiors = <Map<String, dynamic>>[];
  var _subordinates = <Map<String, dynamic>>[];
  var _rowSeq = 0;

  void _toast(String title, {bool afterClose = false}) {
    final ctx = afterClose ? widget.hostContext : context;
    if (!ctx.mounted) return;
    showHyperToast(ctx, content: Text(title));
  }

  String _nextRowId(String prefix) {
    _rowSeq += 1;
    return '${prefix}_$_rowSeq';
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

  List<Map<String, dynamic>> _asMaps(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return [
      for (final e in raw)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  String _cellText(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is Iterable) {
      return [
        for (final e in raw)
          if (e != null && '$e'.trim().isNotEmpty) '$e'.trim(),
      ].join(',');
    }
    return '$raw'.trim();
  }

  String _displayGender(dynamic raw) {
    var s = _cellText(raw);
    if (s.isEmpty && raw is Map) {
      s = _cellText(raw['label'] ?? raw['genderLabel'] ?? raw['name']);
    }
    // Excel 数字常为 1.0 / 2.0
    if (raw is num) {
      final n = raw.toInt();
      if (n == raw || (raw - n).abs() < 1e-9) {
        if (n == 1) return '男';
        if (n == 2) return '女';
        if (n == 0) return '未知';
      }
    }
    final lower = s.toLowerCase();
    if (s == '1' || s == '1.0' || s == '男' || lower == 'male' || lower == 'm') {
      return '男';
    }
    if (s == '2' || s == '2.0' || s == '女' || lower == 'female' || lower == 'f') {
      return '女';
    }
    if (s == '0' || s == '0.0' || s == '未知') return '未知';
    return s;
  }

  dynamic _genderRaw(Map<String, dynamic> row) =>
      row['gender'] ?? row['genderLabel'] ?? row['sex'] ?? row['性别'];

  void _applyPreview(List<Map<String, dynamic>> nested) {
    final contacts = <Map<String, dynamic>>[];
    final superiors = <Map<String, dynamic>>[];
    final subordinates = <Map<String, dynamic>>[];
    for (var i = 0; i < nested.length; i++) {
      final raw = nested[i];
      final name = _cellText(raw['name']);
      contacts.add({
        for (final f in _kContactFields)
          f.$1: f.$1 == 'gender'
              ? _displayGender(_genderRaw(raw))
              : raw[f.$1],
        '_rowId': _nextRowId('c'),
        '_prevName': name,
      });
      for (final rel in _asMaps(raw['superiors'])) {
        superiors.add({
          ...rel,
          if (_cellText(rel['contactName']).isEmpty) 'contactName': name,
          '_rowId': _nextRowId('s'),
        });
      }
      for (final rel in _asMaps(raw['subordinates'])) {
        subordinates.add({
          ...rel,
          if (_cellText(rel['contactName']).isEmpty) 'contactName': name,
          '_rowId': _nextRowId('b'),
        });
      }
    }
    _contacts = contacts;
    _superiors = superiors;
    _subordinates = subordinates;
    _previewTab = 0;
  }

  Future<void> _downloadTemplate() async {
    if (_downloadingTemplate || _parsing || _confirming) return;
    setState(() => _downloadingTemplate = true);
    try {
      final file = await _api.downloadContactImportTemplate();
      if (!mounted) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: '保存导入联系人模板',
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
      final list = await _api.previewContactImport(
        bytes: bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _files = const [];
          _parsing = false;
        });
        _toast('未解析到联系人数据，请检查模板内容');
        return;
      }
      setState(() {
        _applyPreview(list);
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
    if (_confirming || _contacts.isEmpty) return;
    setState(() => _confirming = true);
    try {
      await _api.confirmContactImport(
        contacts: [
          for (final c in _contacts) _contactConfirmRow(c),
        ],
        superiors: [
          for (final rel in _superiors) _relationConfirmRow(rel),
        ],
        subordinates: [
          for (final rel in _subordinates) _relationConfirmRow(rel),
        ],
      );
      if (!mounted) return;
      widget.onClose(true);
      _toast('联系人导入成功（${_contacts.length} 条）', afterClose: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      _toast(e.toString());
    }
  }

  Map<String, dynamic> _contactConfirmRow(Map<String, dynamic> row) {
    return {
      for (final key in _kContactConfirmKeys)
        key: key == 'gender'
            ? _genderForConfirm(row[key])
            : _nullIfEmpty(row[key]),
    };
  }

  Map<String, dynamic> _relationConfirmRow(Map<String, dynamic> row) {
    return {
      'contactName': _nullIfEmpty(row['contactName']),
      for (final key in _kContactConfirmKeys)
        key: key == 'gender'
            ? _genderForConfirm(row[key])
            : _nullIfEmpty(row[key]),
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

  String? _genderForConfirm(Object? raw) {
    final s = _displayGender(raw).trim();
    if (s.isEmpty) return null;
    return s;
  }

  void _syncRelContactName({required String oldName, required String newName}) {
    final from = oldName.trim();
    if (from.isEmpty || from == newName) return;
    for (final rel in [..._superiors, ..._subordinates]) {
      if (_cellText(rel['contactName']) == from) {
        rel['contactName'] = newName;
      }
    }
  }

  void _addContactRow() {
    // AppDataGrid 仅在 rows 引用变化时刷新，必须换新 List。
    setState(() {
      _contacts = [
        ..._contacts,
        <String, dynamic>{
          '_rowId': _nextRowId('c'),
          '_prevName': '',
        },
      ];
    });
  }

  void _addSuperiorRow() {
    final fallback = _contacts.isEmpty ? '' : _cellText(_contacts.first['name']);
    setState(() {
      _superiors = [
        ..._superiors,
        <String, dynamic>{
          '_rowId': _nextRowId('s'),
          if (fallback.isNotEmpty) 'contactName': fallback,
        },
      ];
    });
  }

  void _addSubordinateRow() {
    final fallback = _contacts.isEmpty ? '' : _cellText(_contacts.first['name']);
    setState(() {
      _subordinates = [
        ..._subordinates,
        <String, dynamic>{
          '_rowId': _nextRowId('b'),
          if (fallback.isNotEmpty) 'contactName': fallback,
        },
      ];
    });
  }

  void _removeContactRow(Map<String, dynamic> row) {
    setState(() {
      _contacts = [
        for (final e in _contacts)
          if (!identical(e, row)) e,
      ];
    });
  }

  void _removeSuperiorRow(Map<String, dynamic> row) {
    setState(() {
      _superiors = [
        for (final e in _superiors)
          if (!identical(e, row)) e,
      ];
    });
  }

  void _removeSubordinateRow(Map<String, dynamic> row) {
    setState(() {
      _subordinates = [
        for (final e in _subordinates)
          if (!identical(e, row)) e,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _ImportStage.preview) {
      return HyperDialog(
        title: const Text('导入联系人预览'),
        scrollable: false,
        style: const HyperDialogStyle(maxWidth: 1120),
        content: SizedBox(
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewTabs(
                selected: _previewTab,
                contactCount: _contacts.length,
                superiorCount: _superiors.length,
                subordinateCount: _subordinates.length,
                onSelect: (i) => setState(() => _previewTab = i),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (_previewTab) {
                  1 => _buildSheet(
                      rows: _superiors,
                      fields: _kRelFields,
                      emptyHint: '暂无上级，可点击下方添加',
                      onAdd: _confirming ? null : _addSuperiorRow,
                      onDelete: _removeSuperiorRow,
                    ),
                  2 => _buildSheet(
                      rows: _subordinates,
                      fields: _kRelFields,
                      emptyHint: '暂无下级，可点击下方添加',
                      onAdd: _confirming ? null : _addSubordinateRow,
                      onDelete: _removeSubordinateRow,
                    ),
                  _ => _buildSheet(
                      rows: _contacts,
                      fields: _kContactFields,
                      emptyHint: '暂无联系人，可点击下方添加',
                      onAdd: _confirming ? null : _addContactRow,
                      onDelete: _removeContactRow,
                      onNameChanged: (row, name) {
                        final oldName = _cellText(row['_prevName']);
                        row['name'] = name;
                        _syncRelContactName(oldName: oldName, newName: name.trim());
                        row['_prevName'] = name.trim();
                      },
                    ),
                },
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
      title: const Text('导入联系人'),
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
            dialogTitle: '选择联系人导入文件',
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
            '· 模板仅含联系人信息：联系人 / 上级联系人 / 下级联系人。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            '· 「关联企业」请填经营主体全称（将按此新建客户档案与经营主体）。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            '· 上级 / 下级 sheet 中主联系人姓名须与「联系人」sheet 一致。',
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

  Widget _buildSheet({
    required List<Map<String, dynamic>> rows,
    required List<(String key, String title, double width)> fields,
    required String emptyHint,
    required VoidCallback? onAdd,
    required void Function(Map<String, dynamic> row) onDelete,
    void Function(Map<String, dynamic> row, String name)? onNameChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppDataGrid<Map<String, dynamic>>.local(
                rows: rows,
                rowKey: (row) => row['_rowId'] ?? identityHashCode(row),
                height: null,
                shrinkWrap: false,
                sortable: false,
                showFilters: false,
                empty: Center(
                  child: Text(
                    emptyHint,
                    style: const TextStyle(color: _kMuted),
                  ),
                ),
                columns: [
                  for (final f in fields)
                    AppDataGridColumn(
                      id: f.$1,
                      title: f.$2,
                      width: f.$3,
                      // 默认 minWidth=80，窄列（如原性别 64）会被撑开/裁切输入框
                      minWidth: f.$3,
                      alignment: Alignment.centerLeft,
                      titleAlignment: Alignment.centerLeft,
                      value: (row) => f.$1 == 'gender'
                          ? _displayGender(_genderRaw(row))
                          : _cellText(row[f.$1]),
                      cellBuilder: (context, row, _) => _editCell(
                        value: f.$1 == 'gender'
                            ? _displayGender(_genderRaw(row))
                            : _cellText(row[f.$1]),
                        onChanged: (v) {
                          if (f.$1 == 'name' && onNameChanged != null) {
                            onNameChanged(row, v);
                            return;
                          }
                          if (f.$1 == 'gender') {
                            final t = v.trim();
                            if (t == '男' || t == '女' || t == '未知') {
                              row[f.$1] = t;
                            } else {
                              row[f.$1] = v;
                            }
                          } else {
                            row[f.$1] = v;
                          }
                        },
                      ),
                    ),
                  AppDataGridColumn(
                    id: 'actions',
                    title: '操作',
                    width: 72,
                    minWidth: 72,
                    value: (_) => '',
                    cellBuilder: (context, row, _) => HyperButton.text(
                      onPressed:
                          _confirming ? null : () => onDelete(row),
                      label: const Text(
                        '删除',
                        style: TextStyle(color: _kDanger),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: HyperButton.text(
            onPressed: onAdd,
            label: const Text(
              '+ 添加一行',
              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editCell({
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: TextFormField(
        initialValue: value ?? '',
        style: const TextStyle(fontSize: 13, height: 1.25, color: _kTitle),
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
        onChanged: onChanged,
      ),
    );
  }
}

class _PreviewTabs extends StatelessWidget {
  const _PreviewTabs({
    required this.selected,
    required this.contactCount,
    required this.superiorCount,
    required this.subordinateCount,
    required this.onSelect,
  });

  final int selected;
  final int contactCount;
  final int superiorCount;
  final int subordinateCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int)>[
      ('联系人', contactCount),
      ('联系人上级', superiorCount),
      ('联系人下级', subordinateCount),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 20),
            child: AppInkWell(
              onPressed: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected == i ? _kPrimary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '${items[i].$1}（${items[i].$2}）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected == i ? FontWeight.w600 : FontWeight.w400,
                    color: selected == i ? _kPrimary : _kLabel,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _ImportStage { upload, preview }
