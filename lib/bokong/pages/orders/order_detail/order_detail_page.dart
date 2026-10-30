import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

import 'order_detail_controller.dart';
import 'order_detail_insets.dart';
import 'tabs/order_devices_tab.dart';
import 'tabs/order_feedback_tab.dart';
import 'tabs/order_order_tab.dart';
import 'tabs/order_value_added_tab.dart';

/// 打开订单详情弹窗。
void showOrderDetailDialog(
  BuildContext context, {
  required OrderEntity order,
  required Color accentColor,
  Color? industryColor,
  required String customerName,
  int? customerId,
  String? industryLabel,
  OrderDetailTab initialTab = OrderDetailTab.order,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1500, initialHeight),
    builder: (dialogContext) => OrderDetailPage(
      order: order,
      accentColor: accentColor,
      industryColor: industryColor ?? accentColor,
      customerName: customerName,
      customerId: customerId,
      industryLabel: industryLabel ?? '',
      initialTab: initialTab,
    ),
  );
}

/// 订单详情 Tab 壳：与设备详情同尺寸；Tab 与关闭之间可挂各页操作按钮。
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    required this.order,
    required this.accentColor,
    required this.industryColor,
    required this.customerName,
    this.customerId,
    this.industryLabel = '',
    this.initialTab = OrderDetailTab.order,
    super.key,
  });

  final OrderEntity order;
  final Color accentColor;
  final Color industryColor;
  final String customerName;
  final int? customerId;
  final String industryLabel;
  final OrderDetailTab initialTab;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderDetailController _controller;

  @override
  void initState() {
    super.initState();
    // 在 Obx build 之前创建，避免构造期写 Rx 触发 LxInvalidMutationError。
    _controller = OrderDetailController(
      order: widget.order,
      accentColor: widget.accentColor,
      industryColor: widget.industryColor,
      customerName: widget.customerName,
      customerId: widget.customerId,
      industryLabel: widget.industryLabel,
      initialTab: widget.initialTab,
    );
    _controller.syncExclusiveTogglesFromSelected();
    unawaited(_controller.loadIndustryItems());
    unawaited(_controller.ensureReleaseItemsLoaded());
  }

  @override
  void dispose() {
    unawaited(_controller.disposeController());
    super.dispose();
  }

  List<Widget> _tabActions(OrderDetailTab tab) {
    return switch (tab) {
      OrderDetailTab.order => const [],
      OrderDetailTab.devices => const [],
      OrderDetailTab.feedback => const [],
      OrderDetailTab.valueAdded => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    final fills = AppDialogInteraction.maybeOf(context)?.fillsBounds ?? false;
    final theme = shad.Theme.of(context);
    final titleGap = theme.density.baseGap * theme.scaling;

    return AppFormDialog(
      title: Obx(() {
        final index = _controller.tab.value.index;
        final actions = _tabActions(_controller.tab.value);
        return Row(
          children: [
            AppTabs(
              index: index,
              onChanged: _controller.selectTabIndex,
              selectedColor: const Color(0xFFFFFFFF),
              children: const [
                AppTabItem(child: Text('客户订单')),
                AppTabItem(child: Text('投放设备')),
                AppTabItem(child: Text('监测反馈')),
                AppTabItem(child: Text('增值服务')),
              ],
            ),
            const Spacer(),
            if (actions.isNotEmpty) Row(spacing: 8, children: actions),
          ],
        );
      }),
      constraints: fills
          ? const BoxConstraints()
          : const BoxConstraints(maxWidth: 1500),
      padding: kOrderDetailDialogPadding,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceOpacity: 1,
      // 待上游：AppFormDialog 补标题与内容间距参数后回收。
      content: Container(
        width: double.infinity,
        height: fills ? double.infinity : dialogHeight,
        padding: EdgeInsets.only(top: kOrderDetailEdge - titleGap),
        child: Obx(() {
          return switch (_controller.tab.value) {
            OrderDetailTab.order => OrderOrderTab(controller: _controller),
            OrderDetailTab.devices => OrderDevicesTab(controller: _controller),
            OrderDetailTab.feedback => OrderFeedbackTab(
              controller: _controller,
            ),
            OrderDetailTab.valueAdded => OrderValueAddedTab(
              controller: _controller,
            ),
          };
        }),
      ),
      actions: const [],
    );
  }
}
