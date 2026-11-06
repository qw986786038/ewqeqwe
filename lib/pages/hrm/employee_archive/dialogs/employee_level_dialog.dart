import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../models/hrm_employee.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../services/hrm_api.dart';

const _kTitle = Color(0xFF1D2129);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFF53F3F);
const _kReadonly = Color(0xFFF7F8FA);

/// 花名册 · 调级。编制不变，提交 `POST /desktop/hrm/employee-assign/transfer`。
Future<bool> showEmployeeLevelDialog(
  BuildContext context, {
  required HrmEmployeeProfile employee,
  HrmEmployeeTitle? initial,
}) {
  return showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
      child: _LevelDialog(profile: employee, initial: initial),
    ),
  ).then((v) => v == true);
}

class _LevelDialog extends StatefulWidget {
  const _LevelDialog({required this.profile, this.initial});

  final HrmEmployeeProfile profile;
  final HrmEmployeeTitle? initial;

  @override
  State<_LevelDialog> createState() => _LevelDialogState();
}

class _LevelDialogState extends State<_LevelDialog> {
  final _api = HrmApi();
  final _form = AppFormController();

  var _loading = true;
  var _saving = false;
  String? _loadError;

  List<HrmPost> _posts = const [];
  List<HrmPostSeqLevel> _levels = const [];
  final Map<String, HrmPostSeqLevel> _levelById = {};

  String? _positionId;
  String? _levelId;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initial?.positionId?.trim();
    if (initialId != null && initialId.isNotEmpty) {
      _positionId = initialId;
    } else if (_seats.length == 1) {
      _positionId = _seats.first.positionId?.trim();
    }
    _levelId = _seat?.postSeqLevelId?.trim();
    _loadOptions();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  List<HrmEmployeeTitle> get _seats => [
        for (final t in widget.profile.titleList)
          if (t.positionId?.trim().isNotEmpty == true) t,
      ];

