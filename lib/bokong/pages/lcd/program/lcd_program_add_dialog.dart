import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad hide WidgetExtension;
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_device_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_create_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_create_entity.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_add_dialog.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/pages/orders/add/orders_material_pick_dialog.dart';
import 'package:yidivination/bokong/utils/ext.dart';
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

String _dateText(DateTime? value) {
  if (value == null) return '';
  return value.millisecondsSinceEpoch.date2('yyyy-MM-dd');
}

String _dateTimeText(DateTime? value) {
  if (value == null) return '';
  return value.millisecondsSinceEpoch.date2('yyyy-MM-dd HH:mm:ss');
}

class _ProgramContentGroup {
  int? mediaId;
  String? mediaTitle;
  AdMediaEntity? media;
  int orderPay = 1;
  int playRule = 1;
  DateTime? coverStartTime;
  DateTime? coverEndTime;
  shad.DateTimeRange? contractRange = shad.DateTimeRange(
    DateTime.now(),
    DateTime.now(),
  );
  shad.DateTimeRange? sendRange = shad.DateTimeRange(
    DateTime.now(),
    DateTime.now(),
  );
  int duration = 15;
  int orderFrequency = 120;
  int giveFrequency = 0;
  final Set<int> industryIds = {};
  int exclusiveRule = 0;
  int loopRule = 0;
}

class _LcdProgramAddDialog extends StatefulWidget {
  const _LcdProgramAddDialog({
    required this.device,
    this.initialCustomerId,
    required this.onSubmit,
  });

  final LcdProgramDeviceEntity device;
  final int? initialCustomerId;
  final Future<void> Function(LcdProgramCreateEntity param) onSubmit;

  @override
  State<_LcdProgramAddDialog> createState() => _LcdProgramAddDialogState();
}

