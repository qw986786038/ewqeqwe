import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee.dart';
import '../../../../models/hrm_employee_assign.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../services/hrm_api.dart';
import '../employee_archive_controller.dart';
import 'employee_level_dialog.dart';
import 'employee_transfer_post_dialog.dart';

const _kGreen = Color(0xFF22C55E);
const _kGreenBg = Color(0xFFF0FDF4);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kCard = Color(0xFFF7F8FA);

void showEmployeeTransferDialog(BuildContext context, HrmEmployeeProfile row) {
  final archive = context.lx.find<EmployeeArchiveController>();
  showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => LxScope(
      bindings: (container) {
        container.putInstance<EmployeeArchiveController>(archive, owned: false);
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
        child: _TransferDialog(row: row),
      ),
    ),
  );
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.row});

  final HrmEmployeeProfile row;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _api = HrmApi();
  late HrmEmployeeProfile _profile;
  var _loading = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.row;
    _reload();
  }

  List<HrmEmployeeTitle> get _titles {
    final list = [..._profile.titleList];
    list.sort((a, b) {
      final ap = a.isPrimary == 1 ? 0 : 1;
      final bp = b.isPrimary == 1 ? 0 : 1;
      return ap.compareTo(bp);
    });
    return list;
  }

  Future<void> _reload() async {
    final previous = _profile;
    final id = previous.id?.trim() ?? '';
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        id.isEmpty
            ? Future<HrmEmployeeProfile>.value(previous)
            : _api.fetchEmployeeById(id),
        _api.fetchOnDutyAssigns(),
        _api.fetchPositions(),
        _api.fetchPosts(),
        _api.fetchPostSeqLevels(),
        _api.fetchDepts(),
      ]);
      if (!mounted) return;
      final fresh = results[0] as HrmEmployeeProfile;
      final titles = _titlesFromAssigns(
        userId: fresh.userId ?? previous.userId,
        assigns: results[1] as List<HrmEmployeeAssign>,
        positions: results[2] as List<HrmPosition>,
        posts: results[3] as List<HrmPost>,
        levels: results[4] as List<HrmPostSeqLevel>,
        depts: results[5] as List<HrmDept>,
      );
      if (titles.isNotEmpty) {
        fresh.titleList = titles;
      } else if (fresh.titleList.isEmpty) {
        fresh.titleList = previous.titleList;
      }
      fresh.userId ??= previous.userId;
      if ((fresh.name == null || fresh.name!.trim().isEmpty) &&
          previous.name != null) {
        fresh.name = previous.name;
      }
      setState(() => _profile = fresh);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context: context, title: e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeLevel(HrmEmployeeTitle title) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await showEmployeeLevelDialog(
        context,
        employee: _profile,
        initial: title,
      );
      if (!ok || !mounted) return;
      await _refreshAfterChange();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transfer(HrmEmployeeTitle title) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await showEmployeeTransferPostDialog(
        context,
        profile: _profile,
        initial: title,
      );
      if (!ok || !mounted) return;
      await _refreshAfterChange();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshAfterChange() async {
    final archive = context.lx.find<EmployeeArchiveController>();
    await archive.refreshAll();
    if (!mounted) return;
    final id = _profile.id?.trim() ?? '';
    for (final row in archive.rows) {
      if (row.id?.trim() == id && row.titleList.isNotEmpty) {
        _profile = row;
        break;
      }
    }
    await _reload();
  }

  void _close() {
    final archive = context.lx.find<EmployeeArchiveController>();
    Navigator.of(context).pop();
    archive.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile.name?.trim();
    final title = (name == null || name.isEmpty) ? '发起调动' : '发起调动 - $name';
    final titles = _titles;
    return HyperDialog(
      title: Text(title),
      scrollable: true,
      style: const HyperDialogStyle(maxWidth: 520),
      onClose: _close,
      content: titles.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '暂无在任任职',
                        style: TextStyle(fontSize: 13, color: _kMuted),
                      ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < titles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _AssignCard(
                    title: titles[i],
                    onLevel: _busy ? null : () => _changeLevel(titles[i]),
                    onTransfer: _busy ? null : () => _transfer(titles[i]),
                  ),
                ],
              ],
            ),
      actions: [
        if (_loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        HyperButton.outlined(
          onPressed: _close,
          label: const Text('关闭'),
        ),
      ],
    );
  }
}

