import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../edit/employee_edit_controller.dart';
import '../edit/employee_edit_page.dart';
import 'employee_detail_controller.dart';
import 'tabs/employee_assign_tab.dart';
import 'tabs/employee_attachment_tab.dart';
import 'tabs/employee_basic_tab.dart';
import 'tabs/employee_contract_tab.dart';
import 'tabs/employee_directory_tab.dart';
import 'tabs/employee_onboarding_tab.dart';
import 'tabs/employee_oplog_tab.dart';
import 'tabs/employee_overview_tab.dart';
import 'tabs/employee_promotion_tab.dart';
import 'tabs/employee_salary_tab.dart';
import 'tabs/employee_sales_tab.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF4E5969);
const _kSuccess = Color(0xFF52C41A);
const _kDanger = Color(0xFFFF4D4F);

/// 人事档案详情（只读）。可从列表或组织架构进入。
class EmployeeDetailPage extends StatelessWidget {
  const EmployeeDetailPage({
    super.key,
    required this.userId,
    this.onBack,
  });

  final int userId;

  /// 非空时走壳内返回；为空则 `Navigator.pop`（组织架构 push 场景）。
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final body = LxScope(
      bindings: (container) {
        container.put<EmployeeDetailController>(
          () => EmployeeDetailController(userId),
        );
      },
      child: _Body(onBack: onBack),
    );
    // 人事档案列表内嵌：已在 HomePage 的 AppShadcnScope / 内容区约束下。
    if (onBack != null) return body;
    // 组织架构等 push：新路由不在壳层 Scope 下，需自带主题与全屏约束，
    // 否则 Header 的 Row + Spacer 会在无界宽下撑出极大横向 overflow。
    return AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: Scaffold(
        backgroundColor: _kPageBg,
        body: body,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return ColoredBox(
      color: _kPageBg,
      child: Obx(() {
        if (c.loading.value && c.profile.value == null) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final err = c.errorMessage.value;
        if (err != null && c.profile.value == null) {
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: onBack),
            const _TabBar(),
            Expanded(
              child: Obx(() {
                return switch (c.tab.value) {
                  EmployeeDetailTab.overview => const EmployeeOverviewTab(),
                  EmployeeDetailTab.basic => const EmployeeBasicTab(),
                  EmployeeDetailTab.assign => const EmployeeAssignTab(),
                  EmployeeDetailTab.contract => const EmployeeContractTab(),
                  EmployeeDetailTab.salary => const EmployeeSalaryTab(),
                  EmployeeDetailTab.onboarding =>
                    const EmployeeOnboardingTab(),
                  EmployeeDetailTab.promotion =>
                    const EmployeePromotionTab(),
                  EmployeeDetailTab.sales => const EmployeeSalesTab(),
                  EmployeeDetailTab.directory => const EmployeeDirectoryTab(),
                  EmployeeDetailTab.attachment =>
                    const EmployeeAttachmentTab(),
                  EmployeeDetailTab.oplog => const EmployeeOplogTab(),
                };
              }),
            ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onBack});

  final VoidCallback? onBack;

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _openEdit(BuildContext context) {
    final detail = context.lx.find<EmployeeDetailController>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => LxScope(
          bindings: (container) {
            container.put<EmployeeEditController>(
              () => EmployeeEditController(userId: detail.userId),
            );
          },
          // push 路由不在 HomePage Scope 下，需自带主题与全屏约束。
          child: AppShadcnScope(
            config: AppThemeConfig.standard(primary: _kPrimary),
            child: Scaffold(
              backgroundColor: _kPageBg,
              body: EmployeeEditPage(
                onBack: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return Obx(() {
      final p = c.profile.value;
      final name = p?.name?.trim().isNotEmpty == true
          ? p!.name!.trim()
          : '未命名';
      final en = p?.englishName?.trim() ?? '';
      final avatar = name.isNotEmpty ? name.characters.first : '?';
      final age = c.ageYears();
      final assign = c.primaryAssign;
      final loc = c.officeLocationLabel();
      final tags = <String>[
        if (p?.empType != null)
          EmployeeDetailController.typeLabel(p!.empType),
        if (p?.nation?.trim().isNotEmpty == true) p!.nation!.trim(),
        if (age != null) '$age岁',
      ];

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppInkWell(
                  onPressed: () => _back(context),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 18, color: _kLabel),
                        SizedBox(width: 4),
                        Text(
                          '返回',
                          style: TextStyle(fontSize: 13, color: _kLabel),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                AppButton.primary(
                  onPressed: () => _openEdit(context),
                  child: const Text('编辑档案'),
                ),
                const SizedBox(width: 8),
                AppButton.outline(
                  onPressed: () {
                    AppToast.show(context: context, title: '导出待接入');
                  },
                  child: const Text('导出'),
                ),
                const SizedBox(width: 8),
                AppButton.outline(
                  onPressed: () {
                    AppToast.show(context: context, title: '发到邮箱待接入');
                  },
                  child: const Text('发到邮箱'),
                ),
                const SizedBox(width: 8),
                AppButton.outline(
                  onPressed: () {
                    AppToast.show(context: context, title: '办理离职待接入');
                  },
                  child: const Text(
                    '办理离职',
                    style: TextStyle(color: _kDanger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            en.isEmpty ? name : '$name  $en',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _kTitle,
                            ),
                          ),
                          _Tag(
                            text: EmployeeDetailController.statusLabel(
                              p?.empStatus,
                            ),
                            fg: _kSuccess,
                            bg: const Color(0xFFF6FFED),
                            border: const Color(0xFFB7EB8F),
                          ),
                          if (p?.empType != null)
                            _Tag(
                              text: EmployeeDetailController.typeLabel(
                                p!.empType,
                              ),
                              fg: _kPrimary,
                              bg: const Color(0xFFE6F4FF),
                              border: const Color(0xFF91CAFF),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          '工号 ${EmployeeDetailController.dash(p?.no)}',
                          ?loc,
                          if (assign != null)
                            EmployeeDetailController.dash(
                              c.assignPostName(assign),
                            ),
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 28,
              runSpacing: 10,
              children: [
                _meta(
                  '汇报对象',
                  assign == null
                      ? '—'
                      : EmployeeDetailController.dash(
                          c.assignReportName(assign),
                        ),
                ),
                _meta(
                  '入职日期',
                  assign?.startDate?.trim().isNotEmpty == true
                      ? assign!.startDate!.trim()
                      : '2019-03-11',
                ),
                _meta('司龄', '6 年 7 个月'),
                _meta(
                  '办公地点',
                  loc?.trim().isNotEmpty == true ? loc! : '济南',
                ),
                _meta(
                  '手机号',
                  p?.mobile?.trim().isNotEmpty == true
                      ? p!.mobile!.trim()
                      : '138 1000 0297',
                  hint: '公开',
                ),
                _meta(
                  '邮箱',
                  p?.corpEmail?.trim().isNotEmpty == true
                      ? p!.corpEmail!.trim()
                      : 'dufu@adhr.cn',
                  hint: '公开',
                ),
                _meta(
                  '企业 IM',
                  p?.imAccount?.trim().isNotEmpty == true
                      ? '已绑定（${p!.imAccount!.trim()}）'
                      : '已绑定',
                ),
                _meta('招聘负责人', '罗叶'),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final t in tags)
                    if (t != '—')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(fontSize: 12, color: _kLabel),
                        ),
                      ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _meta(String k, String v, {String? hint}) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _kTitle),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 4),
                Text(
                  hint,
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.fg,
    required this.bg,
    required this.border,
  });

  final String text;
  final Color fg;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, color: _kBorder),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(() {
              final cur = c.tab.value;
              return Row(
                children: [
                  for (final t in EmployeeDetailTab.values)
                    AppInkWell(
                      onPressed: () => c.selectTab(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: cur == t ? _kPrimary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                cur == t ? FontWeight.w600 : FontWeight.w400,
                            color: cur == t ? _kPrimary : _kLabel,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          const Divider(height: 1, color: _kBorder),
        ],
      ),
    );
  }
}
