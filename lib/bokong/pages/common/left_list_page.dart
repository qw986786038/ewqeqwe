import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/router/route_transitions.dart';
import 'package:yidivination/bokong/entity/page_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/widget/app_widget.dart';
import 'package:yidivination/bokong/widget/page_list_view.dart';

typedef DataApi = Future<AppRespEntity<List>> Function({int? page, int? size, Map<String, dynamic>? param});
typedef ItemBuilder = Widget Function(BuildContext context, int index, dynamic data);
typedef TopViewBuilder = Widget Function(BuildContext context, dynamic data);

typedef DatasChanged = void Function(List datas);

class LeftListPage extends StatefulWidget {
  LeftListPage({
    Key? key,
    this.title,
    required this.api,
    required this.itemBuilder,
    this.refresh,
    this.topViewBuilder,
    this.onDatasChanged,
    this.immediateLoad = false,
    this.loadDelay,
    this.queryParam,
  }) : super(key: key);

  final String? title;
  final DataApi api;
  final ItemBuilder itemBuilder;
  final TopViewBuilder? topViewBuilder;
  final Object? refresh;
  final DatasChanged? onDatasChanged;
  final bool immediateLoad;

  /// 首次加载前等待时长；优先于 [immediateLoad] / 路由过渡延迟。
  final Duration? loadDelay;

  /// 列表请求固定查询参数（分页加载、下拉刷新时一并带上）。
  final Map<String, dynamic>? queryParam;

  @override
  _LeftListPageState createState() => _LeftListPageState();
}

class _LeftListPageState extends State<LeftListPage> {
  List datas = List.empty(growable: true);
  bool isError = false;
  String errorMsg = "";
  bool isLoading = true;
  PageEntity? pageEntity;
  dynamic obj;

  StreamSubscription<dynamic>? listener;

  @override
  void initState() {
    super.initState();
    _scheduleInitialLoad();
  }

  void _scheduleInitialLoad() {
    final Duration delay = widget.loadDelay ?? (widget.immediateLoad ? Duration.zero : routeTransitionDuration);
    if (delay <= Duration.zero) {
      getData();
      return;
    }
    Future<void>.delayed(delay, () {
      if (mounted) getData();
    });
  }

  @override
  void didUpdateWidget(LeftListPage oldWidget) {
    final bool refreshChanged = oldWidget.refresh != widget.refresh;
    final bool queryChanged = !_sameQueryParam(oldWidget.queryParam, widget.queryParam);
    if (refreshChanged || queryChanged) {
      getData();
    }
    super.didUpdateWidget(oldWidget);
  }

  bool _sameQueryParam(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || a.isEmpty) return b == null || b.isEmpty;
    if (b == null || a.length != b.length) return false;
    for (final MapEntry<String, dynamic> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  Map<String, dynamic>? _mergedQueryParam(Map<String, dynamic>? param) {
    final Map<String, dynamic> merged = <String, dynamic>{...?widget.queryParam, ...?param};
    return merged.isEmpty ? null : merged;
  }

  Future<void> getData({int page = 1, Map<String, dynamic>? param}) async {
    if (page == 1 && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final AppRespEntity<List> value = await widget.api.call(page: page, param: _mergedQueryParam(param));
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = false;
        errorMsg = "";
        if (page == 1) {
          datas.clear();
        }
        obj = value.obj;
        pageEntity = value.page;
        datas.addAll(value.data ?? []);
      });
      widget.onDatasChanged?.call(List.of(datas));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isError = true;
        errorMsg = _errorMessage(e);
      });
    }
  }

  String _errorMessage(Object e) {
    if (e is AppRespEntity) return e.msg ?? '未知错误';
    if (e is AppException) return e.msg ?? '未知错误';
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.topViewBuilder?.call(context, obj) ?? Container(),
        isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : isError
            ? Expanded(child: Center(child: Text(errorMsg)))
            : Flexible(
                child: PageListView(
                  onRefresh: (index) {
                    return getData(page: 1);
                  },
                  itemCount: datas.length,
                  itemBuilder: (context, index) {
                    return Material(color: Colors.transparent, child: widget.itemBuilder.call(context, index, datas[index]));
                  },
                  onLoadMore: (index) {
                    if (isLoading) {
                      return Future.value();
                    }
                    final int nextPage = index + 1;
                    if (pageEntity?.totalPages != null && nextPage > pageEntity!.totalPages!) {
                      return Future.value();
                    }
                    return getData(page: nextPage);
                  },
                  totalPage: pageEntity?.totalPages ?? 0,
                  thisPage: pageEntity?.page ?? 0,
                ),
              ),
        SizedBox(height: 16),
        // pageEntity == null
        //     ? Container()
        //     : Padding(
        //         padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 8),
        //         child: Row(
        //           children: [
        //             body(context, "总数: ${pageEntity?.totalSize}条"),
        //             Container(width: 16),
        //             body(context, "每页: ${pageEntity?.size}条"),
        //             Container(width: 16),
        //             body(context, "已加载: ${pageEntity?.page}页"),
        //           ],
        //         ),
        //       ),
      ],
    );
  }
}
