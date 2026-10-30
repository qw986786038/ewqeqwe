// 主壳：左侧导航 + 右侧子路由内容区
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/router/routes.dart';
import 'package:yidivination/bokong/widget/menu/demo/menu_logo_demo.dart';
import 'package:yidivination/bokong/widget/menu/demo/menu_user_footer_demo.dart';
import 'package:yidivination/bokong/widget/menu/menu_item.dart';

import 'main_controller.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final MainController main = Lemon.put(MainController.new, permanent: true);

  static const double _menuWidth = 200;

  static const List<MenuItem> _menuItems = [
    MenuItem(
      id: 'lcd',
      title: 'LCD',
      icon: Icons.tv,
      children: [
        MenuItem(id: Routes.lcd_device_manager, title: '设备管理'),
        MenuItem(id: Routes.lcd_order_manager, title: '客户订单'),
        // MenuItem(id: Routes.lcd_program_manager, title: '播放排期'),
        MenuItem(id: Routes.lcd_analytics, title: '数据分析'),
        MenuItem(id: Routes.media_recycler, title: '回收站'),
        MenuItem(id: Routes.ad_media_manager, title: '素材库'),
      ],
    ),
  ];

  RxString selectMenuId = RxString("");

  void _onDestinationSelected(String id) {
    final MenuItem? item = _findItem(_menuItems, id);
    if (item == null) return;
    if (selectMenuId.value != item.id) {
      context.go(item.id);
    }
    selectMenuId.value = item.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButtonMotionScope.disable(
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(24))),
                clipBehavior: Clip.antiAlias,
                child: Obx(
                  () => AppSidebar(
                    content: AppSidebarContent(items: _mapItems(_menuItems)),
                    selectedId: selectMenuId.value,
                    onDestinationSelected: _onDestinationSelected,
                    expandedWidth: _menuWidth,
                    selectParentWhenChildSelected: false,
                    selectionStyle: AppSidebarSelectionStyle.fill,
                    selectedColor: const Color(0xFFF2F2F2),
                    header: const AppSidebarHeader(child: MenuLogoDemo()),
                    // footer: const AppSidebarFooter(child: MenuUserFooterDemo()),
                  ),
                ),
              ),
            ),
            Gap(16),
            Expanded(
              // 水平 12：把原 24 中的 12 让给页面/网格内边距，供 AppMotion.lift 等溢出。
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

/// 待上游：`AppSidebarMenuItem.icon` 改为可选后删掉，现用空白字形占位（仍保留图标宽度）。
const IconData _kNoIcon = IconData(0x20);

List<AppSidebarMenuItem> _mapItems(List<MenuItem> items) {
  return items.map((MenuItem item) => AppSidebarMenuItem(id: item.id, label: item.title, icon: item.icon ?? _kNoIcon, children: _mapItems(item.children))).toList();
}

MenuItem? _findItem(List<MenuItem> items, String id) {
  for (final MenuItem item in items) {
    if (item.id == id) return item;
    final MenuItem? nested = _findItem(item.children, id);
    if (nested != null) return nested;
  }
  return null;
}
