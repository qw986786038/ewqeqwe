import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/lcd/ad_file_list_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_order_file_entity.dart';
import 'package:yidivination/bokong/entity/order/order_customer_entity.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 客户订单页控制器：第一层 [LcdApi.customerList]，第二层 [LcdApi.customerOrderList]。
class OrdersController extends LxController {
  static const double itemMinWidth = 270;

  /// 客户卡片宽度（对齐设备管理楼栋卡）。
  static const double customerItemWidth = 216;

  /// 客户卡片整体高度（下层 124，上层 118）。
  static const double itemHeight = 124;

  /// 文件夹内订单卡片高度（对齐第一层叠卡）。
  static const double orderItemHeight = 124;
  static const double itemSpacing = 16;
  static const int pageSize = 40;

  static const statusOptions = [
    AppOption(value: 'running', label: '执行中'),
    AppOption(value: 'pending', label: '已暂停'),
    AppOption(value: 'ended', label: '已完播'),
  ];

  /// 所属行业级联项（启用中的内容分组，一级 → 二级）。
  final industryOptions = <AppCascadeOption<int>>[].obs;

  /// 文件夹 / 头像主色（与设备页统一品牌蓝）。
  static const folderColor = Color(0xFF00A0E9);

  /// 兼容旧调用；暂与 [folderColor] 相同。
  static const avatarColors = <Color>[folderColor];

  final customers = <OrderCustomerEntity>[].obs;
  final gridOrders = <OrderEntity>[].obs;
  final loading = false.obs;
  final ordersLoading = false.obs;

  /// 网格下钻：null 为客户列表，非 null 为该客户 id。
  final gridCustomerId = Rxn<int>();

  /// 客户文件夹单选（默认选中列表第一项；再点同一项不取消）。
  final selectedCustomerId = Rxn<int>();

  /// 客户列表侧边栏显隐（一级客户 / 二级订单共用）。
  final customerSidebarVisible = true.obs;

  /// 侧边栏文件信息（/api/system/ad/file_list/ type=2）。
  final sidebarFileList = Rxn<AdFileListEntity>();
  final sidebarFileListLoading = false.obs;

  /// 二级：当前选中主订单号（侧栏 ShowDoc 1585）。
  final selectedOrderNo = Rxn<String>();

  /// 二级侧栏：客户订单文件详情。
  final sidebarOrderFile = Rxn<AdCustomerOrderFileEntity>();
  final sidebarOrderFileLoading = false.obs;

  /// 所属行业级联路径：`[一级]` 或 `[一级, 二级]`。
  final selectedIndustry = <int>[].obs;
  final selectedStatusType = Rxn<String>();

  /// 顶栏状态 Tab：null 全部 / running / ended / pending。
  final statusTabFilter = Rxn<String>();
  final selectedDateStart = Rxn<DateTime>();
  final selectedDateEnd = Rxn<DateTime>();
  final viewMode = OrderViewMode.list.obs;

  /// 筛选条件行显隐。
  final filtersVisible = true.obs;
  final page = 1.obs;
  final totalPages = 1.obs;
  final orderPage = 1.obs;
  final orderTotalPages = 1.obs;
  final keywordController = TextEditingController();

  /// 名称排序：`desc` / `asc`；空为不传 `title_sort`。
  final titleSort = Rxn<String>();

  /// 创建时间排序：`desc` / `asc`；空为不传 `create_time_sort`。
  final createTimeSort = Rxn<String>();

  Worker? _sidebarFileListFolderWorker;
  Worker? _sidebarFileListGridWorker;
  Worker? _sidebarOrderFileWorker;

  Future<void> toggleToolbarSort(OrdersToolbarSort mode) async {
    if (mode == OrdersToolbarSort.name) {
      createTimeSort.value = null;
      titleSort.value = _nextSortDir(titleSort.value);
    } else {
      titleSort.value = null;
      createTimeSort.value = _nextSortDir(createTimeSort.value);
    }
    if (gridCustomerId.value != null) {
      await loadOrders(toPage: 1);
    } else {
      await loadCustomers(toPage: 1);
    }
  }

  static String? _nextSortDir(String? current) => switch (current) {
    null => 'desc',
    'desc' => 'asc',
    _ => null,
  };

  void _applyToolbarSort(Map<String, dynamic> params) {
    final title = titleSort.value;
    if (title != null) params['title_sort'] = title;
    final createTime = createTimeSort.value;
    if (createTime != null) params['create_time_sort'] = createTime;
  }

