import 'dart:async';
import 'dart:typed_data';
import 'package:yidivination/bokong/widget/app_empty_state.dart';

import 'package:yidivination/bokong/api/common_api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/pages/preview/preview_dialog_layout.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart' hide AppText;
import 'package:yidivination/bokong/widget/app_text.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

const double _dialogMaxContentWidth = 1300;
const double _dialogMinContentWidth = 780;
const double _dialogMaxContentHeight = 800;
const double _dialogHeightFactor = 0.82;

/// 节目单预览弹窗：展示 [preview_sheet] 接口返回的已排序列表。
Future<void> showLcdProgramPreviewDialog({
  required BuildContext context,
  required int scheduleId,
  String? date,
  int? terminalId,
  String? terminalDeviceNo,
}) {
  final double screenWidth = MediaQuery.sizeOf(context).width;
  final double contentHeight =
      (previewDialogMaxContentHeight(context) * _dialogHeightFactor).clamp(
        260,
        _dialogMaxContentHeight,
      );
  final double contentWidth = (screenWidth - 96).clamp(
    _dialogMinContentWidth,
    _dialogMaxContentWidth,
  );
  final String deviceNo = terminalDeviceNo?.trim() ?? '';
  final String title = deviceNo.isNotEmpty ? '节目单预览 · 设备号：$deviceNo' : '节目单预览';

  return showAppWindowDialog<void>(
    context: context,
    barrierDismissible: true,
    resizable: true,
    initialSize: Size(
      contentWidth + previewDialogWidthPadding,
      contentHeight + 120,
    ),
    builder: (dialogContext) => AppFormDialog(
      title: Text(title),
      constraints: BoxConstraints(
        minWidth: contentWidth + previewDialogWidthPadding,
      ),
      content: SizedBox(
        width: contentWidth,
        height: contentHeight,
        child: LcdProgramPreviewContent(
          scheduleId: scheduleId,
          date: date,
          terminalId: terminalId,
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<void>(dialogContext),
          child: const Text('关闭'),
        ),
      ],
    ),
  ).future;
}

class LcdProgramPreviewContent extends StatefulWidget {
  const LcdProgramPreviewContent({
    super.key,
    required this.scheduleId,
    this.date,
    this.terminalId,
  });

  final int scheduleId;
  final String? date;
  final int? terminalId;

  @override
  State<LcdProgramPreviewContent> createState() =>
      _LcdProgramPreviewContentState();
}

class _LcdProgramPreviewContentState extends State<LcdProgramPreviewContent> {
  final List<LcdProgramMaterialEntity> _materials =
      <LcdProgramMaterialEntity>[];
  bool _loading = true;
  bool _exporting = false;