List<HrmEmployeeTitle> _titlesFromAssigns({
  required int? userId,
  required List<HrmEmployeeAssign> assigns,
  required List<HrmPosition> positions,
  required List<HrmPost> posts,
  required List<HrmPostSeqLevel> levels,
  required List<HrmDept> depts,
}) {
  if (userId == null) return const [];
  final positionById = <String, HrmPosition>{
    for (final p in positions)
      if (p.id?.trim().isNotEmpty == true) p.id!.trim(): p,
  };
  final postNameById = <String, String>{
    for (final p in posts)
      if (p.id?.trim().isNotEmpty == true && p.name?.trim().isNotEmpty == true)
        p.id!.trim(): p.name!.trim(),
  };
  final deptNameById = <String, String>{
    for (final d in depts)
      if (d.deptId?.trim().isNotEmpty == true &&
          d.deptName?.trim().isNotEmpty == true)
        d.deptId!.trim(): d.deptName!.trim(),
  };
  final levelCodeById = <String, String>{
    for (final l in levels)
      if (l.id?.trim().isNotEmpty == true && l.code?.trim().isNotEmpty == true)
        l.id!.trim(): l.code!.trim(),
  };
  return [
    for (final a in assigns)
      if (a.employeeUserId == userId && a.positionId?.trim().isNotEmpty == true)
        () {
          final pos = positionById[a.positionId!.trim()];
          final deptId = pos?.sysDeptId?.trim();
          final postId = pos?.postId?.trim();
          final dept = pos?.deptName?.trim();
          final post = pos?.postName?.trim();
          return HrmEmployeeTitle()
            ..id = a.id
            ..positionId = a.positionId
            ..postSeqLevelId = a.postSeqLevelId
            ..isPrimary = a.isPrimary
            ..startDate = a.startDate
            ..sysDeptId = deptId
            ..deptName = (dept != null && dept.isNotEmpty)
                ? dept
                : (deptId == null ? null : deptNameById[deptId])
            ..postId = postId
            ..postName = (post != null && post.isNotEmpty)
                ? post
                : (postId == null ? null : postNameById[postId])
            ..postSeqLeveName = levelCodeById[a.postSeqLevelId?.trim() ?? ''];
        }(),
  ];
}

class _AssignCard extends StatelessWidget {
  const _AssignCard({
    required this.title,
    required this.onLevel,
    required this.onTransfer,
  });

  final HrmEmployeeTitle title;
  final VoidCallback? onLevel;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    final dept = title.deptName?.trim();
    final post = title.postName?.trim();
    final level = title.postSeqLeveName?.trim();
    final role = [
      if (post != null && post.isNotEmpty) post,
      if (level != null && level.isNotEmpty) level,
    ].join(' / ');
    final start = title.startDate?.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (dept == null || dept.isEmpty) ? '-' : dept,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
              ),
              if (title.isPrimary == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '主岗',
                    style: TextStyle(fontSize: 12, color: _kGreen),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role.isEmpty ? '-' : role,
            style: const TextStyle(fontSize: 13, color: _kMuted),
          ),
          const SizedBox(height: 4),
          Text(
            (start == null || start.isEmpty) ? '任职时间：-' : '任职时间：$start 起',
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Action(label: '调级', onPressed: onLevel),
              const SizedBox(width: 16),
              _Action(label: '调岗', onPressed: onTransfer),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: onPressed == null ? _kMuted : _kGreen,
          ),
        ),
      ),
    );
  }
}
