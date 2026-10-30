import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show DateTimeRange;
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/ad_data_analysis_api.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_scene_pic_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_filter_options_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_up_rate_daily_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_up_rate_list_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../lcd_device_scene_pic_utils.dart';
import '../lcd_device_terminal_mapper.dart';
import '../lcd_devices_constants.dart';
import '../lcd_devices_controller.dart';

enum LcdDeviceDetailTab { info, schedule, preview, publishRate }

/// 上刊率区间预设。
enum PublishRateListPreset { all, year1, month6, day90, day30 }

/// 设备详情弹窗：Tab 切换 + 详情拉取/保存。
class LcdDeviceDetailController extends LxController {
  LcdDeviceDetailController({
    required LcdDeviceEntity device,
    required this.accentColor,
    required this.propertyName,
    this.listController,
    LcdDeviceDetailTab initialTab = LcdDeviceDetailTab.info,
  }) : _initialDevice = device,
       tab = initialTab.obs,
       districtId = Rxn(device.district_id),
       pointName = (device.point_name?.trim() ?? '').obs,
       building = (device.building?.trim() ?? '').obs,
       mediaLocation = (device.media_address?.trim() ?? '').obs,
       mediaSize = (device.media_size?.trim() ?? '').obs,
       resolution = lcdDeviceResolutionText(device).obs,
       os = ((device.system_os ?? device.system_type)?.trim() ?? '').obs,
       network = (device.network_type?.trim() ?? '').obs,
       powerSchedule = lcdDevicePowerScheduleText(device).obs,
       bootHours =
           (device.slot_duration_hours_total?.toString() ??
                   device.total_duration?.trim() ??
                   '')
               .obs,
       soundEnabled = lcdDeviceIsVolumeEnabled(device).obs,
       propertyCompany = (device.property_name?.trim() ?? '').obs,
       propertyContact = (device.property_person?.trim() ?? '').obs,
       propertyPhone = (device.property_phone?.trim() ?? '').obs,
       maintenanceCompany = (device.maintenance_company?.trim() ?? '').obs,
       maintenanceContact = (device.maintenance_person?.trim() ?? '').obs,
       maintenancePhone = (device.maintenance_phone?.trim() ?? '').obs,
       inspectionDept = (device.inspection_department?.trim() ?? '').obs,
       inspectionOwner = (device.inspector?.trim() ?? '').obs,
       inspectionPhone = (device.inspection_phone?.trim() ?? '').obs {
    own(tab);
    own(loading);
    own(mapPreviewOpen);
    own(scenePics);
    own(districtId);
    own(pointName);
    own(building);
    own(mediaLocation);
    own(mediaSize);
    own(resolution);
    own(os);
    own(network);
    own(powerSchedule);
    own(bootHours);
    own(soundEnabled);
    own(propertyCompany);
    own(propertyContact);
    own(propertyPhone);
    own(maintenanceCompany);
    own(maintenanceContact);
    own(maintenancePhone);
    own(inspectionDept);
    own(inspectionOwner);
    own(inspectionPhone);
    own(localFilterOptions);
    own(scheduleDevice);
    own(materials);
    own(selectedMaterial);
    own(loadingSchedule);
    own(loadingMaterials);
    own(previewMaterials);
    own(loadingPreview);
    own(scheduleDate);
    own(publishRateDay);
    own(publishRateDaily);
    own(loadingPublishRateDaily);
    own(publishRateListPreset);
    own(publishRateListRange);
    own(publishRateList);
    own(loadingPublishRateList);
    own(publishRateTrendTick);
  }

  final LcdDeviceEntity _initialDevice;
  final Color accentColor;
  final String propertyName;
  final LcdDevicesController? listController;
  final Rx<LcdDeviceDetailTab> tab;

  LcdDeviceEntity? _detail;
  var _bootstrapped = false;
  var _scheduleLoaded = false;
  var _previewLoaded = false;
  final loading = false.obs;

  /// 地图放大弹窗打开时为 true；用于临时卸载详情内小地图，避免 macOS 双 WKWebView 命中错乱。
  final mapPreviewOpen = false.obs;

  final scenePics = <LcdDeviceScenePicEntity>[].obs;

  final Rxn<int> districtId;
  final Rx<String> pointName;
  final Rx<String> building;
  final Rx<String> mediaLocation;
  final Rx<String> mediaSize;
  final Rx<String> resolution;
  final Rx<String> os;
  final Rx<String> network;
  final Rx<String> powerSchedule;
  final Rx<String> bootHours;
  final Rx<bool> soundEnabled;

