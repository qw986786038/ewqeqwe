import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_create_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_entity.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_add_dialog.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/pages/orders/add/orders_create_controller.dart';
import 'package:yidivination/bokong/pages/orders/add/orders_material_pick_dialog.dart';
import 'package:yidivination/bokong/pages/orders/add/orders_terminal_pick_dialog.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';

const double _kLabelWidth = 88;

const List<AppOption<int>> _kPayTypeOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '付费'),
  AppOption<int>(value: 0, label: '免费'),
];

const List<AppOption<int>> _kPlayRuleOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '循环播放'),
  AppOption<int>(value: 2, label: '定屏播放'),
];

Future<List<AppOption<int>>> _loadAdCustomers() async {
  final resp = await LcdApi.adCustomerList(page: 1, size: 500);
  return (resp.data ?? [])
      .where((AdCustomerEntity e) => e.id != null)
      .map(
        (AdCustomerEntity e) =>
            AppOption<int>(value: e.id!, label: e.customer_name ?? '-'),
      )
      .toList();
}

Future<List<AppOption<int>>> _searchAdCustomers(String query) async {
  final all = await _loadAdCustomers();
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((o) => o.label.toLowerCase().contains(q)).toList();
}

/// 打开创建订单弹窗；提交成功返回 `true`。
Future<bool> showOrdersCreateDialog(BuildContext context) async {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  final submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(860, initialHeight),
    builder: (dialogContext) => const OrdersCreateDialog(),
  ).future;
  return submitted == true;
}

