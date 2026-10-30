import 'dart:async';

import 'package:dart_date/dart_date.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/order/order_monitor_create_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_feedback_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/device_detail/device_detail_title_icon.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';
import '../order_detail_controller.dart';
import '../order_detail_insets.dart';
import 'order_feedback_progress.dart';

TextStyle _monitorFieldLabelStyle(BuildContext context) =>
    ShadcnTheme.of(context).typography.small.copyWith();

Widget _monitorFieldLabel(
  BuildContext context,
  String label, {
  Widget? trailing,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Text(label, style: _monitorFieldLabelStyle(context)),
      if (trailing != null) trailing,
    ],
  );
}

/// 监测反馈 Tab：监测拍摄要求表单 + 反馈与进度。
class OrderFeedbackTab extends StatefulWidget {
  const OrderFeedbackTab({required this.controller, super.key});

  final OrderDetailController controller;

  @override
  State<OrderFeedbackTab> createState() => _OrderFeedbackTabState();
}

class _OrderFeedbackTabState extends State<OrderFeedbackTab> {
  final _form = AppFormController();
  final _timeFieldKey = GlobalKey<FormFieldState<List<int>>>();
  final _distanceFieldKey = GlobalKey<FormFieldState<List<int>>>();
  final _watermarkFieldKey = GlobalKey<FormFieldState<List<int>>>();

  static const _countOptions = <AppOption<int>>[
    AppOption(value: 1, label: '1次'),
    AppOption(value: 2, label: '2次'),
    AppOption(value: 3, label: '3次'),
    AppOption(value: 4, label: '4次'),
    AppOption(value: 5, label: '5次'),
    AppOption(value: 6, label: '6次'),
    AppOption(value: 7, label: '7次'),
    AppOption(value: 8, label: '8次'),
    AppOption(value: 9, label: '9次'),
    AppOption(value: 10, label: '10次'),
  ];

  static const _intervalOptions = <AppOption<int>>[
    AppOption(value: 1, label: '1次/1天'),
    AppOption(value: 7, label: '1次/7天'),
    AppOption(value: 15, label: '1次/15天'),
    AppOption(value: 30, label: '1次/30天'),
  ];

  static const _kNoneId = 0;

  static const _timeOptions = <AppOption<int>>[
    AppOption(value: 0, label: '无要求'),
    AppOption(value: 1, label: '白天'),
    AppOption(value: 2, label: '夜间'),
  ];

  static const _distanceOptions = <AppOption<int>>[
    AppOption(value: 0, label: '无要求'),
    AppOption(value: 1, label: '近景'),
    AppOption(value: 2, label: '中景'),
    AppOption(value: 3, label: '远景'),
  ];

  static const _watermarkOptions = <AppOption<int>>[
    AppOption(value: 0, label: '无要求'),
    AppOption(value: 1, label: '有'),
    AppOption(value: 2, label: '无'),
  ];

  static const _watermarkStyleOptions = <AppOption<int>>[
    AppOption(value: 0, label: '无要求'),
    AppOption(value: 1, label: '报纸'),
    AppOption(value: 2, label: '媒花录水印相机'),
    AppOption(value: 3, label: '其他水印相机'),
  ];

  int _count = 3;
  int _intervalDays = 7;
  String _sendTime = '-';
  List<int> _timeValues = const [_kNoneId];
  List<int> _distanceValues = const [_kNoneId];
  List<int> _watermarkValues = const [_kNoneId];
  int _watermarkStyle = _kNoneId;
  String _other = '';
  int _formRevision = 0;
  Worker? _releaseWorker;