  final Rx<String> propertyCompany;
  final Rx<String> propertyContact;
  final Rx<String> propertyPhone;
  final Rx<String> maintenanceCompany;
  final Rx<String> maintenanceContact;
  final Rx<String> maintenancePhone;
  final Rx<String> inspectionDept;
  final Rx<String> inspectionOwner;
  final Rx<String> inspectionPhone;
  final localFilterOptions = Rxn<LcdFilterOptionsEntity>();

  /// 当日排期（对齐原排期管理 `programDeviceList`）。
  final scheduleDevice = Rxn<LcdProgramDeviceEntity>();
  final materials = <LcdProgramMaterialEntity>[].obs;
  final selectedMaterial = Rxn<LcdProgramMaterialEntity>();
  final loadingSchedule = false.obs;
  final loadingMaterials = false.obs;
  final previewMaterials = <LcdProgramMaterialEntity>[].obs;
  final loadingPreview = false.obs;
  final scheduleDate = Rxn<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  /// 上刊率分析 · 单日查询日期
  final publishRateDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;
  final publishRateDaily = Rxn<LcdTerminalUpRateDailyEntity>();
  final loadingPublishRateDaily = false.obs;
  var _publishRateDailyLoaded = false;

  /// 上刊率分析 · 右侧区间对比
  final publishRateListPreset = PublishRateListPreset.all.obs;
  final publishRateListRange = Rxn<DateTimeRange>();
  final publishRateList = Rxn<LcdTerminalUpRateListEntity>();
  final loadingPublishRateList = false.obs;
  final publishRateTrendTick = 0.obs;
  var _publishRateListLoaded = false;
  List<AppLineSeries> _publishRateTrendSeries = const [];
  List<String> _publishRateTrendLabels = const [];
  double _publishRateTrendMaxY = 100;

  static const mediaSizeOptions = kLcdMediaSizeOptions;

  static const osOptions = [
    AppOption(value: 'android', label: 'Android'),
    AppOption(value: 'linux', label: 'Linux'),
    AppOption(value: 'windows', label: 'Windows'),
  ];

  static const networkOptions = [
    AppOption(value: 'cable', label: '网线'),
    AppOption(value: 'wifi', label: 'Wi-Fi'),
    AppOption(value: '4g', label: '4G'),
    AppOption(value: '5g', label: '5G'),
  ];

  LcdDeviceEntity get device => _detail ?? _initialDevice;

  LcdFilterOptionsEntity? get _filterOptions =>
      listController?.filterOptions.value ?? localFilterOptions.value;

  List<AppOption<int>> get districtOptions {
    final cityId = device.city_id;
    final all = _filterOptions?.districts ?? const [];
    return [
      for (final item in all)
        if (item.value != null && (cityId == null || item.city_value == cityId))
          AppOption(value: item.value!, label: item.label ?? ''),
    ];
  }

  List<AppOption<String>> get osSelectOptions {
    final current = os.value.trim();
    if (current.isEmpty) return osOptions;
    if (osOptions.any((e) => e.value == current || e.label == current)) {
      return osOptions;
    }
    return [AppOption(value: current, label: current), ...osOptions];
  }

  List<AppOption<String>> get networkSelectOptions {
    final current = network.value.trim();
    if (current.isEmpty) return networkOptions;
    if (networkOptions.any((e) => e.value == current || e.label == current)) {
      return networkOptions;
    }
    return [AppOption(value: current, label: current), ...networkOptions];
  }

  bool get _alive => !isDisposed;

  Future<void> bootstrap() async {
    if (_bootstrapped || !_alive) return;
    _bootstrapped = true;
    _loadFilterOptionsIfNeeded();
    await loadDetail();
    if (!_alive) return;
    await loadSchedule();
    if (!_alive) return;
    if (tab.value == LcdDeviceDetailTab.preview) {
      await loadPreviewSheet();
    } else if (tab.value == LcdDeviceDetailTab.publishRate) {
      await Future.wait([loadPublishRateDaily(), loadPublishRateList()]);
    }
  }

  Future<void> _loadFilterOptionsIfNeeded() async {
    if (listController?.filterOptions.value != null) return;
    if (localFilterOptions.value != null) return;
    try {
      final resp = await LcdApi.terminalLcdFilterOptions();
      if (!_alive) return;
      localFilterOptions.value = resp.data;
    } catch (_) {}
  }

  void selectTab(LcdDeviceDetailTab value) {
    if (!_alive) return;
    tab.value = value;
    if (value == LcdDeviceDetailTab.schedule) loadSchedule();
    if (value == LcdDeviceDetailTab.preview) loadPreviewSheet();
    if (value == LcdDeviceDetailTab.publishRate) {
      loadPublishRateDaily();
      loadPublishRateList();
    }
  }

