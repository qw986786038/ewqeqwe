import 'package:flutter/material.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../models/oac_brand_detail.dart';
import '../../../services/customer_api.dart';
import '../../customer_archive/dialogs/select_sales_person_dialog.dart';
import '../brand_detail_controller.dart';

/// 订单明细销售员「+」→ 组织架构选人，确认后 PUT `/desktop/oac/customer`。
Future<bool> showOrderSalesDialog(
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

    final existingUserIds = <int>{};
    final salesList = customer['salesList'];
    if (salesList is List) {
      for (final e in salesList) {
        if (e is! Map) continue;
        final uid = e['userId'];
        if (uid is int) {
          existingUserIds.add(uid);
        } else {
          final n = int.tryParse('$uid');
          if (n != null) existingUserIds.add(n);
        }
      }
    }

    final picked = await showSelectSalesPersonDialog(
      context,
      alreadySelectedUserIds: existingUserIds,
    );
    if (picked == null || picked.isEmpty) return false;
    if (!context.mounted) return false;

    final body = Map<String, dynamic>.from(customer);
    body['id'] = customerId;

    final mergedSales = <Map<String, dynamic>>[
      if (salesList is List)
        for (final e in salesList)
          if (e is Map) Map<String, dynamic>.from(e),
    ];
    final exist = {
      for (final s in mergedSales)
        if (s['userId'] != null)
          int.tryParse('${s['userId']}') ?? s['userId'],
    };
    final addedNames = <String>[];
    for (final e in picked) {
      final uid = e.userId;
      if (uid == null || exist.contains(uid)) continue;
      exist.add(uid);
      final name = e.name?.trim() ?? '';
      mergedSales.add({
        'userId': uid,
        'name': name,
        'nameEn': e.englishName,
        'gender': e.gender,
        'deptTitle': hrmEmployeeDeptPost(e),
      });
      if (name.isNotEmpty) addedNames.add(name);
    }
    if (addedNames.isEmpty) {
      showHyperToast(context, content: const Text('未选择新的销售员'));
      return false;
    }

    body['salesList'] = mergedSales;
    final ownerNames = <String>[
      for (final s in mergedSales)
        if ((s['name']?.toString().trim() ?? '').isNotEmpty)
          s['name'].toString().trim(),
    ];
    body['ownerNames'] = ownerNames.isEmpty ? null : ownerNames.join(',');
    body['ownerNameList'] = ownerNames;

    final orderId = order.id?.trim() ?? '';
    final ordersRaw = body['orders'];
    if (ordersRaw is List && orderId.isNotEmpty) {
      final orderNames = <String>{
        ..._splitNames(order.salesPerson),
        ...addedNames,
      }.toList();
      final joined = orderNames.join('；');
      body['orders'] = [
        for (final e in ordersRaw)
          if (e is Map)
            () {
              final m = Map<String, dynamic>.from(e);
              if (m['id']?.toString().trim() == orderId) {
                m['ownerNames'] = joined;
                m['salesPerson'] = joined;
                m['sales'] = joined;
              }
              return m;
            }()
          else
            e,
      ];
      order.salesPerson = joined;
    } else {
      final names = <String>{
        ..._splitNames(order.salesPerson),
        ...addedNames,
      }.toList();
      order.salesPerson = names.isEmpty ? null : names.join('；');
    }

    await CustomerApi().updateCustomer(body);
    // 先写回本地详情，避免等 load 完成前指标卡仍显示旧销售员。
    final current = controller.detail.value;
    if (current != null) {
      current.salesList = [
        for (final s in mergedSales)
          SalesItem()
            ..id = s['id']?.toString()
            ..userId = int.tryParse('${s['userId']}') ??
                (s['userId'] is int ? s['userId'] as int : null)
            ..name = s['name']?.toString()
            ..nameEn = s['nameEn']?.toString()
            ..gender = s['gender']?.toString()
            ..deptTitle = s['deptTitle']?.toString()
            ..assignTime = s['assignTime']?.toString(),
      ];
      final brand = current.brand;
      if (brand != null) {
        brand.ownerNames =
            ownerNames.isEmpty ? null : ownerNames.join(',');
        brand.ownerNameList = List<String>.from(ownerNames);
      }
    }
    controller.detail.refresh();
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

List<String> _splitNames(String? raw) => (raw ?? '')
    .split(RegExp(r'[,，;；、/|]+'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();