  OrderDetailController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.saveMonitorFeedback = _save;
    _releaseWorker = ever(_c.selectedReleaseKey, (_) {
      unawaited(_reload());
    });
    unawaited(_reload());
  }

  @override
  void dispose() {
    _releaseWorker?.dispose();
    if (_c.saveMonitorFeedback == _save) {
      _c.saveMonitorFeedback = null;
    }
    _form.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await _c.loadMonitorFeedback();
    if (!mounted) return;
    _applyFeedback(_c.monitorFeedback.value);
  }

  void _applyFeedback(OrderMonitorFeedbackEntity? feedback) {
    final config = feedback?.config;
    final sendTime = feedback?.send_time?.trim();
    final releaseSend = _c.selectedRelease?.send_time?.trim();
    setState(() {
      _count = config?.monitor_count ?? 3;
      _intervalDays = config?.interval_days ?? 7;
      _sendTime = (sendTime != null && sendTime.isNotEmpty)
          ? sendTime
          : ((releaseSend != null && releaseSend.isNotEmpty)
                ? releaseSend
                : '-');
      _timeValues = _listFieldValues(config?.time_types);
      _distanceValues = _listFieldValues(config?.distance_types);
      _watermarkValues = _listFieldValues(config?.watermark_types);
      _watermarkStyle = _styleFieldValue(config?.watermark_style);
      _other = config?.other_remark?.trim() ?? '';
      _formRevision++;
    });
  }

  List<int> _listFieldValues(List<int>? values) {
    if (values == null || values.isEmpty) return const [_kNoneId];
    return _sanitizeLoadedValues(List<int>.from(values));
  }

  int _styleFieldValue(int? value) => value ?? _kNoneId;

  String? _requireRadioGroup(int? value) {
    if (value == null) return '请选择一项';
    return null;
  }

  List<int> _sanitizeLoadedValues(List<int> values) {
    if (values.isEmpty) return const [_kNoneId];
    final hasNone = values.contains(_kNoneId);
    final others = values.where((id) => id != _kNoneId).toList();
    if (hasNone && others.isNotEmpty) return others;
    if (hasNone) return const [_kNoneId];
    return others;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return setA.length == b.length && setA.containsAll(b);
  }

  /// 「无要求(0)」与其它选项互斥；至少保留一项。
  List<int> _normalizeExclusiveNone(List<int> next, List<int> previous) {
    if (next.isEmpty) {
      return previous.isNotEmpty ? List<int>.from(previous) : const [_kNoneId];
    }

    final hadNone = previous.contains(_kNoneId);
    final hasNone = next.contains(_kNoneId);
    final others = next.where((id) => id != _kNoneId).toList();

    if (hasNone && others.isNotEmpty) {
      if (!hadNone) return const [_kNoneId];
      return others;
    }

    if (hasNone) return const [_kNoneId];
    return others;
  }

  void _onExclusiveGroupChanged({
    required GlobalKey<FormFieldState<List<int>>> fieldKey,
    required List<int> next,
    required List<int> previous,
    required ValueChanged<List<int>> onValuesChanged,
  }) {
    final normalized = _normalizeExclusiveNone(next, previous);
    onValuesChanged(normalized);
    if (!_listEquals(normalized, next)) {
      fieldKey.currentState?.didChange(normalized);
    }
  }

  String? _requireCheckboxGroup(List<int>? value) {
    if (value == null || value.isEmpty) return '请至少选择一项';
    return null;
  }

  List<int> _formValues(List<int>? values) {
    if (values == null || values.isEmpty) return const [_kNoneId];
    return List<int>.from(values);
  }

  String _baseDate() {
    if (_sendTime != '-') return _sendTime;
    final fromConfig = _c.monitorFeedback.value?.config?.base_date?.trim();
    if (fromConfig != null && fromConfig.isNotEmpty) return fromConfig;
    return DateTime.now().format('yyyy-MM-dd');
  }

  DateTime _parseBaseDateTime() {
    final parsed = DateTime.tryParse(_baseDate().trim());
    if (parsed != null) return parsed;
    return DateTime.now();
  }

  List<String> get _generatedPeriodDates =>
      _buildPeriodStartsFor(_count, _intervalDays);

  List<String> _buildPeriodStartsFor(int count, int intervalDays) {
    final base = _parseBaseDateTime();
    return [
      for (var i = 0; i < count; i++)
        base.add(Duration(days: intervalDays * i)).format('yyyy-MM-dd'),
    ];
  }

  OrderMonitorCreateEntity? _buildSaveParam(Map<String, Object?> values) {
    final orderNo = _c.orderNo;
    if (orderNo == '-') {
      showWarn('订单编号无效');
      return null;
    }
    final detailId = _c.selectedRelease?.id;
    if (detailId == null) {
      showWarn('请先选择发布单');
      return null;
    }

    final count = values['detectCount'] as int? ?? _count;
    final intervalDays = values['intervalDays'] as int? ?? _intervalDays;
    final timeTypes = _formValues(values['timeOptions'] as List<int>?);
    final distanceTypes = _formValues(values['distance'] as List<int>?);
    final watermarkTypes = _formValues(values['watermark'] as List<int>?);
    final watermarkStyle = values['watermarkStyle'] as int? ?? _watermarkStyle;
    final otherRemark = (values['other'] as String? ?? _other).trim();

    return OrderMonitorCreateEntity()
      ..order_no = orderNo
      ..order_detail_id = detailId
      ..monitor_count = count
      ..base_date = _parseBaseDateTime().format('yyyy-MM-dd')
      ..interval_days = intervalDays
      ..period_starts = _buildPeriodStartsFor(count, intervalDays)
      ..time_types = timeTypes
      ..distance_types = distanceTypes
      ..watermark_types = watermarkTypes
      ..watermark_style = watermarkStyle
      ..other_remark = otherRemark;
  }

  Future<void> _save() async {
    if (_c.monitorSaving.value) return;
    if (!_isMonitorRequirementsEditable(_c.monitorFeedback.value)) {
      showWarn('当前监测要求不可编辑');
      return;
    }
    if (_c.selectedRelease?.id == null) {
      showWarn('请先选择素材');
      return;
    }
    final submitted = await _form.submit((values) async {
      final param = _buildSaveParam(values);
      if (param == null) return;
      await _c.saveMonitorFeedbackConfig(param);
      if (!mounted) return;
      _applyFeedback(_c.monitorFeedback.value);
    });
    if (!submitted && mounted) {
      showWarn('请完善监测拍摄要求');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return Column(
      spacing: 20,
      children: [
        _FeedbackMaterialsBar(controller: _c),
        Obx(() {
          if (_c.monitorLoading.value) {
            return const Center(
              child: AppCircularProgressIndicator(),
            ).expanded();
          }
          final feedback = _c.monitorFeedback.value;
          final editable = _isMonitorRequirementsEditable(feedback);
          return Column(
            spacing: 20,
            children: [
              AppForm(
                key: ValueKey('monitor-form-$_formRevision'),
                controller: _form,
                child: AppCard(
                  borderRadius: BorderRadius.circular(24),
                  borderWidth: 0,
                  child: AppDescriptions.custom(
                    title: const Text('监测拍摄要求'),
                    titleIcon: deviceDetailTitleIcon(
                      context,
                      AppLucideIcons.clipboardList,
                    ),
                    actions: editable
                        ? Obx(
                            () => AppButton.primary(
                              config: const AppButtonConfig(height: 28),
                              color: const Color(0xFF00A0EC),
                              loading: _c.monitorSaving.value,
                              // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
                              onPressed: _c.monitorSaving.value
                                  ? null
                                  : () {
                                      unawaited(_save());
                                    },
                              child: const Text('保存'),
                            ),
                          )
                        : null,
                    child: AppFieldScope(
                      config: const AppFieldConfig(gap: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 20,
                              children: [
                                AppSelectFormField<int>(
                                  name: 'detectCount',
                                  label: '监测次数',
                                  hintText: '请选择',
                                  width: 140,
                                  initialValue: _count,
                                  enabled: editable,
                                  options: _countOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _count = value);
                                  },
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _monitorFieldLabel(
                                      context,
                                      '监测日期',
                                      trailing: Icon(
                                        AppLucideIcons.info,
                                        size: 14,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        AppText.caption(
                                          '上刊时间',
                                          style: TextStyle(
                                            color: colors.mutedForeground,
                                          ),
                                        ),
                                        Container(
                                          width: 160,
                                          height:
                                              AppControlMetricsScope.resolve(
                                                context,
                                              ).height,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: colors.muted,
                                            border: Border.all(
                                              color: colors.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              ShadcnTheme.of(context).radiusMd,
                                            ),
                                          ),
                                          child: Text(
                                            _sendTime == '-' ? '' : _sendTime,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.mutedForeground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                AppSelectFormField<int>(
                                  name: 'intervalDays',
                                  label: '间隔天数',
                                  hintText: '请选择',
                                  width: 160,
                                  initialValue: _intervalDays,
                                  enabled: editable,
                                  options: _intervalOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _intervalDays = value);
                                  },
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _monitorFieldLabel(context, '生成日期'),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < _generatedPeriodDates.length;
                                          i++
                                        )
                                          AppTextFormField(
                                            key: ValueKey(
                                              'generated-date-$i-'
                                              '$_count-$_intervalDays-$_sendTime',
                                            ),
                                            readOnly: true,
                                            enabled: false,
                                            width: 160,
                                            initialValue:
                                                _generatedPeriodDates[i],
                                            leading: Icon(
                                              AppLucideIcons.calendar,
                                              size: 16,
                                              color: colors.mutedForeground,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          AppCheckboxGroupFormField<int>(
                            key: _timeFieldKey,
                            name: 'timeOptions',
                            label: '时间选项',
                            layout: AppFieldLayout.horizontal,
                            labelWidth: 72,
                            required: true,
                            enabled: editable,
                            initialValue: _timeValues,
                            options: _timeOptions,
                            validator: _requireCheckboxGroup,
                            onChanged: (next) => _onExclusiveGroupChanged(
                              fieldKey: _timeFieldKey,
                              next: next,
                              previous: _timeValues,
                              onValuesChanged: (v) =>
                                  setState(() => _timeValues = v),
                            ),
                          ),
                          AppCheckboxGroupFormField<int>(
                            key: _distanceFieldKey,
                            name: 'distance',
                            label: '拍摄距离',
                            layout: AppFieldLayout.horizontal,
                            labelWidth: 72,
                            required: true,
                            enabled: editable,
                            initialValue: _distanceValues,
                            options: _distanceOptions,
                            validator: _requireCheckboxGroup,
                            onChanged: (next) => _onExclusiveGroupChanged(
                              fieldKey: _distanceFieldKey,
                              next: next,
                              previous: _distanceValues,
                              onValuesChanged: (v) =>
                                  setState(() => _distanceValues = v),
                            ),
                          ),
                          AppCheckboxGroupFormField<int>(
                            key: _watermarkFieldKey,
                            name: 'watermark',
                            label: '水印',
                            layout: AppFieldLayout.horizontal,
                            labelWidth: 72,
                            required: true,
                            enabled: editable,
                            initialValue: _watermarkValues,
                            options: _watermarkOptions,
                            validator: _requireCheckboxGroup,
                            onChanged: (next) => _onExclusiveGroupChanged(
                              fieldKey: _watermarkFieldKey,
                              next: next,
                              previous: _watermarkValues,
                              onValuesChanged: (v) =>
                                  setState(() => _watermarkValues = v),
                            ),
                          ),
                          AppRadioGroupFormField<int>(
                            name: 'watermarkStyle',
                            label: '水印样式',
                            layout: AppFieldLayout.horizontal,
                            labelWidth: 72,
                            required: true,
                            enabled: editable,
                            initialValue: _watermarkStyle,
                            options: _watermarkStyleOptions,
                            validator: _requireRadioGroup,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _watermarkStyle = value);
                            },
                          ),
                          AppFieldScope.horizontal(
                            labelWidth: 72,
                            child: AppTextFormField(
                              name: 'other',
                              label: '其他要求',
                              hintText: '请输入其他信息',
                              enabled: editable,
                              initialValue: _other,
                              onChanged: (v) => _other = v,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              OrderFeedbackProgressCard(controller: _c, feedback: feedback),
            ],
          ).scroll(padding: kOrderDetailPagePadding).expanded();
        }),
      ],
    );
  }
}

/// 监测配置是否可编辑：已保存（有 config.id）或接口显式不可编辑时为只读。
bool _isMonitorRequirementsEditable(OrderMonitorFeedbackEntity? feedback) {
  if (feedback == null) return true;
  if (feedback.editable == false) return false;
  if (feedback.config?.id != null) return false;
  return true;
}

/// 监测反馈顶栏：素材 Tab，与 [OrderDetailController.selectedRelease] 联动。
class _FeedbackMaterialsBar extends StatelessWidget {
  const _FeedbackMaterialsBar({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.releaseRevision.value;
      final materials = controller.releaseItems;
      if (materials.isEmpty) return const SizedBox.shrink();

      final selectedKey = controller.selectedReleaseKey.value;
      var selectedIndex = 0;
      for (var i = 0; i < materials.length; i++) {
        if (controller.releaseRowKey(materials[i]) == selectedKey) {
          selectedIndex = i;
          break;
        }
      }

      return Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: AppTabs(
            index: selectedIndex,
            onChanged: (index) {
              if (index < 0 || index >= materials.length) return;
              controller.selectRelease(materials[index]);
            },
            selectedColor: const Color(0xFFFFFFFF),
            children: [
              for (var i = 0; i < materials.length; i++)
                AppTabItem(child: Text('订单${i + 1}')),
            ],
          ),
        ),
      );
    });
  }
}
