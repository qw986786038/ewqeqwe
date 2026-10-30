import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:path/path.dart' as p;
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/api/system_file_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_create_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_feedback_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_group_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_vas_entity.dart';
import 'package:yidivination/bokong/entity/order/order_create_entity.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/utils/file_content_type.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../../lcd_devices/lcd_devices_controller.dart';
import '../orders_controller.dart';

enum OrderDetailTab { order, devices, feedback, valueAdded }

enum OrderDevicesViewMode { grid, list }

/// 订单投放设备条目（发布单终端汇总）。
class OrderDeviceEntry {
  const OrderDeviceEntry({
    required this.device,
    required this.color,
    required this.propertyName,
    this.mediaLocation,
    this.ordersToday = 0,
    this.publishRate = 0,
  });

  final LcdDeviceEntity device;
  final Color color;
  final String propertyName;
  final String? mediaLocation;
  final int ordersToday;
  final int publishRate;
}

/// 订单详情弹窗状态：当前 Tab 与展示数据。
class OrderDetailController extends LxController {
  OrderDetailController({
    required this.order,
    required this.accentColor,
    required this.industryColor,
    required this.customerName,
    this.customerId,
    this.industryLabel = '',
    OrderDetailTab initialTab = OrderDetailTab.order,
  }) : tab = initialTab.obs,
       devicesViewMode = OrderDevicesViewMode.grid.obs,
       selectedReleaseKey = Rxn<Object>(_firstReleaseKey(order));

  final OrderEntity order;
  final Color accentColor;
  final Color industryColor;
  final String customerName;

  /// 列表打开时传入；缺省时回退 [OrderDetailEntity.customer_id]。
  final int? customerId;
  final String industryLabel;
  final Rx<OrderDetailTab> tab;
  final Rx<OrderDevicesViewMode> devicesViewMode;

  /// 当前选中的发布单行 key（[releaseRowKey]）。
  final Rxn<Object> selectedReleaseKey;

  /// 排他行业选项（[LcdApi.contentGroupList]）。
  final industryItems = <AdContentGroupEntity>[].obs;

  /// 就地改发布单排它字段后刷新 UI。
  final exclusiveRevision = 0.obs;

  /// 发布单列表变更（上下刊等）后刷新表格。
  final releaseRevision = 0.obs;

  /// 主订单标签（order_detail.tags）。
  final orderTags = <String>[].obs;

  /// 本会话已软删的明细 id；防止 order_detail 刷新把已删首条又带回来当 update 路径。
  final Set<int> _deletedReleaseIds = <int>{};

  Timer? _exclusiveSaveTimer;
  var _exclusiveSaving = false;

  /// 各发布单绑定终端去重汇总；无明细时回退订单根级终端 / device_nos。
  late final List<OrderDeviceEntry> devices = _devicesFromOrder(order);

  /// 发布单列表：优先 [OrderDetailEntity.items]，否则根级 [OrderEntity.items]。
  List<OrderItemEntity> get releaseItems => [
    for (final item in _releaseItemsOf(order))
      if (item.id == null || !_deletedReleaseIds.contains(item.id)) item,
  ];

  OrderItemEntity? get selectedRelease {
    final key = selectedReleaseKey.value;
    if (key == null) return null;
    for (final item in releaseItems) {
      if (releaseRowKey(item) == key) return item;
    }
    return null;
  }

  /// 当前选中物料对应的投放设备。
  ///
  /// 优先该发布单绑定终端；明细未带回终端时回退订单根级 [terminal_list] / [device_nos]。
  List<OrderDeviceEntry> get selectedMaterialDevices {
    final item = selectedRelease;
    if (item == null) return const [];
    return devicesOfRelease(item);
  }

  /// 单个发布单 / 物料绑定的设备。
  List<OrderDeviceEntry> devicesOfRelease(OrderItemEntity item) {
    final fromItem = _devicesFromReleaseItem(item);
    if (fromItem.isNotEmpty) return fromItem;
    return _devicesFromOrderRoot(order);
  }

  int deviceCountOf(OrderItemEntity item) => devicesOfRelease(item).length;

  Object releaseRowKey(OrderItemEntity item) =>
      item.id ?? identityHashCode(item);

  void selectRelease(OrderItemEntity? item) {
    selectedReleaseKey.value = item == null ? null : releaseRowKey(item);
    _syncExclusiveToggles(item);
    notifyExclusive();
  }

  void selectReleaseRows(List<OrderItemEntity> rows) {
    selectRelease(rows.isEmpty ? null : rows.first);
  }

  /// 勾选开关：可在尚无数值时先打开再填。
  final loopRuleOn = false.obs;
  final industryRuleOn = false.obs;
  final exclusiveRuleOn = false.obs;

  /// 排它按**发布单 / 素材**独立，只读该条字段。
  ///
  /// 订单级 [OrderEntity.exclusive] / [exclusive_rule_info] / [OrderDetailEntity]
  /// 上的排它**仅列表外部卡片**使用；详情内禁止读取、禁止回退。
  int resolvedLoopRule(OrderItemEntity? item) => item?.loop_rule ?? 0;

