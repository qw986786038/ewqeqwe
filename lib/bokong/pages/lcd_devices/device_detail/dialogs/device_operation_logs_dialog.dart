import 'package:dart_date/dart_date.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_operation_log_entity.dart';
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

/// 打开操作日志（终端日志）弹窗，尺寸对齐设备详情。
void showDeviceOperationLogsDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1500, initialHeight),
    builder: (dialogContext) =>
        DeviceOperationLogsDialog(controller: controller),
  );
}

/// 操作日志弹窗：设备摘要 + 表格 + 分页。
class DeviceOperationLogsDialog extends StatefulWidget {
  const DeviceOperationLogsDialog({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  @override
  State<DeviceOperationLogsDialog> createState() =>
      _DeviceOperationLogsDialogState();
}

class _DeviceOperationLogsDialogState extends State<DeviceOperationLogsDialog> {
  static const _pageSize = 20;

  var _logs = <LcdTerminalOperationLogEntity>[];
  var _page = 1;
  var _totalPages = 1;
  var _loading = false;

  LcdDeviceEntity get _device => widget.controller.device;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    final deviceNo = _device.device_no?.trim() ?? '';
    if (deviceNo.isEmpty) {
      showWarn('设备编号为空，无法查询终端日志');
      return;
    }
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final resp = await LcdApi.terminalOperationLogList(
        page: page,
        size: _pageSize,
        param: {'device_no': deviceNo},
      );
      if (!mounted) return;
      final pages = resp.page?.totalPages ?? 1;
      setState(() {
        _logs = List<LcdTerminalOperationLogEntity>.from(resp.data ?? const []);
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

  bool? _isSuccess(int? status) => switch (status) {
    1 => true,
    2 => false,
    _ => null,
  };

  int _serialOf(LcdTerminalOperationLogEntity row) {
    final index = _logs.indexOf(row);
    return (_page - 1) * _pageSize + (index < 0 ? 0 : index) + 1;
  }

  List<AppDataGridColumn<LcdTerminalOperationLogEntity>> get _columns => [
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
      widthMode: AppDataGridColumnWidthMode.fill,
      minWidth: 150,
    ),
    AppDataGridColumn(
      id: 'module',
      title: '模块',
      value: (row) => lcdDeviceTextOrDash(row.module),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'action',
      title: '动作',
      value: (row) => lcdDeviceTextOrDash(row.action),
      width: 120,
    ),
    AppDataGridColumn(
      id: 'content',
      title: '内容',
      value: (row) => lcdDeviceTextOrDash(row.operation_content),
      widthMode: AppDataGridColumnWidthMode.fill,
      minWidth: 120,
    ),
    AppDataGridColumn(
      id: 'issuedAt',
      title: '下发时间',
      value: (row) => _formatTime(row.issue_time),
      width: 180,
    ),
    AppDataGridColumn(
      id: 'feedbackAt',
      title: '反馈时间',
      value: (row) => _formatTime(row.result_time),
      width: 180,
    ),
    AppDataGridColumn(
      id: 'status',
      title: '执行状态',
      value: (row) => switch (_isSuccess(row.operation_status)) {
        true => '成功',
        false => '失败',
        null => lcdDeviceNumOrDash(row.operation_status),
      },
      width: 100,
      cellBuilder: (context, row, value) {
        final success = _isSuccess(row.operation_status);
        return Align(
          alignment: Alignment.center,
          child: switch (success) {
            true => AppBadge.success(
              appearance: AppBadgeStyle.soft,
              child: const Text('成功'),
            ),
            false => AppBadge.destructive(
              appearance: AppBadgeStyle.soft,
              child: const Text('失败'),
            ),
            null => Text('$value'),
          },
        );
      },
    ),
    AppDataGridColumn(
      id: 'errorMessage',
      title: '错误信息',
      value: (row) => lcdDeviceTextOrDash(row.error_message),
      widthMode: AppDataGridColumnWidthMode.fill,
      minWidth: 120,
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
      title: const Text('终端日志'),
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
                      AppDataGrid<LcdTerminalOperationLogEntity>.local(
                        columns: _columns,
                        rows: [..._logs],
                        rowKey: (row) =>
                            row.log_no ??
                            '${row.issue_time}-${identityHashCode(row)}',
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
