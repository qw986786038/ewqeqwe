import 'package:flutter/material.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../customer_contact_detail_page.dart';

/// 详情页内点击联系人 → 弹窗查看（列表页仍跳转联系人详情页）。
Future<void> showContactOverviewDialog(
  BuildContext context, {
  required String contactId,
}) {
  final id = contactId.trim();
  if (id.isEmpty) {
    showHyperToast(context, content: const Text('缺少联系人 ID'));
    return Future.value();
  }
  return showHyperDialog<void>(
    context: context,
    builder: (_) => HyperDialog(
      title: const Text('联系人详情'),
      scrollable: false,
      style: const HyperDialogStyle(maxWidth: 960),
      content: SizedBox(
        height: 560,
        child: CustomerContactDetailPage(
          contactId: id,
          embedded: true,
        ),
      ),
    ),
  );
}
