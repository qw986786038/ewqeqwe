import 'dart:io' show Platform, Process;

import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import 'customer_entity_detail_controller.dart';
import 'dialogs/contact_overview_dialog.dart';
import 'dialogs/entity_module_edit_dialog.dart';
import 'dialogs/entity_tax_edit_dialog.dart';

/// 联系人列表可开关的列（序号 / 操作固定显示）。
const _kContactToggleableColumns = <(String id, String title)>[
  ('icon', '图标'),
  ('name', '姓名'),
  ('nameEn', 'Name'),
  ('gender', '性别'),
  ('ent', '关联主体名称'),
  ('relation', '关联关系'),
  ('title', '部门/职位'),
  ('job', '职能描述'),
  ('scope', '负责市场范围'),
  ('brands', '负责品牌'),
  ('tenure', '在职时间'),
  ('city', '所在城市'),
  ('address', '详细地址'),
  ('email', '邮箱'),
  ('owner', '负责人'),
];

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kGold = Color(0xFFFAAD14);
const _kCardPad = Color(0xFFF7F8FA);
/// 「类型」单元格浅黄底（对齐网页端）。
const _kTypeHighlight = Color(0xFFFFF7E6);

/// 点击关联主体全称 → 主体详情（主体概览 / 基本信息 / 银税信息）。
class CustomerEntityDetailPage extends StatelessWidget {
  const CustomerEntityDetailPage({
    super.key,
    required this.customerId,
    required this.enterpriseName,
  });

  final String customerId;
  final String enterpriseName;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<CustomerEntityDetailController>(
          () => CustomerEntityDetailController(
            customerId: customerId,
            enterpriseName: enterpriseName,
          ),
        );
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  CustomerEntityDetailController _c(BuildContext context) =>
      context.lx.find<CustomerEntityDetailController>();

  Future<void> _editModule(
    BuildContext context,
    EntityEditModule module,
  ) async {
    final c = _c(context);
    await showEntityModuleEditDialog(
      context,
      controller: c,
      module: module,
    );
  }

