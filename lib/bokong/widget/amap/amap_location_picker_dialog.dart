import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/amap/amap_location_pick_result.dart';
import 'package:yidivination/bokong/widget/amap/amap_location_picker_widget.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';

/// 打开地图选点弹窗；确认后返回选点结果。
Future<AmapLocationPickResult?> showAmapLocationPickerDialog({
  required BuildContext context,
  AmapLocationPickResult? initial,
  String? city,
  String title = '选择详细地址',
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  return showAppWindowDialog<AmapLocationPickResult>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(720, initialHeight),
    builder: (dialogContext) =>
        _AmapLocationPickerDialog(title: title, initial: initial, city: city),
  ).future;
}

class _AmapLocationPickerDialog extends StatefulWidget {
  const _AmapLocationPickerDialog({
    required this.title,
    this.initial,
    this.city,
  });

  final String title;
  final AmapLocationPickResult? initial;
  final String? city;

  @override
  State<_AmapLocationPickerDialog> createState() =>
      _AmapLocationPickerDialogState();
}

class _AmapLocationPickerDialogState extends State<_AmapLocationPickerDialog> {
  final GlobalKey<AmapLocationPickerWidgetState> _pickerKey =
      GlobalKey<AmapLocationPickerWidgetState>();
  final TextEditingController _searchController = TextEditingController();

  AmapLocationPickResult? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    _pickerKey.currentState?.searchByKeyword(keyword);
  }

  void _confirm(BuildContext dialogContext) {
    final current = _pickerKey.currentState?.current ?? _picked;
    if (current == null || !current.isValid) {
      showWarn('请在地图上选择有效地址');
      return;
    }
    AppOverlay.close<AmapLocationPickResult>(dialogContext, current);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogMaxHeight = screenHeight * 0.62;
    final bodyHeight = (dialogMaxHeight - 120).clamp(300.0, 520.0);
    final picked = _picked;

    return AppFormDialog(
      title: AppText.h3(widget.title),
      constraints: const BoxConstraints(maxWidth: 720),
      content: SizedBox(
        width: 640,
        height: bodyHeight,
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              value: _searchController.text,
              controller: _searchController,
              hintText: '搜索地址、地点',
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
              trailing: SearchIconButton(onPressed: _search),
            ),
            Expanded(
              child: AppCard(
                borderWidth: 1,
                padding: EdgeInsets.zero,
                // macOS WebView：裁剪层会挡住地图拖动/选点。
                clipBehavior: Clip.none,
                child: AmapLocationPickerWidget(
                  key: _pickerKey,
                  initial: widget.initial,
                  city: widget.city,
                  onChanged: (value) => setState(() => _picked = value),
                ),
              ),
            ),
            AppCard(
              borderWidth: 1,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  AppText.body(
                    picked?.address.trim().isNotEmpty == true
                        ? picked!.address
                        : '请在地图上点击选点，或搜索地址',
                  ),
                  if (picked?.hasCoordinates == true)
                    AppText.caption(
                      '经度 ${picked!.longitude.toStringAsFixed(6)}　'
                      '纬度 ${picked.latitude.toStringAsFixed(6)}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<AmapLocationPickResult>(context),
          child: const Text('取消'),
        ),
        AppButton.primary(
          onPressed: () => _confirm(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