  void selectTabIndex(int index) {
    if (index < 0 || index >= LcdDeviceDetailTab.values.length) return;
    selectTab(LcdDeviceDetailTab.values[index]);
  }

  String get floorLabel => device.displayFloor;

  String get statusLabel => device.displayStatusLabel;

  LcdDeviceStatus get status => device.displayStatus;

  Future<void> loadDetail() async {
    final id = device.id ?? _initialDevice.id;
    if (id == null || !_alive) return;
    loading.value = true;
    try {
      final resp = await LcdApi.terminalDetail(id: id);
      if (!_alive) return;
      final data = resp.data;
      if (data != null) {
        _detail = data;
        _syncFromDevice(data);
        _refreshListDevice(data);
      }
      await loadScenePics();
    } catch (e) {
      if (!_alive) return;
      showError('$e');
    } finally {
      if (_alive) loading.value = false;
    }
  }

  Future<void> loadScenePics() async {
    final id = device.id;
    if (id == null || !_alive) return;
    try {
      final resp = await LcdApi.terminalScenePicList(id: id);
      if (!_alive) return;
      scenePics.replaceAll(resp.data ?? const []);
    } catch (e) {
      if (!_alive) return;
      showError('$e');
    }
  }

  Future<void> deleteScenePic(String path) async {
    final id = device.id;
    if (id == null) return;
    try {
      await LcdApi.terminalDeleteScenePic(id: id, path: path);
      showComplete('删除成功');
      await loadDetail();
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> pickAndAddScenePic() async {
    if (!_alive) return;
    final localPath = await pickLcdDeviceScenePicFilePath();
    if (localPath == null || !_alive) return;
    try {
      final file = await AdMediaPickedFile.loadUploadAndParse(localPath);
      if (!_alive) return;
      if (file.mediaType != 1 && file.mediaType != 2) {
        showWarn('仅支持上传图片或视频');
        return;
      }
      final storagePath = lcdDeviceScenePicStoragePath(file);
      final paths = [
        for (final item in scenePics)
          if (item.path?.trim().isNotEmpty == true) item.path!.trim(),
        storagePath,
      ];
      await _save((param) => param.scene_pic = lcdDeviceScenePicValue(paths));
      if (!_alive) return;
      await loadScenePics();
    } on StateError catch (e) {
      if (e.message == 'cancelled') return;
      if (!_alive) return;
      showError('$e');
    } catch (e) {
      if (!_alive) return;
      showError('$e');
    }
  }

  Future<void> saveDistrict(int? value) async {
    if (value == null) return;
    String? label;
    for (final item in _filterOptions?.districts ?? const []) {
      if (item.value == value) {
        label = item.label;
        break;
      }
    }
    districtId.value = value;
    await _save((param) {
      param
        ..district_id = value
        ..district = label ?? device.district;
    });
  }

  Future<void> savePointName(String value) async {
    pointName.value = value;
    await _save((param) => param.point_name = value);
  }

  Future<void> saveBuilding(String value) async {
    building.value = value;
    await _save((param) => param.building = value);
  }

  Future<void> saveMediaLocation(String value) async {
    mediaLocation.value = value;
    await _save((param) => param.media_address = value);
  }

  Future<void> saveMediaSize(String? value) async {
    if (value == null) return;
    mediaSize.value = value;
    await _save((param) => param.media_size = value);
  }

  Future<void> saveResolution(String value) async {
    resolution.value = value;
    final (width, height) = lcdDeviceResolutionFromText(value);
    await _save((param) {
      param
        ..screen_width = width
        ..screen_height = height;
    });
  }

  Future<void> savePowerSchedule(String value) async {
    powerSchedule.value = value;
    await _save(
      (param) => param.time_slots = lcdDeviceTimeSlotsFromText(value),
    );
  }

  Future<void> saveOs(String? value) async {
    if (value == null) return;
    os.value = value;
    await _save((param) => param.system_type = value);
  }

  Future<void> saveNetwork(String? value) async {
    if (value == null) return;
    network.value = value;
    await _save((param) => param.network_type = value);
  }

  Future<void> savePropertyCompany(String value) async {
    propertyCompany.value = value;
    await _save((param) => param.property_name = value);
  }

  Future<void> savePropertyContact(String value) async {
    propertyContact.value = value;
    await _save((param) => param.property_person = value);
  }

  Future<void> savePropertyPhone(String value) async {
    propertyPhone.value = value;
    await _save((param) => param.property_phone = value);
  }

  Future<void> saveMaintenanceCompany(String value) async {
    maintenanceCompany.value = value;
    await _save((param) => param.maintenance_company = value);
  }

  Future<void> saveMaintenanceContact(String value) async {
    maintenanceContact.value = value;
    await _save((param) => param.maintenance_person = value);
  }

  Future<void> saveMaintenancePhone(String value) async {
    maintenancePhone.value = value;
    await _save((param) => param.maintenance_phone = value);
  }

  Future<void> saveInspectionDept(String value) async {
    inspectionDept.value = value;
    await _save((param) => param.inspection_department = value);
  }

  Future<void> saveInspectionOwner(String value) async {
    inspectionOwner.value = value;
    await _save((param) => param.inspector = value);
  }

  Future<void> saveInspectionPhone(String value) async {
    inspectionPhone.value = value;
    await _save((param) => param.inspection_phone = value);
  }

  Future<void> _save(
    void Function(LcdTerminalCreateEntity param) mutate,
  ) async {
    final id = device.id;
    if (id == null) {
      showWarn('无法保存');
      return;
    }
    try {
      final param = lcdTerminalCreateFromDevice(device);
      mutate(param);
      final resp = await LcdApi.terminalUpdate(id: id, param: param);
      final merged = resp.data != null
          ? lcdDeviceMergeTerminalParam(resp.data!, param)
          : lcdDeviceMergeTerminalParam(device, param);
      _detail = merged;
      _syncFromDevice(merged);
      _refreshListDevice(merged);
      showComplete('保存成功');
    } catch (e) {
      showError('$e');
    }
  }

  void _syncFromDevice(LcdDeviceEntity data) {
    districtId.value = data.district_id;
    pointName.value = data.point_name?.trim() ?? '';
    building.value = data.building?.trim() ?? '';
    mediaLocation.value = data.media_address?.trim() ?? '';
    mediaSize.value = data.media_size?.trim() ?? '';
    resolution.value = lcdDeviceResolutionText(data);
    os.value = (data.system_os ?? data.system_type)?.trim() ?? '';
    network.value = data.network_type?.trim() ?? '';
    powerSchedule.value = lcdDevicePowerScheduleText(data);
    bootHours.value =
        data.slot_duration_hours_total?.toString() ??
        data.total_duration?.trim() ??
        '';
    soundEnabled.value = lcdDeviceIsVolumeEnabled(data);
    propertyCompany.value = data.property_name?.trim() ?? '';
    propertyContact.value = data.property_person?.trim() ?? '';
    propertyPhone.value = data.property_phone?.trim() ?? '';
    maintenanceCompany.value = data.maintenance_company?.trim() ?? '';
    maintenanceContact.value = data.maintenance_person?.trim() ?? '';
    maintenancePhone.value = data.maintenance_phone?.trim() ?? '';
    inspectionDept.value = data.inspection_department?.trim() ?? '';
    inspectionOwner.value = data.inspector?.trim() ?? '';
    inspectionPhone.value = data.inspection_phone?.trim() ?? '';
  }

  void _refreshListDevice(LcdDeviceEntity updated) {
    final list = listController;
    if (list == null || updated.id == null) return;
    final index = list.devices.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;
    list.devices[index] = updated;
    list.devices.refresh();
  }

  List<String>? takeControlDeviceNos() {
    final no = device.device_no?.trim() ?? '';
    if (no.isEmpty) {
      showWarn('无法操作');
      return null;
    }
    if (device.status != 1) {
      showWarn('没有可操作的在线设备');
      return null;
    }
    return [no];
  }

  String? get scheduleDateText {
    final value = scheduleDate.value;
    if (value == null) return null;
    return DateTime(
      value.year,
      value.month,
      value.day,
    ).millisecondsSinceEpoch.date();
  }

  Future<void> setScheduleDate(DateTime? value) async {
    DateTime? next;
    if (value != null) {
      next = DateTime(value.year, value.month, value.day);
    }
    final current = scheduleDate.value;
    if (current == null && next == null) return;
    if (current != null &&
        next != null &&
        current.year == next.year &&
        current.month == next.month &&
        current.day == next.day) {
      return;
    }
    if (!_alive) return;
    scheduleDate.value = next;
    _scheduleLoaded = false;
    _previewLoaded = false;
    await loadSchedule();
    if (!_alive) return;
    await loadPreviewSheet(force: true);
  }

  String get schedulePublishRateText {
    final rate = scheduleDevice.value?.total_up_per;
    if (rate == null) return '-';
    final percent = rate <= 1 ? rate * 100 : rate;
    return '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%';
  }

  String get publishRateDayParam {
    final d = publishRateDay.value;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// 单日上刊率百分数（0~100）。
  double get publishRateDailyPercent {
    final rate = publishRateDaily.value?.publishRate;
    if (rate == null) return 0;
    return (rate <= 1 ? rate * 100 : rate).clamp(0, 100);
  }

  String get publishRateDailyPercentText {
    final data = publishRateDaily.value;
    if (data?.publishRate == null) return '-';
    final percent = publishRateDailyPercent;
    return '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%';
  }

  Future<void> setPublishRateDay(DateTime? value) async {
    if (value == null) return;
    final next = DateTime(value.year, value.month, value.day);
    final cur = publishRateDay.value;
    if (cur.year == next.year &&
        cur.month == next.month &&
        cur.day == next.day) {
      return;
    }
    publishRateDay.value = next;
    _publishRateDailyLoaded = false;
    await loadPublishRateDaily(force: true);
  }

  Future<void> loadPublishRateDaily({bool force = false}) async {
    if (!_alive) return;
    if (!force && _publishRateDailyLoaded) return;
    if (loadingPublishRateDaily.value) return;
    final terminalId = device.id ?? _initialDevice.id;
    if (terminalId == null) {
      showWarn('设备 ID 无效');
      return;
    }
    loadingPublishRateDaily.value = true;
    try {
      final resp = await AdDataAnalysisApi.terminalUpRateDaily(
        terminalId: terminalId,
        date: publishRateDayParam,
      );
      if (!_alive) return;
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      publishRateDaily.value = resp.data;
      _publishRateDailyLoaded = true;
    } catch (e) {
      if (!_alive) return;
      _onScheduleApiError(e);
    } finally {
      if (_alive) loadingPublishRateDaily.value = false;
    }
  }

  String get publishRateDeviceAvgText =>
      publishRateList.value?.summary?.deviceAvgRate?.trim().isNotEmpty == true
      ? publishRateList.value!.summary!.deviceAvgRate!.trim()
      : '-';

  String get publishRateTop1AvgText =>
      publishRateList.value?.summary?.top1AvgRate?.trim().isNotEmpty == true
      ? publishRateList.value!.summary!.top1AvgRate!.trim()
      : '-';

  String get publishRateGapWithTop1Text =>
      publishRateList.value?.summary?.gapWithTop1?.trim().isNotEmpty == true
      ? publishRateList.value!.summary!.gapWithTop1!.trim()
      : '-';

  List<AppLineSeries> get publishRateTrendSeries {
    publishRateTrendTick.value;
    return _publishRateTrendSeries;
  }

  List<String> get publishRateTrendLabels {
    publishRateTrendTick.value;
    return _publishRateTrendLabels;
  }

  double get publishRateTrendMaxY {
    publishRateTrendTick.value;
    return _publishRateTrendMaxY;
  }

  String? get publishRateListStartParam {
    final range = publishRateListRange.value;
    if (range == null) return null;
    return _formatYmd(range.start);
  }

  String? get publishRateListEndParam {
    final range = publishRateListRange.value;
    if (range == null) return null;
    return _formatYmd(range.end);
  }

  void selectPublishRateListPreset(PublishRateListPreset? value) {
    if (value == null || publishRateListPreset.value == value) return;
    publishRateListPreset.value = value;
    publishRateListRange.value = _rangeForPublishRatePreset(value);
    _publishRateListLoaded = false;
    _clearPublishRateTrend();
    Future.microtask(() => loadPublishRateList(force: true));
  }

  void setPublishRateListRange(DateTimeRange? value) {
    publishRateListRange.value = value;
    if (value != null &&
        publishRateListPreset.value != PublishRateListPreset.all) {
      publishRateListPreset.value = PublishRateListPreset.all;
    }
    _publishRateListLoaded = false;
    _clearPublishRateTrend();
    Future.microtask(() => loadPublishRateList(force: true));
  }

  Future<void> loadPublishRateList({bool force = false}) async {
    if (!_alive) return;
    if (!force && _publishRateListLoaded) return;
    if (loadingPublishRateList.value) return;
    final terminalId = device.id ?? _initialDevice.id;
    if (terminalId == null) {
      showWarn('设备 ID 无效');
      return;
    }
    loadingPublishRateList.value = true;
    try {
      final resp = await AdDataAnalysisApi.terminalUpRateList(
        terminalId: terminalId,
        startDate: publishRateListStartParam,
        endDate: publishRateListEndParam,
      );
      if (!_alive) return;
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      publishRateList.value = resp.data;
      _refreshPublishRateTrend(resp.data);
      _publishRateListLoaded = true;
    } catch (e) {
      if (!_alive) return;
      _onScheduleApiError(e);
    } finally {
      if (_alive) loadingPublishRateList.value = false;
    }
  }

  void _clearPublishRateTrend() {
    _publishRateTrendSeries = const [];
    _publishRateTrendLabels = const [];
    _publishRateTrendMaxY = 100;
    publishRateTrendTick.value++;
  }

  void _refreshPublishRateTrend(LcdTerminalUpRateListEntity? data) {
    final chart = data?.trendChart;
    final dates = chart?.dateList ?? const <String>[];
    final current = chart?.currentDevice;
    final top1 = chart?.top1Device;
    final currentRates = current?.rateList ?? const <double>[];
    final top1Rates = top1?.rateList ?? const <double>[];
    final len = [
      dates.length,
      currentRates.length,
      top1Rates.length,
    ].where((n) => n > 0).fold<int>(0, (a, b) => a == 0 ? b : (a < b ? a : b));

    if (len == 0) {
      _clearPublishRateTrend();
      return;
    }

    final labels = <String>[
      for (var i = 0; i < len; i++)
        i < dates.length && dates[i].trim().isNotEmpty
            ? _formatMdLabel(dates[i].trim())
            : '${i + 1}',
    ];
    final currentYs = <double>[
      for (var i = 0; i < len; i++)
        i < currentRates.length ? currentRates[i] : 0,
    ];
    final top1Ys = <double>[
      for (var i = 0; i < len; i++) i < top1Rates.length ? top1Rates[i] : 0,
    ];

    // 用两序列逐点取 max 做 LTTB，避免只按当前设备抽稀时丢掉 TOP1 尖峰。
    const maxPoints = 100;
    final envelope = <AppLinePoint>[
      for (var i = 0; i < len; i++)
        AppLinePoint(
          x: i.toDouble(),
          y: currentYs[i] > top1Ys[i] ? currentYs[i] : top1Ys[i],
          label: labels[i],
        ),
    ];
    final indices = envelope.length <= maxPoints
        ? [for (var i = 0; i < envelope.length; i++) i]
        : appChartSampleIndices<AppLinePoint>(
            envelope,
            maxPoints: maxPoints,
            x: (p) => p.x,
            y: (p) => p.y ?? 0,
          );

    var maxY = 0.0;
    final alignedCurrent = <AppLinePoint>[];
    final alignedTop1 = <AppLinePoint>[];
    final sampledLabels = <String>[];
    for (var j = 0; j < indices.length; j++) {
      final i = indices[j];
      final cy = currentYs[i];
      final ty = top1Ys[i];
      if (cy > maxY) maxY = cy;
      if (ty > maxY) maxY = ty;
      final label = labels[i];
      sampledLabels.add(label);
      alignedCurrent.add(AppLinePoint(x: j.toDouble(), y: cy, label: label));
      alignedTop1.add(AppLinePoint(x: j.toDouble(), y: ty, label: label));
    }

    _publishRateTrendMaxY = _nicePublishRateMaxY(maxY);
    _publishRateTrendLabels = sampledLabels;
    _publishRateTrendSeries = [
      AppLineSeries(
        name: current?.name?.trim().isNotEmpty == true
            ? current!.name!.trim()
            : '此设备',
        color: const Color(0xFF4F46E5),
        showPoints: true,
        points: alignedCurrent,
      ),
      AppLineSeries(
        name: top1?.name?.trim().isNotEmpty == true
            ? top1!.name!.trim()
            : 'TOP1设备',
        color: const Color(0xFF14B8A6),
        showPoints: true,
        points: alignedTop1,
      ),
    ];
    publishRateTrendTick.value++;
  }

  /// Y 轴至少 100；有更大峰值时按 4 档上取整，完整保留大值。
  static double _nicePublishRateMaxY(double maxY) {
    if (maxY <= 100) return 100;
    final step = (maxY / 4).ceilToDouble();
    if (step <= 0) return 100;
    return (maxY / step).ceil() * step;
  }

  static DateTimeRange? _rangeForPublishRatePreset(
    PublishRateListPreset preset,
  ) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    return switch (preset) {
      PublishRateListPreset.all => null,
      PublishRateListPreset.year1 => DateTimeRange(
        end.subtract(const Duration(days: 365)),
        end,
      ),
      PublishRateListPreset.month6 => DateTimeRange(
        end.subtract(const Duration(days: 180)),
        end,
      ),
      PublishRateListPreset.day90 => DateTimeRange(
        end.subtract(const Duration(days: 90)),
        end,
      ),
      PublishRateListPreset.day30 => DateTimeRange(
        end.subtract(const Duration(days: 30)),
        end,
      ),
    };
  }

  static String _formatYmd(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static String _formatMdLabel(String ymd) {
    final parts = ymd.split('-');
    if (parts.length >= 3) {
      return '${parts[1]}-${parts[2]}';
    }
    return ymd;
  }

  Future<void> loadSchedule() async {
    if (!_alive || _scheduleLoaded || loadingSchedule.value) return;
    final terminalId = device.id ?? _initialDevice.id;
    if (terminalId == null) return;
    loadingSchedule.value = true;
    try {
      final resp = await LcdApi.programDeviceList(
        page: 1,
        size: 1,
        param: {
          'terminal_id': terminalId,
          if (scheduleDateText != null) 'schedule_date': scheduleDateText,
        },
      );
      if (!_alive) return;
      final list = resp.data ?? const <LcdProgramDeviceEntity>[];
      scheduleDevice.value = list.isEmpty ? null : list.first;
      selectedMaterial.value = null;
      _scheduleLoaded = true;
      await loadMaterials();
    } catch (e) {
      if (!_alive) return;
      _onScheduleApiError(e);
      // 无排期时仍标记已加载，页面走空状态，避免反复请求弹错。
      if (_isNoScheduleError(e)) _scheduleLoaded = true;
    } finally {
      if (_alive) loadingSchedule.value = false;
    }
  }

  Future<void> loadMaterials() async {
    if (!_alive) return;
    final scheduleId = scheduleDevice.value?.id;
    if (scheduleId == null) {
      materials.clear();
      selectedMaterial.value = null;
      return;
    }
    loadingMaterials.value = true;
    try {
      final resp = await LcdApi.programMaterialList(
        page: 1,
        size: 200,
        param: {'schedule_id': scheduleId},
        date: scheduleDateText,
        terminalId: device.id ?? _initialDevice.id,
      );
      if (!_alive) return;
      final list = resp.data ?? const <LcdProgramMaterialEntity>[];
      materials.replaceAll(list);
      final selectedId = selectedMaterial.value?.id;
      if (selectedId != null) {
        LcdProgramMaterialEntity? matched;
        for (final item in list) {
          if (item.id == selectedId) {
            matched = item;
            break;
          }
        }
        selectedMaterial.value = matched ?? (list.isEmpty ? null : list.first);
      } else {
        selectedMaterial.value = list.isEmpty ? null : list.first;
      }
    } catch (e) {
      if (!_alive) return;
      _onScheduleApiError(e);
    } finally {
      if (_alive) loadingMaterials.value = false;
    }
  }

  Future<void> loadPreviewSheet({bool force = false}) async {
    if (!_alive) return;
    if (_previewLoaded && !force) return;
    if (loadingPreview.value) return;
    loadingPreview.value = true;
    try {
      if (!_scheduleLoaded) await loadSchedule();
      if (!_alive) return;
      final resp = await LcdApi.programPreviewSheet(
        scheduleId: scheduleDevice.value?.id,
        date: scheduleDateText,
        terminalId: device.id ?? _initialDevice.id,
      );
      if (!_alive) return;
      final list = List<LcdProgramMaterialEntity>.from(
        resp.data ?? const <LcdProgramMaterialEntity>[],
      );
      previewMaterials.replaceAll(list);
      _previewLoaded = true;
    } catch (e) {
      if (!_alive) return;
      _onScheduleApiError(e, clearPreview: true);
    } finally {
      if (_alive) loadingPreview.value = false;
    }
  }

  void selectMaterial(LcdProgramMaterialEntity material) {
    selectedMaterial.value = material;
  }

  Future<void> reorderMaterials(
    List<Object> orderedKeys,
    List<LcdProgramMaterialEntity> orderedRows,
  ) async {
    if (_sameMaterialOrder(materials, orderedRows)) return;
    final scheduleId = scheduleDevice.value?.id;
    if (scheduleId == null) return;

    final backup = List<LcdProgramMaterialEntity>.from(materials);
    materials.replaceAll(orderedRows);
    for (var i = 0; i < materials.length; i++) {
      materials[i].play_sort = i + 1;
    }

    final ids = materials.map((e) => e.id).whereType<int>().toList();
    if (ids.length != materials.length) {
      materials.replaceAll(backup);
      showWarn('存在无效素材 ID，无法排序');
      return;
    }

    try {
      await LcdApi.programMaterialReorder(scheduleId: scheduleId, ids: ids);
    } catch (e) {
      materials.replaceAll(backup);
      for (var i = 0; i < materials.length; i++) {
        materials[i].play_sort = i + 1;
      }
      _onScheduleApiError(e);
    }
  }

  Future<void> reorderPreviewMaterials(
    List<Object> orderedKeys,
    List<LcdProgramMaterialEntity> orderedRows,
  ) async {
    if (_sameMaterialOrder(previewMaterials, orderedRows)) return;
    final scheduleId = scheduleDevice.value?.id;
    if (scheduleId == null) return;

    final backup = List<LcdProgramMaterialEntity>.from(previewMaterials);
    previewMaterials.replaceAll(orderedRows);

    if (previewMaterials.any((e) => e.id == null)) {
      previewMaterials.replaceAll(backup);
      showWarn('存在无效素材 ID，无法排序');
      return;
    }

    // 预览列表按格子展开，同一节目会出现多次；按首次出现顺序去重后提交。
    final ids = previewMaterials.map((e) => e.id!).toSet().toList();
    try {
      await LcdApi.programMaterialReorder(scheduleId: scheduleId, ids: ids);
      await loadMaterials();
      await loadPreviewSheet(force: true);
    } catch (e) {
      previewMaterials.replaceAll(backup);
      _onScheduleApiError(e);
    }
  }

  Future<void> startScheduleExecution() async {
    final scheduleId = scheduleDevice.value?.id;
    if (scheduleId == null) return;
    try {
      final resp = await LcdApi.programScheduleExecute(
        scheduleId: scheduleId,
        action: 'start',
      );
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '保存并执行成功');
    } catch (e) {
      _onScheduleApiError(e);
    }
  }

  Future<void> createProgram(LcdProgramCreateEntity param) async {
    final resp = await LcdApi.programCreateForSchedule(param: param);
    if (!resp.isSuccess()) throw resp;
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '创建节目成功');
    await loadMaterials();
    await loadPreviewSheet(force: true);
  }

  Future<void> toggleMaterialShelf(LcdProgramMaterialEntity material) async {
    final id = material.id;
    if (id == null) {
      showWarn('素材 ID 无效');
      return;
    }
    final onShelf = material.is_delete == 1;
    try {
      await LcdApi.programMaterialShelf(id: id, onShelf: onShelf);
      await loadMaterials();
    } catch (e) {
      _onScheduleApiError(e);
    }
  }

  Future<void> toggleMaterialPlay(LcdProgramMaterialEntity material) async {
    final id = material.id;
    if (id == null) {
      showWarn('素材 ID 无效');
      return;
    }
    // 1=播放中 → 暂停；2=暂停 → 启动；3=已结束不可操作。
    final status = material.program_status;
    if (status == 3) {
      showWarn('节目已结束，无法暂停或启动');
      return;
    }
    final start = status == 2;
    try {
      await LcdApi.programMaterialPlay(id: id, start: start);
      await loadMaterials();
    } catch (e) {
      _onScheduleApiError(e);
    }
  }

  Future<void> updateMaterialRule({
    required int materialId,
    Set<int>? industryIds,
    int? exclusiveRule,
    int? loopRule,
  }) async {
    try {
      await LcdApi.programMaterialUpdateRule(
        id: materialId,
        exclusiveIndustry: industryIds?.toList(),
        exclusiveRule: exclusiveRule,
        loopRule: loopRule,
      );
      final selectedId = selectedMaterial.value?.id;
      await loadMaterials();
      if (selectedId != null) {
        for (final item in materials) {
          if (item.id == selectedId) {
            selectedMaterial.value = item;
            break;
          }
        }
      }
    } catch (e) {
      _onScheduleApiError(e);
    }
  }

  bool _sameMaterialOrder(
    List<LcdProgramMaterialEntity> currentRows,
    List<LcdProgramMaterialEntity> orderedRows,
  ) {
    if (currentRows.length != orderedRows.length) return false;
    for (var i = 0; i < currentRows.length; i++) {
      if (currentRows[i].id != orderedRows[i].id ||
          currentRows[i].preview_seq != orderedRows[i].preview_seq) {
        return false;
      }
    }
    return true;
  }

  void _clearScheduleEmptyState({bool clearPreview = false}) {
    scheduleDevice.value = null;
    selectedMaterial.value = null;
    materials.clear();
    if (clearPreview) {
      previewMaterials.clear();
      _previewLoaded = true;
    }
  }

  bool _isNoScheduleError(Object e) {
    final String? msg;
    if (e is AppRespEntity) {
      msg = e.msg;
    } else if (e is AppException) {
      msg = e.msg;
    } else {
      msg = e.toString();
    }
    if (msg == null || msg.isEmpty) return false;
    return msg.contains('当日无排期') || msg.contains('当日暂无排期');
  }

  void _onScheduleApiError(Object e, {bool clearPreview = false}) {
    if (_isNoScheduleError(e)) {
      _clearScheduleEmptyState(clearPreview: clearPreview);
      return;
    }
    if (e is AppRespEntity) {
      showError(e.msg);
    } else if (e is AppException) {
      showError(e.msg);
    } else {
      showError(e.toString());
    }
  }
}
