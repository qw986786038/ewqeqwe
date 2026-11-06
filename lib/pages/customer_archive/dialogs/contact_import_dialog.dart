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

const _kContactFields = <(String key, String title, double width)>[
  ('name', '姓名', 100),
  ('nameEn', 'Name', 100),
  ('gender', '性别', 64),
  ('ageDesc', '年龄段', 80),
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
      config: AppThemeConfig.standard(primary: _kPrimary),
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
  var _contacts = <Map<String, dynamic>>[];
  var _selectedIndex = 0;

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

  List<Map<String, dynamic>> _normalizeContacts(
    List<Map<String, dynamic>> raw,
  ) {
    return [
      for (var i = 0; i < raw.length; i++)
        {
          ...raw[i],
          '_rowId': 'c_$i',
          '_prevName': raw[i]['name']?.toString() ?? '',
          'superiors': _asMaps(raw[i]['superiors']),
          'subordinates': _asMaps(raw[i]['subordinates']),
        },
    ];
  }

  List<Map<String, dynamic>> _asMaps(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return [
      for (final e in raw)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
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
      final list = _normalizeContacts(
        await _api.previewContactImport(bytes: bytes, fileName: file.name),
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
        _contacts = list;
        _selectedIndex = 0;
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

  Map<String, dynamic>? get _selected {
    if (_contacts.isEmpty) return null;
    final i = _selectedIndex.clamp(0, _contacts.length - 1);
    return _contacts[i];
  }

  List<Map<String, dynamic>> _relList(String key) {
    final row = _selected;
    if (row == null) return const [];
    final list = row[key];
    if (list is List<Map<String, dynamic>>) return list;
    if (list is List) {
      final mapped = _asMaps(list);
      row[key] = mapped;
      return mapped;
    }
    final empty = <Map<String, dynamic>>[];
    row[key] = empty;
    return empty;
  }

  Future<void> _confirm() async {
    if (_confirming || _contacts.isEmpty) return;
    setState(() => _confirming = true);
    try {
      final payload = [
        for (final c in _contacts)
          {
            for (final entry in c.entries)
              if (entry.key != '_prevName' && entry.key != '_rowId')
                entry.key: entry.value is List
                    ? [
                        for (final rel in _asMaps(entry.value))
                          {
                            for (final e in rel.entries)
                              if (e.key != '_rowId') e.key: e.value,
                          },
                      ]
                    : entry.value,
          },
      ];
      await _api.confirmContactImport(payload);
      if (!mounted) return;
      widget.onClose(true);
      _toast('联系人导入成功（${_contacts.length} 条）', afterClose: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      _toast(e.toString());
    }
  }

  void _backToUpload() {
    if (_confirming) return;
    setState(() {
      _stage = _ImportStage.upload;
      _files = const [];
      _contacts = [];
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _ImportStage.preview) {
      return HyperDialog(
        title: Text('导入联系人 · 预览确认（${_contacts.length}）'),
        scrollable: false,
        style: const HyperDialogStyle(maxWidth: 1120),
        content: SizedBox(
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '请核对并修改预览数据，确认无误后再导入。上级 / 下级随选中联系人编辑。',
                style: TextStyle(fontSize: 13, color: _kLabel),
              ),
              const SizedBox(height: 10),
              Expanded(flex: 3, child: _buildContactsGrid()),
              const SizedBox(height: 10),
              Text(
                '上级（${_relList('superiors').length}）',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _buildRelGrid(
                  listKey: 'superiors',
                  rows: _relList('superiors'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '下级（${_relList('subordinates').length}）',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _buildRelGrid(
                  listKey: 'subordinates',
                  rows: _relList('subordinates'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          HyperButton.outlined(
            onPressed: _confirming ? null : _backToUpload,
            label: const Text('重新上传'),
          ),
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

  Widget _buildContactsGrid() {
    final selectedKey = _contacts.isEmpty
        ? null
        : _contacts[_selectedIndex.clamp(0, _contacts.length - 1)]['_rowId'];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppDataGrid<Map<String, dynamic>>.local(
          rows: _contacts,
          rowKey: (row) => row['_rowId'] ?? identityHashCode(row),
          height: null,
          shrinkWrap: false,
          sortable: false,
          showFilters: false,
          selectionMode: AppDataGridSelectionMode.single,
          selectedKeys: {?selectedKey},
          onSelectionChanged: (rows) {
            if (rows.isEmpty) return;
            final i = _contacts.indexOf(rows.first);
            if (i >= 0) setState(() => _selectedIndex = i);
          },
          empty: const Center(
            child: Text('暂无预览数据', style: TextStyle(color: _kMuted)),
          ),
          columns: [
            AppDataGridColumn(
              id: 'no',
              title: '序号',
              width: 52,
              value: (row) => _contacts.indexOf(row) + 1,
            ),
            for (final f in _kContactFields)
              AppDataGridColumn(
                id: f.$1,
                title: f.$2,
                width: f.$3,
                alignment: Alignment.centerLeft,
                titleAlignment: Alignment.centerLeft,
                value: (row) => '${row[f.$1] ?? ''}',
                cellBuilder: (context, row, _) => _editCell(
                  value: row[f.$1]?.toString(),
                  onChanged: (v) {
                    if (f.$1 == 'name') {
                      final oldName = row['_prevName']?.toString() ?? '';
                      final name = v.trim();
                      row[f.$1] = v;
                      _syncRelContactName(oldName: oldName, newName: name);
                      row['_prevName'] = name;
                    } else {
                      row[f.$1] = v;
                    }
                  },
                ),
              ),
            AppDataGridColumn(
              id: 'supCount',
              title: '上级',
              width: 56,
              value: (row) => _asMaps(row['superiors']).length,
            ),
            AppDataGridColumn(
              id: 'subCount',
              title: '下级',
              width: 56,
              value: (row) => _asMaps(row['subordinates']).length,
            ),
            AppDataGridColumn(
              id: 'actions',
              title: '操作',
              width: 72,
              value: (_) => '',
              cellBuilder: (context, row, _) => HyperButton.text(
                onPressed: _confirming
                    ? null
                    : () {
                        setState(() {
                          _contacts.remove(row);
                          _selectedIndex = _contacts.isEmpty
                              ? 0
                              : _selectedIndex.clamp(0, _contacts.length - 1);
                        });
                      },
                label: const Text('删除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncRelContactName({required String oldName, required String newName}) {
    final from = oldName.trim();
    if (from.isEmpty || from == newName) return;
    for (final c in _contacts) {
      for (final key in const ['superiors', 'subordinates']) {
        for (final rel in _asMaps(c[key])) {
          if ((rel['contactName']?.toString().trim() ?? '') == from) {
            rel['contactName'] = newName;
          }
        }
      }
    }
  }

  Widget _buildRelGrid({
    required String listKey,
    required List<Map<String, dynamic>> rows,
  }) {
    final owner = _selected;
    final ownerName = owner?['name']?.toString().trim() ?? '';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: AppDataGrid<Map<String, dynamic>>.local(
                rows: rows,
                rowKey: (row) =>
                    row['_rowId'] ??
                    '${listKey}_${rows.indexOf(row)}_${identityHashCode(row)}',
                height: null,
                shrinkWrap: false,
                sortable: false,
                showFilters: false,
                empty: Center(
                  child: Text(
                    owner == null ? '请先选择联系人' : '暂无数据',
                    style: const TextStyle(color: _kMuted),
                  ),
                ),
                columns: [
                  for (final f in _kRelFields)
                    AppDataGridColumn(
                      id: f.$1,
                      title: f.$2,
                      width: f.$3,
                      alignment: Alignment.centerLeft,
                      titleAlignment: Alignment.centerLeft,
                      value: (row) => '${row[f.$1] ?? ''}',
                      cellBuilder: (context, row, _) => _editCell(
                        value: row[f.$1]?.toString(),
                        onChanged: (v) => row[f.$1] = v,
                      ),
                    ),
                  AppDataGridColumn(
                    id: 'actions',
                    title: '操作',
                    width: 72,
                    value: (_) => '',
                    cellBuilder: (context, row, _) => HyperButton.text(
                      onPressed: _confirming
                          ? null
                          : () => setState(() => rows.remove(row)),
                      label: const Text('删除'),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: HyperButton.text(
                onPressed: _confirming || owner == null
                    ? null
                    : () {
                        setState(() {
                          rows.add(<String, dynamic>{
                            '_rowId':
                                '${listKey}_${DateTime.now().microsecondsSinceEpoch}',
                            'contactName': ownerName,
                          });
                        });
                      },
                label: const Text('+ 添加一行'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editCell({
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value ?? '',
      style: const TextStyle(fontSize: 12, color: _kTitle),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        border: InputBorder.none,
      ),
      onChanged: onChanged,
    );
  }
}

enum _ImportStage { upload, preview }
