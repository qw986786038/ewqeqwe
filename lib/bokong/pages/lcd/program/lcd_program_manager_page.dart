import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:gap/gap.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:go_router/go_router.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/pages/common/left_list_page.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_add_dialog.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_controller.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_material_rule_panel.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_preview_dialog.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart' hide AppText;
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_layout.dart';
import 'package:yidivination/bokong/widget/app_text.dart';
import 'package:yidivination/bokong/widget/glass_list_item.dart';
import 'package:yidivination/bokong/widget/info/info_item_column.dart';
import 'package:yidivination/bokong/widget/info/info_item_widget.dart';
import 'package:yidivination/bokong/widget/lcd_device_status_icon.dart';
import 'package:yidivination/bokong/widget/message.dart';

class LcdProgramManagerPage extends StatefulWidget {
  const LcdProgramManagerPage({
    super.key,
    this.initialTerminalId,
    this.initialScheduleDate,
  });

  /// 按终端 ID 筛选排期设备列表
  final int? initialTerminalId;

  /// 初始排期日期（yyyy-MM-dd）
  final String? initialScheduleDate;

  @override
  State<LcdProgramManagerPage> createState() => _LcdProgramManagerPageState();
}

/// 【排期管理页】页面根状态：左右分栏、素材表格与底栏详情。
class _LcdProgramManagerPageState extends State<LcdProgramManagerPage> {
  final LcdProgramController _controller = Lemon.put(LcdProgramController.new);
  int _scheduleRefreshTick = 0;
  int? _statusFilter;
  bool _generatingSchedule = false;
  int? _terminalIdFilter;
  late DateTime _scheduleDate;
  bool _routeArgsApplied = false;

  @override
  void initState() {
    super.initState();
    _terminalIdFilter = widget.initialTerminalId;
    _scheduleDate =
        _parseScheduleDate(widget.initialScheduleDate) ??
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;
    _applyRouteArgs(GoRouterState.of(context));
  }

  void _applyRouteArgs(GoRouterState state) {
    final Object? extra = state.extra;
    int? terminalId = widget.initialTerminalId;
    String? scheduleDate = widget.initialScheduleDate;
    if (extra is Map) {
      final Object? tid = extra['terminal_id'];
      if (tid is int) {
        terminalId ??= tid;
      } else if (tid != null) {
        terminalId ??= int.tryParse('$tid');
      }
      final Object? date = extra['schedule_date'];
      if (date is String && (scheduleDate == null || scheduleDate.isEmpty)) {
        scheduleDate = date;
      }
    }
    terminalId ??= int.tryParse(state.uri.queryParameters['terminal_id'] ?? '');
    scheduleDate ??= state.uri.queryParameters['schedule_date'];

    final DateTime? parsedDate = _parseScheduleDate(scheduleDate);
    final bool terminalChanged =
        terminalId != null && terminalId != _terminalIdFilter;
    final bool dateChanged = parsedDate != null && parsedDate != _scheduleDate;
    if (!terminalChanged && !dateChanged) return;

    setState(() {
      if (terminalChanged) _terminalIdFilter = terminalId;
      if (parsedDate != null && dateChanged) _scheduleDate = parsedDate;
      _scheduleRefreshTick++;
    });
  }

