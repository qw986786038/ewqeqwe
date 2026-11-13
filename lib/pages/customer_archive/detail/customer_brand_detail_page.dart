import 'dart:io' show Platform, Process;

import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../brand_detail/dialogs/agency_overview_dialog.dart';
import '../dialogs/quick_create_brand_dialog.dart';
import 'customer_brand_detail_controller.dart';
import 'dialogs/contact_overview_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kGold = Color(0xFFFAAD14);

/// 客户档案 · 品牌详情（主品牌点击进入）。
class CustomerBrandDetailPage extends StatelessWidget {
  const CustomerBrandDetailPage({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<CustomerBrandDetailController>(
          () => CustomerBrandDetailController(customerId: customerId),
        );
      },
      // 与订单品牌详情一致：弹窗 / App* 需要 shadcn Theme。
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  CustomerBrandDetailController _c(BuildContext context) =>
      context.lx.find<CustomerBrandDetailController>();

  Future<void> _edit(BuildContext context) async {
    final c = _c(context);
    await showEditCustomerArchiveDialog(
      context,
      customerId: c.customerId,
      onSaved: c.load,
    );
  }

  void _openEntity(BuildContext context, Map<String, dynamic> ent) {
    final c = _c(context);
    final name = _str(ent['fullName']);
    if (name.isEmpty) {
      AppToast.show(context: context, title: '缺少主体全称，无法打开详情');
      return;
    }
    // 详情页内点击主体 → 弹窗（列表仍跳转主体详情页）。
    showAgencyOverviewDialog(
      context,
      customerId: c.customerId,
      enterpriseName: name,
    );
  }

  void _openContact(BuildContext context, Map<String, dynamic> contact) {
    final id = contact['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      AppToast.show(context: context, title: '缺少联系人 ID，无法打开详情');
      return;
    }
    // 详情页内点击联系人 → 弹窗。
    showContactOverviewDialog(context, contactId: id);
  }

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Obx(() {
      if (c.loading.value && c.raw.value == null) {
        return const Scaffold(
          backgroundColor: _kPageBg,
          body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final err = c.errorMessage.value;
      if (err != null && c.raw.value == null) {
        return Scaffold(
          backgroundColor: _kPageBg,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: Color(0xFFFF4D4F))),
                const SizedBox(height: 12),
                AppButton.primary(onPressed: c.load, child: const Text('重试')),
              ],
            ),
          ),
        );
      }
      final name = c.brandName;
      return Scaffold(
        backgroundColor: _kPageBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _kTitle,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: const Border(bottom: BorderSide(color: _kBorder)),
          leadingWidth: 108,
          leading: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18, color: _kTitle),
            label: const Text(
              '返回列表',
              style: TextStyle(fontSize: 13, color: _kTitle),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          titleSpacing: 0,
          title: Text(
            '客户档案管理 / $name',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4E5969),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _BasicInfoCard(
              controller: c,
              onEdit: () => _edit(context),
            ),
            const SizedBox(height: 12),
            _EnterprisesCard(
              controller: c,
              onOpenEntity: (e) => _openEntity(context, e),
              onOpenContact: (ct) => _openContact(context, ct),
              onEdit: () => _edit(context),
            ),
            const SizedBox(height: 12),
            _ContactsCard(
              controller: c,
              onOpenContact: (ct) => _openContact(context, ct),
              onEdit: () => _edit(context),
            ),
          ],
        ),
      );
    });
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({
    required this.controller,
    required this.onEdit,
  });

  final CustomerBrandDetailController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final letter = c.brandName.isEmpty
        ? '?'
        : String.fromCharCodes(c.brandName.runes.take(1));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                '基础信息',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppButton.primary(
                onPressed: onEdit,
                leading: const Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                child: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E5969),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      c.brandName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoGrid(
                      rows: [
                        [
                          _InfoCell(label: '品牌简称', value: c.brandName),
                          _InfoCell(
                            label: '权重',
                            child: _Stars(weight: c.weight),
                          ),
                          _InfoCell(label: '创建时间', value: c.createTime),
                        ],
                        [
                          _InfoCell(
                            label: '类型',
                            child: Text(
                              c.customerTypeLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _InfoCell(label: '关联子品牌', value: c.subBrandsText),
                          _InfoCell(label: '所属行业', value: c.industryLabel),
                          _InfoCell(label: '品牌性质', value: c.brandNatureLabel),
                        ],
                        [
                          _InfoCell(label: '营收规模/年', value: c.revenueLabel),
                          _InfoCell(label: '营销费规模/年', value: c.marketingLabel),
                          _InfoCell(label: '服务 4A 公司', value: c.serviceAgencyName),
                          _InfoCell(label: '代言人', value: c.spokesperson),
                        ],
                        [
                          _InfoCell(
                            label: '官网',
                            child: _LinkOrText(text: c.website),
                          ),
                          _InfoCell(label: '微信公众号', value: c.wechatAccount),
                          _InfoCell(label: '视频号', value: c.videoAccount),
                          _InfoCell(label: '抖音号', value: c.douyinAccount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.weight});

  final int weight;

  @override
  Widget build(BuildContext context) {
    final n = weight.clamp(0, 5);
    if (n <= 0) {
      return const Text('-', style: TextStyle(fontSize: 13, color: _kTitle));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          const Icon(Icons.star, size: 16, color: _kGold),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.rows});

  final List<List<_InfoCell>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        // 窄屏两列，宽屏四列；避免 Row+Expanded 在异常约束下撑爆。
        final cols = maxW >= 900 ? 4 : (maxW >= 560 ? 2 : 1);
        final gap = 12.0;
        final cellW = cols == 1
            ? maxW
            : (maxW - gap * (cols - 1)) / cols;
        final flat = [for (final row in rows) ...row];
        return Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (final cell in flat)
              SizedBox(width: cellW, child: cell),
          ],
        );
      },
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    this.value,
    this.child,
  });

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 4),
        child ??
            Text(
              value ?? '-',
              style: const TextStyle(fontSize: 13, color: _kTitle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }
}