  int resolvedExclusiveRule(OrderItemEntity? item) => item?.exclusive_rule ?? 0;

  List<int> resolvedIndustryIds(OrderItemEntity? item) {
    final fromItem = item?.exclusive_industry;
    if (fromItem == null || fromItem.isEmpty) return const [];
    return List<int>.from(fromItem);
  }

  void _syncExclusiveToggles(OrderItemEntity? item) {
    loopRuleOn.value = resolvedLoopRule(item) > 0;
    industryRuleOn.value = resolvedIndustryIds(item).isNotEmpty;
    exclusiveRuleOn.value = resolvedExclusiveRule(item) > 0;
  }

  /// 打开详情后同步当前发布单的排它勾选态（勿在构造期写 Rx）。
  void syncExclusiveTogglesFromSelected() {
    _syncExclusiveToggles(selectedRelease);
    notifyExclusive();
  }

  /// 监测反馈 Tab 保存回调（供 Tab 注册，便于外部触发）。
  Future<void> Function()? saveMonitorFeedback;

  final monitorFeedback = Rxn<OrderMonitorFeedbackEntity>();
  final monitorLoading = false.obs;
  final monitorSaving = false.obs;
  final vasSaving = false.obs;
  final vasLoading = false.obs;
  final monitorVas = Rxn<OrderMonitorVasEntity>();

  Future<void> loadMonitorFeedback({bool showLoading = true}) async {
    final orderNo = order.order_no?.trim();
    final detailId = selectedRelease?.id;
    if (orderNo == null || orderNo.isEmpty || detailId == null) {
      monitorFeedback.value = null;
      return;
    }
    if (showLoading) monitorLoading.value = true;
    try {
      final resp = await LcdApi.orderMonitor(
        orderNo: orderNo,
        orderDetailId: detailId,
      );
      if (!resp.isSuccess()) throw resp;
      monitorFeedback.value = resp.data;
    } catch (e) {
      monitorFeedback.value = null;
      _onApiError(e);
    } finally {
      if (showLoading) monitorLoading.value = false;
    }
  }

