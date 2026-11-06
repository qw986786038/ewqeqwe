import 'dart:io' show Platform, Process;

import 'package:flutter/material.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../customer_archive/detail/customer_entity_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kGold = Color(0xFFFAAD14);
const _kTypeHighlight = Color(0xFFFFF7E6);

/// 订单明细「关联 4A」→ 主体概览弹窗（`GET /desktop/oac/customer/{id}`）。
Future<void> showAgencyOverviewDialog(
  BuildContext context, {
  required String customerId,
  String? enterpriseName,
}) {
  final id = customerId.trim();
  if (id.isEmpty) {
    showHyperToast(context, content: const Text('缺少 4A 客户 ID'));
    return Future.value();
  }
  return showHyperDialog<void>(
    context: context,
    builder: (dialogContext) => LxScope(
      bindings: (container) {
        container.put<CustomerEntityDetailController>(
          () => CustomerEntityDetailController(
            customerId: id,
            enterpriseName: enterpriseName?.trim() ?? '',
          ),
        );
      },
      child: const _AgencyOverviewDialog(),
    ),
  );
}

class _AgencyOverviewDialog extends StatelessWidget {
  const _AgencyOverviewDialog();

  @override
  Widget build(BuildContext context) {
    return HyperDialog(
      title: const Text('主体概览'),
      scrollable: true,
      style: const HyperDialogStyle(maxWidth: 960),
      content: const _AgencyOverviewBody(),
    );
  }
}

class _AgencyOverviewBody extends StatelessWidget {
  const _AgencyOverviewBody();

  CustomerEntityDetailController _c(BuildContext context) =>
      context.lx.find<CustomerEntityDetailController>();

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Obx(() {
      if (c.loading.value && c.raw.value == null) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      final err = c.errorMessage.value;
      if (err != null && c.raw.value == null) {
        return SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: Color(0xFFFF4D4F))),
                const SizedBox(height: 12),
                HyperButton.filled(
                  onPressed: c.load,
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      }
      final letter = c.entityFullName == '-'
          ? '?'
          : String.fromCharCodes(c.entityFullName.runes.take(1));
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF52C41A),
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
                    const _TableInfoCell.empty(),
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
                          color: Color(0xFFFA8C16),
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
      );
    });
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
    return HyperPressable(
      onTap: () async {
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
      builder: (context, states, child) => child!,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: _kPrimary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
