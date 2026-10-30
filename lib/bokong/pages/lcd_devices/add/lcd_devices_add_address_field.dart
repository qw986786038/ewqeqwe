import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/widget/amap/amap_location_pick_result.dart';
import 'package:yidivination/bokong/widget/amap/amap_location_picker_dialog.dart';

/// 详细地址地图选点：`AppField` + [AppWidgetGroup]（输入区 | 选点按钮）。
class LcdDevicesAddAddressField extends StatefulWidget {
  const LcdDevicesAddAddressField({
    required this.location,
    required this.regionLabel,
    required this.onPicked,
    super.key,
  });

  final AmapLocationPickResult? location;
  final String? regionLabel;
  final ValueChanged<AmapLocationPickResult> onPicked;

  @override
  State<LcdDevicesAddAddressField> createState() =>
      _LcdDevicesAddAddressFieldState();
}

class _LcdDevicesAddAddressFieldState extends State<LcdDevicesAddAddressField> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: _addressText);
  }

  @override
  void didUpdateWidget(covariant LcdDevicesAddAddressField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _addressText;
    if (_addressController.text != text) {
      _addressController.text = text;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String get _addressText => widget.location?.address.trim() ?? '';

  String? _description() {
    final parts = <String>[];
    final region = widget.regionLabel?.trim();
    if (region != null && region.isNotEmpty) {
      parts.add(region);
    }
    final value = widget.location;
    if (value != null && value.hasCoordinates) {
      parts.add(
        '经度 ${value.longitude.toStringAsFixed(6)}　纬度 ${value.latitude.toStringAsFixed(6)}',
      );
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  Future<void> _openPicker() async {
    final picked = await showAmapLocationPickerDialog(
      context: context,
      initial: widget.location,
      city: widget.location?.city ?? widget.location?.province,
    );
    if (picked == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPicked(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppField(
      label: '详细地址',
      required: true,
      description: _description(),
      child: AppWidgetGroup.horizontal(
        expands: true,
        widths: const [null, 70],
        children: [
          AppTextFormField(
            name: 'detailed_address',
            readOnly: true,
            controller: _addressController,
            hintText: '点击「地图选点」选择位置',
            validator: AppValidators.required(message: '请选择详细地址'),
          ),
          AppButton.outline(onPressed: _openPicker, child: const Text('地图选点')),
        ],
      ),
    );
  }
}