  Future<void> _editTax(
    BuildContext context, {
    bool appendEmpty = false,
  }) async {
    await showEntityTaxEditDialog(
      context,
      controller: _c(context),
      appendEmpty: appendEmpty,
    );
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
      if (err != null && c.enterprise.value == null) {
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
      final name = c.entityFullName;
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
            icon: const Icon(Icons.arrow_back, size: 18, color: _kPrimary),
            label: const Text(
              '返回列表',
              style: TextStyle(fontSize: 13, color: _kPrimary),
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
            _OverviewCard(
              onEdit: () => _editModule(context, EntityEditModule.overview),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                final basic = _BasicInfoCard(
                  onEdit: () => _editModule(context, EntityEditModule.basic),
                );
                final tax = _TaxInfoCard(
                  onEdit: () => _editTax(context),
                  onAdd: () => _editTax(context, appendEmpty: true),
                );
                if (!wide) {
                  return Column(
                    children: [
                      basic,
                      const SizedBox(height: 12),
                      tax,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: basic),
                    const SizedBox(width: 12),
                    Expanded(child: tax),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _ContactsCard(
              onRowEdit: () =>
                  _editModule(context, EntityEditModule.contacts),
            ),
          ],
        ),
      );
    });
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<CustomerEntityDetailController>();
    final letter = c.entityFullName == '-'
        ? '?'
        : String.fromCharCodes(c.entityFullName.runes.take(1));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                '主体概览',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppButton.primary(
                onPressed: onEdit,
                leading: const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: Colors.white,
                ),
                child: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                  const SizedBox(height: 6),
                  const Text(
                    'LOGO/图标',
                    style: TextStyle(fontSize: 11, color: _kMuted),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Table(
                  border: TableBorder.all(color: _kBorder, width: 1),
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1.2),
                  },
                  children: [
                    TableRow(
                      children: [
                        _TableInfoCell(label: '品牌简称', value: c.brandName),
                        _TableInfoCell(
                          label: '权重',
                          child: _Stars(weight: c.weight),
                        ),
                        _TableInfoCell(label: '创建时间', value: c.createTime),
                        const _TableInfoCell.empty(),
                      ],
                    ),
                    TableRow(
                      children: [
                        _TableInfoCell(label: '关联品牌', value: c.subBrandsText),
                        _TableInfoCell(
                          label: '关联关系',
                          value: c.entityRelationLabel,
                        ),
                        _TableInfoCell(
                          label: '企业简称',
                          value: c.entityShortName,
                        ),
                        const _TableInfoCell.empty(),
                      ],
                    ),
                    TableRow(
                      children: [
                        _TableInfoCell(
                          label: '企业全称',
                          value: c.entityFullName,
                        ),
                        _TableInfoCell(
                          label: '类型',
                          highlight: true,
                          child: Text(
                            c.customerTypeLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _TableInfoCell(
                          label: '所属行业',
                          value: c.industryLabel,
                        ),
                        _TableInfoCell(
                          label: '企业性质',
                          value: c.entityNatureLabel,
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _TableInfoCell(
                          label: '营收规模/年',
                          value: c.revenueLabel,
                        ),
                        _TableInfoCell(
                          label: '人员规模/人',
                          value: c.staffScale,
                        ),
                        _TableInfoCell(label: '所在城市', value: c.cityText),
                        _TableInfoCell(label: '详细地址', value: c.address),
                      ],
                    ),
                    TableRow(
                      children: [
                        _TableInfoCell(
                          label: '官网',
                          child: _LinkOrText(text: c.website),
                        ),
                        _TableInfoCell(
                          label: '微信公众号',
                          value: c.wechatAccount,
                        ),
                        _TableInfoCell(label: '视频号', value: c.videoAccount),
                        _TableInfoCell(label: '抖音号', value: c.douyinAccount),
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

class _TableInfoCell extends StatelessWidget {
  const _TableInfoCell({
    required this.label,
    this.value,
    this.child,
    this.highlight = false,
  }) : empty = false;

  const _TableInfoCell.empty()
      : label = '',
        value = null,
        child = null,
        highlight = false,
        empty = true;

  final String label;
  final String? value;
  final Widget? child;
  final bool highlight;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return const SizedBox(height: 44);
    }
    final content = child ??
        Text(
          value ?? '-',
          style: const TextStyle(fontSize: 13, color: _kTitle),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    return ColoredBox(
      color: highlight ? _kTypeHighlight : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(height: 4),
            content,
          ],
        ),
      ),
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<CustomerEntityDetailController>();
    final attach = c.attachmentText;
    return _SectionCard(
      title: '基本信息',
      onEdit: onEdit,
      child: Column(
        children: [
          _KV('统一社会信用代码', c.creditCode),
          _KV('法定代表人', c.legalPerson),
          _KV('注册资金', c.regCapital),
          _KV('成立日期', c.establishDate),
          _KV('营业执照有效期', c.licenseExpire),
          _KV('企业性质', c.entityNatureLabel),
          _KV('注册地址', c.regAddress),
          _KV('经营范围', c.businessScope),
          _KV(
            '附件',
            attach,
            valueColor: c.hasLicenseAttachment ? _kPrimary : null,
          ),
          _KV('备注', c.remark, showDivider: false),
        ],
      ),
    );
  }
}

class _TaxInfoCard extends StatefulWidget {
  const _TaxInfoCard({required this.onEdit, required this.onAdd});

  final VoidCallback onEdit;
  final VoidCallback onAdd;

  @override
  State<_TaxInfoCard> createState() => _TaxInfoCardState();
}

class _TaxInfoCardState extends State<_TaxInfoCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<CustomerEntityDetailController>();
    final entries = c.taxEntries;
    final hasMore = entries.length > 1;
    final visible = _expanded || !hasMore
        ? entries
        : (entries.isEmpty ? const <Map<String, dynamic>>[] : [entries.first]);

    return _SectionCard(
      title: '银税信息',
      onEdit: widget.onEdit,
      showAdd: true,
      onAdd: widget.onAdd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('暂无银税信息', style: TextStyle(color: _kMuted)),
              ),
            )
          else
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              // 银行账户 + 开票为一组，共用一层外框。
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: _kCardPad,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TaxGroupHeader(
                      title: '银行账户信息 ${i + 1}',
                      onDelete: widget.onEdit,
                    ),
                    const SizedBox(height: 8),
                    _KV('开户行', _dash(_str(visible[i]['bankName']))),
                    _KV(
                      '银行账号',
                      _dash(_str(visible[i]['bankAccount'])),
                      showDivider: false,
                    ),
                    const SizedBox(height: 12),
                    _TaxGroupHeader(title: '开票信息 ${i + 1}'),
                    const SizedBox(height: 8),
                    _KV(
                      '名称',
                      _dash(
                        _firstNonEmpty([
                          _str(visible[i]['invoiceName']),
                          c.entityFullName == '-' ? '' : c.entityFullName,
                        ]),
                      ),
                    ),
                    _KV(
                      '税号',
                      _dash(
                        _firstNonEmpty([
                          _str(visible[i]['taxNo']),
                          c.creditCode == '-' ? '' : c.creditCode,
                        ]),
                      ),
                    ),
                    _KV(
                      '注册地址',
                      _dash(
                        _firstNonEmpty([
                          _str(visible[i]['invoiceRegAddress']),
                          c.regAddress == '-' ? '' : c.regAddress,
                        ]),
                      ),
                    ),
                    _KV(
                      '注册电话',
                      _dash(_str(visible[i]['invoiceRegPhone'])),
                    ),
                    _KV(
                      '开户银行',
                      _dash(
                        _firstNonEmpty([
                          _str(visible[i]['invoiceBank']),
                          _str(visible[i]['bankName']),
                        ]),
                      ),
                    ),
                    _KV(
                      '开户银行账号',
                      _dash(
                        _firstNonEmpty([
                          _str(visible[i]['invoiceBankAccount']),
                          _str(visible[i]['bankAccount']),
                        ]),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          if (hasMore) ...[
            const SizedBox(height: 10),
            Center(
              child: AppInkWell(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _expanded ? '收起' : '更多',
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaxGroupHeader extends StatelessWidget {
  const _TaxGroupHeader({required this.title, this.onDelete});

  final String title;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        const Spacer(),
        if (onDelete != null)
          AppInkWell(
            onPressed: onDelete,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '删除',
                style: TextStyle(fontSize: 12, color: Color(0xFFFF4D4F)),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.onEdit,
    this.showAdd = false,
    this.onAdd,
  });

  final String title;
  final Widget child;
  final VoidCallback onEdit;
  final bool showAdd;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              if (showAdd) ...[
                AppButton.primary(
                  onPressed: onAdd ?? onEdit,
                  child: const Text('添加'),
                ),
                const SizedBox(width: 8),
              ],
              AppButton.primary(
                onPressed: onEdit,
                leading: const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: Colors.white,
                ),
                child: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
        for (var i = 0; i < 5; i++)
          Icon(
            Icons.star,
            size: 16,
            color: i < n ? _kGold : const Color(0xFFD9D9D9),
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

class _KV extends StatelessWidget {
  const _KV(
    this.label,
    this.value, {
    this.showDivider = true,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool showDivider;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ),
            ),
            const ColoredBox(
              color: _kBorder,
              child: SizedBox(width: 1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: valueColor ?? _kTitle,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.onRowEdit});

  final VoidCallback onRowEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<CustomerEntityDetailController>();
    final rows = c.entityContacts;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
              Builder(
                builder: (anchorCtx) => AppButton.outline(
                  onPressed: () {
                    AppPopover.show<void>(
                      context: anchorCtx,
                      alignment: Alignment.topRight,
                      anchorAlignment: Alignment.bottomRight,
                      builder: (_) => _ContactColumnSettingsPopover(
                        controller: c,
                      ),
                    );
                  },
                  leading: const Icon(Icons.view_column_outlined, size: 16),
                  child: const Text('列设置'),
                ),
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
            Obx(() {
              final hidden = c.contactHiddenColumnIds.toSet();
              final gridH = (rows.length * 52.0 + 44).clamp(120.0, 360.0);
              final allColumns = <AppDataGridColumn<Map<String, dynamic>>>[
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
                        onPressed: () {
                          final id = row['id']?.toString().trim() ?? '';
                          if (id.isEmpty) {
                            AppToast.show(
                              context: context,
                              title: '缺少联系人 ID，无法打开详情',
                            );
                            return;
                          }
                          // 详情页内点击联系人 → 弹窗。
                          showContactOverviewDialog(context, contactId: id);
                        },
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600,
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
                  width: 140,
                  value: (row) => _dash(_str(row['jobDesc'])),
                  cellBuilder: (context, row, _) => Center(
                    child: Text(
                      _dash(_str(row['jobDesc'])),
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kPrimary,
                      ),
                    ),
                  ),
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
                          onPressed: onRowEdit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '编辑',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ),
                        AppInkWell(
                          onPressed: () {
                            AppToast.show(
                              context: context,
                              title: '删除待接入',
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '删除',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
              final columns = [
                for (final col in allColumns)
                  if (col.id == 'no' ||
                      col.id == 'actions' ||
                      !hidden.contains(col.id))
                    col,
              ];
              return SizedBox(
                height: gridH,
                child: AppDataGrid<Map<String, dynamic>>.local(
                  key: ValueKey('entity-contacts-${hidden.join(',')}'),
                  height: gridH,
                  rows: rows,
                  rowKey: (row) =>
                      '${row['id'] ?? row['name'] ?? rows.indexOf(row)}',
                  sortable: false,
                  showInternalDividers: true,
                  headerBackgroundColor: const Color(0xFFFAFAFA),
                  textStyle: const TextStyle(fontSize: 12),
                  cellTextStyle: const TextStyle(fontSize: 12),
                  columns: columns,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ContactColumnSettingsPopover extends StatelessWidget {
  const _ContactColumnSettingsPopover({required this.controller});

  final CustomerEntityDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '显示 / 隐藏列',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5969),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Obx(() {
                final hidden = controller.contactHiddenColumnIds.toSet();
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (id, title) in _kContactToggleableColumns)
                        AppInkWell(
                          onPressed: () => controller.setContactColumnVisible(
                            id,
                            hidden.contains(id),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                AppCheckboxIndicator(
                                  state: hidden.contains(id)
                                      ? CheckboxState.unchecked
                                      : CheckboxState.checked,
                                  onChanged: (state) =>
                                      controller.setContactColumnVisible(
                                    id,
                                    state == CheckboxState.checked,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kTitle,
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
              }),
            ),
          ],
        ),
      ),
    );
  }
}

String _str(dynamic v) => v?.toString().trim() ?? '';

String _dash(String s) => s.isEmpty ? '-' : s;

String _firstNonEmpty(List<String> parts) {
  for (final p in parts) {
    if (p.trim().isNotEmpty && p.trim() != '-') return p.trim();
  }
  return '';
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
