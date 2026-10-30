import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/widget/amap/amap_widget.dart';

/// 设备详情地图：默认不选中，点击标记后选中并展示与列表地图一致的钉标详情卡。
class DeviceDetailAmapWidget extends StatefulWidget {
  const DeviceDetailAmapWidget({
    required this.device,
    this.showZoomControl = false,
    super.key,
  });

  final LcdDeviceEntity device;
  final bool showZoomControl;

  @override
  State<DeviceDetailAmapWidget> createState() => _DeviceDetailAmapWidgetState();
}

class _DeviceDetailAmapWidgetState extends State<DeviceDetailAmapWidget> {
  var _selected = false;

  @override
  void didUpdateWidget(covariant DeviceDetailAmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.uiKey != widget.device.uiKey) {
      _selected = false;
    }
  }

  void _onMarkerTap(AmapMarkerTapPayload payload) {
    setState(() {
      if (payload.id.isEmpty) {
        _selected = false;
      } else if (payload.id == widget.device.uiKey) {
        _selected = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    // 可拖动弹窗用整窗 Pan 抢手势；在地图外包一层 Eager，避免拖地图时弹窗跟着动。
    // 待上游：AppDialog 仅标题栏可拖。
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (EagerGestureRecognizer instance) {},
            ),
      },
      child: AmapWidget(
        embedded: true,
        showZoomControl: widget.showZoomControl,
        suppressMarkerModal: true,
        requestNativeLocationPermission: false,
        markers: [
          LcdDevicesController.mapMarkerOf(device, selected: _selected),
        ],
        onMarkerTap: _onMarkerTap,
      ),
    );
  }
}
