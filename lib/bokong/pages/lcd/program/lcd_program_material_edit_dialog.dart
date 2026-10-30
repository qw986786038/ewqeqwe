import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_exclusive_industry_field.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_material_utils.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';

const double _kLabelWidth = 88;

const List<AppOption<int>> _kPlayRuleOptions = <AppOption<int>>[
  AppOption<int>(value: 1, label: '循环播放'),
  AppOption<int>(value: 2, label: '定屏播放'),
];

shad.DateTimeRange? _dateTimeRangeOf(int? start, int? end) {
  if (start == null || end == null) return null;
  return shad.DateTimeRange(
    DateTime.fromMillisecondsSinceEpoch(start),
    DateTime.fromMillisecondsSinceEpoch(end),
  );
}

String _dateText(int? millis, {String format = 'yyyy-MM-dd'}) {
  if (millis == null) return '';
  return millis.date2(format);
}

int? _parseDateMillis(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value.split(' ').first)?.millisecondsSinceEpoch;
}

int _playRuleOf(int? playRule) {
  final int id = playRule ?? 1;
  for (final AppOption<int> option in _kPlayRuleOptions) {
    if (option.value == id) return id;
  }
  return _kPlayRuleOptions.first.value;
}

class _LcdProgramMaterialEditDialog extends StatefulWidget {
  const _LcdProgramMaterialEditDialog({required this.material});

  final LcdProgramMaterialEntity material;

  @override
  State<_LcdProgramMaterialEditDialog> createState() =>
      _LcdProgramMaterialEditDialogState();
}

class _LcdProgramMaterialEditDialogState
    extends State<_LcdProgramMaterialEditDialog> {
  late int _playRule = _playRuleOf(widget.material.order_detail_play_rule);
  late int? _startTime = _parseDateMillis(widget.material.start_time);
  late int? _endTime = _parseDateMillis(widget.material.end_time);
  late int? _sendTime = _parseDateMillis(
    widget.material.order_detail_send_time ?? widget.material.start_time,
  );
  late int _duration =
      widget.material.duration ?? widget.material.media_duration ?? 15;
  late int _orderFrequency = widget.material.order_frequency ?? 1;
  late int _nowFrequency =
      widget.material.now_frequency ?? widget.material.order_frequency ?? 1;
  late int _exclusiveRule =
      int.tryParse(widget.material.exclusive_rule?.trim() ?? '') ?? 0;
  late int _loopRule = widget.material.loop_rule ?? 120;

  List<AdContentGroupEntity> _industryItems = [];
  Set<int> _industryIds = {};

  @override
  void initState() {
    super.initState();
    _reloadIndustryItems();
  }

  Future<void> _reloadIndustryItems() async {
    final resp = await LcdApi.contentGroupList(page: 1, size: 500);
    final List<AdContentGroupEntity> items = resp.data ?? [];
    if (!mounted) return;
    setState(() {
      _industryItems = items;
      _industryIds = parseExclusiveIndustryIds(
        widget.material.exclusive_industry,
        items,
      );
    });
  }

  /// 校验并保存；成功返回 `true`（由保存按钮关窗）。
  Future<bool> _save() async {
    if (_startTime == null || _endTime == null) {
      showWarn('请选择上下刊时间');
      return false;
    }
    if (_sendTime == null) {
      showWarn('请选择发布时间');
      return false;
    }
    final int? programId = widget.material.id;
    if (programId == null) {
      showWarn('节目 ID 无效');
      return false;
    }

    await updateProgramMaterial(
      material: widget.material,
      mediaParams: <String, dynamic>{
        'start_time': _dateText(_startTime),
        'end_time': _dateText(_endTime),
        'send_time': _dateText(_sendTime),
        'duration': _duration,
        'order_frequency': _orderFrequency,
        'now_frequency': _nowFrequency,
        'play_rule': _playRule,
      },
      industryIds: _industryIds,
      exclusiveRule: _exclusiveRule,
      loopRule: _loopRule,
    );
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
    final String materialTitle =
        widget.material.media_title?.trim().isNotEmpty == true
        ? widget.material.media_title!.trim()
        : (widget.material.order_no ?? '-');
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: const Text('编辑素材'),
      constraints: const BoxConstraints(minWidth: 720, maxWidth: 800),
      content: ConstrainedBox(
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
                  label: '节目名称',
                  child: AppText(
                    materialTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppField(
                  label: '播放方式',
                  child: AppRadioGroup<int>(
                    options: _kPlayRuleOptions,
                    value: _playRule,
                    onChanged: (value) => setState(() => _playRule = value),
                  ),
                ),
                AppField(
                  label: '上下刊时间',
                  required: true,
                  child: AppDatePicker.range(
                    rangeValue: _dateTimeRangeOf(_startTime, _endTime),
                    hintText: '选择日期区间',
                    onRangeChanged: (range) => setState(() {
                      _startTime = range?.start.millisecondsSinceEpoch;
                      _endTime = range?.end.millisecondsSinceEpoch;
                    }),
                  ),
                ),
                AppField(
                  label: '发布时间',
                  required: true,
                  child: AppDatePicker(
                    value: _sendTime == null
                        ? null
                        : DateTime.fromMillisecondsSinceEpoch(_sendTime!),
                    hintText: '选择日期',
                    onChanged: (value) => setState(
                      () => _sendTime = value?.millisecondsSinceEpoch,
                    ),
                  ),
                ),
                _numberField(
                  label: '广告时长',
                  value: _duration,
                  unit: '秒',
                  min: 1,
                  onChanged: (value) => setState(() => _duration = value),
                ),
                _numberField(
                  label: '订单日播频次',
                  value: _orderFrequency,
                  unit: '次',
                  min: 1,
                  onChanged: (value) => setState(() => _orderFrequency = value),
                ),
                _numberField(
                  label: '设定日播频次',
                  value: _nowFrequency,
                  unit: '次',
                  min: 1,
                  onChanged: (value) => setState(() => _nowFrequency = value),
                ),
                LcdProgramExclusiveIndustryField(
                  key: ValueKey(
                    'edit-industry-${widget.material.id}-${widget.material.exclusive_industry}-${_industryItems.length}',
                  ),
                  items: _industryItems,
                  reload: _reloadIndustryItems,
                  initialValue: _industryIds,
                  onChanged: (value) =>
                      setState(() => _industryIds = Set<int>.from(value)),
                ),
                _numberField(
                  label: '排他时长',
                  value: _exclusiveRule,
                  unit: '秒',
                  onChanged: (value) => setState(() => _exclusiveRule = value),
                ),
                _numberField(
                  label: '循环间隔',
                  value: _loopRule,
                  unit: '秒',
                  min: 1,
                  onChanged: (value) => setState(() => _loopRule = value),
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

/// 打开「编辑素材」弹窗；提交成功返回 `true`。
Future<bool> showLcdProgramMaterialEditDialog({
  required BuildContext context,
  required LcdProgramMaterialEntity material,
}) async {
  final int? mediaId = resolveProgramMaterialMediaId(material);
  if (mediaId == null) {
    showWarn('无法获取素材库 ID');
    return false;
  }

  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  final bool? submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(720, initialHeight),
    builder: (dialogContext) =>
        _LcdProgramMaterialEditDialog(material: material),
  ).future;
  return submitted == true;
}