class _LcdProgramAddDialogState extends State<_LcdProgramAddDialog> {
  int? _customerId;
  int _customerSelectKey = 0;
  final List<_ProgramContentGroup> _groups = [_ProgramContentGroup()];
  List<AdContentGroupEntity> _industryItems = [];

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    _reloadIndustryItems();
  }

  Future<void> _reloadIndustryItems() async {
    final resp = await LcdApi.contentGroupList(page: 1, size: 500);
    if (!mounted) return;
    setState(() => _industryItems = resp.data ?? []);
  }

  String get _terminalStatus {
    final LcdProgramDeviceEntity device = widget.device;
    final List<String> parts = [
      if (device.terminal_point_name?.isNotEmpty == true)
        device.terminal_point_name!,
      if (device.terminal_building?.isNotEmpty == true)
        device.terminal_building!,
      if (device.terminal_detailed_address?.isNotEmpty == true)
        device.terminal_detailed_address!,
    ];
    if (parts.isEmpty) return device.terminal_device_no ?? '-';
    return parts.join(' · ');
  }

  void _addGroup() => setState(() => _groups.add(_ProgramContentGroup()));

  void _removeGroup(int index) {
    if (_groups.length <= 1) return;
    setState(() => _groups.removeAt(index));
  }

  void _ensureFixedScreenTimes(_ProgramContentGroup group) {
    if (group.playRule != 2) return;
    final now = DateTime.now();
    group.coverStartTime ??= DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    group.coverEndTime ??= group.coverStartTime!.add(const Duration(hours: 1));
  }

  void _setPlayRule(int index, int value) {
    final group = _groups[index];
    group.playRule = value;
    _ensureFixedScreenTimes(group);
    setState(() {});
  }

  Future<void> _addCustomer() async {
    final added = await showLcdCustomerAddDialog(
      context: context,
      onSubmit: (AdCustomerCreateEntity param) async {
        final resp = await LcdApi.adCustomerCreate(param: param);
        if (!resp.isSuccess()) throw resp;
        final newId = resp.data?.id;
        if (newId != null) {
          setState(() => _customerId = newId);
        }
        setState(() => _customerSelectKey++);
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
    if (!confirmed || !mounted) return;
    _removeGroup(index);
  }

  Future<void> _confirmClearMaterial(int index) async {
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '移除素材',
      message: '确定移除已选素材吗？',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      final group = _groups[index];
      group.mediaId = null;
      group.mediaTitle = null;
      group.media = null;
    });
  }

  Future<void> _pickMaterial(int index) async {
    final customerId = _customerId;
    if (customerId == null) {
      showWarn('请先选择客户');
      return;
    }

    final selected = await showOrdersMaterialPickDialog(
      context,
      customerId: customerId,
      initialId: _groups[index].mediaId,
    );
    if (selected == null || !mounted) return;
    setState(() {
      final _ProgramContentGroup group = _groups[index];
      group.mediaId = selected.id;
      group.mediaTitle = selected.title ?? selected.media_no;
      group.media = selected;
      final int? mediaDuration = selected.duration;
      if (mediaDuration != null && mediaDuration > 0) {
        group.duration = mediaDuration;
      }
    });
  }

  LcdProgramCreateEntity? _buildParam() {
    final int? customerId = _customerId;
    final int? scheduleId = widget.device.id;
    if (customerId == null) {
      showWarn('请选择客户');
      return null;
    }
    if (scheduleId == null) {
      showWarn('终端排期 ID 无效');
      return null;
    }

    final List<OrderCreateItemEntity> items = [];
    for (int i = 0; i < _groups.length; i++) {
      final _ProgramContentGroup group = _groups[i];
      if (group.mediaId == null) {
        showWarn('第${i + 1}组请选择素材');
        return null;
      }
      if (group.contractRange == null) {
        showWarn('第${i + 1}组请选择合同时间');
        return null;
      }
      if (group.sendRange == null) {
        showWarn('第${i + 1}组请选择开始时间');
        return null;
      }
      if (group.playRule == 2) {
        if (group.coverStartTime == null) {
          showWarn('第${i + 1}组请选择定屏开始时间');
          return null;
        }
        if (group.coverEndTime == null) {
          showWarn('第${i + 1}组请选择定屏结束时间');
          return null;
        }
        if (!group.coverEndTime!.isAfter(group.coverStartTime!)) {
          showWarn('第${i + 1}组定屏结束时间须晚于开始时间');
          return null;
        }
      }

      final bool isFixedScreen = group.playRule == 2;
      items.add(
        OrderCreateItemEntity()
          ..media_id = group.mediaId
          ..media_title = group.mediaTitle
          ..start_time = _dateText(group.contractRange!.start)
          ..end_time = _dateText(group.contractRange!.end)
          ..send_time = _dateText(group.sendRange!.start)
          ..send_end_time = _dateText(group.sendRange!.end)
          ..duration = group.duration
          ..order_frequency = group.orderFrequency
          ..give_frequency = group.giveFrequency
          ..exclusive_industry = group.industryIds.toList()
          ..exclusive_rule = group.exclusiveRule
          ..loop_rule = group.loopRule
          ..order_pay = group.orderPay
          ..play_rule = group.playRule
          ..cover_start_time = isFixedScreen
              ? _dateTimeText(group.coverStartTime)
              : ''
          ..cover_end_time = isFixedScreen
              ? _dateTimeText(group.coverEndTime)
              : '',
      );
    }

    final _ProgramContentGroup firstGroup = _groups.first;
    return LcdProgramCreateEntity()
      ..schedule_id = scheduleId
      ..customer_id = customerId
      ..exclusive_industry = firstGroup.industryIds.toList()
      ..exclusive_rule = firstGroup.exclusiveRule
      ..loop_rule = firstGroup.loopRule
      ..confirm_relist = 0
      ..items = items;
  }

  Future<bool> _save() async {
    final LcdProgramCreateEntity? param = _buildParam();
    if (param == null) return false;
    await widget.onSubmit(param);
    return true;
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
    // 与创建订单同结构，略增高：多一行「绑定终端」且每组字段更多。
    final contentHeight = (MediaQuery.sizeOf(context).height * 0.72).clamp(
      480.0,
      640.0,
    );

    return AppFormDialog(
      title: const Text('创建节目'),
      constraints: const BoxConstraints(maxWidth: 860),
      content: SizedBox(
        width: 820,
        height: contentHeight,
        child: AppCard(
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppField(
                label: '绑定终端',
                child: AppText(
                  _terminalStatus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppField(
                label: '客户名称',
                required: true,
                child: Row(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AppCombobox<int>.async(
                        key: ValueKey('customer-$_customerSelectKey'),
                        searchOptions: _searchAdCustomers,
                        value: _customerId,
                        hintText: '搜索客户',
                        clearable: true,
                        onChanged: (value) =>
                            setState(() => _customerId = value),
                      ),
                    ),
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
                    for (int i = 0; i < _groups.length; i++)
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
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppField(
                                label: '选择素材',
                                required: true,
                                child: Row(
                                  spacing: 12,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_groups[i].media != null)
                                      AppCornerBadge(
                                        position:
                                            AppCornerBadgePosition.topRight,
                                        ignorePointer: false,
                                        badge: MediaThumbRemoveBadge(
                                          onPressed: () =>
                                              _confirmClearMaterial(i),
                                        ),
                                        child: AppInkWell(
                                          onPressed: () => _pickMaterial(i),
                                          child: SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: AdMediaListThumb(
                                              media: _groups[i].media!,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      AppInkWell(
                                        onPressed: () => _pickMaterial(i),
                                        borderRadius: BorderRadius.circular(
                                          ShadcnTheme.of(context).radiusMd,
                                        ),
                                        child: AppCard(
                                          filled: false,
                                          borderColor: colors.border,
                                          borderWidth: 1,
                                          shadow: false,
                                          padding: EdgeInsets.zero,
                                          borderRadius: BorderRadius.circular(
                                            ShadcnTheme.of(context).radiusMd,
                                          ),
                                          child: SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: Center(
                                              child: Icon(
                                                AppLucideIcons.plus,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_groups.length > 1)
                                      AppButton.ghost(
                                        size: AppButtonSize.small,
                                        onPressed: () => _confirmRemoveGroup(i),
                                        child: const Text('删除本组'),
                                      ),
                                  ],
                                ),
                              ),
                              AppField(
                                label: '素材类型',
                                child: AppRadioGroup<int>(
                                  options: _kPayTypeOptions,
                                  value: _groups[i].orderPay,
                                  onChanged: (value) {
                                    _groups[i].orderPay = value;
                                    setState(() {});
                                  },
                                ),
                              ),
                              AppField(
                                label: '播放方式',
                                child: AppRadioGroup<int>(
                                  options: _kPlayRuleOptions,
                                  value: _groups[i].playRule,
                                  onChanged: (value) => _setPlayRule(i, value),
                                ),
                              ),
                              if (_groups[i].playRule == 2)
                                AppField(
                                  label: '定屏时间',
                                  required: true,
                                  child: Row(
                                    spacing: 12,
                                    children: [
                                      Expanded(
                                        child: AppDateTimePicker(
                                          value: _groups[i].coverStartTime,
                                          minuteStep: 1,
                                          hintText: '开始时间',
                                          onChanged: (value) {
                                            _groups[i].coverStartTime = value;
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: AppDateTimePicker(
                                          value: _groups[i].coverEndTime,
                                          minuteStep: 1,
                                          hintText: '结束时间',
                                          onChanged: (value) {
                                            _groups[i].coverEndTime = value;
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              AppField(
                                label: '合同时间',
                                required: true,
                                child: AppDatePicker.range(
                                  rangeValue: _groups[i].contractRange,
                                  hintText: '选择日期区间',
                                  onRangeChanged: (range) {
                                    _groups[i].contractRange = range;
                                    setState(() {});
                                  },
                                ),
                              ),
                              AppField(
                                label: '开始时间',
                                required: true,
                                child: AppDatePicker.range(
                                  rangeValue: _groups[i].sendRange,
                                  hintText: '选择日期区间',
                                  onRangeChanged: (range) {
                                    _groups[i].sendRange = range;
                                    setState(() {});
                                  },
                                ),
                              ),
                              _numberField(
                                label: '广告时长',
                                value: _groups[i].duration,
                                unit: '秒',
                                min: 1,
                                onChanged: (value) =>
                                    _groups[i].duration = value,
                              ),
                              _numberField(
                                label: '合同频次',
                                value: _groups[i].orderFrequency,
                                unit: '次',
                                min: 0,
                                onChanged: (value) =>
                                    _groups[i].orderFrequency = value,
                              ),
                              _numberField(
                                label: '赠送频次',
                                value: _groups[i].giveFrequency,
                                unit: '次',
                                onChanged: (value) =>
                                    _groups[i].giveFrequency = value,
                              ),
                              AppField(
                                label: '排他行业',
                                child: AppMultiSelect<int>(
                                  options: [
                                    for (final item in _industryItems)
                                      if (item.id != null)
                                        AppOption<int>(
                                          value: item.id!,
                                          label: item.category_name ?? '-',
                                        ),
                                  ],
                                  value: _groups[i].industryIds.toList(),
                                  maxVisibleOptions: 3,
                                  onChanged: (value) {
                                    _groups[i].industryIds
                                      ..clear()
                                      ..addAll(value ?? const []);
                                    setState(() {});
                                  },
                                ),
                              ),
                              _numberField(
                                label: '排他时长',
                                value: _groups[i].exclusiveRule,
                                unit: '秒',
                                onChanged: (value) =>
                                    _groups[i].exclusiveRule = value,
                              ),
                              _numberField(
                                label: '循环间隔',
                                value: _groups[i].loopRule,
                                unit: '秒',
                                onChanged: (value) =>
                                    _groups[i].loopRule = value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    AppButton.outline(
                      leading: const Icon(AppLucideIcons.plus, size: 16),
                      onPressed: _addGroup,
                      child: const Text('新增组'),
                    ),
                  ],
                ),
              ),
            ],
          ).scroll(),
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
              final ok = await _save();
              if (ok && mounted) await AppOverlay.close<bool>(context, true);
            } catch (e) {
              if (e is AppRespEntity) {
                showError(e.msg);
              } else {
                showError('$e');
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 打开「创建节目」弹窗；提交成功返回 `true`。
Future<bool> showLcdProgramAddDialog({
  required BuildContext context,
  required LcdProgramDeviceEntity device,
  int? initialCustomerId,
  required Future<void> Function(LcdProgramCreateEntity param) onSubmit,
}) async {
  final bool? submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _LcdProgramAddDialog(
      device: device,
      initialCustomerId: initialCustomerId,
      onSubmit: onSubmit,
    ),
  ).future;
  return submitted == true;
}
