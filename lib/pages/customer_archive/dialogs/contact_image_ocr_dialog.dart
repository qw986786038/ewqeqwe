import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../services/customer_api.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kLabel = Color(0xFF4E5969);
const _kTitle = Color(0xFF1D2129);

const _kGenderOptions = [
  AppOption(value: '1', label: '男'),
  AppOption(value: '2', label: '女'),
  AppOption(value: '0', label: '未知'),
];

/// 联系人图片 / 文本识别回填结果。
class ContactOcrFillData {
  const ContactOcrFillData({
    this.nameZh,
    this.nameEn,
    this.gender,
    this.ageDesc,
    this.relatedEnterprise,
    this.city,
    this.address,
    this.deptTitle,
    this.jobDesc,
    this.mobile,
    this.phone,
    this.email,
    this.remark,
  });

  final String? nameZh;
  final String? nameEn;
  /// 表单性别值：`1` 男 / `2` 女。
  final String? gender;
  final String? ageDesc;
  final String? relatedEnterprise;
  final String? city;
  final String? address;
  final String? deptTitle;
  final String? jobDesc;
  final String? mobile;
  final String? phone;
  final String? email;
  final String? remark;

  bool get hasAny =>
      nameZh != null ||
      nameEn != null ||
      gender != null ||
      ageDesc != null ||
      relatedEnterprise != null ||
      city != null ||
      address != null ||
      deptTitle != null ||
      jobDesc != null ||
      mobile != null ||
      phone != null ||
      email != null ||
      remark != null;
}

/// 选图并做通用文字识别。取消或失败返回 `null`。
Future<OacGeneralOcrResult?> recognizeImageText(
  BuildContext context, {
  String dialogTitle = '选择图片（截图或拍照）',
}) async {
  final picked = await FilePicker.pickFile(
    dialogTitle: dialogTitle,
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
  );
  if (picked == null) return null;

  Uint8List bytes;
  try {
    bytes = await picked.readAsBytes();
  } catch (_) {
    if (picked.path != null && picked.path!.trim().isNotEmpty) {
      bytes = await File(picked.path!).readAsBytes();
    } else {
      if (context.mounted) {
        showHyperToast(context, content: const Text('无法读取所选图片'));
      }
      return null;
    }
  }
  if (bytes.isEmpty) {
    if (context.mounted) {
      showHyperToast(context, content: const Text('图片为空'));
    }
    return null;
  }
  if (!context.mounted) return null;

  try {
    showHyperToast(context, content: const Text('正在识别图片…'));
    return await CustomerApi().ocrAllTextUpload(
      bytes: bytes,
      fileName: picked.name,
    );
  } catch (e) {
    if (context.mounted) {
      showHyperToast(context, content: Text('$e'));
    }
    return null;
  }
}

/// 上传图片（截图或拍照）→ OCR → 预览确认回填。
Future<ContactOcrFillData?> showContactImageOcrDialog(
  BuildContext context,
) async {
  final ocr = await recognizeImageText(
    context,
    dialogTitle: '选择联系人图片（截图或拍照）',
  );
  if (ocr == null || !context.mounted) return null;
  return showContactOcrPreviewDialog(
    context,
    initialContent: ocr.content ?? ocr.words.join('\n'),
    kvData: ocr.kvData,
  );
}

/// 图片识别结果预览 / 修改 / 确认回填。
Future<ContactOcrFillData?> showContactOcrPreviewDialog(
  BuildContext context, {
  String? initialContent,
  Map<String, dynamic>? kvData,
}) {
  return showHyperDialog<ContactOcrFillData>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _ContactOcrPreviewDialog(
        initialContent: initialContent ?? '',
        kvData: kvData,
        onClose: (data) => Navigator.of(dialogContext).pop(data),
      ),
    ),
  );
}

class _ContactOcrPreviewDialog extends StatefulWidget {
  const _ContactOcrPreviewDialog({
    required this.initialContent,
    required this.onClose,
    this.kvData,
  });

  final String initialContent;
  final Map<String, dynamic>? kvData;
  final void Function(ContactOcrFillData? data) onClose;

  @override
  State<_ContactOcrPreviewDialog> createState() =>
      _ContactOcrPreviewDialogState();
}