  Future<void> saveMonitorFeedbackConfig(OrderMonitorCreateEntity param) async {
    if (monitorSaving.value) return;
    monitorSaving.value = true;
    try {
      final configId = monitorFeedback.value?.config?.id;
      if (configId != null) {
        final resp = await LcdApi.orderMonitorUpdate(
          id: configId,
          param:
              json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
        );
        if (!resp.isSuccess()) throw resp;
        await loadMonitorFeedback(showLoading: false);
        final locked = monitorFeedback.value?..editable = false;
        if (locked != null) monitorFeedback.value = locked;
        showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '保存成功');
        return;
      }

      final resp = await LcdApi.orderMonitorCreate(param: param);
      if (!resp.isSuccess()) throw resp;
      monitorFeedback.value = resp.data?..editable = false;
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '保存成功');
    } catch (e) {
      _onApiError(e);
    } finally {
      monitorSaving.value = false;
    }
  }

  ({String orderNo, int orderDetailId})? _monitorGroupMediaContext() {
    final orderNo = order.order_no?.trim();
    final detailId = selectedRelease?.id;
    if (orderNo == null || orderNo.isEmpty || detailId == null) return null;
    return (orderNo: orderNo, orderDetailId: detailId);
  }

  Future<OrderMonitorGroupMediaEntity?> loadMonitorGroupMedia(
    int groupId,
  ) async {
    final ctx = _monitorGroupMediaContext();
    if (ctx == null) return null;
    final resp = await LcdApi.orderMonitorGroupMedia(
      orderNo: ctx.orderNo,
      orderDetailId: ctx.orderDetailId,
      groupId: groupId,
    );
    if (!resp.isSuccess()) throw resp;
    return resp.data;
  }

  Future<void> uploadMonitorGroupMedia(int groupId, String localPath) async {
    final ctx = _monitorGroupMediaContext();
    if (ctx == null) {
      showWarn('请先选择发布单');
      return;
    }

    final fileName = p.basename(localPath);
    final mimeType =
        guessContentTypeFromFilename(fileName) ?? 'application/octet-stream';

    final upload = await SystemFileApi.presignUploadAndComplete(
      filename: fileName,
      contentType: mimeType,
      bytes: await File(localPath).readAsBytes(),
      pathPrefix: 'monitor',
      fileType: guessFileTypeFromMimeType(mimeType),
    );

    final fileUrl = upload.presign.public_url?.trim();
    if (fileUrl == null || fileUrl.isEmpty) {
      throw StateError('上传后文件地址为空');
    }

    final param = OrderMonitorUploadMediaEntity()
      ..order_no = ctx.orderNo
      ..order_detail_id = ctx.orderDetailId
      ..group_id = groupId
      ..file_url = fileUrl
      ..file_name = fileName
      ..file_type = mimeType;

    final resp = await LcdApi.orderMonitorUploadMedia(param: param);
    if (!resp.isSuccess()) throw resp;
    await loadMonitorFeedback(showLoading: false);
  }

  /// 加载监测增值服务。
  Future<void> loadMonitorVas({bool showLoading = true}) async {
    final detailId = selectedRelease?.id;
    if (detailId == null) {
      monitorVas.value = null;
      return;
    }
    if (showLoading) vasLoading.value = true;
    try {
      final resp = await LcdApi.getMonitorVas(orderDetailId: detailId);
      if (!resp.isSuccess()) throw resp;
      monitorVas.value = resp.data;
    } catch (e) {
      monitorVas.value = null;
      _onApiError(e);
    } finally {
      if (showLoading) vasLoading.value = false;
    }
  }

  /// 增值服务本地文件上传，返回公网 URL。
  Future<String> uploadVasMedia(String localPath) async {
    final fileName = p.basename(localPath);
    final mimeType =
        guessContentTypeFromFilename(fileName) ?? 'application/octet-stream';
    final upload = await SystemFileApi.presignUploadAndComplete(
      filename: fileName,
      contentType: mimeType,
      bytes: await File(localPath).readAsBytes(),
      pathPrefix: 'monitor_vas',
      fileType: guessFileTypeFromMimeType(mimeType),
    );
    final fileUrl = upload.presign.public_url?.trim();
    if (fileUrl == null || fileUrl.isEmpty) {
      throw StateError('上传后文件地址为空');
    }
    return fileUrl;
  }

  /// 保存监测增值服务。
  Future<void> saveMonitorVas(OrderMonitorVasSaveEntity param) async {
    final detailId = selectedRelease?.id;
    if (detailId == null) {
      showWarn('请先选择发布单');
      return;
    }
    param.order_detail_id = detailId;
    try {
      final resp = await LcdApi.saveMonitorVas(param: param);
      if (!resp.isSuccess()) throw resp;
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '保存成功');
      await loadMonitorVas(showLoading: false);
    } catch (e) {
      _onApiError(e);
    }
  }

  Future<void> updateMonitorPeriod({
    required OrderMonitorPeriodEntity period,
    required String monitorDate,
    required String monitorEndDate,
  }) async {
    final ctx = _monitorGroupMediaContext();
    if (ctx == null) {
      showWarn('请先选择发布单');
      return;
    }

    final planId = period.plan_id;
    final periodIndex = period.period_index;
    if (planId == null || periodIndex == null) {
      throw StateError('监测期次信息不完整');
    }

    final param = OrderMonitorUpdatePeriodEntity()
      ..order_no = ctx.orderNo
      ..order_detail_id = ctx.orderDetailId
      ..plan_id = planId
      ..period_index = periodIndex
      ..monitor_date = monitorDate
      ..monitor_end_date = monitorEndDate;

    final resp = await LcdApi.orderMonitorUpdatePeriod(param: param);
    if (!resp.isSuccess()) throw resp;
    await loadMonitorFeedback(showLoading: false);
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '保存成功');
  }

  Future<void> deleteMonitorGroupMedia({required int mediaId}) async {
    final ctx = _monitorGroupMediaContext();
    if (ctx == null) {
      showWarn('请先选择发布单');
      return;
    }

    final resp = await LcdApi.orderMonitorDeleteMedia(
      orderNo: ctx.orderNo,
      orderDetailId: ctx.orderDetailId,
      id: mediaId,
    );
    if (!resp.isSuccess()) throw resp;
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '删除成功');
    await loadMonitorFeedback(showLoading: false);
  }

  Future<void> loadIndustryItems() async {
    final resp = await LcdApi.contentGroupList(page: 1, size: 500);
    industryItems
      ..clear()
      ..addAll(resp.data ?? []);
    // 行业选项就绪后刷新勾选态（标签依赖 options）。
    syncExclusiveTogglesFromSelected();
  }

  void notifyExclusive() => exclusiveRevision.value++;

  /// [AppNumberInput] 可能在 build/didUpdateWidget 同步文本时回调 onChanged；
  /// 此时 bump Rx 会触发「setState during build」。
  void _runOutsideBuild(VoidCallback action) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      action();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  void _notifyExclusiveDeferred() => _runOutsideBuild(notifyExclusive);

  void setLoopRuleOn(bool on) {
    loopRuleOn.value = on;
    if (!on) {
      setReleaseLoopRule(0);
      return;
    }
    final current = selectedRelease?.loop_rule ?? 0;
    if (current <= 0) {
      setReleaseLoopRule(60);
      return;
    }
    notifyExclusive();
  }

  void setIndustryRuleOn(bool on) {
    industryRuleOn.value = on;
    if (!on) {
      setReleaseExclusiveIndustry(null);
      return;
    }
    notifyExclusive();
  }

  void setExclusiveRuleOn(bool on) {
    exclusiveRuleOn.value = on;
    if (!on) {
      setReleaseExclusiveRule(0);
      return;
    }
    final current = selectedRelease?.exclusive_rule ?? 0;
    if (current <= 0) {
      setReleaseExclusiveRule(30);
      return;
    }
    notifyExclusive();
  }

  void setReleaseLoopRule(int? value) {
    final item = selectedRelease;
    if (item == null) return;
    final next = value ?? 0;
    if ((item.loop_rule ?? 0) == next) return;
    item.loop_rule = next;
    if (next > 0 && !loopRuleOn.value) {
      _runOutsideBuild(() => loopRuleOn.value = true);
    }
    _notifyExclusiveDeferred();
    _scheduleSaveExclusive();
  }

  void setReleaseExclusiveIndustry(List<int>? value) {
    final item = selectedRelease;
    if (item == null) return;
    final next = value == null || value.isEmpty ? null : List<int>.from(value);
    if (_sameIntList(item.exclusive_industry, next)) return;
    item.exclusive_industry = next;
    if (next != null && next.isNotEmpty && !industryRuleOn.value) {
      _runOutsideBuild(() => industryRuleOn.value = true);
    }
    _notifyExclusiveDeferred();
    _scheduleSaveExclusive();
  }

  void setReleaseExclusiveRule(int? value) {
    final item = selectedRelease;
    if (item == null) return;
    final next = value ?? 0;
    if ((item.exclusive_rule ?? 0) == next) return;
    item.exclusive_rule = next;
    if (next > 0 && !exclusiveRuleOn.value) {
      _runOutsideBuild(() => exclusiveRuleOn.value = true);
    }
    _notifyExclusiveDeferred();
    _scheduleSaveExclusive();
  }

  bool _sameIntList(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return setA.length == b.length && setA.containsAll(b);
  }

  /// 排它区改动后防抖保存，走编辑发布单接口并带回完整字段。
  void _scheduleSaveExclusive() {
    _exclusiveSaveTimer?.cancel();
    _exclusiveSaveTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_saveExclusiveChanges());
    });
  }

  Future<void> _saveExclusiveChanges() async {
    if (_exclusiveSaving) return;
    final item = selectedRelease;
    if (item == null) return;
    final detailId = item.id;
    if (detailId == null) {
      showWarn('发布单 ID 无效');
      return;
    }
    final body = buildReleaseEditBody(item);
    if (body == null) {
      showWarn('发布单信息不完整，无法保存排它要求');
      return;
    }
    _exclusiveSaving = true;
    try {
      await editReleaseDetail(
        orderDetailId: detailId,
        item: body,
        showToast: true,
      );
    } finally {
      _exclusiveSaving = false;
    }
  }

  /// 由当前发布单拼出编辑接口所需完整明细（含排它与其它字段）。
  OrderCreateItemEntity? buildReleaseEditBody(OrderItemEntity item) {
    final detailId = item.id;
    final mediaId = item.media_id;
    if (detailId == null || mediaId == null) return null;

    final start = _dateOnly(item.start_time);
    final end = _dateOnly(item.end_time);
    final sendStart = _dateOnly(item.send_time);
    final sendEnd = _dateOnly(item.send_end_time);
    if (start == null || end == null || sendStart == null || sendEnd == null) {
      return null;
    }

    final terminalIds = <int>[
      for (final device in devicesOfRelease(item))
        if (device.device.id != null) device.device.id!,
    ];
    if (terminalIds.isEmpty) return null;

    final isFixedScreen = item.play_rule == 2;
    final coverStart = item.cover_start_time?.trim();
    final coverEnd = item.cover_end_time?.trim();
    return OrderCreateItemEntity()
      ..id = detailId
      ..media_id = mediaId
      ..media_title = item.media_title
      ..start_time = start
      ..end_time = end
      ..send_time = sendStart
      ..send_end_time = sendEnd
      ..duration = item.duration ?? 15
      ..order_frequency = item.order_frequency ?? 120
      ..give_frequency = item.give_frequency ?? 0
      // 始终传列表（可空列表），避免 null 被序列化剔除后服务端保留旧行业。
      ..exclusive_industry = List<int>.from(item.exclusive_industry ?? const [])
      ..exclusive_rule = item.exclusive_rule ?? 0
      ..loop_rule = item.loop_rule ?? 0
      ..order_pay = item.order_pay ?? 1
      ..play_rule = item.play_rule ?? 1
      ..play_model = item.play_model ?? 1
      ..cover_start_time = isFixedScreen
          ? ((coverStart != null && coverStart.isNotEmpty)
                ? coverStart
                : (item.play_period?.start_time?.trim() ?? ''))
          : ''
      ..cover_end_time = isFixedScreen
          ? ((coverEnd != null && coverEnd.isNotEmpty)
                ? coverEnd
                : (item.play_period?.end_time?.trim() ?? ''))
          : ''
      ..terminal_ids = terminalIds.join(',');
  }

  String? _dateOnly(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return text.split(' ').first;
  }

  @override
  void onDispose() {
    _exclusiveSaveTimer?.cancel();
    _exclusiveSaveTimer = null;
    super.onDispose();
  }

  void notifyReleases() => releaseRevision.value++;

  /// 接口 `status=3` 为已下刊。
  bool isReleaseOffShelf(OrderItemEntity item) => item.status == 3;

  Future<void> setReleaseOnShelf(OrderItemEntity item) async {
    await _setReleaseShelf(item, onShelf: true);
  }

  Future<void> setReleaseOffShelf(OrderItemEntity item) async {
    await _setReleaseShelf(item, onShelf: false);
  }

  Future<void> _setReleaseShelf(
    OrderItemEntity item, {
    required bool onShelf,
  }) async {
    final id = item.id;
    if (id == null) {
      showWarn('发布单 ID 无效');
      return;
    }
    try {
      final resp = onShelf
          ? await LcdApi.customerOrderOnShelf(id: id)
          : await LcdApi.customerOrderOffShelf(id: id);
      if (!resp.isSuccess()) throw resp;
      item.status = onShelf ? 1 : 3;
      notifyReleases();
      showComplete(
        resp.msg?.isNotEmpty == true ? resp.msg! : (onShelf ? '上刊成功' : '下刊成功'),
      );
    } catch (e) {
      _onApiError(e);
    }
  }

  Future<void> deleteRelease(OrderItemEntity item) async {
    final id = item.id;
    if (id == null) {
      showWarn('发布单 ID 无效');
      return;
    }
    try {
      final resp = await LcdApi.customerOrderSoftDelete(id: id);
      if (!resp.isSuccess()) throw resp;
      _removeRelease(item);
      final remaining = releaseItems;
      if (selectedReleaseKey.value == releaseRowKey(item)) {
        selectRelease(remaining.isEmpty ? null : remaining.first);
      }
      notifyReleases();
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '删除成功');
    } catch (e) {
      _onApiError(e);
    }
  }

  /// 修改订单素材（`/api/customer_order/{order_detail_id}/edit_order_detail/`）。
  Future<void> editReleaseDetail({
    required int orderDetailId,
    required OrderCreateItemEntity item,
    bool showToast = true,
  }) async {
    final body = _serializeReleaseDetailBody(item);
    try {
      final resp = await LcdApi.customerOrderEditDetail(
        orderDetailId: orderDetailId,
        params: body,
      );
      if (!resp.isSuccess()) throw resp;
      await _reloadOrderDetail();
      // order_detail 常不回写 items.exclusive_*，需用刚提交的值盖回当前发布单。
      // 禁止把单条结果写回订单级摘要（列表卡片专用，详情内不用）。
      _applySavedExclusiveToRelease(orderDetailId, item);
      syncExclusiveTogglesFromSelected();
      notifyReleases();
      if (showToast) {
        showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '保存成功');
      }
    } catch (e) {
      _onApiError(e);
    }
  }

  /// 把本次编辑提交的排它字段写回内存中的对应发布单（仅该条，不碰订单级）。
  void _applySavedExclusiveToRelease(
    int orderDetailId,
    OrderCreateItemEntity saved,
  ) {
    OrderItemEntity? matched;
    for (final e in releaseItems) {
      if (e.id == orderDetailId) {
        matched = e;
        break;
      }
    }
    if (matched == null) return;

    final industries = saved.exclusive_industry;
    matched.exclusive_industry = industries == null || industries.isEmpty
        ? null
        : List<int>.from(industries);
    matched.exclusive_rule = saved.exclusive_rule ?? 0;
    matched.loop_rule = saved.loop_rule ?? 0;
  }

  /// 新增发布单（`/api/customer_order/{order_id}/create_order/`）。
  Future<void> addReleaseDetail({required OrderCreateItemEntity item}) async {
    final orderId = order.id;
    if (orderId == null) {
      showWarn('订单 ID 无效');
      return;
    }
    final body = _serializeReleaseDetailBody(item);
    try {
      final resp = await LcdApi.customerOrderAddDetail(
        orderId: orderId,
        params: body,
      );
      if (!resp.isSuccess()) throw resp;
      await _reloadOrderDetail();
      notifyReleases();
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '添加成功');
    } catch (e) {
      _onApiError(e);
    }
  }

  Map<String, dynamic> _serializeReleaseDetailBody(OrderCreateItemEntity item) {
    final raw =
        json.decode(JsonMapper.serialize(OrderCreateEntity()..items = [item]))
            as Map<String, dynamic>;
    raw.removeWhere((_, value) => value == null);
    final items = raw['items'];
    if (items is List) {
      for (final entry in items) {
        if (entry is Map<String, dynamic>) {
          entry.removeWhere((_, value) => value == null);
        }
      }
    }
    return raw;
  }

  void _removeRelease(OrderItemEntity item) {
    final id = item.id;
    if (id != null) _deletedReleaseIds.add(id);
    bool match(OrderItemEntity e) =>
        identical(e, item) || (id != null && e.id == id);
    order.detail?.items?.removeWhere(match);
    order.items?.removeWhere(match);
    // detail 被删空会回退到根级 items（常缺 id）；把仍存活的根级行补回 detail。
    final detail = order.detail;
    if (detail != null &&
        (detail.items == null || detail.items!.isEmpty) &&
        (order.items?.isNotEmpty ?? false)) {
      detail.items = [
        for (final e in order.items!)
          if (e.id == null || !_deletedReleaseIds.contains(e.id)) e,
      ];
    }
  }

  void _onApiError(Object e) {
    if (e is AppRespEntity) {
      showError(e.msg);
    } else {
      showError('$e');
    }
  }

  int? get resolvedCustomerId => customerId ?? order.detail?.customer_id;

  /// 打开详情时拉取完整明细，保证每条都有 id（列表接口常不齐）。
  Future<void> ensureReleaseItemsLoaded() async {
    await _reloadOrderDetail();
    if (selectedReleaseKey.value == null && releaseItems.isNotEmpty) {
      selectRelease(releaseItems.first);
    } else {
      // 刷新后重绑当前选中（若仍存在）。
      final key = selectedReleaseKey.value;
      if (key != null) {
        OrderItemEntity? matched;
        for (final item in releaseItems) {
          if (releaseRowKey(item) == key) {
            matched = item;
            break;
          }
        }
        if (matched == null && releaseItems.isNotEmpty) {
          selectRelease(releaseItems.first);
        } else {
          syncExclusiveTogglesFromSelected();
          notifyReleases();
        }
      } else {
        notifyReleases();
      }
    }
  }

  Future<void> _reloadOrderDetail() async {
    final orderNo = order.order_no?.trim();
    if (orderNo == null || orderNo.isEmpty) {
      await _reloadOrderItemsFromList();
      return;
    }
    try {
      final resp = await LcdApi.orderDetail(orderNo: orderNo);
      if (!resp.isSuccess() || resp.data == null) {
        await _reloadOrderItemsFromList();
        return;
      }
      final loaded = resp.data!;
      loaded.id ??= order.id;
      loaded.customer_name ??= order.customer_name;
      loaded.terminal_list ??= order.terminal_list;
      loaded.device_nos ??= order.device_nos;
      if (loaded.detail != null) {
        loaded.detail!.customer_id ??= resolvedCustomerId;
        loaded.detail!.customer_name ??= customerName;
      }
      // 订单级 exclusive_rule_info 仅供列表外部卡片；详情 UI 禁止读取。
      // 仍写回 order，避免关掉详情后列表徽章用到过期摘要。
      if (loaded.exclusive_rule_info != null) {
        order.exclusive_rule_info = loaded.exclusive_rule_info;
      }
      if (loaded.tags != null) {
        order.tags = loaded.tags;
      }
      _syncOrderTags();

      final loadedItems = loaded.detail?.items ?? loaded.items;
      if (loadedItems != null) {
        // order_detail 常不回写各素材 exclusive_*；用刷新前内存值按 id 盖回，避免串成订单级摘要。
        final previousById = <int, OrderItemEntity>{
          for (final item in releaseItems)
            if (item.id != null) item.id!: item,
        };
        final copy = [
          for (final item in loadedItems)
            if (item.id == null || !_deletedReleaseIds.contains(item.id))
              _mergeExclusiveFromPrevious(item, previousById[item.id]),
        ];
        order.detail ??= OrderDetailEntity()
          ..customer_id = resolvedCustomerId
          ..customer_name = customerName;
        final loadedDetail = loaded.detail;
        order.detail!
          ..customer_id = loadedDetail?.customer_id ?? order.detail!.customer_id
          ..customer_name =
              loadedDetail?.customer_name ?? order.detail!.customer_name
          // 订单级 exclusive_* 只给列表卡片；详情排它只看 items。
          ..exclusive_industry = loadedDetail?.exclusive_industry
          ..exclusive_rule = loadedDetail?.exclusive_rule
          ..loop_rule = loadedDetail?.loop_rule
          ..items = copy;
        order.items = copy;
      }
      _purgeDeletedFromOrder();
    } catch (_) {
      await _reloadOrderItemsFromList();
    }
  }

  Future<void> _reloadOrderItemsFromList() async {
    final cid = resolvedCustomerId;
    final orderId = order.id;
    if (cid == null || orderId == null) return;
    try {
      final resp = await LcdApi.customerOrderList(
        page: 1,
        size: 200,
        param: {'customer_id': cid},
      );
      if (!resp.isSuccess()) return;
      for (final item in resp.data ?? const <OrderEntity>[]) {
        if (item.id == orderId) {
          _applyUpdatedOrder(item);
          _purgeDeletedFromOrder();
          return;
        }
      }
    } catch (_) {
      // 列表回退失败则保留当前内存明细。
    }
  }

  void _purgeDeletedFromOrder() {
    if (_deletedReleaseIds.isEmpty) return;
    bool deleted(OrderItemEntity e) =>
        e.id != null && _deletedReleaseIds.contains(e.id);
    order.detail?.items?.removeWhere(deleted);
    order.items?.removeWhere(deleted);
  }

  void _applyUpdatedOrder(OrderEntity? updated) {
    if (updated == null) return;
    final next = updated.detail?.items ?? updated.items;
    if (next == null) return;
    final previousById = <int, OrderItemEntity>{
      for (final item in releaseItems)
        if (item.id != null) item.id!: item,
    };
    final copy = [
      for (final item in next)
        if (item.id == null || !_deletedReleaseIds.contains(item.id))
          _mergeExclusiveFromPrevious(item, previousById[item.id]),
    ];
    if (order.detail != null) {
      order.detail!.items = copy;
    } else {
      order.detail = OrderDetailEntity()
        ..customer_id = resolvedCustomerId
        ..customer_name = customerName
        ..items = copy;
    }
    order.items = copy;
  }

  /// 接口未带回排它时保留内存中该发布单已有值，避免被订单级摘要污染。
  OrderItemEntity _mergeExclusiveFromPrevious(
    OrderItemEntity loaded,
    OrderItemEntity? previous,
  ) {
    if (previous == null) return loaded;
    final loadedIndustry = loaded.exclusive_industry;
    if (loadedIndustry == null || loadedIndustry.isEmpty) {
      final prevIndustry = previous.exclusive_industry;
      if (prevIndustry != null && prevIndustry.isNotEmpty) {
        loaded.exclusive_industry = List<int>.from(prevIndustry);
      }
    }
    // 0 可能是合法「未开启」；仅在字段缺失（null）时回填。
    if (loaded.exclusive_rule == null && previous.exclusive_rule != null) {
      loaded.exclusive_rule = previous.exclusive_rule;
    }
    if (loaded.loop_rule == null && previous.loop_rule != null) {
      loaded.loop_rule = previous.loop_rule;
    }
    return loaded;
  }

  void selectTab(OrderDetailTab value) => tab.value = value;

  void selectTabIndex(int index) {
    if (index < 0 || index >= OrderDetailTab.values.length) return;
    tab.value = OrderDetailTab.values[index];
  }

  String get statusLabel => orderPlayStatusLabel(order);
  OrderPlayStatus get status => orderPlayStatusOf(order);

  double get progress => orderProgressOf(order);

  String get orderNo {
    final no = order.order_no?.trim();
    if (no != null && no.isNotEmpty) return no;
    if (order.id != null) return '${order.id}';
    return '-';
  }

  /// 为主订单添加标签（type=4）。
  Future<bool> addOrderTag(String tag) async {
    final no = order.order_no?.trim();
    if (no == null || no.isEmpty) {
      showWarn('订单号无效');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请输入标签');
      return false;
    }
    try {
      final resp = await LcdApi.addTags(type: 4, tags: text, orderNo: no);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return false;
      }
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : resp.info());
      await _reloadOrderDetail();
      return true;
    } catch (e) {
      showError('$e');
      return false;
    }
  }

  /// 拉取 order_detail 以刷新标签等字段。
  Future<void> refreshOrderDetail() => _reloadOrderDetail();

  void _syncOrderTags() {
    orderTags
      ..clear()
      ..addAll([
        for (final tag in order.tags ?? const <String>[])
          if (tag.trim().isNotEmpty) tag.trim(),
      ]);
  }

  /// 优先用打开弹窗时传入的客户行业；其次 [customer_order.customer_industry]。
  String get displayIndustryLabel {
    final fromArg = industryLabel.trim();
    if (fromArg.isNotEmpty) return fromArg;
    final fromSummary = order.customer_order?.customer_industry?.trim();
    if (fromSummary != null && fromSummary.isNotEmpty) return fromSummary;
    final fromOrder = order.industry?.trim();
    if (fromOrder != null && fromOrder.isNotEmpty) return fromOrder;
    return '-';
  }

  String get displayCustomerName {
    final fromArg = customerName.trim();
    if (fromArg.isNotEmpty) return fromArg;
    final fromOrder = order.customer_name?.trim();
    if (fromOrder != null && fromOrder.isNotEmpty) return fromOrder;
    final fromDetail = order.detail?.customer_name?.trim();
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;
    return '-';
  }
}

