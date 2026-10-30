import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'contact_vcf_parser.dart';

const _kPrimary = Color(0xFF0958D9);
const _kLabel = Color(0xFF334155);
const _kMuted = Color(0xFF64748B);
const _kBarrier = Color(0x99000000);
const _kCardBorder = Color(0xFFD0D5DD);
const _kCardBg = Color(0xFFF8FAFC);

/// 打开「上传 VCF」弹窗；确认填充后返回解析结果列表，取消返回 `null`。
Future<List<ContactVcfData>?> showContactVcfImportDialog(BuildContext context) {
  return AppDialog.show<List<ContactVcfData>>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: _kBarrier,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(
        primary: _kPrimary,
        themeMode: AppThemeMode.light,
        controls: const AppControlMetrics(
          height: 34,
          buttonHeight: 32,
          horizontalPadding: 10,
          fontSize: 12,
          iconSize: 14,
          contentGap: 6,
        ),
      ),
      child: _ContactVcfImportDialog(
        onClose: (data) =>
            AppOverlay.close<List<ContactVcfData>>(dialogContext, data),
      ),
    ),
  ).future;
}

class _ContactVcfImportDialog extends StatefulWidget {
  const _ContactVcfImportDialog({required this.onClose});

  final void Function(List<ContactVcfData>? data) onClose;

  @override
  State<_ContactVcfImportDialog> createState() =>
      _ContactVcfImportDialogState();
}

class _ContactVcfImportDialogState extends State<_ContactVcfImportDialog> {
  var _files = const <AppFileSelection>[];
  List<ContactVcfData> _parsed = const [];
  String? _error;
  var _reading = false;

  void _toast(String title) {
    if (!mounted) return;
    AppToast.show(context: context, title: title);
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
    throw ContactVcfParseException('无法读取所选文件');
  }

  Future<void> _onFilesChanged(List<AppFileSelection> next) async {
    setState(() {
      _files = next;
      _parsed = const [];
      _error = null;
    });
    if (next.isEmpty || _reading) return;
    final file = next.first;
    setState(() => _reading = true);
    try {
      final bytes = await _readBytes(file);
      if (bytes.isEmpty) {
        throw ContactVcfParseException('VCF 文件为空');
      }
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        throw ContactVcfParseException('文件过大（上限 2MB）');
      }
      final text = _decodeText(bytes);
      final parsed = parseContactVcfAll(text);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _error = null;
        _reading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _files = const [];
        _parsed = const [];
        _error = e.toString();
        _reading = false;
      });
      _toast(e.toString());
    }
  }

  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return const Latin1Codec().decode(bytes);
      } catch (_) {
        throw ContactVcfParseException('无法识别文件编码，请使用 UTF-8 的 VCF');
      }
    }
  }

  void _apply() {
    if (_parsed.isEmpty) {
      _toast('请先上传有效的 VCF 文件');
      return;
    }
    widget.onClose(_parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      title: const Text('上传 VCF'),
      constraints: const BoxConstraints(minWidth: 480, maxWidth: 560),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '选择联系人 vCard（.vcf）文件，解析后可自动填充；含多个联系人时将一并导入。',
            style: TextStyle(fontSize: 13, color: _kLabel, height: 1.4),
          ),
          const SizedBox(height: 12),
          AppFilePicker(
            files: _files,
            multiple: false,
            maxFiles: 1,
            enabled: !_reading,
            allowedExtensions: const ['vcf', 'vcard'],
            emptyTitle: '将 VCF 拖到此处，或点击上传',
            dropTitle: '松开以上传文件',
            pickLabel: '点击上传',
            dialogTitle: '选择 VCF 文件',
            onRejected: _toast,
            onChanged: _onFilesChanged,
          ),
          if (_reading) ...[
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
                  '正在解析…',
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFCF1322)),
            ),
          ],
          if (_parsed.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _parsed.length == 1
                  ? '解析预览'
                  : '解析预览（共 ${_parsed.length} 位联系人）',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kLabel,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < _parsed.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _contactPreviewCard(
                        index: i,
                        total: _parsed.length,
                        data: _parsed[i],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            '· 支持标准 vCard（.vcf / .vcard）；单次上传一个文件，可含多个联系人。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 4),
          const Text(
            '· 首位填充到当前联系人，其余将自动新增联系人卡片；未识别字段保持原值。',
            style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
          ),
        ],
      ),
      actions: [
        AppButton.primary(
          onPressed: _parsed.isEmpty || _reading ? null : _apply,
          child: Text(
            _parsed.length > 1
                ? '填充 ${_parsed.length} 位联系人'
                : '填充到联系人',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        AppButton.outline(
          onPressed: _reading ? null : () => widget.onClose(null),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _contactPreviewCard({
    required int index,
    required int total,
    required ContactVcfData data,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '联系人 ${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ),
          _previewRow('姓名', data.nameZh),
          _previewRow('Name', data.nameEn),
          _previewRow(
            '性别',
            switch (data.gender) {
              '1' => '男',
              '2' => '女',
              _ => data.gender,
            },
          ),
          _previewRow('手机号', data.mobile),
          _previewRow('电话', data.phone),
          _previewRow('邮箱', data.email),
          _previewRow('所在城市', data.combinedCity),
          _previewRow('详细地址', data.address),
          _previewRow('部门/职位', data.title),
          _previewRow('组织', data.org),
          _previewRow('职能描述', data.role),
          _previewRow('备注', data.remark),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.35),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 12, color: _kLabel, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
