import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

const _kPrimary = Color(0xFF0958D9);
const _kMuted = Color(0xFF64748B);
const _kLabel = Color(0xFF334155);
const _kTitle = Color(0xFF141414);

/// 识别结果里的一项，确认页可改。
class OcrConfirmField {
  const OcrConfirmField({
    required this.key,
    required this.label,
    this.value,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final String? value;
  final int maxLines;
}

/// 识别文本 + 解析字段的二次确认。取消返回 `null`。
Future<Map<String, String>?> showOcrTextConfirmDialog(
  BuildContext context, {
  required String title,
  required String rawText,
  required List<OcrConfirmField> fields,
  List<OcrConfirmField> Function(String rawText)? reparse,
}) {
  return showHyperDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _OcrTextConfirmDialog(
        title: title,
        rawText: rawText,
        initialFields: fields,
        reparse: reparse,
        onClose: (data) => Navigator.of(dialogContext).pop(data),
      ),
    ),
  );
}

class _OcrTextConfirmDialog extends StatefulWidget {
  const _OcrTextConfirmDialog({
    required this.title,
    required this.rawText,
    required this.initialFields,
    required this.onClose,
    this.reparse,
  });

  final String title;
  final String rawText;
  final List<OcrConfirmField> initialFields;
  final List<OcrConfirmField> Function(String rawText)? reparse;
  final void Function(Map<String, String>? data) onClose;

  @override
  State<_OcrTextConfirmDialog> createState() => _OcrTextConfirmDialogState();
}

class _OcrTextConfirmDialogState extends State<_OcrTextConfirmDialog> {
  late final TextEditingController _rawCtrl;
  late List<OcrConfirmField> _fields;
  late List<TextEditingController> _fieldCtrls;

  @override
  void initState() {
    super.initState();
    _rawCtrl = TextEditingController(text: widget.rawText);
    _fields = const [];
    _fieldCtrls = const [];
    _replaceFields(widget.initialFields);
  }

  @override
  void dispose() {
    _rawCtrl.dispose();
    for (final c in _fieldCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _replaceFields(List<OcrConfirmField> fields) {
    for (final c in _fieldCtrls) {
      c.dispose();
    }
    _fields = fields;
    _fieldCtrls = [
      for (final f in fields) TextEditingController(text: f.value?.trim() ?? ''),
    ];
  }

  void _reparse() {
    final parse = widget.reparse;
    if (parse == null) return;
    setState(() => _replaceFields(parse(_rawCtrl.text)));
  }

  Map<String, String> _collect() {
    final out = <String, String>{};
    for (var i = 0; i < _fields.length; i++) {
      out[_fields[i].key] = _fieldCtrls[i].text.trim();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final wide = <Widget>[];
    final pair = <Widget>[];
    void flushPair() {
      if (pair.isEmpty) return;
      if (pair.length == 1) {
        wide.add(pair.first);
      } else {
        wide.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: pair[0]),
              const SizedBox(width: 12),
              Expanded(child: pair[1]),
            ],
          ),
        );
      }
      pair.clear();
    }

    for (var i = 0; i < _fields.length; i++) {
      final field = _fields[i];
      final box = _labeled(field.label, _fieldCtrls[i], maxLines: field.maxLines);
      if (field.maxLines > 1) {
        flushPair();
        wide.add(box);
      } else {
        pair.add(box);
        if (pair.length == 2) flushPair();
      }
    }
    flushPair();

    return HyperDialog(
      title: Text(widget.title),
      scrollable: true,
      style: const HyperDialogStyle(maxWidth: 720),
      onClose: () => widget.onClose(null),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '识别文本（可编辑，改后点「重新解析」更新下方字段）',
            style: TextStyle(fontSize: 12, color: _kLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rawCtrl,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(fontSize: 13, color: _kTitle, height: 1.45),
            decoration: _decoration(),
          ),
          if (widget.reparse != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: AppInkWell(
                onPressed: _reparse,
                child: const Text(
                  '重新解析',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (var i = 0; i < wide.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            wide[i],
          ],
        ],
      ),
      actions: [
        HyperButton.outlined(
          onPressed: () => widget.onClose(null),
          label: const Text('取消'),
        ),
        HyperButton.filled(
          onPressed: () {
            final data = _collect();
            if (!data.values.any((v) => v.isNotEmpty)) {
              showHyperToast(context, content: const Text('请至少填写一项后再确认'));
              return;
            }
            widget.onClose(data);
          },
          label: const Text('确认回填'),
        ),
      ],
    );
  }

  Widget _labeled(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: _kTitle),
          decoration: _decoration(dense: true),
        ),
      ],
    );
  }

  InputDecoration _decoration({bool dense = false}) {
    const side = BorderSide(color: Color(0xFFE5E6EB));
    return InputDecoration(
      isDense: dense,
      filled: !dense,
      fillColor: dense ? null : const Color(0xFFF7F8FA),
      contentPadding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 10 : 12,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(dense ? 6 : 8), borderSide: side),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(dense ? 6 : 8),
        borderSide: side,
      ),
    );
  }
}
