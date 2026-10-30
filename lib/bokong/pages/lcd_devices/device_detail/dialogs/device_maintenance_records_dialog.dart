import 'dart:async';

import 'package:dart_date/dart_date.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/api/common_api.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_maintain_log_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../device_detail_controller.dart';
import 'device_record_add_dialog.dart';

/// 打开维保 / 巡检 / 异常告警记录时间轴弹窗。
///
/// [type]：`1` 维保，`2` 巡检，`3` 异常告警。
void showDeviceMaintenanceRecordsDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
  int type = 1,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(960, initialHeight),
    builder: (dialogContext) =>
        DeviceMaintenanceRecordsDialog(controller: controller, type: type),
  );
}

/// 维保 / 巡检 / 异常告警记录弹窗：筛选 + 可滚动时间轴。
///
/// 使用上游 [AppTimeline.vertical]；卡片放在 `title` 与圆点同行对齐（`content` 会在 title 区下方留白）。
/// 上游缺口（待回收）：时间点内嵌卡片头（时间 + 操作）一等布局 API。
class DeviceMaintenanceRecordsDialog extends StatefulWidget {
  const DeviceMaintenanceRecordsDialog({
    required this.controller,
    this.type = 1,
    super.key,
  });

  final LcdDeviceDetailController controller;

  /// `1` 维保，`2` 巡检，`3` 异常告警。
  final int type;

  @override
  State<DeviceMaintenanceRecordsDialog> createState() =>
      _DeviceMaintenanceRecordsDialogState();
}