  List<AppDataGridColumn<LcdProgramMaterialEntity>>
  get _columns => <AppDataGridColumn<LcdProgramMaterialEntity>>[
    _previewGridColumn(
      title: '序号',
      width: 56,
      value: (row) => _materials.indexOf(row) + 1,
    ),
    _previewGridColumn(
      title: '节目名称',
      minWidth: 120,
      value: (row) => row.media_title ?? '-',
    ),
    _previewGridColumn(
      title: '行业分类',
      minWidth: 100,
      value: (row) => row.customer_industry ?? '-',
      cellBuilder: (c, row, _) => _previewIndustryTag(row),
    ),
    _previewGridColumn(
      title: '广告时长',
      width: 88,
      value: (row) => _previewDurationLabel(row),
    ),
    _previewGridColumn(
      title: '订单频次',
      width: 88,
      value: (row) => _previewFreqLabel(row.order_frequency),
    ),
    _previewGridColumn(
      title: '有无排它',
      width: 88,
      value: (row) => _previewHasExclusiveLabel(row),
      cellBuilder: (c, row, _) => _ExclusiveRuleCell(item: row),
    ),
    _previewGridColumn(
      title: '设定频次',
      width: 88,
      value: (row) => _previewFreqLabel(row.now_frequency),
    ),
    _previewGridColumn(
      title: '发布时段设定',
      minWidth: 140,
      value: (row) =>
          '${_previewFormatDate(row.start_time)}/${_previewFormatDate(row.end_time)}',
    ),
    _previewGridColumn(
      title: '实播频次',
      width: 88,
      value: (row) => _previewFreqLabel(row.now_play_frequency),
    ),
    _previewGridColumn(
      title: '播量条件',
      width: 96,
      value: (row) => row.satisfy,
      cellBuilder: (c, row, _) => _SatisfyConditionCell(item: row),
    ),
    _previewGridColumn(
      title: '超播频次',
      width: 88,
      value: (row) => _previewFreqLabel(row.play_total_out_frequency),
    ),
    _previewGridColumn(
      title: '超播比例',
      width: 88,
      value: (row) => _previewOutPerLabel(row.play_total_out_per),
    ),
    _previewGridColumn(
      title: '循环间隔',
      width: 88,
      value: (row) => _previewLoopIntervalLabel(row),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    try {
      final AppRespEntity<List<LcdProgramMaterialEntity>> resp =
          await LcdApi.programPreviewSheet(
            scheduleId: widget.scheduleId,
            date: widget.date,
            terminalId: widget.terminalId,
          );
      final List<LcdProgramMaterialEntity> list =
          List<LcdProgramMaterialEntity>.from(
            resp.data ?? <LcdProgramMaterialEntity>[],
          );
      setState(() {
        _materials
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      _onError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onError(Object e) {
    if (e is AppRespEntity) {
      showError(e.msg);
    } else if (e is AppException) {
      showError(e.msg);
    } else {
      showError(e.toString());
    }
  }

  Future<void> _reorderMaterials(
    List<Object> orderedKeys,
    List<LcdProgramMaterialEntity> orderedRows,
  ) async {
    if (_sameMaterialOrder(_materials, orderedRows)) return;

    final List<LcdProgramMaterialEntity> backup =
        List<LcdProgramMaterialEntity>.from(_materials);
    _materials
      ..clear()
      ..addAll(orderedRows);
    setState(() {});

    if (_materials.any((e) => e.id == null)) {
      setState(() {
        _materials
          ..clear()
          ..addAll(backup);
      });
      showWarn('存在无效素材 ID，无法排序');
      return;
    }

    // 预览列表按格子展开，同一节目会出现多次；按首次出现顺序去重后提交。
    final List<int> ids = _materials.map((e) => e.id!).toSet().toList();
    try {
      await LcdApi.programMaterialReorder(
        scheduleId: widget.scheduleId,
        ids: ids,
      );
      await _loadPreview();
    } catch (e) {
      setState(() {
        _materials
          ..clear()
          ..addAll(backup);
      });
      _onError(e);
    }
  }

  String _exportFileName(String url) {
    final String name = Uri.parse(url).pathSegments.lastOrNull?.trim() ?? '';
    if (name.isNotEmpty && name.toLowerCase().endsWith('.xlsx')) return name;
    return '节目单预览.xlsx';
  }

  Future<void> _exportSheet() async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      final AppRespEntity<String> resp = await LcdApi.programExportSheet(
        scheduleId: widget.scheduleId,
      );
      final String? url = resp.data?.trim();
      if (url == null || url.isEmpty) {
        showWarn('导出地址为空');
        return;
      }

      final Uint8List raw = await CommonApi.getRemoteBytes(url);
      if (raw.isEmpty) {
        showWarn('导出文件为空');
        return;
      }

      final Uri? savedUri = await FilePicker.saveFile(
        dialogTitle: '保存节目单',
        fileName: _exportFileName(url),
        type: FileType.custom,
        allowedExtensions: <String>['xlsx'],
        bytes: Uint8List.fromList(raw),
      );
      if (savedUri == null) return;

      showComplete('节目单已保存');
    } catch (e) {
      _onError(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppButton.primary(
            child: Text(_exporting ? '导出中...' : '导出'),
            leading: const Icon(Icons.download_outlined),
            loading: _exporting,
            // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
            onPressed: _exporting
                ? null
                : () {
                    unawaited(_exportSheet());
                  },
          ),
        ),
        const Gap(8),
        Expanded(
          child: AppCard(
            child: _programMaterialGridOverlay(
              loading: _loading,
              child: AppDataGrid<LcdProgramMaterialEntity>.local(
                height: null,
                columns: _columns,
                rows: _materials,
                rowKey: _programMaterialRowKey,
                empty: const Center(child: AppEmptyState()),
                reorderableRows: true,
                onRowsReordered: _reorderMaterials,
                showBorder: false,
                showInternalDividers: false,
                headerBackgroundColor: kTableHeaderBackground,
                headerTextStyle: kTableHeaderTextStyle,
                stripeColor: kTableStripeBackground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _previewFormatDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  return value.split(' ').first.replaceAll('-', '.');
}

String _previewDurationLabel(LcdProgramMaterialEntity item) {
  final int? sec = item.duration ?? item.media_duration;
  if (sec == null) return '-';
  return "$sec'";
}

String _previewFreqLabel(int? value) {
  if (value == null) return '-';
  return '$value次';
}

Widget _previewIndustryTag(LcdProgramMaterialEntity item) {
  return customerIndustryTag(
    label: item.customer_industry ?? '-',
    colorHex: item.color,
    filled: true,
  );
}

bool _previewHasExclusive(LcdProgramMaterialEntity item) {
  final String? industry = item.exclusive_industry?.trim();
  if (industry != null && industry.isNotEmpty) return true;
  final String? rule = item.exclusive_rule?.trim();
  if (rule != null && rule.isNotEmpty && rule != '0') return true;
  return false;
}

String _previewHasExclusiveLabel(LcdProgramMaterialEntity item) =>
    _previewHasExclusive(item) ? '有' : '无';

String _previewExclusiveIndustryLabel(LcdProgramMaterialEntity item) {
  final String? raw = item.exclusive_industry?.trim();
  if (raw == null || raw.isEmpty) return '-';
  return raw
      .split(RegExp(r'[,、，]'))
      .map((String e) => e.trim())
      .where((String e) => e.isNotEmpty)
      .join('、');
}

String _previewSecondsTickLabel(int? seconds) {
  if (seconds == null) return '-';
  return "$seconds'";
}

String _previewExclusiveDurationLabel(LcdProgramMaterialEntity item) {
  final String? rule = item.exclusive_rule?.trim();
  if (rule == null || rule.isEmpty || rule == '0') return '-';
  return _previewSecondsTickLabel(int.tryParse(rule));
}

String _previewExclusiveLoopRuleLabel(LcdProgramMaterialEntity item) =>
    _previewSecondsTickLabel(item.loop_rule);

String _previewOutPerLabel(double? value) {
  if (value == null) return '-';
  return '$value%';
}

String _previewLoopIntervalLabel(LcdProgramMaterialEntity item) {
  final int? interval = item.actual_loop_interval ?? item.loop_rule;
  if (interval == null) return '-';
  return '$interval秒';
}

class _ExclusiveRuleCell extends StatefulWidget {
  const _ExclusiveRuleCell({required this.item});

  final LcdProgramMaterialEntity item;

  @override
  State<_ExclusiveRuleCell> createState() => _ExclusiveRuleCellState();
}

class _ExclusiveRuleCellState extends State<_ExclusiveRuleCell> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePopover() {
    if (!_previewHasExclusive(widget.item)) return;
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final RenderBox box = context.findRenderObject()! as RenderBox;
    _overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(-box.size.width * 0.35, box.size.height + 4),
              child: _ExclusiveRulePopover(item: widget.item),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final bool clickable = _previewHasExclusive(widget.item);
    final Color? color = clickable
        ? Theme.of(context).colorScheme.primary
        : null;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: clickable ? _togglePopover : null,
        child: MouseRegion(
          cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
          child: AppText.body(
            _previewHasExclusiveLabel(widget.item),
            color: color,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _ExclusiveRulePopover extends StatelessWidget {
  const _ExclusiveRulePopover({required this.item});

  final LcdProgramMaterialEntity item;

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.black45);
    final TextStyle? valueStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        );

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(6),
      color: Colors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExclusiveRulePopoverRow(
              label: '相邻排它',
              value: _previewExclusiveIndustryLabel(item),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            const Gap(6),
            _ExclusiveRulePopoverRow(
              label: '排它时长',
              value: _previewExclusiveDurationLabel(item),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            const Gap(6),
            _ExclusiveRulePopoverRow(
              label: '循环间隔',
              value: _previewExclusiveLoopRuleLabel(item),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExclusiveRulePopoverRow extends StatelessWidget {
  const _ExclusiveRulePopoverRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 64, child: Text(label, style: labelStyle)),
        Expanded(child: Text(value, style: valueStyle, softWrap: true)),
      ],
    );
  }
}

class _SatisfyConditionCell extends StatelessWidget {
  const _SatisfyConditionCell({required this.item});

  final LcdProgramMaterialEntity item;

  @override
  Widget build(BuildContext context) {
    if (item.satisfy == null) {
      return const AppText.body('-', maxLines: 1);
    }

    final bool satisfied = item.satisfy == true;
    final String label = satisfied ? '满足' : '不满足';
    final String? reason = item.reason?.trim();
    final String tooltip = reason != null && reason.isNotEmpty ? reason : label;

    return Tooltip(
      message: tooltip,
      child: satisfied
          ? AppBadge.success(shape: AppBadgeShape.square, child: Text(label))
          : AppBadge.destructive(
              appearance: AppBadgeStyle.soft,
              shape: AppBadgeShape.square,
              child: Text(label),
            ),
    );
  }
}

Object _programMaterialRowKey(LcdProgramMaterialEntity row) =>
    row.preview_seq != null
        ? '${row.id}-${row.preview_seq}'
        : row.id ?? identityHashCode(row);

bool _sameMaterialOrder(
  List<LcdProgramMaterialEntity> currentRows,
  List<LcdProgramMaterialEntity> orderedRows,
) {
  if (currentRows.length != orderedRows.length) return false;
  for (int i = 0; i < currentRows.length; i++) {
    if (_programMaterialRowKey(currentRows[i]) !=
        _programMaterialRowKey(orderedRows[i])) {
      return false;
    }
  }
  return true;
}

AppDataGridColumn<LcdProgramMaterialEntity> _previewGridColumn({
  required String title,
  required Object? Function(LcdProgramMaterialEntity row) value,
  double? width,
  double minWidth = 80,
  AppDataGridCellBuilder<LcdProgramMaterialEntity>? cellBuilder,
}) {
  return AppDataGridColumn<LcdProgramMaterialEntity>(
    id: title,
    title: title,
    value: value,
    width: width ?? 160,
    minWidth: minWidth,
    widthMode: width == null
        ? AppDataGridColumnWidthMode.fill
        : AppDataGridColumnWidthMode.fixed,
    cellBuilder: cellBuilder,
    sortable: false,
    filterable: false,
  );
}

Widget _programMaterialGridOverlay({
  required bool loading,
  required Widget child,
}) {
  if (!loading) return child;
  return Stack(
    children: [
      child,
      const ColoredBox(
        color: Color(0x66FFFFFF),
        child: Center(child: CircularProgressIndicator()),
      ),
    ],
  );
}
