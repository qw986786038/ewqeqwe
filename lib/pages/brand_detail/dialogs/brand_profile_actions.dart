import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../models/oac_brand_detail.dart';
import '../../../services/customer_api.dart';
import '../../../services/file_center_api.dart';
import '../brand_detail_controller.dart';
import 'order_contacts_dialog.dart';
import 'order_sales_dialog.dart';

const _kPrimary = Color(0xFF1677FF);

/// 品牌详情分区「添加联系人」→ 复用订单联系人新增（无订单上下文）。
Future<bool> showAddBrandContact(
  BuildContext context, {
  required BrandDetailController controller,
}) async {
  final saved = await showOrderContactsDialog(
    context,
    controller: controller,
    order: OrderItem(),
  );
  if (!saved || !context.mounted) return false;
  await controller.load();
  if (!context.mounted) return false;
  showHyperToast(context, content: const Text('联系人已添加'));
  return true;
}

/// 品牌详情「销售员 · 添加」→ 组织架构选人后 PUT customer。
Future<bool> showAddBrandSales(
  BuildContext context, {
  required BrandDetailController controller,
}) async {
  final saved = await showOrderSalesDialog(
    context,
    controller: controller,
    order: OrderItem(),
  );
  if (!saved || !context.mounted) return false;
  await controller.load();
  if (!context.mounted) return false;
  showHyperToast(context, content: const Text('销售员已添加'));
  return true;
}

