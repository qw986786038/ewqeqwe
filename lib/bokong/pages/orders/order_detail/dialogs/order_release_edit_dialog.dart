import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_create_entity.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/pages/orders/add/orders_material_pick_dialog.dart';
import 'package:yidivination/bokong/pages/orders/add/orders_terminal_pick_dialog.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/order_release_material_card.dart';

import '../order_detail_controller.dart';

const double _kLabelWidth = 88;

const List<AppOption<int>> _kPayTypeOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '付费'),
  AppOption<int>(value: 0, label: '免费'),
];

const List<AppOption<int>> _kPlayRuleOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '循环播放'),
  AppOption<int>(value: 2, label: '定屏播放'),
];

/// 打开编辑发布单弹窗。
void showOrderReleaseEditDialog(
  BuildContext context, {
  required OrderDetailController controller,
  required OrderItemEntity item,
}) {
  showAppWindowDialog<void>(
    context: context,
    builder: (_) => OrderReleaseFormDialog(controller: controller, item: item),
  );
}

/// 打开新增发布单弹窗（客户固定为当前订单，提交传订单 id）。
void showOrderReleaseAddDialog(
  BuildContext context, {
  required OrderDetailController controller,
}) {
  showAppWindowDialog<void>(
    context: context,
    builder: (_) => OrderReleaseFormDialog(controller: controller),
  );
}

class OrderReleaseFormDialog extends StatefulWidget {
  const OrderReleaseFormDialog({
    required this.controller,
    this.item,
    super.key,
  });

  final OrderDetailController controller;

  /// 为空时表示新增发布单。
  final OrderItemEntity? item;

  bool get isAdd => item == null;

  @override
  State<OrderReleaseFormDialog> createState() => _OrderReleaseFormDialogState();
}

class _OrderReleaseFormDialogState extends State<OrderReleaseFormDialog> {
  late int? _mediaId;
  late String? _mediaTitle;
  AdMediaEntity? _media;
  late int _orderPay;
  late int _playRule;
  shad.DateTimeRange? _contractRange;
  shad.DateTimeRange? _sendRange;
  DateTime? _coverStartTime;
  DateTime? _coverEndTime;
  late int _duration;
  late int _orderFrequency;
  late int _giveFrequency;
  final List<int> _terminalIds = [];
  final Map<int, String> _terminalLabels = {};
  late List<int> _industryIds;
  late int _exclusiveRule;
  late int _loopRule;
  var _saving = false;

