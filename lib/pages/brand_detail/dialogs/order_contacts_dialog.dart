import 'package:flutter/material.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../models/oac_brand_detail.dart';
import '../../../services/customer_api.dart';
import '../../customer_archive/detail/dialogs/contact_edit_dialog.dart';
import '../brand_detail_controller.dart';

/// 订单明细联系人「+」→「联系人信息」表单（GET/PUT `/desktop/oac/customer`）。
Future<bool> showOrderContactsDialog(
  BuildContext context, {
  required BrandDetailController controller,
  required OrderItem order,
}) async {
  final customerId = controller.brandId.trim();
  if (customerId.isEmpty) {
    showHyperToast(context, content: const Text('缺少客户档案 ID'));
    return false;
  }

  try {
    final customer = await controller.fetchCustomerDetail(customerId);
    if (!context.mounted) return false;

    final list = customer['contacts'];
    final existingCount = list is List ? list.length : 0;
    final enterprises = <Map<String, dynamic>>[
      if (customer['enterprises'] is List)
        for (final e in customer['enterprises'] as List)
          if (e is Map) Map<String, dynamic>.from(e),
    ];
    // 品牌详情经营主体兜底。
    if (enterprises.isEmpty) {
      for (final e in controller.detail.value?.enterprises ?? const []) {
        enterprises.add({
          'id': e.id,
          'name': e.name,
          'fullName': e.name,
        });
      }
    }

    final brandName = controller.detail.value?.brand?.name?.trim();
    final stub = <String, dynamic>{
      'customerId': customerId,
      if (order.enterprise?.trim().isNotEmpty == true)
        'relatedEnterprise': order.enterprise!.trim(),
      'enterprises': enterprises,
      'careers': [
        for (final e in enterprises)
          {
            'enterpriseId': e['id'],
            'enterpriseFullName': e['fullName'] ?? e['name'],
          },
      ],
      if (brandName != null && brandName.isNotEmpty)
        'responsibleBrands': brandName,
    };

    final saved = await showContactEditDialog(
      context,
      contact: stub,
      isNew: true,
      contactOrdinal: existingCount + 1,
    );
    if (!saved) return false;

    // 回读档案，把新建联系人姓名并入本行订单展示。
    try {
      final latest = await controller.fetchCustomerDetail(customerId);
      final contacts = latest['contacts'];
      String? newestName;
      if (contacts is List && contacts.isNotEmpty) {
        final last = contacts.last;
        if (last is Map) {
          newestName = last['name']?.toString().trim();
        }
      }
      if (newestName != null && newestName.isNotEmpty) {
        final names = (order.contact ?? '')
            .split(RegExp(r'[,，;；、/|]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (!names.contains(newestName)) {
          names.add(newestName);
          order.contact = names.join('；');
          controller.detail.refresh();
        }
      }
    } catch (_) {
      // 展示回填失败不阻断；档案已保存。
    }
    return true;
  } on CustomerApiException catch (e) {
    if (context.mounted) {
      showHyperToast(context, content: Text(e.message));
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      showHyperToast(context, content: Text('$e'));
    }
    return false;
  }
}