Object? _firstReleaseKey(OrderEntity order) {
  final items = _releaseItemsOf(order);
  if (items.isEmpty) return null;
  return items.first.id ?? identityHashCode(items.first);
}

List<OrderItemEntity> _releaseItemsOf(OrderEntity order) {
  final fromDetail = order.detail?.items;
  if (fromDetail != null && fromDetail.isNotEmpty) {
    return List<OrderItemEntity>.from(fromDetail);
  }
  return List<OrderItemEntity>.from(order.items ?? const <OrderItemEntity>[]);
}

OrderDeviceEntry _orderDeviceEntry({
  int? id,
  String? pointName,
  String? deviceNo,
  OrderItemTerminalEntity? terminal,
}) {
  final name = pointName?.trim();
  final no = deviceNo?.trim();
  final device = LcdDeviceEntity()
    ..id = id ?? terminal?.terminal_id ?? terminal?.id
    ..point_name = name ?? terminal?.device_name ?? terminal?.point_name
    ..device_no = no ?? terminal?.device_no
    ..city = terminal?.city
    ..district = terminal?.district
    ..detailed_address = terminal?.detailed_address
    ..building = terminal?.building
    ..media_address = terminal?.media_address
    ..status = terminal?.status;
  return OrderDeviceEntry(
    propertyName: (name != null && name.isNotEmpty)
        ? name
        : (no != null && no.isNotEmpty ? no : '-'),
    color: LcdDevicesController.folderColor,
    device: device,
  );
}

