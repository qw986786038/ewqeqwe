import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_filter_options_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_constants.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 选择终端弹窗确认结果。
class OrdersTerminalPickResult {
  const OrdersTerminalPickResult({required this.ids, required this.labels});

  final Set<int> ids;
  final Map<int, String> labels;
}

/// 网格：卡片固定 216×216（1:1），最多 5 列；拉宽弹窗时只加大列间距，不拉伸卡片。
const _kTerminalPickMaxColumns = 5;
const _kTerminalPickCardSize = 216.0;
const _kTerminalPickMinGap = 16.0;

/// 弹窗初始宽度（5 列满宽时的舒适尺寸）。
const _kTerminalPickDialogWidth = 1264.0;

/// 打开「选择终端」弹窗：筛选 + 卡片网格 + 分页。
Future<OrdersTerminalPickResult?> showOrdersTerminalPickDialog({
  required BuildContext context,
  Set<int>? initialSelectedIds,
  Map<int, String>? seedLabels,
}) async {
  final draft = Set<int>.from(initialSelectedIds ?? const <int>{});
  final cache = <int, LcdDeviceEntity>{};

  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  final confirmed = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(_kTerminalPickDialogWidth, initialHeight),
    builder: (dialogContext) => _OrdersTerminalPickDialog(
      draft: draft,
      selectedCache: cache,
      seedLabels: seedLabels ?? const {},
    ),
  ).future;

  if (confirmed != true) return null;
  return OrdersTerminalPickResult(
    ids: draft,
    labels: {
      for (final id in draft)
        id: cache[id]?.displayName ?? seedLabels?[id] ?? '终端 #$id',
    },
  );
}

/// 可缩放窗口壳：随 [AppDialogInteraction.fillsBounds] 铺满可用区域。
class _OrdersTerminalPickDialog extends StatelessWidget {
  const _OrdersTerminalPickDialog({
    required this.draft,
    required this.selectedCache,
    required this.seedLabels,
  });

  final Set<int> draft;
  final Map<int, LcdDeviceEntity> selectedCache;
  final Map<int, String> seedLabels;

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.78;
    final fills = AppDialogInteraction.maybeOf(context)?.fillsBounds ?? false;

