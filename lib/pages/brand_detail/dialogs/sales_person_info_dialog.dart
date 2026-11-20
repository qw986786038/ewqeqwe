import 'package:flutter/material.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../models/oac_brand_detail.dart';

const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kFieldBg = Color(0xFFF7F8FA);

/// 关系图谱点击销售节点 → 只读「销售人员信息」。
Future<void> showSalesPersonInfoDialog(
  BuildContext context, {
  required SalesItem sales,
}) {
  return showHyperDialog<void>(
    context: context,
    builder: (dialogContext) => HyperDialog(
      title: const Text('销售人员信息'),
      style: const HyperDialogStyle(maxWidth: 560),
      onClose: () => Navigator.of(dialogContext).pop(),
      content: _SalesPersonInfoBody(sales: sales),
    ),
  );
}

class _SalesPersonInfoBody extends StatelessWidget {
  const _SalesPersonInfoBody({required this.sales});

  final SalesItem sales;

  @override
  Widget build(BuildContext context) {
    final nameZh = sales.name?.trim().isNotEmpty == true
        ? sales.name!.trim()
        : '-';
    final nameEn = sales.nameEn?.trim().isNotEmpty == true
        ? sales.nameEn!.trim()
        : null;
    final gender = sales.gender?.trim().isNotEmpty == true
        ? sales.gender!.trim()
        : '未知';
    final dept = sales.deptTitle?.trim().isNotEmpty == true
        ? sales.deptTitle!.trim()
        : '-';
    final assign = sales.assignTime?.trim().isNotEmpty == true
        ? _fmtDate(sales.assignTime!)
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field('姓名（中文）', nameZh)),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                'Name',
                nameEn ?? '自动填充',
                muted: nameEn == null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _field('性别', gender)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _field('部门/职位', dept)),
            const SizedBox(width: 12),
            Expanded(child: _field('创建时间', assign)),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, String value, {bool muted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.2),
        ),
        const SizedBox(height: 4),
        Container(
          height: 34,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _kFieldBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: muted ? _kMuted : _kTitle,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtDate(String raw) {
    final s = raw.trim();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }
}