  DateTime? _parseScheduleDate(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Map<String, dynamic> get _programDeviceListQueryParam {
    final Map<String, dynamic> param = <String, dynamic>{
      'schedule_date': _scheduleDate.millisecondsSinceEpoch.date(),
    };
    if (_statusFilter != null) param['terminal_status'] = _statusFilter;
    if (_terminalIdFilter != null) param['terminal_id'] = _terminalIdFilter;
    return param;
  }

  String get _leftListKey =>
      'program_devices_${_scheduleDate.millisecondsSinceEpoch.date()}_${_statusFilter ?? ''}_${_terminalIdFilter ?? ''}';

  void _setStatusFilter(int? status) {
    if (_statusFilter == status) {
      setState(() => _scheduleRefreshTick++);
      return;
    }
    _controller.current.value = null;
    _controller.currentMaterial.value = null;
    _controller.materials.clear();
    setState(() {
      _statusFilter = status;
      _scheduleRefreshTick++;
    });
  }

  @override
  void dispose() {
    Lemon.remove<LcdProgramController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLayout(
          maxContentWidth: 20000,
          startWidth: 400,
          widePadding: const EdgeInsets.only(left: 0, right: 0),
          start: LeftListPage(
            key: ValueKey<String>(_leftListKey),
            refresh: _scheduleRefreshTick,
            immediateLoad: _terminalIdFilter != null,
            topViewBuilder: (context, obj) {
              return Padding(
                padding: EdgeInsetsGeometry.only(top: 16, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('排期管理', style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    // Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                onTap: _pickScheduleDate,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: context.theme.hintColor,
                                    ),
                                    Gap(6),
                                    Text(
                                      _scheduleDate.millisecondsSinceEpoch
                                          .date(),
                                      style: context.theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Gap(8),
                        AppIconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: _generatingSchedule ? '正在重新生成' : '重新生成',
                          variant: AppButtonVariant.primary,
                          color: ShadcnTheme.of(
                            context,
                          ).colorScheme.primaryForeground,
                          onPressed: _generatingSchedule
                              ? null
                              : _confirmRegenerateSchedules,
                        ),
                      ],
                    ),
                    Gap(16),
                    deviceStatus(context),
                  ],
                ),
              );
            },
            queryParam: _programDeviceListQueryParam,
            api: ({int? page, int? size, Map<String, dynamic>? param}) {
              return LcdApi.programDeviceList(
                page: page,
                size: size,
                param: param,
              );
            },
            onDatasChanged: (datas) {
              final list = datas.whereType<LcdProgramDeviceEntity>().toList();
              _controller.devices.replaceAll(list);
              if (_controller.current.value == null && list.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_controller.current.value == null) {
                    _controller.selectDevice(list.first);
                  }
                });
              }
            },
            itemBuilder: (BuildContext context, int index, value) {
              final data = value as LcdProgramDeviceEntity;
              return deviceItem(context, data);
            },
          ),
          main: Column(
            children: [
              Obx(() {
                final d = _controller.current.value;
                final bool canPop = context.canPop();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      if (canPop) ...[
                        AppIconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: '返回',
                          onPressed: () => context.pop(),
                        ),
                        const Gap(8),
                      ],
                      Flexible(
                        child: AppText.largeTitle(
                          d?.terminal_point_name ?? '请选择左侧节目设备',
                        ),
                      ),
                      Gap(8),
                      _terminalOnlineBadge(d?.terminal_status, height: 25),
                      Gap(16),
                      Container(
                        height: 23,
                        child: const VerticalDivider(width: 2),
                      ),
                      Gap(16),
                      AppText.title(d?.terminal_building ?? '-'),
                      Gap(16),
                      Container(
                        height: 23,
                        child: const VerticalDivider(width: 2),
                      ),
                      Gap(16),
                      Expanded(
                        child: AppText.title(
                          d?.terminal_detailed_address ?? '-',
                        ),
                      ),
                    ],
                  ),
                );
              }),

              Obx(() => _deviceStatsBar(context, _controller.current.value)),
              Gap(13),
              Expanded(
                child: Obx(() {
                  return _ScheduleMaterialPanel(
                    materials: _controller.materials,
                    loading: _controller.loadingMaterials.value,
                    selectedId: _controller.currentMaterial.value?.id,
                    onSelect: _controller.selectMaterial,
                    onPreview: (material) => showProgramMaterialPreviewDialog(
                      context: context,
                      material: material,
                    ),
                    onShelfToggle: _controller.toggleMaterialShelf,
                    onReorder: _controller.reorderMaterials,
                    onCreateProgram: () => _showCreateProgramDialog(context),
                    onPreviewSheet: () => _openProgramPreview(context),
                    onStartExecution: () => _confirmStartExecution(context),
                    onSmartSort: () {},
                  );
                }),
              ),
              Gap(13),
              Obx(() => _materialInfoBar(context)),
            ],
          ),
        ),
    );
  }

  /// 【右侧素材表格 - 工具栏】打开创建节目弹窗。
  Future<void> _showCreateProgramDialog(BuildContext context) async {
    final LcdProgramDeviceEntity? device = _controller.current.value;
    if (device?.id == null) {
      showWarn('请先选择左侧节目设备');
      return;
    }
    await showLcdProgramAddDialog(
      context: context,
      device: device!,
      onSubmit: (param) => _controller.createProgram(param),
    );
  }

  /// 【左侧排期列表 - 工具栏】选择排期日期并刷新列表。
  Future<void> _pickScheduleDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final DateTime dateOnly = DateTime(picked.year, picked.month, picked.day);
    if (dateOnly == _scheduleDate) return;
    _controller.current.value = null;
    _controller.currentMaterial.value = null;
    _controller.materials.clear();
    setState(() {
      _scheduleDate = dateOnly;
      _statusFilter = null;
      _scheduleRefreshTick++;
    });
  }

  /// 【左侧排期列表 - 工具栏】重新生成节目排期确认弹窗。
  void _confirmRegenerateSchedules() {
    showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: const Text('重新生成'),
        content: const Text('确定要重新生成节目排期吗？'),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close<void>(dialogContext),
            child: const Text('取消'),
          ),
          AppButton.primary(
            onPressed: () async {
              try {
                await _regenerateSchedules();
                if (dialogContext.mounted)
                  await AppOverlay.close<void>(dialogContext);
              } catch (e) {
                showError('$e');
              }
            },
            child: const Text('重新生成'),
          ),
        ],
      ),
    );
  }

  /// 【左侧排期列表 - 工具栏】调用重新生成接口并刷新左侧列表。
  Future<void> _regenerateSchedules() async {
    if (_generatingSchedule) return;
    setState(() => _generatingSchedule = true);
    try {
      final resp = await LcdApi.programScheduleNewGenerate();
      if (!resp.isSuccess()) throw resp;
      _controller.current.value = null;
      _controller.currentMaterial.value = null;
      _controller.materials.clear();
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '重新生成任务已提交');
      if (!mounted) return;
      setState(() => _scheduleRefreshTick++);
    } finally {
      if (mounted) {
        setState(() => _generatingSchedule = false);
      }
    }
  }

  /// 【右侧素材表格 - 工具栏】启动排期执行确认弹窗。
  void _confirmStartExecution(BuildContext context) {
    final LcdProgramDeviceEntity? device = _controller.current.value;
    if (device?.id == null) {
      showWarn('请先选择左侧节目设备');
      return;
    }
    final String label =
        device?.schedule_name ?? device?.terminal_point_name ?? '当前排期';
    showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: const Text('启动执行'),
        content: Text('确定要启动执行排期「$label」吗？'),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close<void>(dialogContext),
            child: const Text('取消'),
          ),
          AppButton.primary(
            onPressed: () async {
              try {
                await _controller.startScheduleExecution();
                if (dialogContext.mounted)
                  await AppOverlay.close<void>(dialogContext);
              } catch (e) {
                showError('$e');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 【右侧素材表格 - 工具栏】打开节目单预览弹窗。
  void _openProgramPreview(BuildContext context) {
    final LcdProgramDeviceEntity? device = _controller.current.value;
    final int? scheduleId = device?.id;
    if (scheduleId == null) {
      showWarn('请先选择左侧节目设备');
      return;
    }
    showLcdProgramPreviewDialog(
      context: context,
      scheduleId: scheduleId,
      terminalDeviceNo: device?.terminal_device_no,
    );
  }

  /// 【右侧素材详情底栏】当前选中素材的订单/播放信息面板（左右分栏）。
  Widget _materialInfoBar(BuildContext context) {
    final LcdProgramMaterialEntity? m = _controller.currentMaterial.value;
    if (m == null) {
      return AppCard(
        child: Center(
          child: Text(
            '请选择表格中的节目素材',
            style: context.theme.textTheme.titleMedium,
          ),
        ),
      );
    }
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _materialInfoLeftCard(context, m)),
          const Gap(13),
          Expanded(child: _materialInfoRightCard(context, m)),
        ],
      ),
    );
  }

  /// 【右侧素材详情底栏 - 左栏】客户与订单基础信息。
  Widget _materialInfoLeftCard(
    BuildContext context,
    LcdProgramMaterialEntity m,
  ) {
    return AppCard(
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InfoItemColumn(
                children: _spacedInlineItems([
                  InfoItemInlineWidget(
                    title: '客户名称',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.customer_name,
                  ),
                  InfoItemInlineWidget(
                    title: '订单名称',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: _materialOrderName(m),
                  ),
                  InfoItemInlineWidget(
                    title: '客户分类',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.customer_industry,
                  ),
                  InfoItemInlineWidget(
                    title: '订单类型',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: _materialOrderType(m),
                  ),
                ]),
              ),
            ),
            const Gap(16),
            Expanded(
              child: InfoItemColumn(
                children: _spacedInlineItems([
                  InfoItemInlineWidget(
                    title: '上刊日期',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: _materialDate(
                      m.start_time ?? m.order_detail_send_time,
                    ),
                  ),
                  InfoItemInlineWidget(
                    title: '下刊日期',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: _materialDate(m.end_time),
                  ),
                  InfoItemInlineWidget(
                    title: '订单天数',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.order_days == null ? null : '${m.order_days}天',
                  ),
                  InfoItemInlineWidget(
                    title: '播放形式',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: _materialPlayRule(m.order_detail_play_rule),
                  ),
                  InfoItemInlineWidget(
                    title: '播放时段',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.publish_slots ?? m.set_slots,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 【右侧素材详情底栏 - 右栏】频次、排它行业与间隔设置。
  Widget _materialInfoRightCard(
    BuildContext context,
    LcdProgramMaterialEntity m,
  ) {
    return AppCard(
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InfoItemColumn(
                children: _spacedInlineItems([
                  InfoItemInlineWidget(
                    title: '广告时长',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: _materialDuration(m),
                  ),
                  InfoItemInlineWidget(
                    title: '订单日播频次',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.order_frequency == null
                        ? null
                        : '${m.order_frequency}次',
                  ),
                  InfoItemInlineWidget(
                    title: '设定日播频次',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.now_frequency == null
                        ? null
                        : '${m.now_frequency}次',
                  ),
                  InfoItemInlineWidget(
                    title: '今日已播频次',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.now_play_frequency == null
                        ? null
                        : '${m.now_play_frequency}次',
                  ),
                  InfoItemInlineWidget(
                    title: '超播频次',
                    titleWidth: _kMaterialInfoLabelWidth,
                    info: m.play_total_out_frequency == null
                        ? null
                        : '${m.play_total_out_frequency}次',
                  ),
                ]),
              ),
            ),
            const Gap(16),
            Expanded(
              child: InfoItemColumn(
                children: _spacedInlineItems([
                  LcdProgramMaterialRulePanel(
                    material: m,
                    labelWidth: _kMaterialInfoLabelWidth,
                    showTitle: false,
                    onSave:
                        ({
                          required int materialId,
                          Set<int>? industryIds,
                          int? exclusiveRule,
                          int? loopRule,
                        }) => _controller.updateMaterialRule(
                          materialId: materialId,
                          industryIds: industryIds,
                          exclusiveRule: exclusiveRule,
                          loopRule: loopRule,
                        ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _kMaterialInfoLabelWidth = 88;

  /// 【右侧素材详情底栏】字段列表项之间插入间距。
  List<Widget> _spacedInlineItems(List<Widget> items) {
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      spaced.add(items[i]);
      if (i != items.length - 1) spaced.add(const Gap(10));
    }
    return spaced;
  }

  /// 【右侧素材详情底栏】订单名称展示文案。
  String _materialOrderName(LcdProgramMaterialEntity m) {
    final String? title = m.media_title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return m.order_no ?? '-';
  }

  /// 【右侧素材详情底栏】订单类型展示文案。
  String _materialOrderType(LcdProgramMaterialEntity m) =>
      m.order_pay_label?.toString() ?? '-';

  /// 【右侧素材详情底栏】日期展示文案（仅日期部分）。
  String _materialDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value.split(' ').first;
  }

  /// 【右侧素材详情底栏】广告时长展示文案。
  String _materialDuration(LcdProgramMaterialEntity m) {
    final sec = m.duration ?? m.media_duration;
    if (sec == null) return '-';
    return "${sec}'";
  }

  /// 【右侧素材详情底栏】播放形式展示文案。
  String _materialPlayRule(int? playRule) {
    if (playRule == null) return '-';
    if (playRule == 1) return '循环播放';
    return playRule.toString();
  }

  /// 【右侧设备信息条】当前选中排期的节目/商业/公益等数量汇总。
  Widget _deviceStatsBar(BuildContext context, LcdProgramDeviceEntity? device) {
    final ThemeData theme = context.theme;
    final Color labelColor =
        theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final Color valueColor =
        theme.textTheme.titleMedium?.color ?? Colors.black87;
    final TextStyle? labelStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: labelColor,
    );
    final TextStyle? valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: valueColor,
      height: 1,
    );

    return Container(
      alignment: Alignment.centerLeft,
      // padding: const EdgeInsets.symmetric(horizontal: 30),
      height: 40,
      child: device == null
          ? Center(child: Text('请选择左侧节目设备', style: theme.textTheme.titleMedium))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ScheduleStatItem(
                    label: '此刻时间',
                    value: device.schedule_date ?? '-',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  const Gap(48),
                  _ScheduleStatItem(
                    label: '节目数',
                    value: '${device.total_num ?? 0}',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  const Gap(48),
                  _ScheduleStatItem(
                    label: '商业数量',
                    value: '${device.business_num ?? 0}',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  const Gap(48),
                  _ScheduleStatItem(
                    label: '公益数量',
                    value: '${device.public_num ?? 0}',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  const Gap(48),
                  _ScheduleStatItem(
                    label: '收费数量',
                    value: '${device.charge_num ?? 0}',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                  const Gap(48),
                  _ScheduleStatItem(
                    label: '赠送数量',
                    value: '${device.gift_num ?? 0}',
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                  ),
                ],
              ),
            ),
    );
  }

  int get _statusFilterIndex => switch (_statusFilter) {
    1 => 1,
    2 => 2,
    _ => 0,
  };

  Widget deviceStatus(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
      child: DefaultTabController(
        initialIndex: _statusFilterIndex,
        length: 3,
        child: Obx(
          () => TabBar(
            dividerColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll<Color>(
              Colors.transparent,
            ),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Tab(text: '全部 ${_controller.total}', height: 30),
              Tab(text: '在线 ${_controller.onlineCount}', height: 30),
              Tab(text: '离线 ${_controller.offlineCount}', height: 30),
            ],
            onTap: (int index) => _setStatusFilter(index == 0 ? null : index),
          ),
        ),
      ),
    );
  }

  /// 【左侧设备列表】单个排期设备列表项。
  Widget deviceItem(BuildContext context, LcdProgramDeviceEntity item) {
    final ThemeData theme = context.theme;
    return Obx(() {
      final bool isSelected = _controller.current.value?.id == item.id;
      return GlassListItem(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        selected: isSelected,
        onTap: () => _controller.selectDevice(item),
        child: Builder(
          builder: (context) {
            final ThemeData itemTheme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Tooltip(
                          message: '${item.terminal_point_name}',
                          child: Text(
                            '${item.terminal_point_name}',
                            style: itemTheme.listTileTheme.titleTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Gap(16),
                      _terminalOnlineBadge(item.terminal_status, height: 20),
                    ],
                  ),
                  Gap(8),
                  Row(
                    children: [
                      AppBadge.info(
                        appearance: AppBadgeStyle.outline,
                        shape: AppBadgeShape.square,
                        child: Text('${item.schedule_date ?? '未知'}'),
                      ),
                      Gap(6),
                      AppBadge.info(
                        appearance: AppBadgeStyle.outline,
                        shape: AppBadgeShape.square,
                        child: Text('${item.terminal_building ?? '未知'}'),
                      ),
                      Gap(6),
                      Expanded(
                        child: Tooltip(
                          message: '${item.terminal_detailed_address}',
                          child: Text(
                            '${item.terminal_detailed_address}',
                            style: theme.listTileTheme.subtitleTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

/// 【排期统计】单行标签 + 数值。
class _ScheduleStatItem extends StatelessWidget {
  const _ScheduleStatItem({
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: labelStyle),
        const Gap(8),
        Text(value, style: valueStyle),
      ],
    );
  }
}

/// 节目排期及播放规则设定（本页私有，不拆文件）。
class _ScheduleMaterialPanel extends StatelessWidget {
  const _ScheduleMaterialPanel({
    required this.materials,
    this.loading = false,
    this.selectedId,
    this.onSelect,
    this.onPreview,
    this.onShelfToggle,
    this.onCreateProgram,
    this.onPreviewSheet,
    this.onStartExecution,
    this.onSmartSort,
    this.onReorder,
  });

  final List<LcdProgramMaterialEntity> materials;
  final bool loading;
  final int? selectedId;
  final void Function(LcdProgramMaterialEntity item)? onSelect;
  final void Function(LcdProgramMaterialEntity item)? onPreview;
  final void Function(LcdProgramMaterialEntity item)? onShelfToggle;
  final VoidCallback? onCreateProgram;
  final VoidCallback? onPreviewSheet;
  final VoidCallback? onStartExecution;
  final VoidCallback? onSmartSort;
  final AppDataGridReorderCallback<LcdProgramMaterialEntity>? onReorder;

  static const Color _insufficient = Color(0xFFE53935);

  List<AppDataGridColumn<LcdProgramMaterialEntity>> get _columns {
    final bool showActions = onPreview != null || onShelfToggle != null;
    return <AppDataGridColumn<LcdProgramMaterialEntity>>[
      _scheduleGridColumn(
        title: '次序',
        width: 56,
        value: (row) => materials.indexOf(row) + 1,
      ),
      _scheduleGridColumn(
        title: '行业分类',
        minWidth: 100,
        value: (row) => row.customer_industry ?? '-',
        cellBuilder: (c, row, _) => _scheduleIndustryTag(row),
      ),
      _scheduleGridColumn(
        title: '状态',
        width: 88,
        value: (row) => row.is_delete,
        cellBuilder: (c, row, _) => _scheduleMaterialStatus(row.is_delete),
      ),
      _scheduleGridColumn(
        title: '订单名称',
        minWidth: 120,
        value: (row) => row.media_title ?? '-',
      ),
      _scheduleGridColumn(
        title: '广告时长',
        width: 88,
        value: (row) => _scheduleDurationLabel(row),
      ),
      _scheduleGridColumn(
        title: '订单日播频次',
        width: 110,
        value: (row) => _scheduleFreqLabel(row.order_frequency),
      ),
      _scheduleGridColumn(
        title: '今日已播放次数',
        width: 120,
        value: (row) => _scheduleFreqLabel(row.now_play_frequency),
      ),
      _scheduleGridColumn(
        title: '设定日播频次',
        width: 110,
        value: (row) => _scheduleFreqLabel(row.now_frequency),
      ),
      _scheduleGridColumn(
        title: '播量满足',
        width: 88,
        value: (row) => row.satisfy,
        cellBuilder: (c, row, _) => row.satisfy == true
            ? AppBadge.success(
                shape: AppBadgeShape.square,
                child: const Text('满足'),
              )
            : AppBadge.destructive(
                appearance: AppBadgeStyle.soft,
                shape: AppBadgeShape.square,
                child: const Text('不足'),
              ),
      ),
      _scheduleGridColumn(
        title: '广告物料',
        width: 88,
        value: (row) => row.media_type?.toString() ?? '1',
      ),
      if (showActions)
        _scheduleGridColumn(
          title: '操作',
          width: 128,
          pin: AppDataGridColumnPin.end,
          value: (row) => row.id,
          cellBuilder: (c, row, _) => _ScheduleRowActions(
            item: row,
            insufficientColor: _insufficient,
            onPreview: onPreview,
            onShelfToggle: onShelfToggle,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AppText.body(
                  '节目排期及播放规则设定',
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                ),
                const Spacer(),
                AppButton.primary(
                  child: const Text('创建节目'),
                  onPressed: onCreateProgram,
                ),
                const Gap(8),
                AppButton.primary(
                  child: const Text('节目单预览'),
                  onPressed: onPreviewSheet,
                ),
                const Gap(8),
                AppButton.primary(
                  child: const Text('启动执行'),
                  onPressed: onStartExecution,
                ),
                const Gap(8),
                AppButton.primary(
                  child: const Text('智能排序'),
                  onPressed: onSmartSort,
                ),
              ],
            ),
          ),
          Expanded(
            child: _scheduleGridOverlay(
              loading: loading,
              child: AppDataGrid<LcdProgramMaterialEntity>.local(
                height: null,
                columns: _columns,
                rows: materials,
                rowKey: (row) => row.id ?? identityHashCode(row),
                empty: const Center(child: AppEmptyState()),
                selectionMode: onSelect == null
                    ? AppDataGridSelectionMode.none
                    : AppDataGridSelectionMode.single,
                selectedKeys: <Object>{?selectedId},
                onSelectionChanged: onSelect == null
                    ? null
                    : (rows) {
                        if (rows.isNotEmpty) onSelect!(rows.first);
                      },
                reorderableRows: onReorder != null,
                onRowsReordered: onReorder,
                showBorder: false,
                showInternalDividers: false,
                headerBackgroundColor: kTableHeaderBackground,
                headerTextStyle: kTableHeaderTextStyle,
                stripeColor: kTableStripeBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRowActions extends StatelessWidget {
  const _ScheduleRowActions({
    required this.item,
    required this.insufficientColor,
    this.onPreview,
    this.onShelfToggle,
  });

  final LcdProgramMaterialEntity item;
  final Color insufficientColor;
  final void Function(LcdProgramMaterialEntity item)? onPreview;
  final void Function(LcdProgramMaterialEntity item)? onShelfToggle;

  @override
  Widget build(BuildContext context) {
    final bool offShelf = item.is_delete == 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onPreview != null)
          AppIconButton(
            icon: const Icon(Icons.desktop_windows_outlined),
            tooltip: '预览',
            onPressed: () => onPreview!(item),
          ),
        if (onPreview != null && onShelfToggle != null) const Gap(8),
        if (onShelfToggle != null)
          AppIconButton(
            icon: Icon(
              offShelf
                  ? Icons.publish_outlined
                  : Icons.desktop_access_disabled_outlined,
              color: offShelf ? const Color(0xFF43A047) : insufficientColor,
            ),
            tooltip: offShelf ? '上刊' : '下刊',
            onPressed: () => onShelfToggle!(item),
          ),
      ],
    );
  }
}

Widget _scheduleMaterialStatus(int? status) {
  switch (status) {
    case 1:
      return AppBadge.destructive(
        appearance: AppBadgeStyle.soft,
        shape: AppBadgeShape.square,
        child: const Text('已下刊'),
      );
    default:
      return AppBadge.success(
        shape: AppBadgeShape.square,
        child: const Text('已上刊'),
      );
  }
}

String _scheduleDurationLabel(LcdProgramMaterialEntity item) {
  final int? sec = item.duration ?? item.media_duration;
  if (sec == null) return '-';
  return "$sec'";
}

String _scheduleFreqLabel(int? value) {
  if (value == null) return '-';
  return '$value次';
}

Widget _scheduleIndustryTag(LcdProgramMaterialEntity item) {
  return customerIndustryTag(
    label: item.customer_industry ?? '-',
    colorHex: item.color,
    filled: true,
  );
}

AppDataGridColumn<LcdProgramMaterialEntity> _scheduleGridColumn({
  required String title,
  required Object? Function(LcdProgramMaterialEntity row) value,
  double? width,
  double minWidth = 80,
  AppDataGridColumnPin pin = AppDataGridColumnPin.none,
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
    pin: pin,
    cellBuilder: cellBuilder,
    sortable: false,
    filterable: false,
  );
}

Widget _scheduleGridOverlay({required bool loading, required Widget child}) {
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

Widget _terminalOnlineBadge(int? status, {double height = 22}) {
  final size = AppBadgeSize(
    fontSize: 14,
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
    iconSize: 12,
    contentGap: 8,
  );
  if (status == 1) {
    return AppBadge.success(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.pill,
      size: size,
      leading: const LcdDeviceStatusIcon.online(size: 12),
      child: const Text('在线'),
    );
  }
  return AppBadge.secondary(
    appearance: AppBadgeStyle.soft,
    shape: AppBadgeShape.pill,
    size: size,
    leading: const LcdDeviceStatusIcon.offline(size: 12),
    child: const Text('离线'),
  );
}