    return AppFormDialog(
      title: const Text('选择终端'),
      constraints: fills
          ? const BoxConstraints()
          : const BoxConstraints(
              minWidth: 720,
              maxWidth: _kTerminalPickDialogWidth,
            ),
      content: SizedBox(
        width: double.infinity,
        height: fills ? double.infinity : dialogHeight.clamp(420.0, 720.0),
        child: _TerminalPickerBody(
          draft: draft,
          selectedCache: selectedCache,
          seedLabels: seedLabels,
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<bool>(context, false),
          child: const Text('取消'),
        ),
        AppButton.primary(
          onPressed: () {
            if (draft.isEmpty) {
              showWarn('请至少选择一台终端');
              return;
            }
            AppOverlay.close<bool>(context, true);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _TerminalPickerBody extends StatefulWidget {
  const _TerminalPickerBody({
    required this.draft,
    required this.selectedCache,
    required this.seedLabels,
  });

  final Set<int> draft;
  final Map<int, LcdDeviceEntity> selectedCache;
  final Map<int, String> seedLabels;

  @override
  State<_TerminalPickerBody> createState() => _TerminalPickerBodyState();
}

class _TerminalPickerBodyState extends State<_TerminalPickerBody> {
  static const int _pageSize = LcdDevicesController.pageSize;
  static const double _minGap = _kTerminalPickMinGap;
  static const int _maxColumns = _kTerminalPickMaxColumns;
  static const double _cardSize = _kTerminalPickCardSize;

  LcdFilterOptionsEntity? _filterOptions;
  int? _cityId;
  int? _districtId;
  int? _propertyId;
  String? _mediaAddress;
  String? _mediaSize;
  String? _sound;

  var _tabIndex = 0;
  var _page = 1;
  var _totalPages = 1;
  final _items = <LcdDeviceEntity>[];
  var _loading = true;
  var _loadingFilters = true;
  String? _errorMsg;
  var _listEpoch = 0;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _reload();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final resp = await LcdApi.terminalLcdFilterOptions();
      if (!mounted) return;
      setState(() {
        _filterOptions = resp.data;
        _loadingFilters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingFilters = false);
    }
  }

  Map<String, dynamic> get _queryParam {
    final param = <String, dynamic>{};
    if (_cityId != null) param['city_ids'] = '$_cityId';
    if (_districtId != null) param['district_ids'] = '$_districtId';
    if (_propertyId != null) param['property_id'] = _propertyId;
    final mediaAddress = _mediaAddress?.trim();
    if (mediaAddress != null && mediaAddress.isNotEmpty) {
      param['media_address'] = mediaAddress;
    }
    final mediaSize = _mediaSize?.trim();
    if (mediaSize != null && mediaSize.isNotEmpty) {
      param['media_size'] = mediaSize;
    }
    if (_sound == '1' || _sound == '0') param['is_volume'] = _sound;
    return param;
  }

  List<AppOption<int>> get _cityOptions => [
    for (final item in _filterOptions?.cities ?? const [])
      if (item.value != null)
        AppOption(value: item.value!, label: item.label ?? ''),
  ];

  List<AppOption<int>> _districtOptions(int? cityId) {
    return [
      for (final item in _filterOptions?.districts ?? const [])
        if (item.value != null && (cityId == null || item.city_value == cityId))
          AppOption(value: item.value!, label: item.label ?? ''),
    ];
  }

  List<AppOption<int>> get _propertyOptions => [
    for (final item in _filterOptions?.propertys ?? const [])
      if (item.property_id != null)
        AppOption(
          value: item.property_id!,
          label: item.name?.trim().isNotEmpty == true
              ? item.name!.trim()
              : '${item.property_id}',
        ),
  ];

  List<AppOption<String>> _stringOptions(
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

  List<AppOption<String>> get _mediaAddressOptions =>
      _stringOptions(_filterOptions?.media_address);

  List<AppOption<String>> get _mediaSizeOptions {
    final fromApi = _stringOptions(_filterOptions?.media_size);
    if (fromApi.isNotEmpty) return fromApi;
    return kLcdMediaSizeOptions;
  }

  void _applyFilters() {
    _page = 1;
    _reload();
  }

  Future<void> _reload() async {
    final epoch = ++_listEpoch;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final resp = await LcdApi.terminalList(
        page: _page,
        size: _pageSize,
        param: _queryParam,
      );
      if (!mounted || epoch != _listEpoch) return;
      final list = resp.data ?? const <LcdDeviceEntity>[];
      setState(() {
        _loading = false;
        _items
          ..clear()
          ..addAll(list);
        _totalPages = resp.page?.totalPages ?? 1;
        if (_totalPages < 1) _totalPages = 1;
        _page = resp.page?.page ?? _page;
        _cacheSelectedFrom(list);
      });
    } catch (e) {
      if (!mounted || epoch != _listEpoch) return;
      setState(() {
        _loading = false;
        _errorMsg = _errorMessage(e);
      });
    }
  }

  Future<void> _goPage(int nextPage) async {
    if (nextPage < 1 || nextPage > _totalPages || _loading) return;
    final epoch = ++_listEpoch;
    setState(() {
      _loading = true;
      _errorMsg = null;
      _page = nextPage;
    });
    try {
      final resp = await LcdApi.terminalList(
        page: _page,
        size: _pageSize,
        param: _queryParam,
      );
      if (!mounted || epoch != _listEpoch) return;
      final list = resp.data ?? const <LcdDeviceEntity>[];
      setState(() {
        _loading = false;
        _items
          ..clear()
          ..addAll(list);
        _totalPages = resp.page?.totalPages ?? 1;
        if (_totalPages < 1) _totalPages = 1;
        _page = resp.page?.page ?? _page;
        _cacheSelectedFrom(list);
      });
    } catch (e) {
      if (!mounted || epoch != _listEpoch) return;
      setState(() {
        _loading = false;
        _errorMsg = _errorMessage(e);
      });
    }
  }

  void _cacheSelectedFrom(List<LcdDeviceEntity> devices) {
    for (final device in devices) {
      final id = device.id;
      if (id == null || !widget.draft.contains(id)) continue;
      widget.selectedCache[id] = device;
    }
  }

  static String _errorMessage(Object e) {
    if (e is AppRespEntity) return e.msg ?? '未知错误';
    if (e is AppException) return e.msg ?? '未知错误';
    return e.toString();
  }

  void _toggle(LcdDeviceEntity device) {
    final id = device.id;
    if (id == null) return;
    setState(() {
      if (widget.draft.contains(id)) {
        widget.draft.remove(id);
        widget.selectedCache.remove(id);
      } else {
        widget.draft.add(id);
        widget.selectedCache[id] = device;
      }
    });
  }

  List<LcdDeviceEntity> get _selectedItems {
    final items = <LcdDeviceEntity>[];
    for (final id in widget.draft) {
      final cached = widget.selectedCache[id];
      if (cached != null) {
        items.add(cached);
      } else {
        items.add(
          LcdDeviceEntity()
            ..id = id
            ..point_name = widget.seedLabels[id] ?? '终端 #$id',
        );
      }
    }
    return items;
  }

  Widget _filterSelect<T>({
    Key? key,
    required String hintText,
    required T? value,
    required List<AppOption<T>> options,
    required ValueChanged<T?> onChanged,
  }) {
    return AppSelect<T>(
      key: key,
      hintText: hintText,
      clearable: true,
      value: value,
      options: options,
      onChanged: onChanged,
    ).expanded();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final showingSelected = _tabIndex == 1;
    final selectedCount = widget.draft.length;

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingFilters)
          const LinearProgressIndicator(minHeight: 2)
        else
          Row(
            spacing: 8,
            children: [
              _filterSelect<int>(
                hintText: '城市',
                value: _cityId,
                options: _cityOptions,
                onChanged: (value) {
                  setState(() {
                    _cityId = value;
                    final options = _districtOptions(value);
                    if (_districtId != null &&
                        !options.any((e) => e.value == _districtId)) {
                      _districtId = null;
                    }
                  });
                  _applyFilters();
                },
              ),
              _filterSelect<int>(
                key: ValueKey(_cityId),
                hintText: '行政区',
                value: _districtId,
                options: _districtOptions(_cityId),
                onChanged: (value) {
                  setState(() => _districtId = value);
                  _applyFilters();
                },
              ),
              _filterSelect<int>(
                hintText: '物业名称',
                value: _propertyId,
                options: _propertyOptions,
                onChanged: (value) {
                  setState(() => _propertyId = value);
                  _applyFilters();
                },
              ),
              _filterSelect<String>(
                hintText: '媒体位置',
                value: _mediaAddress,
                options: _mediaAddressOptions,
                onChanged: (value) {
                  setState(() => _mediaAddress = value);
                  _applyFilters();
                },
              ),
              _filterSelect<String>(
                hintText: '媒体尺寸',
                value: _mediaSize,
                options: _mediaSizeOptions,
                onChanged: (value) {
                  setState(() => _mediaSize = value);
                  _applyFilters();
                },
              ),
              _filterSelect<String>(
                hintText: '是否可播放声音',
                value: _sound,
                options: LcdDevicesController.soundOptions,
                onChanged: (value) {
                  setState(() => _sound = value);
                  _applyFilters();
                },
              ),
            ],
          ),
        Row(
          spacing: 12,
          children: [
            AppTabs(
              index: _tabIndex,
              selectedColor: Colors.white,
              onChanged: (index) => setState(() => _tabIndex = index),
              children: const [
                AppTabItem(child: Text('未选择')),
                AppTabItem(child: Text('已选择')),
              ],
            ),
            AppText.body(
              '已选择 ',
              style: TextStyle(color: colors.mutedForeground),
            ),
            AppText.body(
              '$selectedCount',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppText.body(
              ' 个终端',
              style: TextStyle(color: colors.mutedForeground),
            ),
          ],
        ),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: showingSelected ? _selectedGrid() : _unselectedGrid(),
                ),
                if (!showingSelected && _totalPages > 1)
                  Center(
                    child: AppPagination(
                      page: _page,
                      totalPages: _totalPages,
                      maxPages: 5,
                      onPageChanged: _goPage,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _unselectedGrid() {
    if (_loading && _items.isEmpty) {
      return const Center(child: AppCircularProgressIndicator());
    }
    if (_errorMsg != null) {
      return Center(child: AppText.muted(_errorMsg!));
    }
    if (_items.isEmpty) {
      return const Center(child: AppEmptyState());
    }
    return _deviceGrid(_items);
  }

  Widget _selectedGrid() {
    final items = _selectedItems;
    if (items.isEmpty) {
      return const Center(child: AppEmptyState());
    }
    return _deviceGrid(items);
  }

  Widget _deviceGrid(List<LcdDeviceEntity> devices) {
    return FixedSizeGrid(
      itemWidth: _cardSize,
      itemHeight: _cardSize,
      spacing: _minGap,
      maxColumns: _maxColumns,
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final id = device.id;
        final selected = id != null && widget.draft.contains(id);
        return _TerminalPickCard(
          device: device,
          selected: selected,
          onTap: id == null ? null : () => _toggle(device),
        );
      },
    );
  }
}

class _TerminalPickCard extends StatelessWidget {
  const _TerminalPickCard({
    required this.device,
    required this.selected,
    this.onTap,
  });

  final LcdDeviceEntity device;
  final bool selected;
  final VoidCallback? onTap;

  static const _selectedBorder = Color(0xFF22C55E);

  static String _resolution(LcdDeviceEntity device) {
    if (device.screen_width != null && device.screen_height != null) {
      return '${device.screen_width}x${device.screen_height}';
    }
    return '-';
  }

  static String _mediaSizeLabel(LcdDeviceEntity device) {
    final size = device.media_size?.trim();
    if (size != null && size.isNotEmpty) {
      return size.contains('寸') ? size : '$size寸';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    final resolution = _resolution(device);
    final mediaSize = _mediaSizeLabel(device);
    final title = device.displayName.isNotEmpty ? device.displayName : '-';

    return ClipRRect(
      borderRadius: radius,
      child: AppInkWell(
        onPressed: onTap,
        borderRadius: radius,
        hoverOpacity: 0,
        pressedOpacity: 0,
        child: Stack(
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              borderRadius: radius,
              borderWidth: 1,
              borderColor: selected ? _selectedBorder : colors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TerminalPickThumbPlaceholder(
                      mediaSize: device.media_size,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      spacing: 6,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.label(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            if (resolution != '-')
                              AppBadge.custom(
                                color: colors.primary,
                                appearance: AppBadgeStyle.soft,
                                shape: AppBadgeShape.square,
                                size: AppBadgeSize.small,
                                child: Text(resolution),
                              ),
                            if (mediaSize != '-')
                              AppBadge.warning(
                                shape: AppBadgeShape.square,
                                size: AppBadgeSize.small,
                                child: Text(mediaSize),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                left: 0,
                child: CustomPaint(
                  painter: const _TerminalCornerCheckPainter(
                    color: _selectedBorder,
                    innerRadius: 12,
                  ),
                  child: const SizedBox(
                    width: 30,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8, left: 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Icon(
                          AppLucideIcons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 终端卡片缩略图：按媒体尺寸选外观图（98 寸用 100 寸图，其余用 86 寸图）。
class _TerminalPickThumbPlaceholder extends StatelessWidget {
  const _TerminalPickThumbPlaceholder({this.mediaSize});

  /// 媒体尺寸（如「98寸」）。
  final String? mediaSize;

  static const _assetLarge = 'assets/images/terminal_thumb_100.png';
  static const _assetDefault = 'assets/images/terminal_thumb_86.png';
  static const _background = Color(0xFFF2F3F5);

  /// 仅 98 寸机型改用 100 寸外观图。
  bool get _useLargeAsset {
    final match = RegExp(r'\d+').firstMatch(mediaSize ?? '');
    return match != null && int.tryParse(match.group(0)!) == 98;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: ColoredBox(
        color: _background,
        child: Image.asset(
          _useLargeAsset ? _assetLarge : _assetDefault,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// 选中态左上角勾选角标；外轮廓由卡片 [ClipRRect] 裁切，此处只画内侧圆角。
class _TerminalCornerCheckPainter extends CustomPainter {
  const _TerminalCornerCheckPainter({
    required this.color,
    this.innerRadius = 12,
  });

  final Color color;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      bottomRight: Radius.circular(innerRadius.clamp(0, size.shortestSide)),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TerminalCornerCheckPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.innerRadius != innerRadius;
  }
}