class _LinkOrText extends StatelessWidget {
  const _LinkOrText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text == '-' || text.isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 13, color: _kTitle));
    }
    final uri = Uri.tryParse(text);
    final canOpen = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!canOpen) {
      return Text(
        text,
        style: const TextStyle(fontSize: 13, color: _kTitle),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return AppInkWell(
      onPressed: () async {
        try {
          if (Platform.isWindows) {
            await Process.start('cmd', ['/c', 'start', '', text]);
          } else if (Platform.isMacOS) {
            await Process.start('open', [text]);
          } else if (Platform.isLinux) {
            await Process.start('xdg-open', [text]);
          }
        } catch (_) {}
      },
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: _kPrimary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EnterprisesCard extends StatelessWidget {
  const _EnterprisesCard({
    required this.controller,
    required this.onOpenEntity,
    required this.onOpenContact,
    required this.onEdit,
  });

  final CustomerBrandDetailController controller;
  final ValueChanged<Map<String, dynamic>> onOpenEntity;
  final ValueChanged<Map<String, dynamic>> onOpenContact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final rows = c.enterprises;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                '关联主体明细',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppButton.outline(
                onPressed: () {
                  AppToast.show(context: context, title: '列设置待接入');
                },
                leading: const Icon(Icons.view_column_outlined, size: 16),
                child: const Text('列设置'),
              ),
              const SizedBox(width: 8),
              AppButton.outline(
                onPressed: onEdit,
                leading: const Icon(Icons.add, size: 16),
                child: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text('暂无关联主体', style: TextStyle(color: _kMuted)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final gridH = (rows.length * 52.0 + 44).clamp(120.0, 320.0);
                return SizedBox(
                  width: constraints.maxWidth,
                  height: gridH,
                  child: AppDataGrid<Map<String, dynamic>>.local(
              height: gridH,
              rows: rows,
              rowKey: (row) => '${row['id'] ?? row['fullName'] ?? rows.indexOf(row)}',
              sortable: false,
              showInternalDividers: true,
              headerBackgroundColor: const Color(0xFFFAFAFA),
              textStyle: const TextStyle(fontSize: 12),
              cellTextStyle: const TextStyle(fontSize: 12),
              columns: [
                AppDataGridColumn(
                  id: 'no',
                  title: '序号',
                  width: 56,
                  value: (row) => rows.indexOf(row) + 1,
                  type: AppDataGridColumnType.number,
                ),
                AppDataGridColumn(
                  id: 'icon',
                  title: '图标',
                  width: 56,
                  value: (row) => _str(row['fullName']),
                  cellBuilder: (context, row, _) {
                    final name = _str(row['fullName']);
                    final letter = name.isEmpty
                        ? '?'
                        : String.fromCharCodes(name.runes.take(1));
                    return Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E5969),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AppDataGridColumn(
                  id: 'name',
                  title: '主体名称',
                  width: 220,
                  alignment: Alignment.centerLeft,
                  titleAlignment: Alignment.centerLeft,
                  value: (row) => _str(row['fullName']),
                  cellBuilder: (context, row, _) {
                    final name = _str(row['fullName']);
                    if (name.isEmpty) return const Text('-');
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AppInkWell(
                        onPressed: () => onOpenEntity(row),
                        child: Text(
                          name,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AppDataGridColumn(
                  id: 'shortName',
                  title: '企业简称',
                  width: 120,
                  value: (row) => _dash(
                    _str(row['shortName'] ?? row['aliasName'] ?? row['enterpriseShort']),
                  ),
                ),
                AppDataGridColumn(
                  id: 'relation',
                  title: '关联关系',
                  width: 120,
                  value: (row) => c.relationLabel(row['relationType']),
                ),
                AppDataGridColumn(
                  id: 'nature',
                  title: '企业性质',
                  width: 96,
                  value: (row) => c.entityNatureLabel(row['entityNature']),
                ),
                AppDataGridColumn(
                  id: 'city',
                  title: '所在城市',
                  width: 100,
                  value: (row) {
                    final city = _str(row['city']);
                    final prov = _str(row['province']);
                    if (city.isEmpty && prov.isEmpty) return '-';
                    return '$prov$city';
                  },
                ),
                AppDataGridColumn(
                  id: 'address',
                  title: '详细地址',
                  width: 180,
                  alignment: Alignment.centerLeft,
                  titleAlignment: Alignment.centerLeft,
                  value: (row) => _dash(_str(row['address'])),
                ),
                AppDataGridColumn(
                  id: 'contacts',
                  title: '联系人',
                  width: 140,
                  value: (row) {
                    final list = c.contactsOfEnterprise(_str(row['fullName']));
                    return list
                        .map((e) => _str(e['name']))
                        .where((e) => e.isNotEmpty)
                        .join('；');
                  },
                  cellBuilder: (context, row, _) {
                    final list = c.contactsOfEnterprise(_str(row['fullName']));
                    if (list.isEmpty) {
                      return const Text('-', style: TextStyle(fontSize: 12));
                    }
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final ct in list)
                            AppInkWell(
                              onPressed: () => onOpenContact(ct),
                              child: Tooltip(
                                message: _contactTooltip(ct),
                                child: Text(
                                  _str(ct['name']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                AppDataGridColumn(
                  id: 'owner',
                  title: '负责人',
                  width: 140,
                  value: (_) => c.ownerNamesText,
                  cellBuilder: (context, row, _) {
                    final text = c.ownerNamesText;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            softWrap: false,
                            style: const TextStyle(fontSize: 12, color: _kTitle),
                          ),
                          AppInkWell(
                            onPressed: onEdit,
                            child: const Text(
                              '+ 添加',
                              style: TextStyle(fontSize: 12, color: _kPrimary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                AppDataGridColumn(
                  id: 'actions',
                  title: '操作',
                  width: 100,
                  pin: AppDataGridColumnPin.end,
                  value: (_) => '',
                  cellBuilder: (context, row, _) => Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppInkWell(
                          onPressed: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '编辑',
                              style: TextStyle(fontSize: 12, color: _kPrimary),
                            ),
                          ),
                        ),
                        AppInkWell(
                          onPressed: () {
                            AppToast.show(context: context, title: '删除待接入');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '删除',
                              style: TextStyle(fontSize: 12, color: _kPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          const Text(
            '备注：鼠标放在人名上显示气泡，显示联系人信息',
            style: TextStyle(fontSize: 11, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({
    required this.controller,
    required this.onOpenContact,
    required this.onEdit,
  });

  final CustomerBrandDetailController controller;
  final ValueChanged<Map<String, dynamic>> onOpenContact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final rows = c.contacts;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                '联系人信息',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppButton.outline(
                onPressed: () {
                  AppToast.show(context: context, title: '列设置待接入');
                },
                leading: const Icon(Icons.view_column_outlined, size: 16),
                child: const Text('列设置'),
              ),
              const SizedBox(width: 8),
              AppButton.primary(
                onPressed: onEdit,
                leading: const Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                child: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text('暂无联系人', style: TextStyle(color: _kMuted)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final gridH = (rows.length * 52.0 + 44).clamp(120.0, 360.0);
                return SizedBox(
                  width: constraints.maxWidth,
                  height: gridH,
                  child: AppDataGrid<Map<String, dynamic>>.local(
              height: gridH,
              rows: rows,
              rowKey: (row) => '${row['id'] ?? row['name'] ?? rows.indexOf(row)}',
              sortable: false,
              showInternalDividers: true,
              headerBackgroundColor: const Color(0xFFFAFAFA),
              textStyle: const TextStyle(fontSize: 12),
              cellTextStyle: const TextStyle(fontSize: 12),
              columns: [
                AppDataGridColumn(
                  id: 'no',
                  title: '序号',
                  width: 56,
                  value: (row) => rows.indexOf(row) + 1,
                  type: AppDataGridColumnType.number,
                ),
                AppDataGridColumn(
                  id: 'icon',
                  title: '图标',
                  width: 56,
                  value: (row) => _str(row['name']),
                  cellBuilder: (context, row, _) {
                    final name = _str(row['name']);
                    final letter = name.isEmpty
                        ? '?'
                        : String.fromCharCodes(name.runes.take(1));
                    return Center(
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: _avatarColor(name),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AppDataGridColumn(
                  id: 'name',
                  title: '姓名',
                  width: 88,
                  value: (row) => _dash(_str(row['name'])),
                  cellBuilder: (context, row, _) {
                    final name = _str(row['name']);
                    if (name.isEmpty) return const Text('-');
                    return Center(
                      child: AppInkWell(
                        onPressed: () => onOpenContact(row),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AppDataGridColumn(
                  id: 'nameEn',
                  title: 'Name',
                  width: 100,
                  value: (row) => _dash(_str(row['nameEn'])),
                ),
                AppDataGridColumn(
                  id: 'gender',
                  title: '性别',
                  width: 56,
                  value: (row) => c.genderLabel(row['gender']),
                ),
                AppDataGridColumn(
                  id: 'ent',
                  title: '关联主体名称',
                  width: 180,
                  value: (row) => _dash(_str(row['relatedEnterprise'])),
                ),
                AppDataGridColumn(
                  id: 'relation',
                  title: '关联关系',
                  width: 100,
                  value: (row) => c.relationLabel(row['relationType']),
                ),
                AppDataGridColumn(
                  id: 'title',
                  title: '部门/职位',
                  width: 120,
                  value: (row) => _dash(_str(row['deptTitle'])),
                ),
                AppDataGridColumn(
                  id: 'job',
                  title: '职能描述',
                  width: 120,
                  value: (row) => _dash(_str(row['jobDesc'])),
                ),
                AppDataGridColumn(
                  id: 'scope',
                  title: '负责市场范围',
                  width: 120,
                  value: (row) => _dash(_str(row['marketScope'])),
                ),
                AppDataGridColumn(
                  id: 'brands',
                  title: '负责品牌',
                  width: 140,
                  value: (row) => c.brandsText(row['responsibleBrands']),
                ),
                AppDataGridColumn(
                  id: 'tenure',
                  title: '在职时间',
                  width: 100,
                  value: (row) => c.tenureLabel(row['tenure']),
                ),
                AppDataGridColumn(
                  id: 'city',
                  title: '所在城市',
                  width: 120,
                  value: (row) => _dash(_str(row['city'])),
                ),
                AppDataGridColumn(
                  id: 'address',
                  title: '详细地址',
                  width: 160,
                  value: (row) => _dash(_str(row['address'])),
                ),
                AppDataGridColumn(
                  id: 'phone',
                  title: '手机号',
                  width: 120,
                  value: (row) => _dash(_str(row['phones'])),
                ),
                AppDataGridColumn(
                  id: 'email',
                  title: '邮箱',
                  width: 140,
                  value: (row) => _dash(_str(row['emails'])),
                ),
                AppDataGridColumn(
                  id: 'owner',
                  title: '负责人',
                  width: 100,
                  value: (_) => c.ownerNamesText,
                ),
                AppDataGridColumn(
                  id: 'actions',
                  title: '操作',
                  width: 100,
                  pin: AppDataGridColumnPin.end,
                  value: (_) => '',
                  cellBuilder: (context, row, _) => Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppInkWell(
                          onPressed: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '编辑',
                              style: TextStyle(fontSize: 12, color: _kPrimary),
                            ),
                          ),
                        ),
                        AppInkWell(
                          onPressed: () {
                            AppToast.show(context: context, title: '删除待接入');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '删除',
                              style: TextStyle(fontSize: 12, color: _kPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

String _str(dynamic v) => v?.toString().trim() ?? '';

String _dash(String s) => s.isEmpty ? '-' : s;

String _contactTooltip(Map<String, dynamic> ct) {
  final name = _str(ct['name']);
  final phone = _str(ct['phones']);
  final email = _str(ct['emails']);
  final title = _str(ct['deptTitle']);
  final parts = <String>[
    if (name.isNotEmpty) name,
    if (title.isNotEmpty) title,
    if (phone.isNotEmpty) '手机：$phone',
    if (email.isNotEmpty) '邮箱：$email',
  ];
  return parts.isEmpty ? '' : parts.join('\n');
}

Color _avatarColor(String name) {
  const colors = [
    Color(0xFF4E5969),
    Color(0xFF52C41A),
    Color(0xFF1677FF),
    Color(0xFFFA8C16),
    Color(0xFF722ED1),
  ];
  if (name.isEmpty) return colors.first;
  return colors[name.hashCode.abs() % colors.length];
}
