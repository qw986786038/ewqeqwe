import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_dept.dart';
import '../org_structure_controller.dart';

const _kPrimary = Color(0xFF1677FF);

const _statusOptions = [
  AppOption(value: '0', label: '正常'),
  AppOption(value: '1', label: '停用'),
];

/// 在 [parent] 下新增子部门。上级可在弹窗里改选。
Future<void> showDeptAddDialog(
  BuildContext context, {
  required HrmDept parent,
}) {
  final parentId = parent.deptId?.trim() ?? '';
  if (parentId.isEmpty) {
    AppToast.show(context: context, title: '父部门无效');
    return Future.value();
  }
  return _showDeptFormDialog(
    context,
    title: '新增部门',
    parentId: parentId,
    initialName: '',
    initialOrderNum: 0,
    initialStatus: '0',
    editingId: null,
  );
}

/// 修改当前部门。
Future<void> showDeptEditDialog(BuildContext context, HrmDept dept) {
  final id = dept.deptId?.trim() ?? '';
  if (id.isEmpty) {
    AppToast.show(context: context, title: '部门 id 无效');
    return Future.value();
  }
  final status = dept.status?.trim();
  return _showDeptFormDialog(
    context,
    title: '修改部门',
    parentId: dept.parentId?.trim() ?? '',
    initialName: dept.deptName?.trim() ?? '',
    initialOrderNum: dept.orderNum ?? 0,
    initialStatus: status == '1' ? '1' : '0',
    editingId: id,
  );
}

Future<void> confirmDeleteDept(BuildContext context, HrmDept dept) async {
  final id = dept.deptId?.trim();
  if (id == null || id.isEmpty) {
    AppToast.show(context: context, title: '部门 id 无效');
    return;
  }
  final name = dept.deptName?.trim().isNotEmpty == true
      ? dept.deptName!.trim()
      : '未命名部门';
  final hostContext = context;
  final c = context.lx.find<OrgStructureController>();
  final ok = await showHyperDialog<bool>(
    context: context,
    builder: (dialogContext) => HyperDialog(
      title: const Text('确认删除'),
      content: Text('确定删除部门「$name」吗？'),
      actions: [
        HyperButton.outlined(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          label: const Text('取消'),
        ),
        HyperButton.filled(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          label: const Text('删除'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await c.deleteDept(id);
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: '删除部门成功');
    }
  } catch (e) {
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: e.toString());
    }
  }
}

List<AppOption<String>> _parentOptions(
  OrgStructureController c, {
  String? excludeId,
}) {
  final blocked = <String>{};
  void block(OrgDeptNode node) {
    final id = node.id;
    if (id != null && id.isNotEmpty) blocked.add(id);
    for (final child in node.children) {
      block(child);
    }
  }

  final self = excludeId?.trim() ?? '';
  if (self.isNotEmpty) {
    final node = c.findNode(self);
    if (node != null) block(node);
  }
  return [
    for (final dept in c.flatDepts)
      if ((dept.deptId?.trim() ?? '').isNotEmpty &&
          !blocked.contains(dept.deptId!.trim()))
        AppOption(
          value: dept.deptId!.trim(),
          label: dept.deptName?.trim().isNotEmpty == true
              ? dept.deptName!.trim()
              : '未命名部门',
        ),
  ];
}

Future<void> _showDeptFormDialog(
  BuildContext context, {
  required String title,
  required String parentId,
  required String initialName,
  required int initialOrderNum,
  required String initialStatus,
  required String? editingId,
}) {
  final hostContext = context;
  final c = context.lx.find<OrgStructureController>();
  final isEdit = editingId != null;
  final parents = _parentOptions(c, excludeId: editingId);
  final initialParent =
      parents.any((option) => option.value == parentId) ? parentId : null;
  return showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _DeptFormDialog(
          title: title,
          parentOptions: parents,
          initialParentId: initialParent,
          fallbackParentId: parentId,
          initialName: initialName,
          initialOrderNum: initialOrderNum,
          initialStatus: initialStatus,
          onClose: () => Navigator.of(dialogContext).pop(),
          onSubmit: (payload) async {
            if (isEdit) {
              await c.updateDept(
                deptId: editingId,
                parentId: payload.parentId,
                deptName: payload.name,
                orderNum: payload.orderNum,
                status: payload.status,
              );
              if (hostContext.mounted) {
                AppToast.show(context: hostContext, title: '修改部门成功');
              }
            } else {
              await c.createDept(
                parentId: payload.parentId,
                deptName: payload.name,
                orderNum: payload.orderNum,
                status: payload.status,
              );
              if (hostContext.mounted) {
                AppToast.show(context: hostContext, title: '新增部门成功');
              }
            }
          },
        ),
    ),
  );
}