  HrmEmployeeTitle? get _seat {
    final id = _positionId?.trim();
    if (id == null || id.isEmpty) return null;
    for (final t in _seats) {
      if (t.positionId?.trim() == id) return t;
    }
    return null;
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchPosts(),
        _api.fetchPostSeqLevels(),
      ]);
      if (!mounted) return;
      final levels = results[1] as List<HrmPostSeqLevel>;
      setState(() {
        _posts = results[0] as List<HrmPost>;
        _levels = levels;
        _levelById
          ..clear()
          ..addEntries([
            for (final l in levels)
              if (l.id?.trim().isNotEmpty == true) MapEntry(l.id!.trim(), l),
          ]);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  List<HrmPostSeqLevel> get _targetLevels {
    final postId = _seat?.postId?.trim();
    HrmPost? post;
    for (final item in _posts) {
      if (item.id?.trim() == postId) {
        post = item;
        break;
      }
    }
    final min = _levelById[post?.postSeqLevelIdMin?.trim() ?? ''];
    final max = _levelById[post?.postSeqLevelIdMax?.trim() ?? ''];
    final seq = min?.postSeqId?.trim();
    if (seq == null || seq.isEmpty || seq != max?.postSeqId?.trim()) {
      return _levels;
    }
    final lo = min!.orderNum ?? 0;
    final hi = max!.orderNum ?? lo;
    final from = lo < hi ? lo : hi;
    final to = lo > hi ? lo : hi;
    final matched = [
      for (final l in _levels)
        if (l.postSeqId?.trim() == seq && l.id?.trim().isNotEmpty == true)
          if (l.orderNum == null || (l.orderNum! >= from && l.orderNum! <= to))
            l,
    ];
    return matched.isEmpty ? _levels : matched;
  }

  String _seatLabel(HrmEmployeeTitle title) {
    final dept = title.deptName?.trim() ?? '';
    final post = title.postName?.trim() ?? '';
    final level = title.postSeqLeveName?.trim() ?? '';
    final parts = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
      if (level.isNotEmpty) level,
    ];
    final text = parts.isEmpty ? (title.positionId?.trim() ?? '-') : parts.join(' / ');
    if (title.isPrimary == 1) return '$text · 主岗';
    return text;
  }

  String? _need(String? id, String label) {
    if (id == null || id.trim().isEmpty) return '请选择$label';
    return null;
  }

  Future<void> _submit() async {
    if (_saving || _loading) return;
    await _form.submit((_) async {
      final missing = _need(_positionId, '在职编制') ?? _need(_levelId, '目标职级');
      if (missing != null) {
        AppToast.show(context: context, title: missing);
        return;
      }
      final positionId = _positionId!.trim();
      final levelId = _levelId!.trim();
      if (positionId.isEmpty || levelId.isEmpty) {
        AppToast.show(context: context, title: '在职编制或职级无效');
        return;
      }
      setState(() => _saving = true);
      try {
        await _api.transferEmployeeAssign(
          oldPositionId: positionId,
          newPositionId: positionId,
          newPostSeqLevelId: levelId,
        );
        if (!mounted) return;
        AppToast.show(context: context, title: '调级成功');
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        AppToast.show(context: context, title: e.toString());
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.name?.trim() ?? '';
    final currentLevel = _seat?.postSeqLeveName?.trim() ?? '';
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: const Text('调级'),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 520),
        onClose: _saving ? null : () => Navigator.of(context).pop(false),
        content: _loading
            ? const SizedBox(
                height: 180,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              )
            : _loadError != null
                ? SizedBox(
                    height: 180,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: _kDanger),
                          ),
                          const SizedBox(height: 12),
                          HyperButton.outlined(
                            onPressed: _loadOptions,
                            label: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _Readonly(label: '员工', value: name),
                      _Field(
                        label: '在职编制',
                        required: true,
                        child: AppSelectFormField<String>(
                          name: 'positionId',
                          hintText: '请选择在职编制',
                          options: [
                            for (final t in _seats)
                              AppOption(
                                value: t.positionId!.trim(),
                                label: _seatLabel(t),
                              ),
                          ],
                          initialValue: _positionId,
                          validator: (_) => _need(_positionId, '在职编制'),
                          onChanged: (value) {
                            setState(() {
                              _positionId = value;
                              _levelId = _seat?.postSeqLevelId?.trim();
                            });
                          },
                        ),
                      ),
                      _Readonly(
                        label: '原职级',
                        value: currentLevel,
                      ),
                      _Field(
                        label: '目标职级',
                        required: true,
                        child: AppSelectFormField<String>(
                          key: ValueKey('level-$_positionId'),
                          name: 'postSeqLevelId',
                          hintText: _positionId == null ? '请先选择在职编制' : '请选择目标职级',
                          enabled: _positionId != null,
                          options: [
                            for (final l in _targetLevels)
                              if (l.id?.trim().isNotEmpty == true &&
                                  l.code?.trim().isNotEmpty == true)
                                AppOption(value: l.id!.trim(), label: l.code!.trim()),
                          ],
                          initialValue: _levelId,
                          validator: (_) => _need(_levelId, '目标职级'),
                          onChanged: (value) => _levelId = value,
                        ),
                      ),
                    ],
                  ),
        actions: [
          HyperButton.outlined(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            label: const Text('取消'),
          ),
          HyperButton.filled(
            loading: _saving,
            onPressed: (_saving || _loading || _loadError != null) ? null : _submit,
            label: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _Readonly extends StatelessWidget {
  const _Readonly({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Field(
      label: label,
      child: Container(
        height: 34,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _kReadonly,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: _kTitle),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Text.rich(
              TextSpan(
                children: [
                  if (required)
                    const TextSpan(
                      text: '* ',
                      style: TextStyle(color: _kDanger, fontSize: 13),
                    ),
                  TextSpan(text: label),
                ],
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
