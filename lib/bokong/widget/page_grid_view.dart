import 'dart:async';

import 'package:flutter/material.dart' hide RefreshCallback;
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/page_list_view.dart'
    show LoadMoreCallback, RefreshCallback;

class PageGridView extends StatefulWidget {
  PageGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.onRefresh,
    this.onLoadMore,
    required this.totalPage,
    required this.thisPage,
    this.padding,
    this.shrinkWrap,
  });

  final RefreshCallback? onRefresh;
  final LoadMoreCallback? onLoadMore;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final int totalPage;
  final int thisPage;
  final EdgeInsetsGeometry? padding;
  final bool? shrinkWrap;

  @override
  State<PageGridView> createState() => _PageGridViewState();
}

class _PageGridViewState extends State<PageGridView> {
  bool _isLoading = false;
  Timer? _timer;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget grid = _isEmpty()
        ? _emptyWidget()
        : NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              shrinkWrap: widget.shrinkWrap ?? false,
              slivers: [
                SliverPadding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) =>
                          widget.itemBuilder(context, index),
                      childCount: widget.itemCount,
                    ),
                    gridDelegate: widget.gridDelegate,
                  ),
                ),
              ],
            ),
          );

    final Widget child = RefreshIndicator(
      onRefresh: () => widget.onRefresh?.call(0) ?? Future.value(),
      child: grid,
    );
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification note) {
        if (note.metrics.pixels >= note.metrics.maxScrollExtent - 50 &&
            note.metrics.axis == Axis.vertical) {
          _timer?.cancel();
          _timer = Timer(const Duration(milliseconds: 50), () {
            _timer?.cancel();
            _loadMore();
          });
        }
        return true;
      },
      child: widget.onRefresh == null ? grid : child,
    );
  }

  bool _isEmpty() => widget.itemCount == 0;

  Widget _emptyWidget() {
    return const Center(child: AppEmptyState());
  }

  Future<void> _loadMore() async {
    if (widget.onLoadMore == null) return;
    if (_isLoading) return;
    if (widget.thisPage == widget.totalPage) return;
    _isLoading = true;
    await widget.onLoadMore!(widget.thisPage);
    _isLoading = false;
  }
}
