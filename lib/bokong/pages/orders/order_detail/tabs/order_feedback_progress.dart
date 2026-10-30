import 'package:dart_date/dart_date.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import 'package:yidivination/bokong/entity/order/order_monitor_feedback_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/device_detail/device_detail_title_icon.dart';
import 'package:yidivination/bokong/pages/orders/order_detail/dialogs/order_monitor_group_media_dialog.dart';
import 'package:yidivination/bokong/pages/orders/order_detail/order_detail_controller.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 反馈与进度卡片：总体进度 + 拍摄矩阵。
class OrderFeedbackProgressCard extends StatelessWidget {
  const OrderFeedbackProgressCard({
    required this.controller,
    this.feedback,
    super.key,
  });

  final OrderDetailController controller;
  final OrderMonitorFeedbackEntity? feedback;

  static const _indexWidth = 56.0;
  static const _dateWidth = 120.0;
  static const _shotWidth = 184.0;
  static const _doneBg = Color(0xFFF0FDF4);
  static const _rowHeight = 120.0;
  static const _progressTextStyle = TextStyle(fontSize: 14);

  double get _progress {
    final raw = feedback?.progress?.percent?.trim();
    final parsed = double.tryParse(raw ?? '');
    if (parsed != null) return parsed / 100;
    final total = feedback?.progress?.total ?? 0;
    if (total <= 0) return 0;
    return (feedback?.progress?.completed ?? 0) / total;
  }

  int get _completedCount => feedback?.progress?.completed ?? 0;

  int get _totalCount => feedback?.progress?.total ?? 0;

  List<OrderMonitorComboColumnEntity> get _columns {
    final cols = feedback?.combo_columns ?? const [];
    return [...cols]..sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
  }

  List<OrderMonitorPeriodEntity> get _periods {
    final items = feedback?.periods ?? const [];
    return [...items]
      ..sort((a, b) => (a.period_index ?? 0).compareTo(b.period_index ?? 0));
  }

  double get _tableWidth =>
      _indexWidth + _dateWidth + _shotWidth * _columns.length;

  AppTableCell _headerCell(String text) {
    return AppTableCell(
      alignment: Alignment.center,
      child: AppText.caption(text, style: kTableHeaderTextStyle),
    );
  }

