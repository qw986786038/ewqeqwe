import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import '../employee_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF86909C);
const _kBorder = Color(0xFFE5E6EB);
const _kDivider = Color(0xFFF2F3F5);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF86909C);
const _kHeaderBg = Color(0xFFFAFBFC);
const _kOrange = Color(0xFFD46B08);
const _kGreen = Color(0xFF00B42A);
const _kSuccessBg = Color(0xFFF6FFED);
const _kSuccessBorder = Color(0xFFB7EB8F);
const _kPageShadow = Color(0x0A000000);

/// 通讯录展示：按设计稿左右分栏；无接口字段写死演示。
class EmployeeDirectoryTab extends StatefulWidget {
  const EmployeeDirectoryTab({super.key});

  @override
  State<EmployeeDirectoryTab> createState() => _EmployeeDirectoryTabState();
}

class _EmployeeDirectoryTabState extends State<EmployeeDirectoryTab> {
  bool _showMobile = true;
  bool _showCorpEmail = true;
  bool _allowWecom = true;
  bool _keepAfterLeave = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return Obx(() {
      final p = c.profile.value;
      final name = _nz(p?.name, '杜甫');
      final avatar = name.isNotEmpty ? name.characters.first : '?';
      final no = _nz(p?.no, '1298');
      final loc = c.officeLocationLabel()?.trim();
      final locLine = (loc == null || loc.isEmpty) ? '济南 · SH-18' : loc;
      final mobileRaw = p?.mobile?.trim();
      final mobile = _maskMobile(
        (mobileRaw == null || mobileRaw.isEmpty) ? '13810000297' : mobileRaw,
      );
      final emailRaw = p?.corpEmail?.trim();
      final email = _maskEmail(
        (emailRaw == null || emailRaw.isEmpty) ? 'dufu@adhr.cn' : emailRaw,
      );
      final statusText = EmployeeDetailController.statusLabel(p?.empStatus);
      final statusOk = statusText == '在职' || statusText == '—';

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '通讯录卡片预览',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kTitle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '同事在通讯录中看到的展示效果（当前预览）',
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Text(
                                avatar,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _kTitle,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _kSuccessBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _kSuccessBorder,
                                          ),
                                        ),
                                        child: Text(
                                          statusOk ? '在职' : statusText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _kGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '工号 $no',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    locLine,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _showMobile ? mobile : '手机号已隐藏',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _showCorpEmail ? email : '企业邮箱已隐藏',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _OutlineAction(
                              label: '拨打',
                              onPressed: () {
                                AppToast.show(
                                  context: context,
                                  title: '拨打待接入',
                                );
                              },
                            ),
                            _OutlineAction(
                              label: '邮件',
                              onPressed: () {
                                AppToast.show(
                                  context: context,
                                  title: '邮件待接入',
                                );
                              },
                            ),
                            _OutlineAction(
                              label: 'IM',
                              onPressed: () {
                                AppToast.show(
                                  context: context,
                                  title: 'IM 待接入',
                                );
                              },
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1, color: _kDivider),
                        ),
                        AppCheckbox(
                          state: _showMobile
                              ? CheckboxState.checked
                              : CheckboxState.unchecked,
                          trailing: const Text('在通讯录中展示手机号'),
                          onChanged: (s) => setState(
                            () => _showMobile = s == CheckboxState.checked,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppCheckbox(
                          state: _showCorpEmail
                              ? CheckboxState.checked
                              : CheckboxState.unchecked,
                          trailing: const Text('在通讯录中展示企业邮箱'),
                          onChanged: (s) => setState(
                            () =>
                                _showCorpEmail = s == CheckboxState.checked,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppCheckbox(
                          state: _allowWecom
                              ? CheckboxState.checked
                              : CheckboxState.unchecked,
                          trailing: const Text('允许同事通过企业微信联系我'),
                          onChanged: (s) => setState(
                            () => _allowWecom = s == CheckboxState.checked,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppCheckbox(
                          state: _keepAfterLeave
                              ? CheckboxState.checked
                              : CheckboxState.unchecked,
                          trailing: const Text('离职后保留在通讯录'),
                          onChanged: (s) => setState(
                            () =>
                                _keepAfterLeave = s == CheckboxState.checked,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(flex: 7, child: _VisibilityCard()),
              ],
            ),
          ),
        ],
      );
    });
  }

  static String _nz(String? value, String fallback) {
    final s = value?.trim();
    if (s == null || s.isEmpty || s == '—') return fallback;
    return s;
  }

  static String _maskMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return raw;
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
  }

