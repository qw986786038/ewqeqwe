import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_create_entity.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';

const List<AppOption<int>> _kCustomerTypeOptions = <AppOption<int>>[
  AppOption<int>(value: 0, label: '渠道'),
  AppOption<int>(value: 1, label: '直客'),
  AppOption<int>(value: 2, label: '代理公司'),
];

const List<AppOption<int>> _kCustomerStatusOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '生效中'),
  AppOption<int>(value: 2, label: '已到期'),
  AppOption<int>(value: 0, label: '已禁用'),
];

String? _requiredSelect<T>(T? value, String message) =>
    value == null ? message : null;

String? _requiredDateTime(DateTime? value) => value == null ? '请选择时间' : null;

String _dateTimeText(DateTime? value) {
  if (value == null) return '';
  return value.millisecondsSinceEpoch.date2('yyyy-MM-dd HH:mm:ss');
}

Future<List<AppOption<int>>> _loadIndustries() async {
  final resp = await LcdApi.contentGroupList(
    page: 1,
    size: 999,
    param: <String, dynamic>{'status': 1},
  );
  return (resp.data ?? [])
      .where((e) => e.id != null)
      .map((e) => AppOption<int>(value: e.id!, label: e.category_name ?? '-'))
      .toList();
}

/// 打开添加客户弹窗；提交成功返回 `true`。
Future<bool> showLcdCustomerAddDialog({
  required BuildContext context,
  required Future<void> Function(AdCustomerCreateEntity param) onSubmit,
}) async {
  final bool? submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _LcdCustomerAddDialog(onSubmit: onSubmit),
  ).future;
  return submitted == true;
}

class _LcdCustomerAddDialog extends StatefulWidget {
  const _LcdCustomerAddDialog({required this.onSubmit});

  final Future<void> Function(AdCustomerCreateEntity param) onSubmit;

  @override
  State<_LcdCustomerAddDialog> createState() => _LcdCustomerAddDialogState();
}

class _LcdCustomerAddDialogState extends State<_LcdCustomerAddDialog> {
  final AppFormController _form = AppFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// 校验并提交；成功返回 `true`（由保存按钮关窗）。
  Future<bool> _submit(Map<String, Object?> values) async {
    final String name = (values['customer_name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      showWarn('请输入客户名称');
      return false;
    }
    final int? type = values['type'] as int?;
    if (type == null) {
      showWarn('请选择客户类型');
      return false;
    }
    final int? industryId = values['industry'] as int?;
    if (industryId == null) {
      showWarn('请选择行业');
      return false;
    }
    final DateTime? purchaseTime = values['purchase_time'] as DateTime?;
    final DateTime? effectiveTime = values['effective_time'] as DateTime?;
    final DateTime? expireTime = values['expire_time'] as DateTime?;
    if (purchaseTime == null || effectiveTime == null || expireTime == null) {
      showWarn('请完整填写购买、生效与到期时间');
      return false;
    }

    final AdCustomerCreateEntity param = AdCustomerCreateEntity()
      ..status = values['status'] as int? ?? 1
      ..type = type
      ..customer_name = name
      ..industry = industryId
      ..industry_id = industryId
      ..purchase_time = _dateTimeText(purchaseTime)
      ..effective_time = _dateTimeText(effectiveTime)
      ..expire_time = _dateTimeText(expireTime)
      ..contact_person = (values['contact_person'] as String?)?.trim()
      ..contact_phone = (values['contact_phone'] as String?)?.trim()
      ..email = (values['email'] as String?)?.trim()
      ..address = (values['address'] as String?)?.trim()
      ..remark = (values['remark'] as String?)?.trim();

    await widget.onSubmit(param);
    showComplete('添加成功');
    return true;
  }

  Widget _row(Widget left, [Widget? right]) {
    return Row(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        Expanded(child: right ?? const SizedBox.shrink()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: const Text('添加'),
      constraints: const BoxConstraints(minWidth: 820, maxWidth: 900),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: AppForm(
          controller: _form,
          child: AppCard(
            borderWidth: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(
                  AppTextFormField(
                    name: 'customer_name',
                    label: '客户名称',
                    required: true,
                    hintText: '请输入',
                    validator: AppValidators.required(message: '请输入客户名称'),
                  ),
                  AppSelectFormField<int>(
                    name: 'type',
                    label: '客户类型',
                    required: true,
                    hintText: '请选择客户类型',
                    options: _kCustomerTypeOptions,
                    validator: (value) => _requiredSelect(value, '请选择客户类型'),
                  ),
                ),
                _row(
                  AppSelectFormField<int>.async(
                    name: 'industry',
                    label: '行业',
                    required: true,
                    hintText: '请选择行业',
                    loadOptions: _loadIndustries,
                    validator: (value) => _requiredSelect(value, '请选择行业'),
                  ),
                  AppSelectFormField<int>(
                    name: 'status',
                    label: '状态',
                    hintText: '请选择',
                    options: _kCustomerStatusOptions,
                    initialValue: 1,
                  ),
                ),
                _row(
                  AppDateTimePickerFormField(
                    name: 'purchase_time',
                    label: '购买时间',
                    required: true,
                    validator: _requiredDateTime,
                  ),
                  AppDateTimePickerFormField(
                    name: 'effective_time',
                    label: '生效时间',
                    required: true,
                    validator: _requiredDateTime,
                  ),
                ),
                _row(
                  AppDateTimePickerFormField(
                    name: 'expire_time',
                    label: '到期时间',
                    required: true,
                    validator: _requiredDateTime,
                  ),
                ),
                _row(
                  const AppTextFormField(
                    name: 'contact_person',
                    label: '联系人',
                    hintText: '请输入',
                  ),
                  const AppTextFormField(
                    name: 'contact_phone',
                    label: '联系电话',
                    hintText: '请输入',
                    keyboardType: TextInputType.phone,
                  ),
                ),
                _row(
                  const AppTextFormField(
                    name: 'email',
                    label: '邮箱',
                    hintText: '请输入',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const AppTextFormField(
                    name: 'address',
                    label: '地址',
                    hintText: '请输入',
                  ),
                ),
                AppTextAreaFormField(
                  name: 'remark',
                  label: '备注',
                  hintText: '请输入',
                  minHeight: 72,
                ),
              ],
            ).scroll(),
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<bool>(context, false),
          child: const Text('取消'),
        ),
        AppButton.primary(
          onPressed: () async {
            try {
              var submitted = false;
              await _form.submit((values) async {
                submitted = await _submit(values);
              });
              if (submitted && mounted) {
                await AppOverlay.close<bool>(context, true);
              }
            } catch (e) {
              if (e is AppRespEntity) {
                showError(e.msg);
              } else {
                showError('$e');
              }
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