class _DeptFormPayload {
  const _DeptFormPayload({
    required this.parentId,
    required this.name,
    required this.orderNum,
    required this.status,
  });

  final String parentId;
  final String name;
  final int orderNum;
  final String status;
}

class _DeptFormDialog extends StatefulWidget {
  const _DeptFormDialog({
    required this.title,
    required this.parentOptions,
    required this.initialParentId,
    required this.fallbackParentId,
    required this.initialName,
    required this.initialOrderNum,
    required this.initialStatus,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final List<AppOption<String>> parentOptions;
  final String? initialParentId;
  final String fallbackParentId;
  final String initialName;
  final int initialOrderNum;
  final String initialStatus;
  final VoidCallback onClose;
  final Future<void> Function(_DeptFormPayload payload) onSubmit;

  @override
  State<_DeptFormDialog> createState() => _DeptFormDialogState();
}

class _DeptFormDialogState extends State<_DeptFormDialog> {
  final _form = AppFormController();
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final name = (values['deptName'] as String?)?.trim() ?? '';
      final parent = (values['parentId'] as String?)?.trim();
      final parentId = (parent == null || parent.isEmpty)
          ? widget.fallbackParentId
          : parent;
      final orderRaw = values['orderNum'];
      final orderNum = orderRaw is int
          ? orderRaw
          : int.tryParse('$orderRaw') ?? widget.initialOrderNum;
      final status = (values['status'] as String?)?.trim();
      if (name.isEmpty || parentId.isEmpty) return;

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _DeptFormPayload(
            parentId: parentId,
            name: name,
            orderNum: orderNum,
            status: (status == null || status.isEmpty) ? '0' : status,
          ),
        );
        if (mounted) widget.onClose();
      } catch (e) {
        if (mounted) {
          AppToast.show(context: context, title: e.toString());
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: Text(widget.title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 520),
        onClose: _saving ? null : widget.onClose,
        content: AppFieldScope.horizontal(
          labelWidth: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              AppSelectFormField<String>(
                name: 'parentId',
                label: '上级部门',
                hintText: '请选择上级部门',
                options: widget.parentOptions,
                initialValue: widget.initialParentId,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) &&
                        widget.fallbackParentId.isEmpty
                    ? '请选择上级部门'
                    : null,
              ),
              AppTextFormField(
                name: 'deptName',
                label: '部门名称',
                required: true,
                hintText: '请输入部门名称',
                maxLength: 30,
                initialValue:
                    widget.initialName.isEmpty ? null : widget.initialName,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '请输入部门名称';
                  if (s.length > 30) return '不能超过 30 字';
                  return null;
                },
              ),
              AppNumberInputFormField(
                name: 'orderNum',
                label: '显示排序',
                required: true,
                min: 0,
                max: 99999,
                initialValue: widget.initialOrderNum,
              ),
              AppRadioGroupFormField<String>(
                name: 'status',
                label: '部门状态',
                valueDirection: Axis.horizontal,
                spacing: 28,
                initialValue: widget.initialStatus,
                options: _statusOptions,
              ),
            ],
          ),
        ),
        actions: [
          HyperButton.filled(
            loading: _saving,
            onPressed: _saving
                ? null
                : () async {
                    await _submit();
                  },
            label: Text(_saving ? '提交中…' : '确定'),
          ),
          HyperButton.outlined(
            onPressed: _saving ? null : widget.onClose,
            label: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