/// 单个发布单绑定设备（不去重到其它发布单）。
List<OrderDeviceEntry> _devicesFromReleaseItem(OrderItemEntity item) {
  final byId = <int, OrderDeviceEntry>{};
  final byKey = <String, OrderDeviceEntry>{};

  void put({
    int? id,
    String? pointName,
    String? deviceNo,
    OrderItemTerminalEntity? terminal,
  }) {
    final resolvedId = id ?? terminal?.terminal_id ?? terminal?.id;
    if (resolvedId != null) {
      byId.putIfAbsent(
        resolvedId,
        () => _orderDeviceEntry(
          id: resolvedId,
          pointName: pointName ?? terminal?.device_name ?? terminal?.point_name,
          deviceNo: deviceNo ?? terminal?.device_no,
          terminal: terminal,
        ),
      );
      return;
    }
    final key = (deviceNo?.trim().isNotEmpty == true)
        ? 'no:${deviceNo!.trim()}'
        : (pointName?.trim().isNotEmpty == true
              ? 'name:${pointName!.trim()}'
              : null);
    if (key == null) return;
    byKey.putIfAbsent(
      key,
      () => _orderDeviceEntry(pointName: pointName, deviceNo: deviceNo),
    );
  }

  for (final terminal
      in item.terminal_list ?? const <OrderItemTerminalEntity>[]) {
    put(
      id: terminal.terminal_id ?? terminal.id,
      pointName: terminal.device_name ?? terminal.point_name,
      deviceNo: terminal.device_no,
      terminal: terminal,
    );
  }
  final rawIds = item.terminal_ids?.split(',') ?? const <String>[];
  for (final raw in rawIds) {
    final id = int.tryParse(raw.trim());
    if (id == null) continue;
    put(id: id, pointName: '终端 #$id');
  }

  return [...byId.values, ...byKey.values];
}