class _ContactOcrPreviewDialogState extends State<_ContactOcrPreviewDialog> {
  late final TextEditingController _contentCtrl;
  late final TextEditingController _nameZhCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _enterpriseCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _remarkCtrl;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.initialContent);
    _nameZhCtrl = TextEditingController();
    _nameEnCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _enterpriseCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _titleCtrl = TextEditingController();
    _roleCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _remarkCtrl = TextEditingController();
    _applyParsed(
      parseContactOcrText(widget.initialContent, kvData: widget.kvData),
    );
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _nameZhCtrl.dispose();
    _nameEnCtrl.dispose();
    _ageCtrl.dispose();
    _enterpriseCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _titleCtrl.dispose();
    _roleCtrl.dispose();
    _mobileCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _applyParsed(ContactOcrFillData data) {
    void set(TextEditingController c, String? v) {
      c.text = v?.trim() ?? '';
    }

    set(_nameZhCtrl, data.nameZh);
    set(_nameEnCtrl, data.nameEn);
    set(_ageCtrl, data.ageDesc);
    set(_enterpriseCtrl, data.relatedEnterprise);
    set(_cityCtrl, data.city);
    set(_addressCtrl, data.address);
    set(_titleCtrl, data.deptTitle);
    set(_roleCtrl, data.jobDesc);
    set(_mobileCtrl, data.mobile);
    set(_phoneCtrl, data.phone);
    set(_emailCtrl, data.email);
    set(_remarkCtrl, data.remark);
    _gender = data.gender;
  }

  void _reparse() {
    setState(() {
      _applyParsed(parseContactOcrText(_contentCtrl.text));
    });
  }

  ContactOcrFillData _collect() {
    String? t(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    return ContactOcrFillData(
      nameZh: t(_nameZhCtrl),
      nameEn: t(_nameEnCtrl),
      gender: _gender,
      ageDesc: t(_ageCtrl),
      relatedEnterprise: t(_enterpriseCtrl),
      city: t(_cityCtrl),
      address: t(_addressCtrl),
      deptTitle: t(_titleCtrl),
      jobDesc: t(_roleCtrl),
      mobile: t(_mobileCtrl),
      phone: t(_phoneCtrl),
      email: t(_emailCtrl),
      remark: t(_remarkCtrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HyperDialog(
      title: const Text('图片识别结果'),
      scrollable: true,
      style: const HyperDialogStyle(maxWidth: 720),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '识别文本（可编辑，改后点「重新解析」更新下方字段）',
            style: TextStyle(fontSize: 12, color: _kLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(fontSize: 13, color: _kTitle, height: 1.45),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E6EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E6EB)),
              ),
            ),
          ),
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
          const SizedBox(height: 14),
          _fieldRow(
            _labeled('姓名', _nameZhCtrl, hint: '中文姓名'),
            _labeled('Name', _nameEnCtrl, hint: 'English name'),
          ),
          const SizedBox(height: 10),
          _fieldRow(
            _genderField(),
            _labeled('年龄段', _ageCtrl, hint: '如：约为35岁左右'),
          ),
          const SizedBox(height: 10),
          _fieldRow(
            _labeled('关联企业', _enterpriseCtrl, hint: '经营主体'),
            _labeled('所在城市', _cityCtrl, hint: '省+市，如山东省济南市'),
          ),
          const SizedBox(height: 10),
          _labeled('详细地址', _addressCtrl),
          const SizedBox(height: 10),
          _fieldRow(
            _labeled('部门/职位', _titleCtrl),
            _labeled('职能描述', _roleCtrl),
          ),
          const SizedBox(height: 10),
          _fieldRow(
            _labeled('手机号', _mobileCtrl),
            _labeled('电话', _phoneCtrl),
          ),
          const SizedBox(height: 10),
          _labeled('邮箱', _emailCtrl),
          const SizedBox(height: 10),
          _labeled('备注', _remarkCtrl, maxLines: 2),
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
            if (!data.hasAny) {
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

  Widget _fieldRow(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  Widget _labeled(
    String label,
    TextEditingController controller, {
    String? hint,
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
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E6EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E6EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('性别', style: TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 4),
        AppSelect<String>(
          value: _gender,
          hintText: '请选择',
          clearable: true,
          options: _kGenderOptions,
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }
}

/// 从 OCR 文本 / kvData 解析联系人字段。
ContactOcrFillData parseContactOcrText(
  String raw, {
  Map<String, dynamic>? kvData,
}) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  String? fromKv(List<String> keys) {
    if (kvData == null || kvData.isEmpty) return null;
    for (final entry in kvData.entries) {
      final k = entry.key.toString().trim();
      for (final want in keys) {
        if (k == want || k.contains(want)) {
          final v = entry.value?.toString().trim() ?? '';
          if (v.isNotEmpty) return v;
        }
      }
    }
    return null;
  }

  String? pick(RegExp re, {int group = 1}) {
    final m = re.firstMatch(text);
    if (m == null) return null;
    final v = m.group(group)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  var nameZh = fromKv(const ['姓名', 'name', 'Name']) ??
      pick(RegExp(r'姓名[:：\s]*([^\s性别民族出生住公民手机电话邮箱]{1,20})'));
  // 「姓名张三」无空格
  nameZh ??= pick(RegExp(r'姓名([^\s性别民族出生住址公民]{2,8})'));

  final genderRaw = fromKv(const ['性别', 'gender', 'Sex']) ??
      pick(RegExp(r'性别[:：\s]*([男女])'));
  String? gender;
  if (genderRaw == '男' || genderRaw == '1') gender = '1';
  if (genderRaw == '女' || genderRaw == '2') gender = '2';

  final birthY = pick(RegExp(r'出生[:：\s]*(\d{4})\s*年')) ??
      pick(RegExp(r'(\d{4})\s*年\s*\d{1,2}\s*月\s*\d{1,2}\s*日'));
  String? ageDesc;
  if (birthY != null) {
    final y = int.tryParse(birthY);
    if (y != null && y > 1900 && y < 2100) {
      final age = DateTime.now().year - y;
      if (age > 0 && age < 120) ageDesc = '约为$age岁左右，约$y年左右';
    }
  }

  var address = fromKv(const ['住址', '地址', '详细地址', 'address', 'Address']) ??
      pick(
        RegExp(
          r'住\s*址[:：\s]*(.+?)(?=公民身份号码|身份证号|手机|电话|邮箱|$)',
          dotAll: true,
        ),
      );
  address = address?.replaceAll(RegExp(r'\s+'), '');

  String? city;
  if (address != null && address.isNotEmpty) {
    final m = RegExp(r'^(.+?(?:省|自治区|市))(.+?(?:市|州|地区|盟|县))?').firstMatch(
      address,
    );
    if (m != null) {
      final p = m.group(1) ?? '';
      final c = m.group(2) ?? '';
      city = '$p$c'.trim().isEmpty ? null : '$p$c';
    }
  }
  city ??= fromKv(const ['所在城市', '城市', 'city', 'City']);

  // 身份证号仅作校验，不写入电话。
  final idNo = fromKv(const ['公民身份号码', '身份证号', '身份证']) ??
      pick(RegExp(r'(?:公民身份号码|身份证号?码?)[:：\s]*(\d{15}|\d{17}[\dXx])')) ??
      pick(RegExp(r'(?<!\d)(\d{17}[\dXx]|\d{15})(?!\d)'));

  String? mobile = fromKv(const ['手机号', '手机', 'mobile', 'Mobile']);
  String? phone = fromKv(const ['电话', '座机', 'tel', 'Tel', 'phone']);
  final email = fromKv(const ['邮箱', 'email', 'Email', 'E-mail']) ??
      pick(RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'));

  // 从全文抽手机 / 座机，避开身份证号。
  final mobiles = RegExp(r'(?<!\d)(1[3-9]\d{9})(?!\d)')
      .allMatches(text)
      .map((m) => m.group(1)!)
      .where((m) => idNo == null || !idNo.contains(m))
      .toList();
  if (mobile == null && mobiles.isNotEmpty) mobile = mobiles.first;

  final phones = RegExp(r'(?<!\d)(0\d{2,3}-?\d{7,8})(?!\d)')
      .allMatches(text)
      .map((m) => m.group(1)!)
      .toList();
  if (phone == null && phones.isNotEmpty) phone = phones.first;

  final title = fromKv(const ['部门/职位', '职位', '职务', '部门', 'title']);
  final role = fromKv(const ['职能描述', '职能', 'job']);
  final enterprise = fromKv(const ['关联企业', '企业', '公司', '单位', 'org']);
  final remark = fromKv(const ['备注', 'remark']);

  return ContactOcrFillData(
    nameZh: nameZh,
    gender: gender,
    ageDesc: ageDesc,
    relatedEnterprise: enterprise,
    city: city,
    address: address,
    deptTitle: title,
    jobDesc: role,
    mobile: mobile,
    phone: phone,
    email: email,
    remark: remark,
  );
}