  OrderMonitorPeriodGroupEntity? _groupFor(
    OrderMonitorPeriodEntity period,
    OrderMonitorComboColumnEntity column,
  ) {
    final target = column.col_index;
    if (target == null) return null;
    for (final group in period.groups ?? const []) {
      if (group.col_index == target) return group;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final columns = _columns;
    final periods = _periods;

    return AppCard(
      borderRadius: BorderRadius.circular(24),
      borderWidth: 0,
      child: AppDescriptions.custom(
        title: const Text('反馈与进度'),
        titleIcon: deviceDetailTitleIcon(context, AppLucideIcons.calendarCheck),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Icon(
                  AppMaterialIcons.circle,
                  size: 8,
                  color: Color(0xFF16A34A),
                ),
                AppText.body('已完成拍摄', style: _progressTextStyle),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                AppText.body('总体进度', style: _progressTextStyle),
                AppProgress(
                  progress: _progress,
                  color: colors.primary,
                ).size(width: 120, height: 6),
                AppText.body(
                  '${(_progress * 100).round()}%',
                  style: _progressTextStyle.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppText.body(
                  '已完成 ($_completedCount/$_totalCount)',
                  style: _progressTextStyle,
                ),
              ],
            ),
          ],
        ),
        child: columns.isEmpty || periods.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: AppText.muted('暂无反馈数据')),
              )
            : SizedBox(
                width: double.infinity,
                child: ScrollConfiguration(
                  behavior: const _HorizontalDragScrollBehavior(),
                  child: AppScrollbarView(
                    scrollDirection: Axis.horizontal,
                    thumbVisibility: true,
                    child: SizedBox(
                      width: _tableWidth,
                      child: AppTable(
                        headerHeight: 36,
                        rowHeight: _rowHeight,
                        cellPadding: EdgeInsets.zero,
                        headerBackgroundColor: kTableHeaderBackground,
                        columnWidths: {
                          0: const FixedColumnWidth(_indexWidth),
                          1: const FixedColumnWidth(_dateWidth),
                          for (var i = 0; i < columns.length; i++)
                            i + 2: const FixedColumnWidth(_shotWidth),
                        },
                        rows: [
                          AppTableHeader(
                            cells: [
                              _headerCell('序号'),
                              _headerCell('监测日期'),
                              for (var i = 0; i < columns.length; i++)
                                _headerCell('拍摄 ${i + 1}'),
                            ],
                          ),
                          for (final period in periods)
                            AppTableRow(
                              cells: [
                                AppTableCell(
                                  alignment: Alignment.center,
                                  child: AppText.caption(
                                    '${period.period_index ?? '-'}',
                                  ),
                                ),
                                AppTableCell(
                                  alignment: Alignment.center,
                                  child: _PeriodDateCell(
                                    controller: controller,
                                    period: period,
                                  ),
                                ),
                                for (final column in columns)
                                  AppTableCell(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                    child: _ShotCell(
                                      controller: controller,
                                      group: _groupFor(period, column),
                                      doneBg: _doneBg,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PeriodDateCell extends StatefulWidget {
  const _PeriodDateCell({required this.controller, required this.period});

  final OrderDetailController controller;
  final OrderMonitorPeriodEntity period;

  @override
  State<_PeriodDateCell> createState() => _PeriodDateCellState();
}

class _PeriodDateCellState extends State<_PeriodDateCell> {
  var _saving = false;

  shad.DateTimeRange? get _range {
    final start = _parseDate(widget.period.monitor_date);
    if (start == null) return null;
    final end = _parseDate(widget.period.monitor_end_date) ?? start;
    return shad.DateTimeRange(start, end);
  }

  DateTime? _parseDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _onRangeChanged(shad.DateTimeRange? range) async {
    if (range == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.updateMonitorPeriod(
        period: widget.period,
        monitorDate: range.start.format('yyyy-MM-dd'),
        monitorEndDate: range.end.format('yyyy-MM-dd'),
      );
    } catch (e) {
      showError('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime value) => value.format('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final hint = widget.period.date_label ?? '选择日期';
    // 待上游：AppDatePicker.range 支持 rangeLabelBuilder（竖排起止日期）。
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: shad.ObjectFormField<shad.DateTimeRange>(
        value: _range,
        onChanged: _onRangeChanged,
        enabled: !_saving,
        mode: shad.PromptMode.popover,
        immediateValueChange: false,
        placeholder: Text(hint),
        builder: (context, value) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(_formatDate(value.start)),
            Text(_formatDate(value.end)),
          ],
        ),
        editorBuilder: (context, handler) =>
            _PeriodRangeDateEditor(handler: handler),
      ),
    );
  }
}

/// 区间日期弹层编辑器（对齐 AppDatePicker.range 的确认/取消行为）。
class _PeriodRangeDateEditor extends StatefulWidget {
  const _PeriodRangeDateEditor({required this.handler});

  final shad.ObjectFormHandler<shad.DateTimeRange> handler;

  @override
  State<_PeriodRangeDateEditor> createState() => _PeriodRangeDateEditorState();
}

class _PeriodRangeDateEditorState extends State<_PeriodRangeDateEditor> {
  late final shad.DateTimeRange? _initialValue = widget.handler.value;
  late shad.DateTimeRange? _value = _initialValue;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          shad.DatePickerDialog(
            initialViewType: shad.CalendarViewType.date,
            selectionMode: shad.CalendarSelectionMode.range,
            viewMode: MediaQuery.sizeOf(context).width < 500
                ? shad.CalendarSelectionMode.single
                : shad.CalendarSelectionMode.range,
            initialValue: _value == null
                ? null
                : shad.CalendarValue.range(_value!.start, _value!.end),
            onChanged: (value) {
              final range = value?.toRange();
              setState(() {
                _value = range == null
                    ? null
                    : shad.DateTimeRange(range.start, range.end);
              });
            },
          ),
          Row(
            children: [
              AppButton.text(
                onPressed: () {
                  widget.handler.value = null;
                  widget.handler.close();
                },
                child: const Text('清空'),
              ),
              const Spacer(),
              AppButton.outline(
                onPressed: () {
                  widget.handler.value = _initialValue;
                  widget.handler.close();
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              AppButton.primary(
                onPressed: () {
                  widget.handler.value = _value;
                  widget.handler.close();
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShotCell extends StatelessWidget {
  const _ShotCell({
    required this.controller,
    required this.group,
    required this.doneBg,
  });

  final OrderDetailController controller;
  final OrderMonitorPeriodGroupEntity? group;
  final Color doneBg;

  void _openMediaDialog(BuildContext context, {bool autoUpload = false}) {
    final groupId = group?.group_id;
    if (groupId == null) return;
    showOrderMonitorGroupMediaDialog(
      context,
      controller: controller,
      groupId: groupId,
      autoUpload: autoUpload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    if (group == null) {
      return const SizedBox.expand();
    }

    final required = group!.required_count ?? 0;
    final maxUpload = group!.max_upload_count ?? 10;
    final done = group!.completed_count ?? 0;
    final completed =
        group!.is_completed == true || (required > 0 && done >= required);

    final body = Column(
      children: [
        ColoredBox(
          color: kTableHeaderBackground,
          child: SizedBox(
            width: double.infinity,
            height: 28,
            child: Center(
              child: AppText.caption(
                group!.time_label ?? '-',
                style: TextStyle(color: colors.mutedForeground),
              ),
            ),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: completed ? doneBg : null),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(
                    AppLucideIcons.camera,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                  AppText.caption('($done/$maxUpload)'),
                  AppText.caption(group!.watermark_label ?? '-'),
                  AppText.caption(group!.distance_label ?? '-'),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return AppHoverOverlay(
      overlay: ColoredBox(
        color: const Color(0xFF000000).withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              AppButton.primary(
                size: AppButtonSize.small,
                onPressed: () => _openMediaDialog(context),
                child: const Text('查看'),
              ),
              AppButton.primary(
                size: AppButtonSize.small,
                color: const Color(0xFFE11D48),
                onPressed: () => _openMediaDialog(context, autoUpload: true),
                child: const Text('上传照片'),
              ),
            ],
          ),
        ),
      ),
      child: body,
    );
  }
}

/// 桌面端允许鼠标拖拽横向滚动（默认 ScrollBehavior 不含 mouse）。
class _HorizontalDragScrollBehavior extends ScrollBehavior {
  const _HorizontalDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