/// 订单根级终端 / device_nos（明细未带终端时的回退）。
List<OrderDeviceEntry> _devicesFromOrderRoot(OrderEntity order) {
  final byId = <int, OrderDeviceEntry>{};
  final byKey = <String, OrderDeviceEntry>{};

  void put(OrderDeviceEntry entry) {
    final id = entry.device.id;
    if (id != null) {
      byId.putIfAbsent(id, () => entry);
      return;
    }
    final no = entry.device.device_no?.trim();
    final name = entry.propertyName.trim();
    final key = (no != null && no.isNotEmpty)
        ? 'no:$no'
        : (name.isNotEmpty ? 'name:$name' : null);
    if (key == null) return;
    byKey.putIfAbsent(key, () => entry);
  }

  for (final terminal in order.terminal_list ?? const <OrderTerminalEntity>[]) {
    put(
      _orderDeviceEntry(
        id: terminal.terminal_id,
        pointName: terminal.device_name,
        deviceNo: terminal.device_no,
      ),
    );
  }
  if (byId.isNotEmpty || byKey.isNotEmpty) {
    return [...byId.values, ...byKey.values];
  }

  return [
    for (final no in order.device_nos ?? const <String>[])
      if (no.trim().isNotEmpty)
        _orderDeviceEntry(deviceNo: no.trim(), pointName: no.trim()),
  ];
}

/// 汇总各发布单绑定设备；同终端 id / 编号只保留一条。
List<OrderDeviceEntry> _devicesFromOrder(OrderEntity order) {
  final byId = <int, OrderDeviceEntry>{};
  final byKey = <String, OrderDeviceEntry>{};

  void put(OrderDeviceEntry entry) {
    final id = entry.device.id;
    if (id != null) {
      byId.putIfAbsent(id, () => entry);
      return;
    }
    final no = entry.device.device_no?.trim();
    final name = entry.propertyName.trim();
    final key = (no != null && no.isNotEmpty)
        ? 'no:$no'
        : (name.isNotEmpty ? 'name:$name' : null);
    if (key == null) return;
    byKey.putIfAbsent(key, () => entry);
  }

  for (final item in _releaseItemsOf(order)) {
    for (final entry in _devicesFromReleaseItem(item)) {
      put(entry);
    }
  }

  if (byId.isNotEmpty || byKey.isNotEmpty) {
    return [...byId.values, ...byKey.values];
  }

  return _devicesFromOrderRoot(order);
}
