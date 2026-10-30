import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show TimeOfDay;
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_create_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_area_resolver.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_power_period.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_tab_fields.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_utils.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/tabs/lcd_devices_add_basic_tab.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/tabs/lcd_devices_add_device_tab.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/tabs/lcd_devices_add_maintenance_tab.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_constants.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/amap/amap_location_pick_result.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 打开添加设备弹窗；提交成功返回 `true`。
Future<bool> showLcdDevicesAddDialog(
  BuildContext context, {
  LcdDevicesController? listController,
}) async {
  // 等「新建」按钮的 pointer/mouse 事件结束后再打开 overlay，避免 MouseTracker 重入。
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return false;

  final lx = LxScope.maybeOf(context);
  final controller =
      listController ??
      (lx != null && lx.contains<LcdDevicesController>()
          ? lx.find<LcdDevicesController>()
          : null);
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  final submitted = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(720, initialHeight),
    builder: (dialogContext) => LcdDevicesAddDialog(listController: controller),
  ).future;
  return submitted == true;
}

/// 添加设备弹窗：Tab 壳 + 表单提交。
class LcdDevicesAddDialog extends StatefulWidget {
  const LcdDevicesAddDialog({this.listController, super.key});

  final LcdDevicesController? listController;

  @override
  State<LcdDevicesAddDialog> createState() => _LcdDevicesAddDialogState();
}

class _LcdDevicesAddDialogState extends State<LcdDevicesAddDialog> {
  final AppFormController _form = AppFormController();
  AddDeviceTab _tab = AddDeviceTab.basic;
  bool _mountAllForSubmit = false;

  final _periods = <LcdDevicesAddPowerPeriod>[
    LcdDevicesAddPowerPeriod(
      onTime: const TimeOfDay(hour: 8, minute: 0),
      offTime: const TimeOfDay(hour: 22, minute: 0),
    ),
  ];

  String? _cityName;
  int? _cityId;
  String? _districtName;
  int? _districtId;
  AmapLocationPickResult? _location;
  LcdDevicesResolvedArea? _resolvedArea;
  bool _resolvingArea = false;

  static const _yesNoOptions = [
    AppOption(value: true, label: '是'),
    AppOption(value: false, label: '否'),
  ];

  static const _systemOptions = [
    AppOption(value: 'Android', label: 'Android'),
    AppOption(value: 'Linux', label: 'Linux'),
    AppOption(value: 'Windows', label: 'Windows'),
  ];

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  String? get _regionLabel =>
      _resolvedArea?.displayLabel ?? _location?.regionLabel;

  Future<void> _onLocationPicked(AmapLocationPickResult value) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    setState(() {
      _location = value;
      _resolvedArea = null;
      _cityName = null;
      _cityId = null;
      _districtName = null;
      _districtId = null;
      _resolvingArea = true;
    });