  OrderDetailController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _mediaId = item.media_id;
      _mediaTitle = item.media_title;
      _media = orderReleaseToAdMedia(item);
      _orderPay = item.order_pay ?? 1;
      _playRule = item.play_rule ?? 1;
      _contractRange = _dateRange(item.start_time, item.end_time);
      // 与列表「上刊/下刊时间」一致：send_* → cover_* → 合同时间。
      _sendRange = _dateRange(
        item.send_time ?? item.cover_start_time ?? item.start_time,
        item.send_end_time ?? item.cover_end_time ?? item.end_time,
      );
      _coverStartTime = _parseDateTime(item.cover_start_time);
      _coverEndTime = _parseDateTime(item.cover_end_time);
      _duration = item.duration ?? 15;
      _orderFrequency = item.order_frequency ?? 120;
      _giveFrequency = item.give_frequency ?? 0;
      _industryIds = List<int>.from(item.exclusive_industry ?? const []);
      _exclusiveRule = item.exclusive_rule ?? 0;
      _loopRule = item.loop_rule ?? 0;
      _loadTerminals(item);
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _mediaId = null;
      _mediaTitle = null;
      _media = null;
      _orderPay = _c.order.order_pay ?? 1;
      _playRule = _c.order.play_rule ?? 1;
      _contractRange = shad.DateTimeRange(today, today);
      _sendRange = shad.DateTimeRange(today, today);
      _duration = _c.order.duration ?? 15;
      _orderFrequency = _c.order.order_frequency ?? 120;
      _giveFrequency = 0;
      // 新建发布单：排它默认空。订单级摘要仅列表卡片用，详情禁止抄。
      _industryIds = [];
      _exclusiveRule = 0;
      _loopRule = 0;
    }
    unawaited(_loadIndustryOptions());
  }

  Future<void> _loadIndustryOptions() async {
    await _c.loadIndustryItems();
    if (!mounted) return;
    // 选项异步就绪后刷新，确保已选行业能显示标签。
    setState(() {});
  }

  void _loadTerminals(OrderItemEntity item) {
    _terminalIds.clear();
    _terminalLabels.clear();
    for (final terminal in item.terminal_list ?? const []) {
      final id = terminal.terminal_id ?? terminal.id;
      if (id == null) continue;
      _terminalIds.add(id);
      _terminalLabels[id] =
          terminal.device_name ?? terminal.point_name ?? '$id';
    }
    if (_terminalIds.isEmpty) {
      for (final raw in item.terminal_ids?.split(',') ?? const <String>[]) {
        final id = int.tryParse(raw.trim());
        if (id != null) _terminalIds.add(id);
      }
    }
  }

  shad.DateTimeRange? _dateRange(String? start, String? end) {
    final s = _parseDateOnly(start);
    final e = _parseDateOnly(end);
    if (s == null && e == null) return null;
    if (s != null && e != null) return shad.DateTimeRange(s, e);
    final only = s ?? e!;
    return shad.DateTimeRange(only, only);
  }

  DateTime? _parseDateOnly(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text.split(' ').first);
  }

  DateTime? _parseDateTime(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _dateText(DateTime? value) {
    if (value == null) return '';
    return value.millisecondsSinceEpoch.date2('yyyy-MM-dd');
  }

  String _dateTimeText(DateTime? value) {
    if (value == null) return '';
    return value.millisecondsSinceEpoch.date2('yyyy-MM-dd HH:mm:ss');
  }

  Future<void> _pickMaterial() async {
    final customerId = _c.resolvedCustomerId;
    if (customerId == null) {
      showWarn('客户信息无效');
      return;
    }
    final picked = await showOrdersMaterialPickDialog(
      context,
      customerId: customerId,
      initialId: _mediaId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _mediaId = picked.id;
      _mediaTitle = picked.title ?? picked.media_no;
      _media = picked;
      final duration = picked.duration;
      if (duration != null && duration > 0) _duration = duration;
    });
  }

  Future<void> _confirmClearMaterial() async {
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '移除素材',
      message: '确定移除已选素材吗？',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _mediaId = null;
      _mediaTitle = null;
      _media = null;
    });
  }

  Future<void> _pickTerminals() async {
    final result = await showOrdersTerminalPickDialog(
      context: context,
      initialSelectedIds: _terminalIds.toSet(),
      seedLabels: Map<int, String>.from(_terminalLabels),
    );
    if (result == null || !mounted) return;
    setState(() {
      _terminalIds
        ..clear()
        ..addAll(result.labels.keys);
      _terminalLabels
        ..clear()
        ..addAll(result.labels);
    });
  }

  OrderCreateItemEntity? _buildParam() {
    if (_mediaId == null) {
      showWarn('请选择素材');
      return null;
    }
    if (_contractRange == null) {
      showWarn('请选择合同时间');
      return null;
    }
    if (_sendRange == null) {
      showWarn('请选择上刊时间');
      return null;
    }
    if (_terminalIds.isEmpty) {
      showWarn('请选择绑定终端');
      return null;
    }
    if (_playRule == 2) {
      if (_coverStartTime == null || _coverEndTime == null) {
        showWarn('请选择定屏时间');
        return null;
      }
      if (!_coverEndTime!.isAfter(_coverStartTime!)) {
        showWarn('定屏结束时间须晚于开始时间');
        return null;
      }
    }

    final isFixedScreen = _playRule == 2;
    final item = OrderCreateItemEntity()
      ..media_id = _mediaId
      ..media_title = _mediaTitle
      ..start_time = _dateText(_contractRange!.start)
      ..end_time = _dateText(_contractRange!.end)
      ..send_time = _dateText(_sendRange!.start)
      ..send_end_time = _dateText(_sendRange!.end)
      ..duration = _duration
      ..order_frequency = _orderFrequency
      ..give_frequency = _giveFrequency
      ..exclusive_industry = List<int>.from(_industryIds)
      ..exclusive_rule = _exclusiveRule
      ..loop_rule = _loopRule
      ..order_pay = _orderPay
      ..play_rule = _playRule
      ..cover_start_time = isFixedScreen ? _dateTimeText(_coverStartTime) : ''
      ..cover_end_time = isFixedScreen ? _dateTimeText(_coverEndTime) : ''
      ..terminal_ids = _terminalIds.join(',');
    final detailId = widget.item?.id;
    if (!widget.isAdd) {
      if (detailId == null) {
        showWarn('发布单 ID 无效');
        return null;
      }
      item.id = detailId;
    }
    return item;
  }

  Future<void> _save() async {
    if (_saving) return;
    final param = _buildParam();
    if (param == null) return;

    setState(() => _saving = true);
    try {
      if (widget.isAdd) {
        await _c.addReleaseDetail(item: param);
      } else {
        final detailId = widget.item!.id;
        if (detailId == null) {
          showWarn('发布单 ID 无效');
          return;
        }
        await _c.editReleaseDetail(orderDetailId: detailId, item: param);
      }
      if (mounted) AppOverlay.close<void>(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// [AppNumberInput] 可能在 build 期经 TextField 回调 onChanged；此处避开同步 setState。
  void _setNumber(
    int Function() read,
    void Function(int value) write,
    int next,
  ) {
    if (read() == next) return;
    void apply() {
      if (!mounted || read() == next) return;
      setState(() => write(next));
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      apply();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return AppFormDialog(
      title: Text(widget.isAdd ? '添加发布单' : '编辑发布单'),
      constraints: const BoxConstraints(maxWidth: 720),
      content: SizedBox(
        width: 680,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AppCard(
            borderWidth: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: AppFieldScope.horizontal(
              labelWidth: _kLabelWidth,
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
                        if (_media != null)
                          AppCornerBadge(
                            position: AppCornerBadgePosition.topRight,
                            ignorePointer: false,
                            badge: MediaThumbRemoveBadge(
                              onPressed: _confirmClearMaterial,
                            ),
                            child: AppInkWell(
                              onPressed: _pickMaterial,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: AdMediaListThumb(media: _media!),
                              ),
                            ),
                          )
                        else
                          AppInkWell(
                            onPressed: _pickMaterial,
                            borderRadius: BorderRadius.circular(
                              ShadcnTheme.of(context).radiusMd,
                            ),
                            child: AppCard(
                              filled: false,
                              borderColor: colors.border,
                              borderWidth: 1,
                              shadow: false,
                              padding: EdgeInsets.zero,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: Icon(AppLucideIcons.plus, size: 20),
                                ),
                              ),
                            ),
                          ),
                        if (_mediaTitle?.trim().isNotEmpty == true)
                          Expanded(
                            child: AppText.body(_mediaTitle!, maxLines: 2),
                          ),
                      ],
                    ),
                  ),
                  AppField(
                    label: '素材类型',
                    child: AppRadioGroup<int>(
                      options: _kPayTypeOptions,
                      value: _orderPay,
                      onChanged: (value) => setState(() => _orderPay = value),
                    ),
                  ),
                  AppField(
                    label: '播放方式',
                    child: AppRadioGroup<int>(
                      options: _kPlayRuleOptions,
                      value: _playRule,
                      onChanged: (value) {
                        setState(() {
                          _playRule = value;
                          if (value == 2) {
                            final now = DateTime.now();
                            _coverStartTime ??= DateTime(
                              now.year,
                              now.month,
                              now.day,
                              now.hour,
                              now.minute,
                            );
                            _coverEndTime ??= _coverStartTime!.add(
                              const Duration(hours: 1),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  if (_playRule == 2)
                    AppField(
                      label: '定屏时间',
                      required: true,
                      child: Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: AppDateTimePicker(
                              value: _coverStartTime,
                              minuteStep: 1,
                              hintText: '开始时间',
                              onChanged: (value) =>
                                  setState(() => _coverStartTime = value),
                            ),
                          ),
                          Expanded(
                            child: AppDateTimePicker(
                              value: _coverEndTime,
                              minuteStep: 1,
                              hintText: '结束时间',
                              onChanged: (value) =>
                                  setState(() => _coverEndTime = value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppField(
                    label: '合同时间',
                    required: true,
                    child: AppDatePicker.range(
                      rangeValue: _contractRange,
                      hintText: '选择日期区间',
                      onRangeChanged: (range) =>
                          setState(() => _contractRange = range),
                    ),
                  ),
                  AppField(
                    label: '上刊时间',
                    required: true,
                    child: AppDatePicker.range(
                      rangeValue: _sendRange,
                      hintText: '选择日期区间',
                      onRangeChanged: (range) =>
                          setState(() => _sendRange = range),
                    ),
                  ),
                  _numberField(
                    label: '广告时长',
                    value: _duration,
                    unit: '秒',
                    min: 1,
                    onChanged: (value) => _setNumber(
                      () => _duration,
                      (v) => _duration = v,
                      value,
                    ),
                  ),
                  _numberField(
                    label: '合同频次',
                    value: _orderFrequency,
                    unit: '次',
                    min: 0,
                    onChanged: (value) => _setNumber(
                      () => _orderFrequency,
                      (v) => _orderFrequency = v,
                      value,
                    ),
                  ),
                  _numberField(
                    label: '赠送频次',
                    value: _giveFrequency,
                    unit: '次',
                    onChanged: (value) => _setNumber(
                      () => _giveFrequency,
                      (v) => _giveFrequency = v,
                      value,
                    ),
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
                          onPressed: _pickTerminals,
                          child: const Text('选择终端'),
                        ),
                        Expanded(
                          child: _terminalIds.isEmpty
                              ? AppText(
                                  '未选择终端',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                  ),
                                )
                              : Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: '已选 '),
                                      TextSpan(
                                        text: '${_terminalIds.length}',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' 台：${_terminalLabels.values.join('、')}',
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                  AppField(
                    label: '排他行业',
                    child: Obx(() {
                      final industryItems = _c.industryItems.toList();
                      return AppMultiSelect<int>(
                        key: ValueKey(
                          'edit-industry-${widget.item?.id}-${industryItems.length}',
                        ),
                        options: [
                          for (final item in industryItems)
                            if (item.id != null)
                              AppOption<int>(
                                value: item.id!,
                                label: item.category_name ?? '-',
                              ),
                        ],
                        value: _industryIds,
                        maxVisibleOptions: 3,
                        onChanged: (value) => setState(
                          () =>
                              _industryIds = List<int>.from(value ?? const []),
                        ),
                      );
                    }),
                  ),
                  _numberField(
                    label: '排他时长',
                    value: _exclusiveRule,
                    unit: '秒',
                    onChanged: (value) => _setNumber(
                      () => _exclusiveRule,
                      (v) => _exclusiveRule = v,
                      value,
                    ),
                  ),
                  _numberField(
                    label: '循环间隔',
                    value: _loopRule,
                    unit: '秒',
                    onChanged: (value) => _setNumber(
                      () => _loopRule,
                      (v) => _loopRule = v,
                      value,
                    ),
                  ),
                ],
              ).scroll(padding: EdgeInsets.zero),
            ),
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: _saving ? null : () => AppOverlay.close<void>(context),
          child: const Text('取消'),
        ),
        AppButton.primary(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isAdd ? '添加' : '保存'),
        ),
      ],
    );
  }
}
