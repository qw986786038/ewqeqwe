import 'dart:async';

import 'package:dart_date/dart_date.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/api/common_api.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_play_log_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_terminal_mapper.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../device_detail_controller.dart';
import '../device_detail_insets.dart';
import '../device_detail_status_badge.dart';

/// 打开播放日志弹窗（尺寸对齐设备详情）。
void showDevicePlayLogsDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1500, initialHeight),
    builder: (dialogContext) => DevicePlayLogsDialog(controller: controller),
  );
}

/// 播放日志弹窗：筛选 + 设备摘要 + 表格 + 分页。
class DevicePlayLogsDialog extends StatefulWidget {
  const DevicePlayLogsDialog({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  @override
  State<DevicePlayLogsDialog> createState() => _DevicePlayLogsDialogState();
}

class _DevicePlayLogsDialogState extends State<DevicePlayLogsDialog> {
  static const _pageSize = 20;

  final _keywordController = TextEditingController();
  var _logs = <LcdTerminalPlayLogEntity>[];

  DateTime? _startTime;
  DateTime? _endTime;
  var _page = 1;
  var _totalPages = 1;
  var _loading = false;
  var _exporting = false;

  LcdDeviceEntity get _device => widget.controller.device;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _queryParams() {
    final deviceNo = _device.device_no?.trim() ?? '';
    if (deviceNo.isEmpty) return null;
    return {
      'device_no': deviceNo,
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
        'media_keyword': _keywordController.text.trim(),
    };
  }

  Future<void> _load({required int page}) async {
    final param = _queryParams();
    if (param == null) {
      showWarn('设备编号为空，无法查询播放日志');
      return;
    }
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final resp = await LcdApi.terminalPlayLogList(
        page: page,
        size: _pageSize,
        param: param,
      );
      if (!mounted) return;
      final pages = resp.page?.totalPages ?? 1;
      setState(() {
        _logs = List<LcdTerminalPlayLogEntity>.from(resp.data ?? const []);
        _totalPages = pages < 1 ? 1 : pages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _logs = const []);
      showError(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() => _load(page: 1);

  Future<void> _reset() {
    _keywordController.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
    });
    return _load(page: 1);
  }

  Future<void> _export() async {
    if (_exporting) return;
    final param = _queryParams();
    if (param == null) {
      showWarn('设备编号为空，无法导出');
      return;
    }
    setState(() => _exporting = true);
    try {
      final resp = await LcdApi.terminalPlayLogExport(param: param);
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
        dialogTitle: '保存播放日志',
        fileName: _exportFileName(url),
        bytes: raw,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );
      if (savedUri == null) return;
      showComplete('播放日志已保存');
    } catch (e) {
      showError(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _exportFileName(String url) {
    final name = Uri.parse(url).pathSegments.lastOrNull?.trim() ?? '';
    if (name.isNotEmpty && name.toLowerCase().endsWith('.xlsx')) return name;
    return '播放日志.xlsx';
  }

  String _errorMessage(Object e) {
    if (e is AppRespEntity) return e.msg ?? '未知错误';
    if (e is AppException) return e.msg ?? '未知错误';
    return e.toString();
  }

  String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    return dt.format('yyyy-MM-dd HH:mm:ss');
  }

  String _playTypeLabel(int? playType) => switch (playType) {
    1 => '排期播放',
    2 => '插播',
    _ => playType?.toString() ?? '-',
  };

  int _serialOf(LcdTerminalPlayLogEntity row) {
    final index = _logs.indexOf(row);
    return (_page - 1) * _pageSize + (index < 0 ? 0 : index) + 1;
  }

  List<AppDataGridColumn<LcdTerminalPlayLogEntity>> get _columns => [
    AppDataGridColumn(
      id: 'index',
      title: '次序',
      value: _serialOf,
      type: AppDataGridColumnType.number,
      width: 72,
      minWidth: 56,
      sortable: false,
      filterable: false,
    ),
    AppDataGridColumn(
      id: 'logNo',
      title: '日志编号',
      value: (row) => lcdDeviceTextOrDash(row.log_no),
      width: 160,
    ),
    AppDataGridColumn(
      id: 'deviceNo',
      title: '设备编号',
      value: (row) => lcdDeviceTextOrDash(row.device_no),
      width: 160,
    ),
    AppDataGridColumn(
      id: 'siteName',
      title: '点位名称',
      value: (row) => lcdDeviceTextOrDash(_device.displayName),
      widthMode: AppDataGridColumnWidthMode.fill,
      minWidth: 140,
    ),
    AppDataGridColumn(
      id: 'playType',
      title: '播放类型',
      value: (row) => _playTypeLabel(row.play_type),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'programName',
      title: '节目名称',
      value: (row) => lcdDeviceTextOrDash(row.media_title),
      widthMode: AppDataGridColumnWidthMode.fill,
      minWidth: 160,
    ),
    AppDataGridColumn(
      id: 'startAt',
      title: '开始时间',
      value: (row) => _formatTime(row.play_start_time),
      width: 180,
    ),
    AppDataGridColumn(
      id: 'endAt',
      title: '结束时间',
      value: (row) => _formatTime(row.play_end_time),
      width: 180,
    ),
    AppDataGridColumn(
      id: 'durationSec',
      title: '播放时长',
      value: (row) => row.play_duration == null ? '-' : '${row.play_duration}秒',
      width: 100,
    ),
  ];

  Widget _statusBadge(LcdDeviceStatus status) =>
      deviceDetailStatusBadge(status);

  @override
  Widget build(BuildContext context) {
    final headerHeight = AppControlMetricsScope.resolve(context).buttonHeight;
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    final fills = AppDialogInteraction.maybeOf(context)?.fillsBounds ?? false;
    final device = _device;

    return AppFormDialog(
      title: const Text('播放日志'),
      constraints: fills
          ? const BoxConstraints()
          : const BoxConstraints(maxWidth: 1500),
      padding: kDeviceDetailDialogPadding,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceOpacity: 1,
      content: SizedBox(
        width: double.infinity,
        height: fills ? double.infinity : dialogHeight,
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
                  hintText: '输入节目名称关键字',
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
            AppCard(
              borderWidth: 0,
              padding: kDeviceDetailHeaderPadding,
              child: SizedBox(
                height: headerHeight,
                child: Row(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.h3(
                      device.displayName,
                      style: kDeviceDetailHeaderTitleStyle,
                    ),
                    if (device.building?.trim().isNotEmpty == true)
                      AppBadge.primary(
                        child: Text(device.building!.trim()),
                        shape: AppBadgeShape.square,
                      ),
                    if (device.media_address?.trim().isNotEmpty == true)
                      AppText.subtitle(
                        device.media_address!.trim(),
                        style: kDeviceDetailHeaderTextStyle,
                      ),
                    _statusBadge(device.displayStatus),
                  ],
                ),
              ),
            ),
            AppCard(
              borderWidth: 0,
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AppDataGrid<LcdTerminalPlayLogEntity>.local(
                        columns: _columns,
                        rows: [..._logs],
                        rowKey: (row) =>
                            row.log_no ??
                            '${row.play_start_time}-${identityHashCode(row)}',
                        height: height.isFinite && height > 0 ? height : null,
                        sortable: false,
                        showBorder: false,
                        showInternalDividers: false,
                        headerBackgroundColor: kTableHeaderBackground,
                        headerTextStyle: kTableHeaderTextStyle,
                        stripeColor: kTableStripeBackground,
                        empty: const Center(child: const AppEmptyState()),
                      ),
                      if (_loading)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Color(0x66FFFFFF),
                            child: Center(
                              child: AppCircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ).expanded(),
            if (_totalPages > 1)
              Center(
                child: AppPagination(
                  page: _page,
                  totalPages: _totalPages,
                  maxPages: 5,
                  onPageChanged: (value) => _load(page: value),
                ),
              ),
          ],
        ),
      ),
      actions: const [],
    );
  }
}