  static String _maskEmail(String raw) {
    final at = raw.indexOf('@');
    if (at <= 0) return raw;
    final local = raw.substring(0, at);
    final domain = raw.substring(at);
    if (local.length <= 2) return '${local[0]}***$domain';
    return '${local.substring(0, 2)}***$domain';
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: _kPageShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton.outline(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '字段可见性与隐藏规则',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Column(
              children: [
                Container(
                  color: _kHeaderBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: _HText('字段')),
                      Expanded(flex: 2, child: _HText('全员可见')),
                      Expanded(flex: 2, child: _HText('部门负责人')),
                      Expanded(flex: 2, child: _HText('HR / 本人')),
                    ],
                  ),
                ),
                for (var i = 0; i < _rules.length; i++)
                  _RuleRow(row: _rules[i], zebra: i.isOdd),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '带开关的项以通讯录权限、四宫格隐藏入口。',
            style: TextStyle(fontSize: 12, color: _kOrange),
          ),
        ],
      ),
    );
  }
}

enum _CellTone { on, off, warn }

class _RuleData {
  const _RuleData({
    required this.field,
    required this.all,
    required this.dept,
    required this.hr,
    this.allTone = _CellTone.on,
    this.deptTone = _CellTone.on,
  });

  final String field;
  final String all;
  final String dept;
  final String hr;
  final _CellTone allTone;
  final _CellTone deptTone;
}

const _rules = <_RuleData>[
  _RuleData(field: '头像', all: '开启', dept: '开启', hr: '开启'),
  _RuleData(field: '姓名 / 英文名', all: '开启', dept: '开启', hr: '开启'),
  _RuleData(field: '部门 / 职务 / 职级', all: '开启', dept: '开启', hr: '开启'),
  _RuleData(
    field: '手机号',
    all: '中间四位隐藏',
    dept: '开启',
    hr: '开启',
    allTone: _CellTone.warn,
  ),
  _RuleData(field: '企业邮箱', all: '开启', dept: '开启', hr: '开启'),
  _RuleData(
    field: '个人邮箱',
    all: '不可见',
    dept: '不可见',
    hr: '开启',
    allTone: _CellTone.off,
    deptTone: _CellTone.off,
  ),
  _RuleData(
    field: '身份证号',
    all: '不可见',
    dept: '不可见',
    hr: '开启',
    allTone: _CellTone.off,
    deptTone: _CellTone.off,
  ),
  _RuleData(
    field: '工资 / 薪酬',
    all: '不可见',
    dept: '不可见',
    hr: '开启',
    allTone: _CellTone.off,
    deptTone: _CellTone.off,
  ),
  _RuleData(
    field: '紧急联系人',
    all: '不可见',
    dept: '部门可见',
    hr: '开启',
    allTone: _CellTone.off,
    deptTone: _CellTone.warn,
  ),
];

class _HText extends StatelessWidget {
  const _HText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _kLabel,
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.row, required this.zebra});

  final _RuleData row;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: zebra ? const Color(0xFFFAFBFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.field,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          Expanded(flex: 2, child: _ToneText(row.all, row.allTone)),
          Expanded(flex: 2, child: _ToneText(row.dept, row.deptTone)),
          Expanded(flex: 2, child: _ToneText(row.hr, _CellTone.on)),
        ],
      ),
    );
  }
}

class _ToneText extends StatelessWidget {
  const _ToneText(this.text, this.tone);

  final String text;
  final _CellTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _CellTone.on => _kGreen,
      _CellTone.warn => _kOrange,
      _CellTone.off => _kMuted,
    };
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