class _DeviceMaintenanceRecordsDialogState
    extends State<DeviceMaintenanceRecordsDialog> {
  static const _pageSize = 50;

  final _keywordController = TextEditingController();
  var _records = <LcdTerminalMaintainLogEntity>[];
  DateTime? _startTime;
  DateTime? _endTime;
  var _loading = false;
  var _exporting = false;
  final _collapsedRecordIds = <int>{};

  String get _pageTitle => switch (widget.type) {
    2 => '巡检记录',
    3 => '异常告警',
    _ => '维保记录',
  };

  bool _isRecordExpanded(LcdTerminalMaintainLogEntity record) {
    final id = record.id;
    if (id == null) return true;
    return !_collapsedRecordIds.contains(id);
  }

  void _toggleRecordExpanded(LcdTerminalMaintainLogEntity record) {
    final id = record.id;
    if (id == null) return;
    setState(() {
      if (_collapsedRecordIds.contains(id)) {
        _collapsedRecordIds.remove(id);
      } else {
        _collapsedRecordIds.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _filterParams() {
    return {
      if (_startTime != null)
        'start_time': DateTime(
          _startTime!.year,
          _startTime!.month,
          _startTime!.day,
        ).format('yyyy-MM-dd HH:mm:ss'),
      if (_endTime != null)
        'end_time': DateTime(
          _endTime!.year,
          _endTime!.month,
          _endTime!.day,
          23,
          59,
          59,
        ).format('yyyy-MM-dd HH:mm:ss'),
      if (_keywordController.text.trim().isNotEmpty)
        'keyword': _keywordController.text.trim(),
    };
  }

  Future<void> _load() async {
    final terminalId = widget.controller.device.id;
    if (terminalId == null) {
      showWarn('设备 ID 为空，无法查询$_pageTitle');
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await LcdApi.terminalMaintainLogs(
        terminalId: terminalId,
        type: widget.type,
        page: 1,
        size: _pageSize,
        param: _filterParams(),
      );
      if (!mounted) return;
      setState(() {
        _records = List<LcdTerminalMaintainLogEntity>.from(
          resp.data ?? const [],
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _records = const []);
      showError(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() => _load();

  Future<void> _reset() {
    _keywordController.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
    });
    return _load();
  }

  Future<void> _export() async {
    if (_exporting) return;
    final terminalId = widget.controller.device.id;
    if (terminalId == null) {
      showWarn('设备 ID 为空，无法导出');
      return;
    }
    setState(() => _exporting = true);
    try {
      final resp = await LcdApi.terminalMaintainLogExport(
        terminalId: terminalId,
        type: widget.type,
        param: _filterParams(),
      );
      if (!resp.isSuccess()) throw resp;
      final url = resp.data?.trim();
      if (url == null || url.isEmpty) {
        showWarn('导出地址为空');
        return;
      }
      final raw = await CommonApi.getRemoteBytes(url);
      if (raw.isEmpty) {
        showWarn('导出文件为空');
        return;
      }
      final savedUri = await FilePicker.saveFile(
        dialogTitle: '保存$_pageTitle',
        fileName: _exportFileName(url),
        bytes: raw,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );
      if (savedUri == null) return;
      showComplete('$_pageTitle已保存');
    } catch (e) {
      showError(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _exportFileName(String url) {
    final name = Uri.parse(url).pathSegments.lastOrNull?.trim() ?? '';
    if (name.isNotEmpty && name.toLowerCase().endsWith('.xlsx')) return name;
    return '$_pageTitle.xlsx';
  }

  String _errorMessage(Object e) {
    if (e is AppRespEntity) return e.msg ?? '请求失败';
    if (e is AppException) return e.msg ?? '请求失败';
    return '$e';
  }

  String _displayTitle(LcdTerminalMaintainLogEntity record) {
    final title = record.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    final label = record.type_label?.trim() ?? '';
    if (label.isNotEmpty) return label;
    return _pageTitle;
  }

  String _displayDetail(LcdTerminalMaintainLogEntity record) {
    return record.remark?.trim() ?? '';
  }

  String _displayTime(LcdTerminalMaintainLogEntity record) {
    return record.create_time?.trim() ?? '-';
  }

  Widget _recordReplyAction(LcdTerminalMaintainLogEntity record) {
    return AppInkWell(
      onPressed: () => _addReply(record),
      hoverOpacity: 0,
      pressedOpacity: 0,
      child: const Text(
        '回复',
        style: TextStyle(fontSize: 14, color: Color(0xFF22C55E)),
      ),
    );
  }

  Widget _recordDeleteAction(LcdTerminalMaintainLogEntity record) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return AppIconButton(
      icon: Icon(AppLucideIcons.trash2, size: 16, color: colors.destructive),
      tooltip: '删除',
      variant: AppButtonVariant.ghost,
      config: const AppButtonConfig(height: 18),
      onPressed: () => _deleteRecord(record),
    );
  }

  Widget _recordCollapseAction({
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return AppInkWell(
      onPressed: onPressed,
      hoverOpacity: 0,
      pressedOpacity: 0,
      child: Text(
        expanded ? '收起' : '展开',
        style: TextStyle(fontSize: 14, color: colors.primary),
      ),
    );
  }

  Widget _recordCardHeader(
    BuildContext context,
    LcdTerminalMaintainLogEntity record, {
    required bool showReply,
    bool? expanded,
    VoidCallback? onToggleExpand,
  }) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return Row(
      spacing: 8,
      children: [
        AppText.caption(
          _displayTime(record),
          style: TextStyle(color: colors.mutedForeground),
        ).expanded(),
        if (showReply) _recordReplyAction(record),
        _recordDeleteAction(record),
        if (onToggleExpand != null && expanded != null)
          _recordCollapseAction(expanded: expanded, onPressed: onToggleExpand),
      ],
    );
  }

  List<LcdTerminalMaintainLogFileEntity> _mediaOf(
    LcdTerminalMaintainLogEntity record,
  ) {
    return List<LcdTerminalMaintainLogFileEntity>.from(
      record.files ?? const [],
    );
  }

  Future<void> _addReply(LcdTerminalMaintainLogEntity record) async {
    final parentId = record.id;
    if (parentId == null) {
      showWarn('记录 ID 为空，无法回复');
      return;
    }
    final ok = await showDeviceRecordAddDialog(
      context,
      controller: widget.controller,
      type: widget.type,
      parentId: parentId,
    );
    if (ok && mounted) await _load();
  }

  Future<void> _deleteRecord(LcdTerminalMaintainLogEntity record) async {
    final id = record.id;
    if (id == null) {
      showWarn('记录 ID 为空，无法删除');
      return;
    }
    final confirmed = await showAppWindowDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDeleteConfirmAlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除「${_displayTitle(record)}」吗？'),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close(dialogContext, false),
            child: const Text('取消'),
          ),
          AppButton.destructive(
            onPressed: () => AppOverlay.close(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    ).future;
    if (confirmed != true || !mounted) return;
    try {
      final resp = await LcdApi.terminalMaintainLogSoftDelete(id: id);
      if (!resp.isSuccess()) throw resp;
      showComplete(
        resp.msg?.trim().isNotEmpty == true ? resp.msg!.trim() : '删除成功',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      showError(_errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: Text(_pageTitle),
      constraints: const BoxConstraints(maxWidth: 960),
      content: SizedBox(
        width: 920,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 8,
                children: [
                  AppDatePicker(
                    hintText: '起始时间',
                    value: _startTime,
                    onChanged: (value) => setState(() => _startTime = value),
                  ).width(180),
                  AppDatePicker(
                    hintText: '结束时间',
                    value: _endTime,
                    onChanged: (value) => setState(() => _endTime = value),
                  ).width(180),
                  AppTextFormField(
                    hintText: '搜索关键字',
                    width: 220,
                    controller: _keywordController,
                    onSubmitted: (_) => _search(),
                  ),
                  AppButton.primary(
                    onPressed: _loading ? null : _search,
                    child: const Text('查询'),
                  ),
                  AppButton.outline(
                    onPressed: _loading ? null : _reset,
                    child: const Text('重置'),
                  ),
                  AppButton.outline(
                    loading: _exporting,
                    // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
                    onPressed: _loading || _exporting
                        ? null
                        : () {
                            unawaited(_export());
                          },
                    child: Text(_exporting ? '导出中...' : '导出'),
                  ),
                ],
              ),
              if (_loading)
                const Center(child: Text('加载中…')).expanded()
              else if (_records.isEmpty)
                Center(child: const AppEmptyState()).expanded()
              else
                AppTimeline.vertical(
                  timeConstraints: const BoxConstraints(maxWidth: 0),
                  data: [
                    for (final record in _records)
                      AppTimelineData(
                        time: const SizedBox.shrink(),
                        title: Builder(
                          builder: (context) {
                            final expanded = _isRecordExpanded(record);
                            return AppCard(
                              filled: true,
                              fillColor: colors.card,
                              borderWidth: 1,
                              borderColor: colors.border,
                              shadow: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Column(
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _recordCardHeader(
                                    context,
                                    record,
                                    showReply: true,
                                    expanded: expanded,
                                    onToggleExpand: () =>
                                        _toggleRecordExpanded(record),
                                  ),
                                  if (expanded) ...[
                                    AppText.label(
                                      _displayTitle(record),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_displayDetail(record).isNotEmpty)
                                      AppText.caption(
                                        _displayDetail(record),
                                        style: TextStyle(
                                          color: colors.mutedForeground,
                                        ),
                                      ),
                                    if (_mediaOf(record).isNotEmpty)
                                      _MediaRow(files: _mediaOf(record)),
                                    for (final update
                                        in record.replies ?? const [])
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: colors.muted.withValues(
                                            alpha: 0.55,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            ShadcnTheme.of(context).radiusMd,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            spacing: 8,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _recordCardHeader(
                                                context,
                                                update,
                                                showReply: false,
                                              ),
                                              AppText.label(
                                                _displayTitle(update),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (_displayDetail(
                                                update,
                                              ).isNotEmpty)
                                                AppText.caption(
                                                  _displayDetail(update),
                                                  style: TextStyle(
                                                    color:
                                                        colors.mutedForeground,
                                                  ),
                                                ),
                                              if (_mediaOf(update).isNotEmpty)
                                                _MediaRow(
                                                  files: _mediaOf(update),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ).scroll().expanded(),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.files});

  final List<LcdTerminalMaintainLogFileEntity> files;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        for (final item in files)
          Builder(
            builder: (context) {
              final url = item.url?.trim();
              final hasUrl = url != null && url.isNotEmpty;
              return AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(
                      ShadcnTheme.of(context).radiusSm,
                    ),
                    image: hasUrl
                        ? DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasUrl
                      ? null
                      : Icon(
                          AppLucideIcons.image,
                          size: 18,
                          color: const Color(0x66FFFFFF),
                        ).center(),
                ),
              ).size(width: 64, height: 64);
            },
          ),
      ],
    );
  }
}
