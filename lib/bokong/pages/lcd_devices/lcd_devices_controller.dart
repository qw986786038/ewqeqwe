import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/ad_office_api.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/ad_file_list_entity.dart';
import 'package:yidivination/bokong/entity/lcd/ad_office_building_file_entity.dart';
import 'package:yidivination/bokong/entity/lcd/ad_office_list_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_filter_options_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_play_preview_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_stats_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_terminal_mapper.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_constants.dart';
import 'package:yidivination/bokong/utils/pinyin_initial.dart';
import 'package:yidivination/bokong/widget/amap/amap_marker.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 设备管理页：第一层 [AdOfficeApi.officeList]，第二层 [LcdApi.terminalList]。
class LcdDevicesController extends LxController {
  static const double itemMinWidth = 270;

  /// 楼栋卡片宽度。
  static const double officeItemWidth = 216;

  /// 楼栋卡片整体高度（下层 124，上层 118）。
  static const double itemHeight = 124;

  /// 文件夹内设备内容卡片高度。
  static const double deviceItemHeight = 156;
  static const double itemSpacing = 16;
  static const int pageSize = 40;

  static const soundOptions = [
    AppOption(value: '1', label: '可播放声音'),
    AppOption(value: '0', label: '不可播放声音'),
  ];

  /// 文件夹主色（暂统一 #098292）。
  static const folderColor = Color(0xFF00A0E9);

