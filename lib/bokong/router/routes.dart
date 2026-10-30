import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/http/auth_token.dart';
import 'package:yidivination/bokong/pages/analytics/analytics_page.dart';
import 'package:yidivination/bokong/pages/error/page_not_found_page.dart';
import 'package:yidivination/bokong/pages/home/home_page.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_manager_page.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_page.dart';
import 'package:yidivination/bokong/pages/media/ad_media_manager_page.dart';
import 'package:yidivination/bokong/pages/media/recycler/ad_media_recycler_page.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_manager_page.dart';
import 'package:yidivination/bokong/pages/login/login_page.dart';
import 'package:yidivination/bokong/pages/orders/orders_page.dart';
import 'package:yidivination/bokong/pages/main/main_layout.dart';
import 'package:yidivination/bokong/pages/preview/image_preview_page.dart';
import 'package:yidivination/bokong/router/route_transitions.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

class Routes {
  static const String home = '/';
  static const String login = '/login';
  static const String notFound = '/404';

  // 素材库
  static const String ad_media_manager = '/ad_media_manager';
  static const String media_recycler = '/media-recycler';

  // 客户管理
  static const String lcd_customer_manager = '/lcd_customer_manager';

  // LCD设备管理
  static const String lcd_device_manager = '/lcd_device_manager';

  // LCD订单管理
  static const String lcd_order_manager = '/lcd_order_manager';

  //LCD节目排期
  static const String lcd_program_manager = '/lcd_program_manager';

  // 数据分析（静态 Demo）
  static const String lcd_analytics = '/lcd_analytics';

  // 图片预览
  static const String image_preview = '/image_preview';

  static const Set<String> _shellPaths = {
    home,
    ad_media_manager,
    media_recycler,
    lcd_customer_manager,
    lcd_device_manager,
    lcd_order_manager,
    lcd_program_manager,
    lcd_analytics,
    image_preview,
    notFound,
  };

  static String _notFoundLocation(String fromPath) {
    return '$notFound?from=${Uri.encodeComponent(fromPath)}';
  }

  static GoRouter routes = GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [LemonRouteObserver()],
    initialLocation: login,
    redirect: (BuildContext context, GoRouterState state) {
      final String path = state.uri.path;
      if (path == login) {
        // 已有 token（进入前无感登录成功）则直接进首页，不闪登录页。
        final token = AuthToken.loadableAccessToken;
        if (token != null && token.isNotEmpty) return home;
        return null;
      }
      if (_shellPaths.contains(path)) return null;
      return _notFoundLocation(path);
    },
    onException: (BuildContext context, GoRouterState state, GoRouter router) {
      router.go(_notFoundLocation(state.uri.path));
    },
    routes: <RouteBase>[
      GoRoute(
        path: login,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            slideFromRightRoutePage(state: state, child: const LoginPage()),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        notifyRootObserver: false,
        observers: [LemonRouteObserver()],
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: home,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(state: state, child: const HomePage()),
          ),
          GoRoute(
            path: ad_media_manager,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: const AdMediaManagerPage(),
                ),
          ),
          GoRoute(
            path: media_recycler,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: const AdMediaRecyclerPage(),
                ),
          ),
          GoRoute(
            path: lcd_customer_manager,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: const LcdCustomerManagerPage(),
                ),
          ),
          GoRoute(
            path: lcd_device_manager,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: const LcdDevicesPage(),
                ),
          ),
          GoRoute(
            path: lcd_order_manager,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: const OrdersPage(),
                ),
          ),
          GoRoute(
            path: lcd_program_manager,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final Object? extra = state.extra;
              int? terminalId;
              String? scheduleDate;
              if (extra is Map) {
                final Object? tid = extra['terminal_id'];
                if (tid is int) {
                  terminalId = tid;
                } else if (tid != null) {
                  terminalId = int.tryParse('$tid');
                }
                final Object? date = extra['schedule_date'];
                if (date is String) scheduleDate = date;
              }
              terminalId ??= int.tryParse(
                state.uri.queryParameters['terminal_id'] ?? '',
              );
              scheduleDate ??= state.uri.queryParameters['schedule_date'];
              return slideFromRightRoutePage(
                state: state,
                child: LcdProgramManagerPage(
                  key: ValueKey<String>(
                    'lcd_program_${terminalId ?? ''}_${scheduleDate ?? ''}',
                  ),
                  initialTerminalId: terminalId,
                  initialScheduleDate: scheduleDate,
                ),
              );
            },
          ),
          GoRoute(
            path: lcd_analytics,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: const AnalyticsPage(),
                ),
          ),
          GoRoute(
            path: image_preview,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final String? path = state.uri.queryParameters['path'];
              final String? title = state.uri.queryParameters['title'];
              return slideFromRightRoutePage(
                state: state,
                child: ImagePreviewPage(imagePath: path ?? '', title: title),
              );
            },
          ),
          GoRoute(
            path: notFound,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                slideFromRightRoutePage(
                  state: state,
                  child: PageNotFoundPage(
                    fromPath: state.uri.queryParameters['from'],
                  ),
                ),
          ),
          GoRoute(
            path: '/:path(.*)',
            redirect: (BuildContext context, GoRouterState state) =>
                _notFoundLocation(state.uri.path),
          ),
        ],
      ),
    ],
  );
}