/// 创建订单弹窗（对接 `/api/customer_order/`）。
///
/// 上游缺口（待回收）：
/// - 建议 `AppFormDialog` 默认取消/保存。
/// - 建议 `AppDashedCard` / 分组框：虚线边框 + 角标「第 N 组」。
class OrdersCreateDialog extends StatelessWidget {
  const OrdersCreateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<OrdersCreateController>(OrdersCreateController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  OrdersCreateController get _c => context.lx.find<OrdersCreateController>();
  var _industryLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_industryLoaded) return;
    _industryLoaded = true;
    _c.loadIndustryItems();
  }

  Future<void> _addCustomer() async {
    final added = await showLcdCustomerAddDialog(
      context: context,
      onSubmit: (AdCustomerCreateEntity param) async {
        final resp = await LcdApi.adCustomerCreate(param: param);
        if (!resp.isSuccess()) throw resp;
        final newId = resp.data?.id;
        if (newId != null) {
          _c.setCustomerId(newId);
        }
        _c.bumpCustomerSelect();
      },
    );
    if (added && mounted) setState(() {});
  }

  Future<void> _confirmRemoveGroup(int index) async {
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '删除本组',
      message: '确定删除该播放内容组吗？',
    );
    if (!confirmed) return;
    _c.removeGroup(index);
  }

  Future<void> _confirmClearMaterial(int index) async {
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '移除素材',
      message: '确定移除已选素材吗？',
    );
    if (!confirmed) return;
    _c.clearMaterial(index);
  }

  Future<void> _pickMaterial(int index) async {
    final customerId = _c.customerId.value;
    if (customerId == null) {
      showWarn('请先选择客户');
      return;
    }
    final picked = await showOrdersMaterialPickDialog(
      context,
      customerId: customerId,
      initialId: _c.groups[index].mediaId,
    );
    if (picked == null || !mounted) return;
    _c.setMaterial(index, picked);
  }

  Future<void> _pickTerminals(int index) async {
    final group = _c.groups[index];
    final result = await showOrdersTerminalPickDialog(
      context: context,
      initialSelectedIds: group.terminalIds.toSet(),
      seedLabels: Map<int, String>.from(group.terminalLabels),
    );
    if (result == null || !mounted) return;
    _c.setTerminals(index, result.labels);
  }

  Future<void> _save() async {
    try {
      final ok = await _c.submit();
      if (ok && mounted) await AppOverlay.close<bool>(context, true);
    } catch (e) {
      _c.onApiError(e);
    }
  }

  Widget _numberField({
    required String label,
    required int value,
    required String unit,
    required ValueChanged<int> onChanged,
    int min = 0,
  }) {
    return AppField(
      label: label,
      labelWidth: _kLabelWidth,
      layout: AppFieldLayout.horizontal,
      child: Row(
        spacing: 8,
        children: [
          AppNumberInput(value: value, min: min, onChanged: onChanged),
          AppText.muted(unit),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final fills = AppDialogInteraction.maybeOf(context)?.fillsBounds ?? false;
    // 非铺满时略低于屏占比，给 AppFormDialog 标题/操作栏留空。
    final contentHeight = (MediaQuery.sizeOf(context).height * 0.68).clamp(
      420.0,
      560.0,
    );

    return AppFormDialog(
      title: const Text('创建订单'),
      constraints: fills
          ? const BoxConstraints()
          : const BoxConstraints(minWidth: 720, maxWidth: 860),
      content: SizedBox(
        width: double.infinity,
        height: fills ? double.infinity : contentHeight,
        child: AppCard(
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppField(
                label: '客户名称',
                child: Row(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Obx(
                      () => AppCombobox<int>.async(
                        key: ValueKey('customer-${_c.customerSelectKey.value}'),
                        searchOptions: _searchAdCustomers,
                        value: _c.customerId.value,
                        hintText: '搜索客户',
                        clearable: true,
                        onChanged: _c.setCustomerId,
                      ),
                    ).expanded(),
                    AppButton.outline(
                      leading: const Icon(AppLucideIcons.plus, size: 16),
                      onPressed: _addCustomer,
                      child: const Text('新增'),
                    ),
                  ],
                ),
              ),
              AppFieldScope.horizontal(
                labelWidth: _kLabelWidth,
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText.label('播放内容'),
                    Obx(() {
                      final groupList = _c.groups.toList();
                      final industryItems = _c.industryItems.toList();
                      return Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < groupList.length; i++)
                            AppCornerBadge(
                              position: AppCornerBadgePosition.topRight,
                              overlap: 1,
                              badge: AppBadge.custom(
                                color: colors.primary,
                                appearance: AppBadgeStyle.soft,
                                shape: AppBadgeShape.square,
                                size: AppBadgeSize.large,
                                child: Text('第${i + 1}组'),
                              ),
                              child: AppCard(
                                filled: false,
                                shadow: false,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  spacing: 12,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppField(
                                      label: '选择素材',
                                      required: true,
                                      child: Row(
                                        spacing: 12,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (groupList[i].media != null)
                                            AppCornerBadge(
                                              position: AppCornerBadgePosition
                                                  .topRight,
                                              ignorePointer: false,
                                              badge: MediaThumbRemoveBadge(
                                                onPressed: () =>
                                                    _confirmClearMaterial(i),
                                              ),
                                              child: AppInkWell(
                                                onPressed: () =>
                                                    _pickMaterial(i),
                                                child: SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: AdMediaListThumb(
                                                    media: groupList[i].media!,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            AppInkWell(
                                              onPressed: () => _pickMaterial(i),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    ShadcnTheme.of(
                                                      context,
                                                    ).radiusMd,
                                                  ),
                                              child: AppCard(
                                                filled: false,
                                                borderColor: colors.border,
                                                borderWidth: 1,
                                                shadow: false,
                                                padding: EdgeInsets.zero,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      ShadcnTheme.of(
                                                        context,
                                                      ).radiusMd,
                                                    ),
                                                child: SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: const Icon(
                                                    AppLucideIcons.plus,
                                                    size: 20,
                                                  ).center(),
                                                ),
                                              ),
                                            ),
                                          if (groupList.length > 1)
                                            AppButton.ghost(
                                              size: AppButtonSize.small,
                                              onPressed: () =>
                                                  _confirmRemoveGroup(i),
                                              child: const Text('删除本组'),
                                            ),
                                        ],
                                      ),
                                    ),
                                    AppField(
                                      label: '素材类型',
                                      child: AppRadioGroup<int>(
                                        options: _kPayTypeOptions,
                                        value: groupList[i].orderPay,
                                        onChanged: (value) {
                                          groupList[i].orderPay = value;
                                          _c.notifyGroups();
                                        },
                                      ),
                                    ),
                                    AppField(
                                      label: '播放方式',
                                      child: AppRadioGroup<int>(
                                        options: _kPlayRuleOptions,
                                        value: groupList[i].playRule,
                                        onChanged: (value) =>
                                            _c.setPlayRule(i, value),
                                      ),
                                    ),
                                    if (groupList[i].playRule == 2)
                                      AppField(
                                        label: '定屏时间',
                                        required: true,
                                        child: Row(
                                          spacing: 12,
                                          children: [
                                            AppDateTimePicker(
                                              value:
                                                  groupList[i].coverStartTime,
                                              minuteStep: 1,
                                              hintText: '开始时间',
                                              onChanged: (value) {
                                                groupList[i].coverStartTime =
                                                    value;
                                                _c.notifyGroups();
                                              },
                                            ).expanded(),
                                            AppDateTimePicker(
                                              value: groupList[i].coverEndTime,
                                              minuteStep: 1,
                                              hintText: '结束时间',
                                              onChanged: (value) {
                                                groupList[i].coverEndTime =
                                                    value;
                                                _c.notifyGroups();
                                              },
                                            ).expanded(),
                                          ],
                                        ),
                                      ),
                                    AppField(
                                      label: '合同时间',
                                      required: true,
                                      child: AppDatePicker.range(
                                        rangeValue: groupList[i].contractRange,
                                        hintText: '选择日期区间',
                                        onRangeChanged: (range) {
                                          groupList[i].contractRange = range;
                                          _c.notifyGroups();
                                        },
                                      ),
                                    ),
                                    AppField(
                                      label: '开始时间',
                                      required: true,
                                      child: AppDatePicker.range(
                                        rangeValue: groupList[i].sendRange,
                                        hintText: '选择日期区间',
                                        onRangeChanged: (range) {
                                          groupList[i].sendRange = range;
                                          _c.notifyGroups();
                                        },
                                      ),
                                    ),
                                    _numberField(
                                      label: '广告时长',
                                      value: groupList[i].duration,
                                      unit: '秒',
                                      min: 1,
                                      // 只写模型，勿 refresh：AppNumberInput 同步 value 时会再触发 onChanged。
                                      onChanged: (value) =>
                                          groupList[i].duration = value,
                                    ),
                                    _numberField(
                                      label: '合同频次',
                                      value: groupList[i].orderFrequency,
                                      unit: '次',
                                      min: 0,
                                      onChanged: (value) =>
                                          groupList[i].orderFrequency = value,
                                    ),
                                    _numberField(
                                      label: '赠送频次',
                                      value: groupList[i].giveFrequency,
                                      unit: '次',
                                      onChanged: (value) =>
                                          groupList[i].giveFrequency = value,
                                    ),
                                    AppField(
                                      label: '绑定终端',
                                      required: true,
                                      child: Row(
                                        spacing: 12,
                                        children: [
                                          AppButton.primary(
                                            size: AppButtonSize.small,
                                            color: const Color(0xFF00A0EC),
                                            onPressed: () => _pickTerminals(i),
                                            child: const Text('选择终端'),
                                          ),
                                          Expanded(
                                            child:
                                                groupList[i].terminalIds.isEmpty
                                                ? AppText(
                                                    '未选择终端',
                                                    style: TextStyle(
                                                      color: colors
                                                          .mutedForeground,
                                                    ),
                                                  )
                                                : Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                          text: '已选 ',
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${groupList[i].terminalIds.length}',
                                                          style: TextStyle(
                                                            color:
                                                                colors.primary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              ' 台：${groupList[i].terminalLabels.values.join('、')}',
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppField(
                                      label: '排他行业',
                                      child: AppMultiSelect<int>(
                                        options: [
                                          for (final item in industryItems)
                                            if (item.id != null)
                                              AppOption<int>(
                                                value: item.id!,
                                                label:
                                                    item.category_name ?? '-',
                                              ),
                                        ],
                                        value: groupList[i].industryIds
                                            .toList(),
                                        maxVisibleOptions: 3,
                                        onChanged: (value) {
                                          groupList[i].industryIds
                                            ..clear()
                                            ..addAll(value ?? const []);
                                          _c.notifyGroups();
                                        },
                                      ),
                                    ),
                                    _numberField(
                                      label: '排他时长',
                                      value: groupList[i].exclusiveRule,
                                      unit: '秒',
                                      onChanged: (value) =>
                                          groupList[i].exclusiveRule = value,
                                    ),
                                    _numberField(
                                      label: '循环间隔',
                                      value: groupList[i].loopRule,
                                      unit: '秒',
                                      onChanged: (value) =>
                                          groupList[i].loopRule = value,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          AppButton.outline(
                            leading: const Icon(AppLucideIcons.plus, size: 16),
                            onPressed: _c.addGroup,
                            child: const Text('新增组'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ).scroll(),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(context, false),
          child: const Text('取消'),
        ),
        AppButton.primary(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