  /// 地图标记 / 设备卡片色板（按设备稳定取色）。
  static const markerColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF007AFF),
    Color(0xFF43A047),
    Color(0xFFFFC107),
    Color(0xFF8E24AA),
    Color(0xFFFF6CC1),
    Color(0xFFFF6D00),
    Color(0xFF3949AB),
    Color(0xFFD81B60),
    Color(0xFF009688),
    Color(0xFFFF7043),
    Color(0xFF5C6BC0),
    Color(0xFF0097A7),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF20B2AA),
    Color(0xFFF06292),
    Color(0xFF3F51B5),
    Color(0xFFFFA000),
  ];

  /// 兼容旧调用；文件夹仍用 [folderColor]。
  static const avatarColors = <Color>[folderColor];

  final keywordController = TextEditingController();
  final stats = Rxn<LcdTerminalStatsEntity>();
  final officeInfo = Rxn<AdOfficeListInfoEntity>();
  final filterOptions = Rxn<LcdFilterOptionsEntity>();
  final selectedCityId = Rxn<int>();
  final selectedDistrictId = Rxn<int>();
  final selectedOfficeId = Rxn<int>();
  final selectedMediaAddress = Rxn<String>();
  final selectedMediaSize = Rxn<String>();
  final selectedSound = Rxn<String>();

  /// 第一层楼栋列表。
  final offices = <AdOfficeListItemEntity>[].obs;
  final officesLoading = false.obs;
  final officePage = 1.obs;
  final officeTotalPages = 1.obs;

  /// 网格下钻：null 为楼栋列表，非 null 为该楼栋 id。
  final gridOfficeId = Rxn<int>();

  /// 第二层设备列表。
  final devices = <LcdDeviceEntity>[].obs;
  final loading = false.obs;
  final viewMode = LcdDeviceViewMode.grid.obs;

  /// 筛选条件行显隐。
  final filtersVisible = true.obs;
  final page = 1.obs;
  final totalPages = 1.obs;
  final statusFilter = Rxn<int>();
  final selectedDeviceIds = <String>{}.obs;

  /// 楼栋文件夹多选。
  final selectedOfficeFolderIds = <int>{}.obs;

  /// 侧边栏当前楼栋（最后一次点选；仅单选时侧栏展示该项）。
  final selectedOfficeFolderId = Rxn<int>();

  /// 楼栋列表侧边栏显隐。
  final officeSidebarVisible = true.obs;

  /// 侧边栏文件信息（/api/system/ad/file_list/）。
  final sidebarFileList = Rxn<AdFileListEntity>();
  final sidebarFileListLoading = false.obs;

  /// 设备侧边栏：正在播放内容预览（ShowDoc 1515）。
  final playPreview = Rxn<LcdTerminalPlayPreviewEntity>();
  final playPreviewLoading = false.obs;
  final selectedMapSiteId = ''.obs;
  final mapMarkerAnchor = Rxn<AmapMarkerAnchor>();

  /// 名称排序：`desc` / `asc`；空为不传 `title_sort`。
  final titleSort = Rxn<String>();

  /// 创建时间排序：`desc` / `asc`；空为不传 `create_time_sort`。
  final createTimeSort = Rxn<String>();

  Worker? _sidebarFileListFolderWorker;
  Worker? _sidebarFileListGridWorker;
  Worker? _playPreviewWorker;
  Timer? _playPreviewTimer;
  var _playPreviewRequesting = false;
  static const _playPreviewPollInterval = Duration(seconds: 5);

  Future<void> toggleToolbarSort(LcdDevicesToolbarSort mode) async {
    if (mode == LcdDevicesToolbarSort.name) {
      createTimeSort.value = null;
      titleSort.value = _nextSortDir(titleSort.value);
    } else {
      titleSort.value = null;
      createTimeSort.value = _nextSortDir(createTimeSort.value);
    }
    if (isMapMode || isAtDeviceLevel) {
      await loadDevices(toPage: 1);
    } else {
      await loadOffices(toPage: 1);
    }
  }

  static String? _nextSortDir(String? current) => switch (current) {
    null => 'desc',
    'desc' => 'asc',
    _ => null,
  };

  void _applyToolbarSort(Map<String, dynamic> param) {
    final title = titleSort.value;
    if (title != null) param['title_sort'] = title;
    final createTime = createTimeSort.value;
    if (createTime != null) param['create_time_sort'] = createTime;
  }

  int get totalCount =>
      officeInfo.value?.deviceCount ?? stats.value?.total ?? 0;
  int get onlineCount =>
      officeInfo.value?.totalOnline ?? stats.value?.online ?? 0;
  int get offlineCount =>
      officeInfo.value?.totalOffline ?? stats.value?.offline ?? 0;
  int get abnormalCount => officeInfo.value?.totalAbnormal ?? 0;

  bool get isAtDeviceLevel => gridOfficeId.value != null;

  /// 楼栋层（卡片 / 列表共用两级导航；地图不分层）。
  bool get isOfficeGridLevel => !isMapMode && !isAtDeviceLevel;

  /// 侧边栏请求用楼栋 ID：仅单选时有效；多选 / 未选不请求。
  int? get sidebarOfficeId {
    if (isOfficeGridLevel && selectedOfficeFolderIds.length != 1) {
      return null;
    }
    return selectedOfficeFolderId.value ?? gridOfficeId.value;
  }

  AdOfficeListItemEntity? get gridOffice {
    final id = gridOfficeId.value;
    if (id == null) return null;
    for (final item in offices) {
      if (item.office_id == id) return item;
    }
    return null;
  }

  static Color colorAt(int index) => folderColor;

  /// 地图标记色：按设备 id 稳定映射到 [markerColors]。
  static Color markerColorOf(LcdDeviceEntity device) =>
      markerColors[device.uiKey.hashCode.abs() % markerColors.length];

  /// 列表 / 详情 / 预览共用：设备地图钉标（需已具备坐标）。
  static AmapMarker mapMarkerOf(
    LcdDeviceEntity device, {
    bool selected = false,
  }) {
    return AmapMarker(
      id: device.uiKey,
      longitude: device.lng!,
      latitude: device.lat!,
      title: device.displayName,
      description: device.displayAddress,
      initial: pinyinInitialOf(device.displayName),
      accentColor: markerColorOf(device),
      online: device.status == 1,
      selected: selected,
      region: device.displayRegion,
      building: device.building?.trim() ?? '',
      mediaAddress: device.media_address?.trim() ?? '',
      statusLabel: device.displayStatusLabel,
      propertyName: device.property_name?.trim() ?? '',
      operationStatus: device.operation_status?.trim() ?? '',
      soundOn: device.is_volume == 1 || device.play_sound == true,
    );
  }

  Color colorOf(LcdDeviceEntity device) =>
      colorAt(devices.indexOf(device).clamp(0, 1 << 20));

  Color colorOfOffice(AdOfficeListItemEntity office) {
    final index = offices.indexOf(office);
    return colorAt(index < 0 ? 0 : index);
  }

  int serialOf(LcdDeviceEntity device) {
    final index = devices.indexOf(device);
    return index + 1;
  }

  int officeSerialOf(AdOfficeListItemEntity office) {
    final index = offices.indexOf(office);
    return index + 1;
  }

  List<AppOption<int>> get cityOptions => [
    for (final item in filterOptions.value?.cities ?? const [])
      if (item.value != null)
        AppOption(value: item.value!, label: item.label ?? ''),
  ];

  List<AppOption<int>> get districtOptions =>
      districtOptionsFor(selectedCityId.value);

  List<AppOption<int>> districtOptionsFor(int? cityId) {
    return [
      for (final item in filterOptions.value?.districts ?? const [])
        if (item.value != null && (cityId == null || item.city_value == cityId))
          AppOption(value: item.value!, label: item.label ?? ''),
    ];
  }

  /// 更新筛选条件并立即刷新列表。
  void setFilters({
    int? cityId,
    int? districtId,
    int? officeId,
    String? mediaAddress,
    String? mediaSize,
    String? sound,
  }) {
    selectedCityId.value = cityId;
    if (districtId != null &&
        !districtOptionsFor(cityId).any((e) => e.value == districtId)) {
      selectedDistrictId.value = null;
    } else {
      selectedDistrictId.value = districtId;
    }
    selectedOfficeId.value = officeId;
    selectedMediaAddress.value = mediaAddress;
    selectedMediaSize.value = mediaSize;
    selectedSound.value = sound;
    search();
  }

  /// 筛选栏当前生效的条件数。
  int get activeFilterCount {
    var n = 0;
    if (selectedCityId.value != null) n++;
    if (selectedDistrictId.value != null) n++;
    if (selectedOfficeId.value != null) n++;
    if (selectedMediaAddress.value != null) n++;
    if (selectedMediaSize.value != null) n++;
    if (selectedSound.value != null) n++;
    return n;
  }

  /// 楼栋筛选项（`office_building`）。
  List<AppOption<int>> get officeOptions => [
    for (final item in filterOptions.value?.office_building ?? const [])
      if (item.office_id != null)
        AppOption(
          value: item.office_id!,
          label: item.name?.trim().isNotEmpty == true
              ? item.name!.trim()
              : '${item.office_id}',
        ),
  ];

  List<AppOption<String>> get mediaAddressOptions =>
      _uniqueStringOptions(filterOptions.value?.media_address);

  List<AppOption<String>> get mediaSizeOptions {
    final fromApi = _uniqueStringOptions(filterOptions.value?.media_size);
    if (fromApi.isNotEmpty) return fromApi;
    return kLcdMediaSizeOptions;
  }

  List<AppOption<String>> _uniqueStringOptions(
    List<LcdFilterStringOptionEntity>? list,
  ) {
    final seen = <String>{};
    final options = <AppOption<String>>[];
    for (final item in list ?? const []) {
      final value = item.value?.trim() ?? '';
      if (value.isEmpty || !seen.add(value)) continue;
      options.add(AppOption(value: value, label: item.label ?? value));
    }
    return options;
  }

  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();
    loadOffices();
    _sidebarFileListFolderWorker = ever(selectedOfficeFolderIds, (_) {
      loadSidebarFileList();
    });
    _sidebarFileListGridWorker = ever(gridOfficeId, (_) {
      loadSidebarFileList();
    });
    _playPreviewWorker = ever(selectedDeviceIds, (_) {
      loadPlayPreview();
    });
    loadSidebarFileList();
    loadPlayPreview();
  }

  @override
  void onDispose() {
    _sidebarFileListFolderWorker?.dispose();
    _sidebarFileListGridWorker?.dispose();
    _playPreviewWorker?.dispose();
    _stopPlayPreviewPolling();
    keywordController.dispose();
    super.onDispose();
  }

  void _stopPlayPreviewPolling() {
    _playPreviewTimer?.cancel();
    _playPreviewTimer = null;
  }

  void _ensurePlayPreviewPolling() {
    if (_playPreviewTimer != null) return;
    if (selectedDeviceIds.length != 1) return;
    final device = firstSelectedDevice;
    final deviceNo = device?.device_no?.trim() ?? '';
    if (deviceNo.isEmpty) return;
    if (device?.displayStatus != LcdDeviceStatus.online) return;
    _playPreviewTimer = Timer.periodic(_playPreviewPollInterval, (_) {
      loadPlayPreview(silent: true);
    });
  }

  /// 侧边栏：预览当前选中设备正在播放内容（ShowDoc 1515）。
  ///
  /// 单选且在线时每 5 秒静默刷新；离线不请求；[silent] 为 true 时不展示 loading 遮罩。
  Future<void> loadPlayPreview({bool silent = false}) async {
    if (selectedDeviceIds.length != 1) {
      _stopPlayPreviewPolling();
      playPreview.value = null;
      playPreviewLoading.value = false;
      return;
    }
    final device = firstSelectedDevice;
    final deviceNo = device?.device_no?.trim() ?? '';
    if (deviceNo.isEmpty) {
      _stopPlayPreviewPolling();
      playPreview.value = null;
      playPreviewLoading.value = false;
      return;
    }
    if (device?.displayStatus != LcdDeviceStatus.online) {
      _stopPlayPreviewPolling();
      playPreview.value = null;
      playPreviewLoading.value = false;
      return;
    }
    if (!silent) {
      _stopPlayPreviewPolling();
      playPreviewLoading.value = true;
    } else if (_playPreviewRequesting) {
      return;
    }
    _playPreviewRequesting = true;
    try {
      final resp = await LcdApi.terminalPlayPreview(deviceNo: deviceNo);
      if (selectedDeviceIds.length != 1 ||
          firstSelectedDevice?.device_no?.trim() != deviceNo) {
        return;
      }
      if (!resp.isSuccess()) {
        if (!silent) playPreview.value = null;
        return;
      }
      playPreview.value = resp.data;
    } catch (_) {
      if (!silent) playPreview.value = null;
    } finally {
      _playPreviewRequesting = false;
      if (!silent) playPreviewLoading.value = false;
      if (selectedDeviceIds.length == 1 &&
          firstSelectedDevice?.device_no?.trim() == deviceNo &&
          firstSelectedDevice?.displayStatus == LcdDeviceStatus.online) {
        _ensurePlayPreviewPolling();
      } else {
        _stopPlayPreviewPolling();
      }
    }
  }

  /// 侧边栏文件信息（写字楼：ShowDoc 1512 office_building）。
  Future<void> loadSidebarFileList() async {
    final officeId = sidebarOfficeId;
    if (officeId == null) {
      sidebarFileList.value = null;
      sidebarFileListLoading.value = false;
      return;
    }
    sidebarFileListLoading.value = true;
    try {
      final resp = await LcdApi.officeBuildingFile(officeId: officeId);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      sidebarFileList.value = _mapOfficeBuildingFile(resp.data);
    } catch (e) {
      showError('$e');
    } finally {
      sidebarFileListLoading.value = false;
    }
  }

  /// 为当前选中楼栋添加标签（type=3）。
  Future<bool> addOfficeTag(String tag) async {
    final officeId = sidebarOfficeId;
    if (officeId == null) {
      showWarn('请先选择楼栋');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请输入标签');
      return false;
    }
    try {
      final resp = await LcdApi.addTags(
        type: 3,
        tags: text,
        officeId: officeId,
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

  /// 删除当前选中楼栋的标签（type=3）。
  Future<bool> deleteOfficeTag(String tag) async {
    final officeId = sidebarOfficeId;
    if (officeId == null) {
      showWarn('请先选择楼栋');
      return false;
    }
    final text = tag.trim();
    if (text.isEmpty) {
      showWarn('请选择标签');
      return false;
    }
    try {
      final resp = await LcdApi.delTags(
        type: 3,
        tags: text,
        officeId: officeId,
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

  Map<String, dynamic> get _officeQuery {
    final param = <String, dynamic>{};
    final kw = keywordController.text.trim();
    if (kw.isNotEmpty) param['kw'] = kw;
    // 楼栋列表：-1 全部，1 在线，2 离线（UI 用 null 表示全部）。
    param['status'] = statusFilter.value ?? -1;
    final cityId = selectedCityId.value;
    if (cityId != null) param['city_ids'] = '$cityId';
    final districtId = selectedDistrictId.value;
    if (districtId != null) param['district_ids'] = '$districtId';
    final officeId = selectedOfficeId.value;
    if (officeId != null) param['office_id'] = officeId;
    final mediaAddress = selectedMediaAddress.value?.trim();
    if (mediaAddress != null && mediaAddress.isNotEmpty) {
      param['media_address'] = mediaAddress;
    }
    final mediaSize = selectedMediaSize.value?.trim();
    if (mediaSize != null && mediaSize.isNotEmpty) {
      param['media_size'] = mediaSize;
    }
    final sound = selectedSound.value;
    if (sound == '1' || sound == '0') param['is_volume'] = sound;
    _applyToolbarSort(param);
    return param;
  }

  Map<String, dynamic>? get _deviceQuery {
    final param = <String, dynamic>{};
    final kw = keywordController.text.trim();
    if (kw.isNotEmpty) param['kw'] = kw;
    final status = statusFilter.value;
    if (status != null) param['status'] = status;
    final cityId = selectedCityId.value;
    if (cityId != null) param['city_ids'] = '$cityId';
    final districtId = selectedDistrictId.value;
    if (districtId != null) param['district_ids'] = '$districtId';
    // 地图用平铺设备列表，只吃筛选栏楼栋；网格下钻仍用当前楼栋。
    final officeId = isMapMode
        ? selectedOfficeId.value
        : (gridOfficeId.value ?? selectedOfficeId.value);
    if (officeId != null) param['office_id'] = officeId;
    final mediaAddress = selectedMediaAddress.value?.trim();
    if (mediaAddress != null && mediaAddress.isNotEmpty) {
      param['media_address'] = mediaAddress;
    }
    final mediaSize = selectedMediaSize.value?.trim();
    if (mediaSize != null && mediaSize.isNotEmpty) {
      param['media_size'] = mediaSize;
    }
    final sound = selectedSound.value;
    if (sound == '1' || sound == '0') param['is_volume'] = sound;
    _applyToolbarSort(param);
    if (param.isEmpty) return null;
    return param;
  }

  bool get isMapMode => viewMode.value == LcdDeviceViewMode.map;

  Future<void> loadFilterOptions() async {
    try {
      final resp = await LcdApi.terminalLcdFilterOptions();
      filterOptions.value = resp.data;
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadStats() async {
    try {
      final resp = await LcdApi.terminalListStats();
      stats.value = resp.data;
    } catch (e) {
      showError('$e');
    }
  }

  /// 第一层：楼栋列表。
  Future<void> loadOffices({int toPage = 1, bool append = false}) async {
    if (append && officesLoading.value) return;
    final nextPage = toPage;
    officesLoading.value = true;
    try {
      final q = _officeQuery;
      final resp = await AdOfficeApi.officeList(
        deviceTab: 'LCD',
        cityIds: q['city_ids'] as String?,
        districtIds: q['district_ids'] as String?,
        officeId: q['office_id'] as int?,
        mediaAddress: q['media_address'] as String?,
        mediaSize: q['media_size'] as String?,
        isVolume: q['is_volume'] as String?,
        status: q['status'] as int?,
        kw: q['kw'] as String?,
        titleSort: q['title_sort'] as String?,
        createTimeSort: q['create_time_sort'] as String?,
        page: nextPage,
        size: pageSize,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      officeInfo.value = resp.data?.info;
      final list = resp.data?.list ?? const <AdOfficeListItemEntity>[];
      final pages = resp.page?.totalPages ?? 1;
      officePage.value = resp.page?.page ?? nextPage;
      officeTotalPages.value = pages < 1 ? 1 : pages;
      if (append) {
        offices.addAll(list);
      } else {
        offices.replaceAll(list);
      }
      _syncGridOffice();
      _ensureOfficeFolderSelection();
    } catch (e) {
      showError('$e');
    } finally {
      officesLoading.value = false;
    }
  }

  /// 设备列表（网格下钻需当前楼栋；地图模式直接拉终端列表，不走楼栋双层）。
  Future<void> loadDevices({int toPage = 1, bool append = false}) async {
    if (!isMapMode && gridOfficeId.value == null) return;
    if (append && loading.value) return;
    final nextPage = toPage;
    loading.value = true;
    try {
      final resp = await LcdApi.terminalList(
        page: nextPage,
        size: isMapMode ? 500 : pageSize,
        param: _deviceQuery,
      );
      final list = resp.data ?? const <LcdDeviceEntity>[];
      final pages = resp.page?.totalPages ?? 1;
      page.value = resp.page?.page ?? nextPage;
      totalPages.value = pages < 1 ? 1 : pages;
      if (append) {
        devices.addAll(list);
      } else {
        _replaceDevices(list);
        loadStats();
      }
    } catch (e) {
      showError('$e');
    } finally {
      loading.value = false;
    }
  }

  void setViewMode(LcdDeviceViewMode mode) {
    if (viewMode.value == mode) return;
    viewMode.value = mode;
    if (mode == LcdDeviceViewMode.map) {
      exitOfficeGrid();
      clearMapSelection();
      loadDevices(toPage: 1);
      return;
    }
    // 卡片 ↔ 列表只换展示，保留当前层级；离开地图时回到楼栋层。
    if (gridOfficeId.value == null) {
      loadOffices();
    }
  }

  Future<void> enterOfficeGrid(AdOfficeListItemEntity office) async {
    final id = office.office_id;
    if (id == null) return;
    gridOfficeId.value = id;
    devices.clear();
    selectedDeviceIds.clear();
    page.value = 1;
    totalPages.value = 1;
    await loadDevices(toPage: 1);
  }

  void exitOfficeGrid() {
    gridOfficeId.value = null;
    devices.clear();
    selectedDeviceIds.clear();
    page.value = 1;
    totalPages.value = 1;
  }

  void toggleOfficeFolder(int? id) {
    if (id == null) return;
    if (selectedOfficeFolderIds.contains(id)) {
      selectedOfficeFolderIds.remove(id);
      if (selectedOfficeFolderId.value == id) {
        selectedOfficeFolderId.value = selectedOfficeFolderIds.isEmpty
            ? null
            : selectedOfficeFolderIds.first;
      }
    } else {
      selectedOfficeFolderIds.add(id);
      selectedOfficeFolderId.value = id;
    }
    selectedOfficeFolderIds.refresh();
  }

  void selectAllOffices() {
    selectedOfficeFolderIds
      ..clear()
      ..addAll([
        for (final office in offices)
          if (office.office_id != null) office.office_id!,
      ]);
    selectedOfficeFolderId.value = selectedOfficeFolderIds.isEmpty
        ? null
        : selectedOfficeFolderIds.first;
    selectedOfficeFolderIds.refresh();
  }

  void updateSelectedOffices(Iterable<AdOfficeListItemEntity> rows) {
    selectedOfficeFolderIds
      ..clear()
      ..addAll([
        for (final office in rows)
          if (office.office_id != null) office.office_id!,
      ]);
    selectedOfficeFolderId.value = selectedOfficeFolderIds.isEmpty
        ? null
        : selectedOfficeFolderIds.first;
    selectedOfficeFolderIds.refresh();
  }

  void clearOfficeSelection() {
    if (selectedOfficeFolderIds.isEmpty &&
        selectedOfficeFolderId.value == null) {
      return;
    }
    selectedOfficeFolderIds.clear();
    selectedOfficeFolderId.value = null;
    selectedOfficeFolderIds.refresh();
  }

  /// 楼栋列表有数据时保证有选中项：当前无效或为空则选第一项。
  void _ensureOfficeFolderSelection() {
    if (offices.isEmpty) {
      selectedOfficeFolderIds.clear();
      selectedOfficeFolderId.value = null;
      return;
    }
    final validIds = {
      for (final office in offices)
        if (office.office_id != null) office.office_id!,
    };
    selectedOfficeFolderIds.removeWhere((id) => !validIds.contains(id));
    final current = selectedOfficeFolderId.value;
    if (current != null && selectedOfficeFolderIds.contains(current)) {
      selectedOfficeFolderIds.refresh();
      return;
    }
    if (selectedOfficeFolderIds.isNotEmpty) {
      selectedOfficeFolderId.value = selectedOfficeFolderIds.first;
      selectedOfficeFolderIds.refresh();
      return;
    }
    final first = offices.first.office_id;
    selectedOfficeFolderId.value = first;
    if (first != null) selectedOfficeFolderIds.add(first);
    selectedOfficeFolderIds.refresh();
  }

  void _syncGridOffice() {
    final id = gridOfficeId.value;
    if (id == null) return;
    if (!offices.any((e) => e.office_id == id)) {
      exitOfficeGrid();
    }
  }

  void search() {
    if (isMapMode) {
      loadDevices(toPage: 1);
      return;
    }
    if (isAtDeviceLevel) {
      loadDevices(toPage: 1);
      return;
    }
    exitOfficeGrid();
    loadOffices(toPage: 1);
  }

  void resetFilters() => setFilters();

  void setCityId(int? value) {
    selectedCityId.value = value;
    final districtId = selectedDistrictId.value;
    if (districtId == null) return;
    final valid = districtOptions.any((e) => e.value == districtId);
    if (!valid) selectedDistrictId.value = null;
  }

  void selectStatusFilter(int? status) {
    if (statusFilter.value == status) {
      if (isMapMode || isAtDeviceLevel) {
        loadDevices();
      } else {
        loadOffices();
      }
      return;
    }
    statusFilter.value = status;
    if (isMapMode || isAtDeviceLevel) {
      page.value = 1;
      loadDevices(toPage: 1);
      return;
    }
    officePage.value = 1;
    loadOffices(toPage: 1);
  }

  /// 触底加载下一页（地图模式一次拉全量，不追加）。
  void loadMore() {
    if (isMapMode) return;
    if (isAtDeviceLevel) {
      if (loading.value || page.value >= totalPages.value) return;
      loadDevices(toPage: page.value + 1, append: true);
      return;
    }
    if (officesLoading.value || officePage.value >= officeTotalPages.value) return;
    loadOffices(toPage: officePage.value + 1, append: true);
  }

  void _replaceDevices(List<LcdDeviceEntity> list) {
    devices.replaceAll(list);
    final current = selectedMapSiteId.value;
    if (current.isEmpty) return;
    if (!devices.any((device) => device.uiKey == current)) {
      clearMapSelection();
    }
  }

  void selectMapSite(String id, {AmapMarkerAnchor? anchor}) {
    selectedMapSiteId.value = id;
    if (anchor != null) {
      setMapMarkerAnchor(anchor);
    }
  }

  void setMapMarkerAnchor(AmapMarkerAnchor anchor) {
    if (anchor.id.isEmpty) {
      mapMarkerAnchor.value = null;
      return;
    }
    // 忽略无效像素，避免详情卡被 clamp 到左上角
    if (anchor.x <= 0 && anchor.y <= 0) return;
    mapMarkerAnchor.value = anchor;
  }

  void clearMapSelection() {
    selectedMapSiteId.value = '';
    mapMarkerAnchor.value = null;
  }

  LcdDeviceEntity? get selectedMapSite {
    final id = selectedMapSiteId.value;
    if (id.isEmpty) return null;
    for (final device in devices) {
      if (device.uiKey == id) return device;
    }
    return null;
  }

  String propertyNameOf(LcdDeviceEntity device) =>
      device.property_name ?? device.displayName;

  void updateSelectedDevices(Iterable<LcdDeviceEntity> rows) {
    selectedDeviceIds
      ..clear()
      ..addAll(rows.map((e) => e.uiKey));
  }

  void clearDeviceSelection() {
    if (selectedDeviceIds.isEmpty) return;
    selectedDeviceIds.clear();
    selectedDeviceIds.refresh();
  }

  void selectAllDevices() {
    selectedDeviceIds
      ..clear()
      ..addAll(devices.map((e) => e.uiKey));
    selectedDeviceIds.refresh();
  }

  void toggleDeviceSelected(String id) {
    if (selectedDeviceIds.contains(id)) {
      selectedDeviceIds.remove(id);
    } else {
      selectedDeviceIds.add(id);
    }
    selectedDeviceIds.refresh();
  }

  List<String> get selectedDeviceNos {
    final ids = selectedDeviceIds;
    final nos = <String>[];
    for (final device in devices) {
      if (!ids.contains(device.uiKey)) continue;
      final no = device.device_no?.trim() ?? '';
      if (no.isEmpty) continue;
      nos.add(no);
    }
    return nos;
  }

  List<String> get selectedOnlineDeviceNos {
    final ids = selectedDeviceIds;
    final nos = <String>[];
    for (final device in devices) {
      if (!ids.contains(device.uiKey)) continue;
      if (device.status != 1) continue;
      final no = device.device_no?.trim() ?? '';
      if (no.isEmpty) continue;
      nos.add(no);
    }
    return nos;
  }

  LcdDeviceEntity? get firstSelectedDevice {
    final ids = selectedDeviceIds;
    for (final device in devices) {
      if (ids.contains(device.uiKey)) return device;
    }
    return null;
  }

  /// 开关机时段：已选设备全部下发，不按在线过滤。
  List<String>? takeScheduleDeviceNos() {
    if (isOfficeGridLevel) {
      if (selectedOfficeFolderIds.isEmpty) {
        showWarn('请先选择设备');
        return null;
      }
      final nos = selectedOfficeAllTerminalNos;
      if (nos.isEmpty) {
        showWarn('没有可操作的设备');
        return null;
      }
      return nos;
    }
    if (selectedDeviceIds.isEmpty) {
      showWarn('请先选择设备');
      return null;
    }
    final nos = selectedDeviceNos;
    if (nos.isEmpty) {
      showWarn('没有可操作的设备');
      return null;
    }
    return nos;
  }

  List<String>? takeControlDeviceNos() {
    if (isOfficeGridLevel) {
      if (selectedOfficeFolderIds.isEmpty) {
        showWarn('请先选择设备');
        return null;
      }
      final nos = selectedOfficeTerminalNos;
      if (nos.isEmpty) {
        showWarn('没有可操作的在线设备');
        return null;
      }
      return nos;
    }
    if (selectedDeviceIds.isEmpty) {
      showWarn('请先选择设备');
      return null;
    }
    final nos = selectedOnlineDeviceNos;
    if (nos.isEmpty) {
      showWarn('没有可操作的在线设备');
      return null;
    }
    return nos;
  }

  List<String> get selectedOfficeAllTerminalNos {
    final ids = selectedOfficeFolderIds;
    final nos = <String>{};
    for (final office in offices) {
      final id = office.office_id;
      if (id == null || !ids.contains(id)) continue;
      for (final raw in office.terminal_list ?? const <String>[]) {
        final no = raw.trim();
        if (no.isNotEmpty) nos.add(no);
      }
    }
    return nos.toList();
  }

  List<String> get selectedOfficeTerminalNos {
    final ids = selectedOfficeFolderIds;
    final nos = <String>{};
    var hasOnline = false;
    for (final office in offices) {
      final id = office.office_id;
      if (id == null || !ids.contains(id)) continue;
      if ((office.online ?? 0) > 0) hasOnline = true;
      for (final raw in office.terminal_list ?? const <String>[]) {
        final no = raw.trim();
        if (no.isNotEmpty) nos.add(no);
      }
    }
    if (!hasOnline) return const [];
    return nos.toList();
  }

  Future<void> rebootDevices(List<String> deviceNos) => _runBatchTerminalCmd(
    deviceNos,
    (nos) => LcdApi.terminalReboot(deviceNo: nos),
    '重启指令已发送',
  );

  Future<void> setDevicesVolume(List<String> deviceNos, int volume) =>
      _runBatchTerminalCmd(
        deviceNos,
        (nos) => LcdApi.terminalVolume(deviceNo: nos, volume: volume),
        '音量设置已发送',
      );

  Future<void> setDevicesBrightness(List<String> deviceNos, int brightness) =>
      _runBatchTerminalCmd(
        deviceNos,
        (nos) => LcdApi.terminalScreenBrightness(
          deviceNo: nos,
          screenBrightness: brightness,
        ),
        '亮度设置已发送',
      );

  Future<void> setDevicesScreenPower(List<String> deviceNos, int screenPower) =>
      _runBatchTerminalCmd(
        deviceNos,
        (nos) =>
            LcdApi.terminalScreenPower(deviceNo: nos, screenPower: screenPower),
        screenPower == 1 ? '屏幕已开启' : '屏幕已关闭',
      );

  Future<void> setDevicesPowerSchedule(
    List<String> deviceNos,
    String scheduleText,
  ) {
    final slots = lcdDeviceTimeSlotsFromText(scheduleText);
    for (var i = 0; i < slots.length; i++) {
      slots[i].slot_index = i + 1;
    }
    return _runBatchTerminalCmd(
      deviceNos,
      (nos) => LcdApi.terminalEditTimeSlots(deviceNo: nos, timeSlots: slots),
      '开关机时间已更新',
    );
  }

  /// 添加终端设备；失败时抛出异常供弹窗保持打开。
  Future<LcdDeviceEntity?> createTerminalDevice(
    LcdTerminalCreateEntity param,
  ) async {
    final resp = await LcdApi.terminalCreate(param: param);
    if (!resp.isSuccess()) throw resp;
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '添加成功');
    if (isMapMode || isAtDeviceLevel) {
      page.value = 1;
      await loadDevices(toPage: 1);
    } else {
      await loadOffices();
    }
    await loadStats();
    return resp.data;
  }

  Future<void> _runBatchTerminalCmd(
    List<String> deviceNos,
    Future<AppRespEntity<String>> Function(List<String> deviceNo) call,
    String successMsg,
  ) async {
    try {
      final resp = await call(deviceNos);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : successMsg);
    } catch (e) {
      showError('$e');
    }
  }
}

enum LcdDeviceViewMode { grid, list, map }

/// 将写字楼文件详情映射为侧栏 [AdFileListEntity] 结构。
AdFileListEntity? _mapOfficeBuildingFile(AdOfficeBuildingFileEntity? raw) {
  if (raw == null) return null;
  final info = raw.file_info;
  final proportion = raw.device_proportion;
  final segments = <AdFileListChartSegmentEntity>[
    for (var i = 0; i < (proportion?.list?.length ?? 0); i++)
      AdFileListChartSegmentEntity()
        ..id = i + 1
        ..name = proportion!.list![i].name
        ..value = proportion.list![i].count
        ..percentage = _parsePercent(proportion.list![i].percent)
        ..percentage_label = proportion.list![i].percent,
  ];
  return AdFileListEntity()
    ..file_info = info?.name
    ..avatar_icon = info?.avatar_icon
    ..device_basic_data = (AdFileListDeviceBasicEntity()
      ..total_devices = info?.device_total
      ..count_98inch = info?.size_98_count
      ..count_86inch = info?.size_86_count
      ..online_devices = info?.online_device
      ..offline_devices = info?.offline_device
      ..abnormal_devices = info?.abnormal_device
      ..operation_days = info?.operation_days)
    ..advertising_rate_top3 = [
      for (final row in raw.publish_rate_top3 ?? const [])
        AdFileListRateTopEntity()
          ..rank = row.serial_number
          ..media_location = row.media_position
          ..rate = row.publish_rate,
    ]
    ..tags = raw.tag_info
    ..chart = (AdFileListChartEntity()
      ..total = proportion?.total_device
      ..center = (AdFileListChartCenterEntity()
        ..label = '设备总量'
        ..value = proportion?.total_device)
      ..segments = segments)
    ..cards = [
      AdFileListCardEntity()
        ..id = 1
        ..title = '今日播放量'
        ..value = proportion?.today_play_volume
        ..extra = _compareExtra(
          label: '较昨日',
          delta: proportion?.play_volume_compare_yesterday,
        ),
      AdFileListCardEntity()
        ..id = 2
        ..title = '设备总量'
        ..value = proportion?.total_device ?? info?.device_total
        ..extra = _compareExtra(
          label: '较昨日',
          delta: proportion?.device_total_compare_yesterday,
        ),
    ];
}

AdFileListCardExtraEntity _compareExtra({
  required String label,
  required int? delta,
}) {
  final value = delta ?? 0;
  return AdFileListCardExtraEntity()
    ..label = label
    ..value = value.abs()
    ..direction = value < 0 ? 'down' : 'up'
    ..display = '${value.abs()}';
}

double? _parsePercent(String? text) {
  final raw = text?.trim();
  if (raw == null || raw.isEmpty) return null;
  final n = double.tryParse(raw.replaceAll('%', '').replaceAll('％', ''));
  return n;
}

/// 设备管理工具栏排序字段。
enum LcdDevicesToolbarSort { name, time }

enum LcdDeviceStatus { online, offline, abnormal }

extension LcdDeviceEntityUi on LcdDeviceEntity {
  String get uiKey => '${id ?? device_no ?? point_code}';

  String get displayName {
    final pointName = point_name?.trim() ?? '';
    if (pointName.isNotEmpty) return pointName;
    return device_no?.trim() ?? '';
  }

  String get displayRegion {
    final parts = <String>[
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((district ?? '').trim().isNotEmpty) district!.trim(),
    ];
    return parts.join('·');
  }

  String get displayAddress =>
      detailed_address ?? road_name ?? media_address ?? '';

  String get displayFloor => building ?? '';

  String get displayDeviceNo => device_no ?? point_code ?? displayName;

  LcdDeviceStatus get displayStatus =>
      status == 1 ? LcdDeviceStatus.online : LcdDeviceStatus.offline;

  String get displayStatusLabel => switch (displayStatus) {
    LcdDeviceStatus.online => '在线',
    LcdDeviceStatus.offline => '离线',
    LcdDeviceStatus.abnormal => '异常',
  };

  bool get hasMapPoint {
    final lat = this.lat;
    final lng = this.lng;
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return lat.abs() <= 90 && lng.abs() <= 180;
  }
}