    final resolved = await lcdDevicesResolveAreaFromPick(value);
    if (!mounted) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() {
      _resolvingArea = false;
      _resolvedArea = resolved;
      _cityName = resolved?.cityName;
      _cityId = resolved?.cityId;
      _districtName = resolved?.districtName;
      _districtId = resolved?.districtId;
    });
  }

  void _addPeriod() {
    setState(() {
      _periods.add(LcdDevicesAddPowerPeriod());
    });
  }

  Future<void> _removePeriod(int index) async {
    if (_periods.length <= 1) return;
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '删除时段',
      message: '确定删除该开关机时段吗？',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _periods.removeAt(index);
    });
  }

  String? _readString(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}'.trim());
  }

  Future<void> _handleSave() async {
    try {
      if (!_validateBasicExtras(showMessage: true)) return;

      setState(() => _mountAllForSubmit = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      Map<String, Object?>? savedValues;
      var formOk = false;
      try {
        formOk = await _form.submit((values) {
          savedValues = values;
        });
      } finally {
        if (mounted) setState(() => _mountAllForSubmit = false);
      }
      if (!mounted) return;

      if (!formOk) {
        _focusInvalidTab(showMessage: true);
        return;
      }

      final submitted = await _submit(savedValues!);
      if (submitted && mounted) {
        await AppOverlay.close<bool>(context, true);
      }
    } catch (e) {
      if (e is AppRespEntity) {
        showError(e.msg);
      } else {
        showError('$e');
      }
    }
  }

  Widget _buildTabContent(AddDeviceTab tab) {
    return switch (tab) {
      AddDeviceTab.basic => LcdDevicesAddBasicTab(
        periods: _periods,
        onAddPeriod: _addPeriod,
        onRemovePeriod: _removePeriod,
        mediaSizeOptions: kLcdMediaSizeOptions,
        yesNoOptions: _yesNoOptions,
        location: _location,
        regionLabel: _regionLabel,
        onLocationPicked: _onLocationPicked,
      ),
      AddDeviceTab.device => LcdDevicesAddDeviceTab(
        systemOptions: _systemOptions,
      ),
      AddDeviceTab.maintenance => const LcdDevicesAddMaintenanceTab(),
    };
  }

  Widget _buildTabBody() {
    if (_mountAllForSubmit) {
      return Offstage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tab in AddDeviceTab.values) _buildTabContent(tab),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      key: ValueKey(_tab),
      child: _buildTabContent(_tab),
    );
  }

  void _goToTab(AddDeviceTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  bool _hasResolvedArea() => _cityId != null && _districtId != null;

  bool _validateBasicExtras({bool showMessage = false}) {
    if (_resolvingArea) {
      if (showMessage) showWarn('正在解析行政区，请稍候');
      return false;
    }
    if (_location?.isValid != true) {
      _goToTab(AddDeviceTab.basic);
      if (showMessage) {
        showWarn(LcdDevicesAddTabFields.hintFor(AddDeviceTab.basic));
      }
      return false;
    }
    if (!_hasResolvedArea()) {
      _goToTab(AddDeviceTab.basic);
      if (showMessage) showWarn('地图选点未能识别行政区，请重新选点');
      return false;
    }
    if (lcdDevicesTimeSlotsFromPeriods(_periods).isEmpty) {
      _goToTab(AddDeviceTab.basic);
      if (showMessage) showWarn('请至少填写一组开关机时段');
      return false;
    }
    return true;
  }

  void _focusInvalidTab({required bool showMessage}) {
    _form.validateSync();

    if (_location?.isValid != true) {
      _goToTab(AddDeviceTab.basic);
      if (showMessage) {
        showWarn(LcdDevicesAddTabFields.hintFor(AddDeviceTab.basic));
      }
      return;
    }
    if (!_hasResolvedArea()) {
      _goToTab(AddDeviceTab.basic);
      if (showMessage) showWarn('地图选点未能识别行政区，请重新选点');
      return;
    }
    if (lcdDevicesTimeSlotsFromPeriods(_periods).isEmpty) {
      _goToTab(AddDeviceTab.basic);
      if (showMessage) showWarn('请至少填写一组开关机时段');
      return;
    }

    final values = _form.values;
    for (final (tab, fields) in LcdDevicesAddTabFields.tabOrder) {
      for (final name in fields) {
        if (LcdDevicesAddTabFields.isEmptyRequired(name, values)) {
          _goToTab(tab);
          if (showMessage) showWarn(LcdDevicesAddTabFields.hintFor(tab));
          return;
        }
      }
    }

    if (showMessage) showWarn('请完善表单中的必填项');
  }

  /// 校验通过后提交；成功返回 `true`（由 [_handleSave] 关窗）。
  Future<bool> _submit(Map<String, Object?> values) async {
    final controller = widget.listController;
    if (controller == null) {
      showWarn('无法提交，请从设备管理页打开');
      return false;
    }

    final param = LcdTerminalCreateEntity()
      ..device_type = 'LCD'
      ..point_name = _readString(values, 'point_name')
      ..city = _cityName
      ..city_id = _cityId
      ..district = _districtName
      ..district_id = _districtId
      ..detailed_address = _location?.address.trim()
      ..lng = _location?.longitude
      ..lat = _location?.latitude
      ..building = _readString(values, 'building')
      ..media_address = _readString(values, 'media_address')
      ..media_size = _readString(values, 'media_size')
      ..screen_width = _readInt(values['screen_width'])
      ..screen_height = _readInt(values['screen_height'])
      ..time_slots = lcdDevicesTimeSlotsFromPeriods(_periods)
      ..play_sound = values['play_sound'] as bool?
      ..is_volume = (values['play_sound'] as bool?) == true ? 1 : 0
      ..device_no = _readString(values, 'device_no')
      ..accounting_date = _readInt(values['accounting_date'])
      ..power_price = _readString(values, 'power_price')
      ..screen_brand = _readString(values, 'screen_brand')
      ..brand_model = _readString(values, 'brand_model')
      ..system_type = _readString(values, 'system_type')
      ..network_type = _readString(values, 'network_type')
      ..property_name = _readString(values, 'property_name')
      ..property_person = _readString(values, 'property_person')
      ..property_phone = _readString(values, 'property_phone')
      ..maintenance_company = _readString(values, 'maintenance_company')
      ..maintenance_person = _readString(values, 'maintenance_person')
      ..maintenance_phone = _readString(values, 'maintenance_phone')
      ..inspection_department = _readString(values, 'inspection_department')
      ..inspector = _readString(values, 'inspector')
      ..inspection_phone = _readString(values, 'inspection_phone');

    await controller.createTerminalDevice(param);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final fills = AppDialogInteraction.maybeOf(context)?.fillsBounds ?? false;
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.62;

    return AppFormDialog(
      title: const Text('新建设备'),
      constraints: fills
          ? const BoxConstraints()
          : const BoxConstraints(minWidth: 640, maxWidth: 720),
      content: SizedBox(
        width: double.infinity,
        height: fills ? double.infinity : dialogHeight,
        child: AppForm(
          controller: _form,
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AppTabs(
                  index: _tab.index,
                  onChanged: (i) {
                    setState(() => _tab = AddDeviceTab.values[i]);
                  },
                  selectedColor: const Color(0xFFFFFFFF),
                  children: const [
                    AppTabItem(child: Text('基本信息')),
                    AppTabItem(child: Text('设备信息')),
                    AppTabItem(child: Text('维保巡检')),
                  ],
                ),
              ),
              Expanded(
                child: AppCard(
                  borderWidth: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: _buildTabBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(context),
          child: const Text('取消'),
        ),
        AppButton.primary(onPressed: _handleSave, child: const Text('保存')),
      ],
    );
  }
}
