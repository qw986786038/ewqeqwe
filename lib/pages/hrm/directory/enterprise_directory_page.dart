import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee.dart';
import '../../location_breadcrumb.dart';
import 'enterprise_directory_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF86909C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);
const _kDanger = Color(0xFFFF4D4F);
const _kSelectedBg = Color(0xFFE8F3FF);
const _kSuccess = Color(0xFF00B42A);
const _kSuccessBg = Color(0xFFE8FFEA);
const _kSuccessBorder = Color(0xFFB7EB8F);
const _kSideW = 260.0;
const _kCardShadow = Color(0x0A000000);

/// HRM · 企业通讯录（左部门树 + 右人员卡片）。
class EnterpriseDirectoryPage extends StatelessWidget {
  const EnterpriseDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<EnterpriseDirectoryController>(
          EnterpriseDirectoryController.new,
        );
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EnterpriseDirectoryController>();
    return ColoredBox(
      color: _kPageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: LocationBreadcrumb(segments: ['HRM', '企业通讯录']),
          ),
          Expanded(
            child: Obx(() {
        if (c.loading.value && c.roots.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final err = c.errorMessage.value;
        if (err != null && c.roots.isEmpty && c.employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: _kDanger)),
                const SizedBox(height: 12),
                AppButton.outline(
                  onPressed: c.load,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _kSideW, child: _DeptPanel()),
            VerticalDivider(width: 1, color: _kBorder),
            Expanded(child: _PeoplePanel()),
          ],
        );
      }),
          ),
        ],
      ),
    );
  }
}

class _DeptPanel extends StatelessWidget {
  const _DeptPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EnterpriseDirectoryController>();
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              '部门',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kTitle,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              c.expandedIds.length;
              c.selectedDeptId.value;
              c.roots.length;
              c.allCount.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  _AllColleaguesRow(
                    count: c.allCount.value,
                    selected: c.selectedDeptId.value == null,
                    onTap: c.selectAll,
                  ),
                  const SizedBox(height: 4),
                  for (final root in c.roots)
                    _DeptTreeItem(node: root, depth: 0),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AllColleaguesRow extends StatelessWidget {
  const _AllColleaguesRow({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kSelectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '全部同事',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _kPrimary : _kTitle,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: selected ? _kPrimary : _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeptTreeItem extends StatelessWidget {
  const _DeptTreeItem({required this.node, required this.depth});

  final DirectoryDeptNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EnterpriseDirectoryController>();
    final id = node.id ?? '';
    final hasChildren = node.children.isNotEmpty;
    final expanded = c.expandedIds.contains(id);
    final selected = c.selectedDeptId.value == id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInkWell(
          onPressed: () {
            if (id.isNotEmpty) c.selectDept(id);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: EdgeInsets.only(
              left: 8.0 + depth * 14,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: selected ? _kSelectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: hasChildren
                      ? AppInkWell(
                          onPressed: () {
                            if (id.isNotEmpty) c.toggleExpand(id);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Icon(
                            expanded
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            size: 16,
                            color: _kMuted,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? _kPrimary : _kTitle,
                    ),
                  ),
                ),
                Text(
                  '${node.onDuty}',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? _kPrimary : _kMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && expanded)
          for (final child in node.children)
            _DeptTreeItem(node: child, depth: depth + 1),
      ],
    );
  }
}

class _PeoplePanel extends StatelessWidget {
  const _PeoplePanel();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EnterpriseDirectoryController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Obx(() {
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: c.headerTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kTitle,
                        ),
                      ),
                      TextSpan(
                        text: '  ${c.headerCount} 人',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 34,
                child: TextField(
                  controller: c.searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  onChanged: c.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: '搜索姓名、职务',
                    hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: _kMuted,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _kBorder),
        Expanded(
          child: Obx(() {
            if (c.empLoading.value) {
              return const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              );
            }
            final list = c.filteredEmployees;
            if (list.isEmpty) {
              return const Center(
                child: Text(
                  '暂无同事',
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final cross = w >= 1200
                    ? 3
                    : w >= 800
                        ? 2
                        : 1;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 210,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _EmployeeCard(employee: list[i]),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});

  final HrmEmployee employee;

  @override
  Widget build(BuildContext context) {
    final name = employee.name?.trim().isNotEmpty == true
        ? employee.name!.trim()
        : '未命名';
    final en = employee.englishName?.trim() ?? '';
    final avatar = name.characters.first;
    final status = EnterpriseDirectoryController.statusLabel(
      employee.empStatus,
    );
    final active = EnterpriseDirectoryController.statusActive(
      employee.empStatus,
    );
    final title = EnterpriseDirectoryController.titleLine(employee);
    final mobile = EnterpriseDirectoryController.formatMobile(employee.mobile);
    final email = employee.corpEmail?.trim().isNotEmpty == true
        ? employee.corpEmail!.trim()
        : '未公开';
    final im = EnterpriseDirectoryController.formatIm(employee);
    final avatarBg = EnterpriseDirectoryController.avatarColor(employee);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  avatar,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kTitle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? _kSuccessBg
                                : const Color(0xFFF2F3F5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: active ? _kSuccessBorder : _kBorder,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: active ? _kSuccess : _kMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (en.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        en,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ContactLine(icon: Icons.phone_outlined, text: mobile),
          const SizedBox(height: 4),
          _ContactLine(icon: Icons.mail_outline, text: email),
          const SizedBox(height: 4),
          _ContactLine(icon: Icons.chat_bubble_outline, text: im),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.phone_outlined,
                  label: '拨打',
                  onPressed: () {
                    EnterpriseDirectoryController.callMobile(
                      context,
                      employee.mobile,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.mail_outline,
                  label: '邮件',
                  onPressed: () {
                    EnterpriseDirectoryController.sendEmail(
                      context,
                      employee.corpEmail,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: 'IM',
                  onPressed: () {
                    AppToast.show(context: context, title: 'IM 待接入');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _kLabel),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder),
          color: const Color(0xFFFAFBFC),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: _kPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _kTitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