  /// 侧边栏请求用客户 ID：优先文件夹单选，其次下钻客户。
  int? get sidebarCustomerId =>
      selectedCustomerId.value ?? gridCustomerId.value;

  /// 客户列表接口 `obj` 的汇总（顶栏数量）。
  final customerListStatus = Rxn<_CustomerListStatusObj>();

  /// 全部：有未删除订单的客户数 [obj.customer_count]。
  int get totalCount =>
      customerListStatus.value?.customerCount ??
      customers.fold<int>(
        0,
        (sum, e) => sum + (e.order_total_count ?? _customerOrderSum(e)),
      );

  /// 执行中：参考日排期上刊行数 [obj.onplay_count]。
  int get runningCount =>
      customerListStatus.value?.onplayCount ??
      customers.fold<int>(0, (sum, e) => sum + (e.playing_count ?? 0));

  /// 已暂停：obj 无对应字段，暂回退当前页客户 [paused_count] 累加。
  int get pendingCount =>
      customers.fold<int>(0, (sum, e) => sum + (e.paused_count ?? 0));

  /// 已完播：obj 无对应字段，暂回退当前页客户 [finished_count] 累加。
  int get endedCount =>
      customers.fold<int>(0, (sum, e) => sum + (e.finished_count ?? 0));

  /// 未删除订单总数 [obj.order_count]（供其它展示用）。
  int get orderCount => customerListStatus.value?.orderCount ?? 0;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    loadIndustryOptions();
    _sidebarFileListFolderWorker = ever(selectedCustomerId, (_) {
      loadSidebarFileList();
    });
    _sidebarFileListGridWorker = ever(gridCustomerId, (_) {
      loadSidebarFileList();
    });
    _sidebarOrderFileWorker = ever(selectedOrderNo, (_) {
      loadSidebarOrderFile();
    });
    loadSidebarFileList();
  }

  @override
  void onDispose() {
    _sidebarFileListFolderWorker?.dispose();
    _sidebarFileListGridWorker?.dispose();
    _sidebarOrderFileWorker?.dispose();
    keywordController.dispose();
    super.onDispose();
  }

  /// 侧边栏文件信息（type=2 客户；需 customer_id）。
  Future<void> loadSidebarFileList() async {
    final customerId = sidebarCustomerId;
    if (customerId == null) {
      sidebarFileList.value = null;
      sidebarFileListLoading.value = false;
      return;
    }
    sidebarFileListLoading.value = true;
    try {
      final resp = await LcdApi.fileList(
        type: 2,
        customerId: customerId,
        deviceTab: 'LCD',
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      sidebarFileList.value = resp.data;
    } catch (e) {
      showError('$e');
    } finally {
      sidebarFileListLoading.value = false;
    }
  }

  /// 为当前选中客户添加标签（type=2）。
  Future<bool> addCustomerTag(String tag) async {
    final customerId = sidebarCustomerId;
    if (customerId == null) {
      showWarn('请先选择客户');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请输入标签');
      return false;
    }
    try {
      final resp = await LcdApi.addTags(
        type: 2,
        tags: text,
        customerId: customerId,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return false;
      }
      showComplete(resp.info());
      await loadSidebarFileList();
      return true;
    } catch (e) {
      showError('$e');
      return false;
    }
  }

  /// 删除当前选中客户的标签（type=2）。
  Future<bool> deleteCustomerTag(String tag) async {
    final customerId = sidebarCustomerId;
    if (customerId == null) {
      showWarn('请先选择客户');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请选择标签');
      return false;
    }
    try {
      final resp = await LcdApi.delTags(
        type: 2,
        tags: text,
        customerId: customerId,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return false;
      }
      showComplete(resp.info());
      await loadSidebarFileList();
      return true;
    } catch (e) {
      showError('$e');
      return false;
    }
  }

  /// 二级侧栏：按主订单号拉取文件详情（ShowDoc 1585）。
  ///
  /// [silent] 为 true 时不闪 loading（标签增删刷新，避免拆掉输入框）。
  Future<void> loadSidebarOrderFile({bool silent = false}) async {
    final orderNo = selectedOrderNo.value?.trim();
    if (orderNo == null || orderNo.isEmpty) {
      sidebarOrderFile.value = null;
      sidebarOrderFileLoading.value = false;
      return;
    }
    if (!silent) sidebarOrderFileLoading.value = true;
    try {
      final resp = await LcdApi.customerOrderFile(orderNo: orderNo);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      if (selectedOrderNo.value?.trim() != orderNo) return;
      sidebarOrderFile.value = resp.data;
    } catch (e) {
      showError('$e');
    } finally {
      if (!silent) sidebarOrderFileLoading.value = false;
    }
  }

  /// 为当前选中主订单添加标签（type=4）。
  Future<bool> addOrderTag(String tag) async {
    final orderNo = selectedOrderNo.value?.trim();
    if (orderNo == null || orderNo.isEmpty) {
      showWarn('请先选择订单');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请输入标签');
      return false;
    }
    try {
      final resp = await LcdApi.addTags(type: 4, tags: text, orderNo: orderNo);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return false;
      }
      showComplete(resp.info());
      await loadSidebarOrderFile(silent: true);
      return true;
    } catch (e) {
      showError('$e');
      return false;
    }
  }

  /// 删除当前选中主订单的标签（type=4）。
  Future<bool> deleteOrderTag(String tag) async {
    final orderNo = selectedOrderNo.value?.trim();
    if (orderNo == null || orderNo.isEmpty) {
      showWarn('请先选择订单');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请选择标签');
      return false;
    }
    try {
      final resp = await LcdApi.delTags(type: 4, tags: text, orderNo: orderNo);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return false;
      }
      showComplete(resp.info());
      await loadSidebarOrderFile(silent: true);
      return true;
    } catch (e) {
      showError('$e');
      return false;
    }
  }

  Map<String, dynamic> get _listQuery {
    final params = <String, dynamic>{};
    final kw = keywordController.text.trim();
    if (kw.isNotEmpty) params['kw'] = kw;
    // status：-1 全部，1 执行中，2 已完播，3 已暂停（非必传，默认 -1）。
    params['status'] = _statusApiValue;
    final start = selectedDateStart.value;
    final end = selectedDateEnd.value;
    if (start != null) params['start_time'] = start.format('yyyy-MM-dd');
    if (end != null) params['end_time'] = end.format('yyyy-MM-dd');
    final industryIds = _industryFilterIds;
    if (industryIds.isNotEmpty) params['industry_ids'] = industryIds.join(',');
    _applyToolbarSort(params);
    return params;
  }

  /// 顶栏 Tab 优先，其次筛选弹窗；未选则全部 (-1)。
  int get _statusApiValue {
    final raw = statusTabFilter.value ?? selectedStatusType.value;
    return switch (raw) {
      'running' => 1,
      'ended' => 2,
      'pending' => 3,
      _ => -1,
    };
  }

  /// 只选一级时，有二级则传其全部二级 id，否则传一级 id。
  List<int> get _industryFilterIds {
    final path = selectedIndustry;
    if (path.isEmpty) return const [];
    if (path.length > 1) return [path.last];
    final parent = industryOptions.where((e) => e.value == path.first).firstOrNull;
    final children = parent?.children ?? const [];
    return children.isEmpty ? [path.first] : [for (final c in children) c.value];
  }

  Future<void> loadIndustryOptions() async {
    final resp = await LcdApi.contentGroupList(
      page: 1,
      size: 999,
      param: <String, dynamic>{'status': 1},
    );
    if (!resp.isSuccess()) return;
    industryOptions.replaceAll([
      for (final item in resp.data ?? const [])
        if (item.id != null)
          AppCascadeOption<int>(
            value: item.id!,
            label: item.category_name ?? '-',
            children: [
              for (final child in item.children ?? const [])
                if (child.id != null)
                  AppCascadeOption<int>(value: child.id!, label: child.category_name ?? '-'),
            ],
          ),
    ]);
  }

  /// 第一层：订单客户列表。
  Future<void> loadCustomers({int toPage = 1, bool append = false}) async {
    if (append && loading.value) return;
    final nextPage = toPage;
    loading.value = true;
    try {
      final resp = await LcdApi.customerList(
        page: nextPage,
        size: pageSize,
        param: _listQuery,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      final list = resp.data ?? const <OrderCustomerEntity>[];
      final pages = resp.page?.totalPages ?? 1;
      page.value = resp.page?.page ?? nextPage;
      totalPages.value = pages < 1 ? 1 : pages;
      if (append) {
        customers.addAll(list);
      } else {
        customers.replaceAll(list);
      }
      customerListStatus.value = _CustomerListStatusObj.tryParse(resp.obj);
      _syncGridCustomer();
      _ensureCustomerFolderSelection();
    } catch (e) {
      showError('$e');
    } finally {
      loading.value = false;
    }
  }

  void search() {
    if (isGridAtOrderLevel) {
      loadOrders(toPage: 1);
      return;
    }
    exitCustomerGrid();
    loadCustomers(toPage: 1);
  }

  void selectStatusTab(String? status) {
    if (statusTabFilter.value == status) {
      if (isGridAtOrderLevel) {
        loadOrders();
      } else {
        loadCustomers();
      }
      return;
    }
    statusTabFilter.value = status;
    if (isGridAtOrderLevel) {
      orderPage.value = 1;
      loadOrders(toPage: 1);
      return;
    }
    loadCustomers(toPage: 1);
  }

  /// 更新筛选条件并立即刷新列表。
  void setFilters({
    DateTime? dateStart,
    DateTime? dateEnd,
    List<int> industry = const [],
    String? statusType,
  }) {
    selectedDateStart.value = dateStart;
    selectedDateEnd.value = dateEnd;
    selectedIndustry.replaceAll(industry);
    selectedStatusType.value = statusType;
    search();
  }

  /// 筛选栏当前生效的条件数。
  int get activeFilterCount {
    var n = 0;
    if (selectedDateStart.value != null || selectedDateEnd.value != null) n++;
    if (selectedIndustry.isNotEmpty) n++;
    if (selectedStatusType.value != null) n++;
    return n;
  }

  void resetFilters() => setFilters();

  /// 触底加载下一页。
  void loadMore() {
    if (isGridAtOrderLevel) {
      if (ordersLoading.value || orderPage.value >= orderTotalPages.value) return;
      loadOrders(toPage: orderPage.value + 1, append: true);
      return;
    }
    if (loading.value || page.value >= totalPages.value) return;
    loadCustomers(toPage: page.value + 1, append: true);
  }

  static Color colorAt(int index) => folderColor;

  /// 卡片 / 头像主色（暂统一 [folderColor]）。
  Color colorOf(OrderCustomerEntity customer) => folderColor;

  /// 行业标签色：接口 `color` 字段；解析失败时回退主色。
  Color industryColorOf(OrderCustomerEntity customer) =>
      parseHexColor(customer.color) ?? colorOf(customer);

  OrderCustomerEntity? get gridCustomer {
    final id = gridCustomerId.value;
    if (id == null) return null;
    for (final customer in customers) {
      if (customer.customer_id == id) return customer;
    }
    return null;
  }

  bool get isGridAtOrderLevel => gridCustomerId.value != null;

  void selectCustomerFolder(int? id) {
    if (id == null) return;
    // 已选中再点同一项不取消。
    if (selectedCustomerId.value == id) return;
    selectedCustomerId.value = id;
  }

  /// 订单二级：单选主订单（侧栏）；再点同一项不取消。
  void selectOrder(OrderEntity order) {
    final no = order.order_no?.trim();
    if (no == null || no.isEmpty) return;
    if (selectedOrderNo.value == no) return;
    selectedOrderNo.value = no;
  }

  OrderEntity? get selectedOrder {
    final no = selectedOrderNo.value?.trim();
    if (no == null || no.isEmpty) return null;
    for (final item in gridOrders) {
      if (item.order_no?.trim() == no) return item;
    }
    return null;
  }

  /// 客户列表有数据时保证有选中项：当前无效或为空则选第一项。
  void _ensureCustomerFolderSelection() {
    if (customers.isEmpty) {
      selectedCustomerId.value = null;
      return;
    }
    final current = selectedCustomerId.value;
    final stillValid =
        current != null && customers.any((e) => e.customer_id == current);
    if (stillValid) return;
    selectedCustomerId.value = customers.first.customer_id;
  }

  /// 订单列表有数据时保证有选中项。
  void _ensureOrderSelection() {
    if (gridOrders.isEmpty) {
      selectedOrderNo.value = null;
      sidebarOrderFile.value = null;
      return;
    }
    final current = selectedOrderNo.value?.trim();
    final stillValid =
        current != null &&
        current.isNotEmpty &&
        gridOrders.any((e) => e.order_no?.trim() == current);
    if (stillValid) return;
    selectedOrderNo.value = gridOrders.first.order_no?.trim();
  }

  Future<void> enterCustomerGrid(OrderCustomerEntity customer) async {
    final id = customer.customer_id;
    if (id == null) return;
    gridCustomerId.value = id;
    gridOrders.clear();
    selectedOrderNo.value = null;
    sidebarOrderFile.value = null;
    orderPage.value = 1;
    orderTotalPages.value = 1;
    await loadOrders(toPage: 1);
  }

  int customerSerialOf(OrderCustomerEntity customer) {
    return customers.indexOf(customer) + 1;
  }

  int orderSerialOf(OrderEntity order) {
    return gridOrders.indexOf(order) + 1;
  }

  void exitCustomerGrid() {
    gridCustomerId.value = null;
    gridOrders.clear();
    selectedOrderNo.value = null;
    sidebarOrderFile.value = null;
    orderPage.value = 1;
    orderTotalPages.value = 1;
  }

  void setViewMode(OrderViewMode mode) {
    if (viewMode.value == mode) return;
    // 卡片 ↔ 列表只换展示，保留当前层级。
    viewMode.value = mode;
  }

  /// 第二层：当前客户的订单列表。
  Future<void> loadOrders({int toPage = 1, bool append = false}) async {
    final customerId = gridCustomerId.value;
    if (customerId == null) return;
    if (append && ordersLoading.value) return;
    final nextPage = toPage;
    if (nextPage < 1) return;
    ordersLoading.value = true;
    try {
      final kw = keywordController.text.trim();
      final resp = await LcdApi.customerOrderList(
        page: nextPage,
        size: pageSize,
        param: {
          'customer_id': customerId,
          'status': _statusApiValue,
          if (kw.isNotEmpty) 'kw': kw,
          if (titleSort.value != null) 'title_sort': titleSort.value,
          if (createTimeSort.value != null)
            'create_time_sort': createTimeSort.value,
        },
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      // 下钻期间客户可能已切换
      if (gridCustomerId.value != customerId) return;
      final list = resp.data ?? const <OrderEntity>[];
      final pages = resp.page?.totalPages ?? 1;
      orderPage.value = resp.page?.page ?? nextPage;
      orderTotalPages.value = pages < 1 ? 1 : pages;
      if (append) {
        gridOrders.addAll(list);
      } else {
        gridOrders.replaceAll(list);
      }
      _ensureOrderSelection();
    } catch (e) {
      showError('$e');
    } finally {
      ordersLoading.value = false;
    }
  }

  void _syncGridCustomer() {
    final id = gridCustomerId.value;
    if (id == null) return;
    if (!customers.any((e) => e.customer_id == id)) {
      exitCustomerGrid();
    }
  }

  static int _customerOrderSum(OrderCustomerEntity e) =>
      (e.playing_count ?? 0) + (e.paused_count ?? 0) + (e.finished_count ?? 0);

  static double customerProgress(OrderCustomerEntity e) {
    final total = e.order_total_count ?? _customerOrderSum(e);
    if (total <= 0) return 0;
    return (e.finished_count ?? 0) / total;
  }

  static int customerFolderCount(OrderCustomerEntity e) =>
      e.order_total_count ?? _customerOrderSum(e);
}

/// 客户列表 `/customer_list/` 响应 `obj` 汇总。
class _CustomerListStatusObj {
  const _CustomerListStatusObj({
    required this.customerCount,
    required this.orderCount,
    required this.onplayCount,
    this.date,
  });

  /// 有未删除订单的客户数
  final int customerCount;

  /// 上述客户未删除订单数
  final int orderCount;

  /// 上述订单在参考日排期上刊行数
  final int onplayCount;

  /// 参考日期
  final String? date;

  static _CustomerListStatusObj? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = <String, dynamic>{
      for (final e in raw.entries) '${e.key}': e.value,
    };
    int? readInt(String key) {
      final v = map[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    final date = map['date']?.toString().trim();
    return _CustomerListStatusObj(
      customerCount: readInt('customer_count') ?? 0,
      orderCount: readInt('order_count') ?? 0,
      onplayCount: readInt('onplay_count') ?? 0,
      date: (date == null || date.isEmpty) ? null : date,
    );
  }
}

enum OrderViewMode { grid, list }

/// 订单管理工具栏排序字段。
enum OrdersToolbarSort { name, time }

/// 订单播放状态。
///
/// 优先读 [OrderCustomerOrderSummaryEntity.main_status]；根级 [OrderEntity.status] 为上下刊状态。
enum OrderPlayStatus { running, pending, ended }

/// 执行中语义绿（对齐订单卡 / [AppBadge.success]）。
const kOrderPlayRunningColor = Color(0xFF16A34A);

/// 已完播语义蓝。
const kOrderPlayEndedColor = Color(0xFF00A0E9);

/// 订单播放态颜色：执行中绿 / 已完播蓝 / 已暂停红。
Color orderPlayStatusColor(
  OrderPlayStatus status, {
  required Color paused,
}) => switch (status) {
  OrderPlayStatus.running => kOrderPlayRunningColor,
  OrderPlayStatus.ended => kOrderPlayEndedColor,
  OrderPlayStatus.pending => paused,
};

OrderPlayStatus orderPlayStatusOf(OrderEntity order) {
  final main = order.customer_order?.main_status;
  if (main != null) {
    return switch (main) {
      1 => OrderPlayStatus.running,
      2 => OrderPlayStatus.ended,
      _ => OrderPlayStatus.pending,
    };
  }
  if (order.status == 0) return OrderPlayStatus.running;
  if (order.status == 2 || orderProgressOf(order) >= 1) {
    return OrderPlayStatus.ended;
  }
  return OrderPlayStatus.pending;
}

String orderPlayStatusLabel(OrderEntity order) =>
    switch (orderPlayStatusOf(order)) {
      OrderPlayStatus.running => '执行中',
      OrderPlayStatus.pending => '已暂停',
      OrderPlayStatus.ended => '已完播',
    };

double? parseOrderAverageProgress(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  final normalized = text.endsWith('%')
      ? text.substring(0, text.length - 1)
      : text;
  final value = double.tryParse(normalized.trim());
  if (value == null) return null;
  return (value / 100).clamp(0.0, 1.0);
}

double orderProgressOf(OrderEntity order) {
  final fromAverage = parseOrderAverageProgress(
    order.customer_order?.average_per,
  );
  if (fromAverage != null) return fromAverage;

  if (order.customer_order?.main_status == 2) return 1;

  final start = _parseOrderDateTime(order.start_time, endOfDay: false);
  final end = _parseOrderDateTime(order.end_time, endOfDay: true);
  if (start == null || end == null || !end.isAfter(start)) return 0;

  final now = DateTime.now();
  if (now.isBefore(start)) return 0;
  if (!now.isBefore(end)) return 1;
  return (now.difference(start).inMilliseconds /
          end.difference(start).inMilliseconds)
      .clamp(0.0, 1.0);
}

/// 列表外部卡片是否展示「排它」徽章。
///
/// 可看订单级摘要字段；订单详情内部排它禁止用这些字段，只绑各发布单。
bool orderHasExclusive(OrderEntity order) {
  final rootExclusive = order.exclusive?.trim();
  if (rootExclusive != null &&
      rootExclusive.isNotEmpty &&
      rootExclusive != '无') {
    return true;
  }

  final info = order.exclusive_rule_info;
  if (info != null) {
    if ((info.exclusive_duration ?? 0) > 0) return true;
    final industry = info.exclusive_industry?.trim();
    if (industry != null && industry.isNotEmpty && industry != '无') {
      return true;
    }
  }

  final detail = order.detail;
  if ((detail?.exclusive_rule ?? 0) > 0) return true;
  if (detail?.exclusive_industry?.isNotEmpty == true) return true;

  for (final item in _orderReleaseItems(order)) {
    if ((item.exclusive_rule ?? 0) > 0) return true;
    if (item.exclusive_industry?.isNotEmpty == true) return true;
  }
  return false;
}

List<OrderItemEntity> _orderReleaseItems(OrderEntity order) {
  final fromDetail = order.detail?.items;
  if (fromDetail != null && fromDetail.isNotEmpty) {
    return fromDetail;
  }
  return order.items ?? const <OrderItemEntity>[];
}

/// 解析订单日期；仅日期时结束日取当天 23:59:59.999。
DateTime? _parseOrderDateTime(String? raw, {required bool endOfDay}) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) {
    if (endOfDay && !_hasTimeComponent(text)) {
      return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59, 999);
    }
    return parsed;
  }
  // 兼容 `yyyy-MM-dd HH:mm:ss` / `yyyy/MM/dd` 等。
  final normalized = text.replaceAll('/', '-');
  final fallback = DateTime.tryParse(normalized);
  if (fallback == null) return null;
  if (endOfDay && !_hasTimeComponent(normalized)) {
    return DateTime(
      fallback.year,
      fallback.month,
      fallback.day,
      23,
      59,
      59,
      999,
    );
  }
  return fallback;
}

bool _hasTimeComponent(String text) =>
    text.contains('T') || text.contains(' ') || text.contains(':');
