import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/ad_media_api.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 回收站类型筛选（对齐 ShowDoc 1513 `type`）。
enum AdMediaRecyclerType { all, image, video, file }

extension AdMediaRecyclerTypeX on AdMediaRecyclerType {
  int get apiValue => switch (this) {
    AdMediaRecyclerType.all => 0,
    AdMediaRecyclerType.image => 1,
    AdMediaRecyclerType.video => 2,
    AdMediaRecyclerType.file => 3,
  };

  String get label => switch (this) {
    AdMediaRecyclerType.all => '全部',
    AdMediaRecyclerType.image => '图片',
    AdMediaRecyclerType.video => '视频',
    AdMediaRecyclerType.file => '文件',
  };
}

/// 素材库回收站。
class AdMediaRecyclerController extends LxController {
  static const int pageSize = 50;

  final searchController = TextEditingController();
  final typeFilter = AdMediaRecyclerType.all.obs;
  final items = <AdMediaEntity>[].obs;
  final selectedIds = <int>{}.obs;
  final loading = false.obs;
  final page = 1.obs;
  final totalPages = 0.obs;
  final total = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadPage(1);
  }

  @override
  void onDispose() {
    searchController.dispose();
    super.onDispose();
  }

  Future<void> setType(AdMediaRecyclerType type) async {
    if (typeFilter.value == type) return;
    typeFilter.value = type;
    selectedIds.clear();
    await loadPage(1);
  }

  Future<void> search() async {
    selectedIds.clear();
    await loadPage(1);
  }

  /// 触底加载下一页。
  void loadMore() {
    if (loading.value || page.value >= totalPages.value) return;
    loadPage(page.value + 1, append: true);
  }

  Future<void> loadPage(int pageNo, {bool append = false}) async {
    if (pageNo < 1) return;
    if (loading.value) return;
    if (append && totalPages.value > 0 && pageNo > totalPages.value) return;

    loading.value = true;
    try {
      final kw = searchController.text.trim();
      final resp = await AdMediaApi.recyclerList(
        page: pageNo,
        size: pageSize,
        param: {'type': typeFilter.value.apiValue, if (kw.isNotEmpty) 'kw': kw},
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        items.clear();
        page.value = 1;
        totalPages.value = 1;
        total.value = 0;
        selectedIds.clear();
        return;
      }
      final list = resp.data ?? const <AdMediaEntity>[];
      if (!append) items.clear();
      items.addAll(list);
      final totalSize = resp.page?.totalSize ?? list.length;
      var pages = resp.page?.totalPages ?? 0;
      if (pages < 1) {
        pages = totalSize <= 0 ? 1 : ((totalSize + pageSize - 1) ~/ pageSize);
      }
      page.value = resp.page?.page ?? pageNo;
      totalPages.value = pages < 1 ? 1 : pages;
      total.value = totalSize;
      selectedIds.removeWhere((id) => !items.any((e) => e.id == id));
      selectedIds.refresh();
    } catch (e) {
      showError('$e');
      items.clear();
      page.value = 1;
      totalPages.value = 1;
      total.value = 0;
      selectedIds.clear();
    } finally {
      loading.value = false;
    }
  }

  void setSelected(Iterable<AdMediaEntity> rows) {
    selectedIds
      ..clear()
      ..addAll([
        for (final e in rows)
          if (e.id != null) e.id!,
      ]);
    selectedIds.refresh();
  }

  Future<void> restoreOne(AdMediaEntity item) async {
    final id = item.id;
    if (id == null) {
      showWarn('素材 ID 无效');
      return;
    }
    await _restoreIds([id]);
  }

  Future<void> restoreSelected() async {
    final ids = selectedIds.toList();
    if (ids.isEmpty) {
      showWarn('请先选择要还原的素材');
      return;
    }
    await _restoreIds(ids);
  }

  Future<void> deleteOne(AdMediaEntity item) async {
    final id = item.id;
    if (id == null) {
      showWarn('素材 ID 无效');
      return;
    }
    try {
      final resp = await AdMediaApi.recyclerDelete(mediaId: id);
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '删除成功');
      selectedIds.remove(id);
      selectedIds.refresh();
      await _reloadAfterWrite();
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> emptyRecycler() async {
    try {
      final resp = await AdMediaApi.recyclerClear();
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '清空成功');
      selectedIds.clear();
      await loadPage(1);
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> _restoreIds(List<int> ids) async {
    if (ids.isEmpty) {
      showWarn('请选择要还原的素材');
      return;
    }
    try {
      final resp = await AdMediaApi.recyclerRestore(mediaIds: ids.join(','));
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '还原成功');
      selectedIds.removeWhere(ids.contains);
      selectedIds.refresh();
      await _reloadAfterWrite();
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> _reloadAfterWrite() => loadPage(1);
}