/// 品牌画像「子品牌 · 添加」。
Future<bool> showAddSubBrandDialog(
  BuildContext context, {
  required BrandDetailController controller,
}) async {
  final customerId = controller.brandId.trim();
  if (customerId.isEmpty) {
    showHyperToast(context, content: const Text('缺少客户档案 ID'));
    return false;
  }

  final hostContext = context;
  final nameCtrl = TextEditingController();
  final form = AppFormController();
  var saving = false;

  final ok = await showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            if (saving) return;
            final name = nameCtrl.text.trim();
            if (name.isEmpty) {
              showHyperToast(context, content: const Text('请输入子品牌名称'));
              return;
            }
            setState(() => saving = true);
            try {
              final customer =
                  await controller.fetchCustomerDetail(customerId);
              if (!dialogContext.mounted) return;
              final existing = <String>{
                for (final s in controller.detail.value?.subBrands ??
                    const <String>[])
                  s.trim(),
                ..._asStringList(customer['subBrands']),
              }..removeWhere((e) => e.isEmpty);
              if (existing.contains(name)) {
                showHyperToast(context, content: const Text('该子品牌已存在'));
                setState(() => saving = false);
                return;
              }
              final body = Map<String, dynamic>.from(customer);
              body['id'] = customerId;
              body['subBrands'] = [...existing, name];
              await CustomerApi().updateCustomer(body);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(true);
            } catch (e) {
              if (dialogContext.mounted) {
                setState(() => saving = false);
                showHyperToast(context, content: Text('$e'));
              }
            }
          }

          return AppShadcnScope(
            config: AppThemeConfig.standard(primary: _kPrimary),
            child: AppForm(
              controller: form,
              child: HyperDialog(
                title: const Text('添加子品牌'),
                style: const HyperDialogStyle(maxWidth: 420),
                onClose: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                content: AppTextFormField(
                  name: 'subBrand',
                  label: '子品牌名称',
                  hintText: '请输入子品牌名称',
                  required: true,
                  controller: nameCtrl,
                  onSubmitted: (_) => submit(),
                ),
                actions: [
                  HyperButton.outlined(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    label: const Text('取消'),
                  ),
                  HyperButton.filled(
                    onPressed: saving ? null : submit,
                    label: Text(saving ? '保存中…' : '确定'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    nameCtrl.dispose();
    form.dispose();
  });

  if (ok != true) return false;
  if (!hostContext.mounted) return false;
  await controller.load();
  if (!hostContext.mounted) return false;
  showHyperToast(hostContext, content: const Text('子品牌已添加'));
  return true;
}

/// 备注与附件「编辑」备注。
Future<bool> showEditBrandRemarkDialog(
  BuildContext context, {
  required BrandDetailController controller,
  String? initialRemark,
}) async {
  final customerId = controller.brandId.trim();
  if (customerId.isEmpty) {
    showHyperToast(context, content: const Text('缺少客户档案 ID'));
    return false;
  }

  final hostContext = context;
  final remarkCtrl = TextEditingController(text: initialRemark?.trim() ?? '');
  final form = AppFormController();
  var saving = false;

  final ok = await showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            if (saving) return;
            setState(() => saving = true);
            try {
              final customer =
                  await controller.fetchCustomerDetail(customerId);
              if (!dialogContext.mounted) return;
              final body = Map<String, dynamic>.from(customer);
              body['id'] = customerId;
              final text = remarkCtrl.text.trim();
              body['remark'] = text.isEmpty ? null : text;
              await CustomerApi().updateCustomer(body);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(true);
            } catch (e) {
              if (dialogContext.mounted) {
                setState(() => saving = false);
                showHyperToast(context, content: Text('$e'));
              }
            }
          }

          return AppShadcnScope(
            config: AppThemeConfig.standard(primary: _kPrimary),
            child: AppForm(
              controller: form,
              child: HyperDialog(
                title: const Text('编辑备注'),
                style: const HyperDialogStyle(maxWidth: 480),
                onClose: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                content: AppTextAreaFormField(
                  name: 'remark',
                  label: '备注',
                  hintText: '请输入备注',
                  controller: remarkCtrl,
                  minHeight: 120,
                ),
                actions: [
                  HyperButton.outlined(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    label: const Text('取消'),
                  ),
                  HyperButton.filled(
                    onPressed: saving ? null : submit,
                    label: Text(saving ? '保存中…' : '保存'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    remarkCtrl.dispose();
    form.dispose();
  });

  if (ok != true) return false;
  if (!hostContext.mounted) return false;
  await controller.load();
  if (!hostContext.mounted) return false;
  showHyperToast(hostContext, content: const Text('备注已保存'));
  return true;
}

/// 备注与附件「上传附件」：文件中心上传后写入客户档案 `attachments`。
Future<bool> uploadBrandAttachment(
  BuildContext context, {
  required BrandDetailController controller,
}) async {
  final customerId = controller.brandId.trim();
  if (customerId.isEmpty) {
    showHyperToast(context, content: const Text('缺少客户档案 ID'));
    return false;
  }

  final file = await FilePicker.pickFile(
    type: FileType.any,
    windowsOptions: const WindowsOptions(lockParentWindow: true),
  );
  if (file == null) return false;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    if (context.mounted) {
      showHyperToast(context, content: const Text('无法读取所选文件'));
    }
    return false;
  }

  try {
    if (context.mounted) {
      showHyperToast(context, content: const Text('正在上传…'));
    }
    final upload = await FileCenterApi().uploadBytes(
      bytes: bytes,
      fileName: file.name,
      fetchDetail: false,
    );
    if (!context.mounted) return false;

    final customer = await controller.fetchCustomerDetail(customerId);
    if (!context.mounted) return false;

    final merged = <Map<String, dynamic>>[
      ..._asAttachmentMaps(customer['attachments']),
    ];
    final fileId = upload.fileId.trim();
    final already = merged.any(
      (e) =>
          (e['fileId'] ?? e['ossId'] ?? e['id'])?.toString().trim() == fileId,
    );
    if (!already) {
      merged.add({
        'fileId': fileId,
        'ossId': fileId,
        'name': file.name,
        'fileName': file.name,
        'url': upload.displayUrl ?? upload.publicUrl,
        'fileUrl': upload.publicUrl,
      });
    }

    final body = Map<String, dynamic>.from(customer);
    body['id'] = customerId;
    body['attachments'] = merged;
    await CustomerApi().updateCustomer(body);
    if (!context.mounted) return false;
    await controller.load();
    if (!context.mounted) return false;
    showHyperToast(context, content: const Text('附件已上传'));
    return true;
  } on CustomerApiException catch (e) {
    if (context.mounted) {
      showHyperToast(context, content: Text(e.message));
    }
    return false;
  } on FileCenterApiException catch (e) {
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

List<String> _asStringList(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e != null && '$e'.trim().isNotEmpty) '$e'.trim(),
  ];
}

List<Map<String, dynamic>> _asAttachmentMaps(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map)
        Map<String, dynamic>.from(e)
      else if (e != null && '$e'.trim().isNotEmpty)
        <String, dynamic>{'fileId': '$e'.trim(), 'name': '$e'.trim()},
  ];
}
