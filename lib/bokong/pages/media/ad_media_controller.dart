import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/ad_media_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_category_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_filter_options_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/utils/ext.dart';

/// 素材库范围：本地 / 云端。
enum AdMediaLibraryScope { local, cloud }

/// 顶栏库范围 Tab。
enum AdMediaLibraryTab { all, local, cloudDisk, cloudRepo }

extension AdMediaLibraryTabX on AdMediaLibraryTab {
  bool get isCloud =>
      this == AdMediaLibraryTab.cloudDisk ||
      this == AdMediaLibraryTab.cloudRepo;

  AdMediaLibraryScope get dataScope =>
      isCloud ? AdMediaLibraryScope.cloud : AdMediaLibraryScope.local;
}

/// 网格缩略图宽高比。
enum AdMediaThumbRatio { r1x1, r4x3, r16x9 }

extension AdMediaThumbRatioX on AdMediaThumbRatio {
  double get layoutFactor => switch (this) {
    AdMediaThumbRatio.r4x3 => 4 / 3,
    AdMediaThumbRatio.r1x1 => 1,
    AdMediaThumbRatio.r16x9 => 16 / 9,
  };
}

/// 素材库工具栏排序字段。
enum AdMediaToolbarSort { name, time }

class AdMediaScopeState {
  final RxList<AdMediaEntity> items = RxList();
  final RxBool loading = false.obs;
  final RxInt page = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalSize = 0.obs;
}

class AdMediaController extends LxController {
  static const int pageSize = 40;
  static const AppOption<int?> _allCustomerOption = AppOption<int?>(
    value: null,
    label: '全部客户',
  );
  static const Object allFolderId = '__all__';

  final AdMediaScopeState local = AdMediaScopeState();
  final AdMediaScopeState cloud = AdMediaScopeState();

  RxString keyword = ''.obs;
  Rxn<int> customerId = Rxn();
  Rxn<int> categoryId = Rxn();
  final Rxn<int> mediaType = Rxn();
  final Rxn<String> resolution = Rxn();
  final Rxn<String> fileFormat = Rxn();

  /// 名称排序：`desc` / `asc`；空为不传 `title_sort`。
  final titleSort = Rxn<String>();

  /// 创建时间排序：`desc` / `asc`；空为不传 `create_time_sort`。
  final createTimeSort = Rxn<String>();
  final RxList<AppOption<int?>> mediaTypeOptions = RxList<AppOption<int?>>();
  final RxList<AppOption<int?>> customerOptions = RxList<AppOption<int?>>([
    _allCustomerOption,
  ]);
  final RxList<AppOption<String?>> resolutionOptions =
      RxList<AppOption<String?>>();
  final RxList<AppOption<String?>> fileFormatOptions =
      RxList<AppOption<String?>>();
  final Rxn<AdContentCategoryEntity> categoryRoot = Rxn();
  final RxBool categoryLoading = false.obs;
  final Rxn<Object> selectedFolderId = Rxn<Object>(allFolderId);
  final libraryTab = AdMediaLibraryTab.all.obs;
  final thumbRatio = AdMediaThumbRatio.r1x1.obs;
  final RxBool uploading = false.obs;
  final searchController = TextEditingController();

  bool get hasFormFilter =>
      customerId.value != null ||
      mediaType.value != null ||
      resolution.value != null ||
      fileFormat.value != null;

  /// 筛选弹窗里当前生效的条件数（用于筛选按钮角标）。
  int get activeFilterCount {
    var n = 0;
    if (customerId.value != null) n++;
    if (mediaType.value != null) n++;
    if (resolution.value != null) n++;
    if (fileFormat.value != null) n++;
    return n;
  }

  AdMediaLibraryScope get activeScope => libraryTab.value.dataScope;

  AdMediaScopeState stateOf(AdMediaLibraryScope scope) =>
      scope == AdMediaLibraryScope.local ? local : cloud;

  AdMediaScopeState get activeState => stateOf(activeScope);

  static String _generateMediaNo() =>
      'M${DateTime.now().millisecondsSinceEpoch.date2('yyyyMMddHHmmssSSS')}';

  static Object categoryFolderId(int id) => 'cat:$id';

  @override
  void onInit() {
    super.onInit();
    _loadInitial();
  }

  @override
  void onDispose() {
    searchController.dispose();
    super.onDispose();
  }

  Future<void> selectLibraryTab(AdMediaLibraryTab tab) async {
    if (libraryTab.value == tab) return;
    libraryTab.value = tab;
    await ensureLoaded(activeScope);
  }

  Future<void> filterByCustomerForActiveScope(int? id) =>
      filterByCustomer(id, activeScope);

  Future<void> selectFolderForActiveScope(AdContentCategoryEntity node) =>
      selectFolder(node, activeScope);

  Future<void> selectAllFolderForActiveScope() => selectAllFolder(activeScope);

  Future<void> searchActiveScope() =>
      search(searchController.text, activeScope);

  Future<void> loadMoreActive() => loadMore(activeScope);

  Future<String> deleteMedia(int id) async {
    final resp = await AdMediaApi.delete(id: id);
    await Future.wait([reload(activeScope), loadCategories()]);
    return resp.msg?.isNotEmpty == true ? resp.msg! : '删除成功';
  }

  /// 更新素材标题（其余可写字段原样回传）。
  Future<String> renameMedia({
    required AdMediaEntity item,
    required String title,
  }) async {
    final id = item.id;
    if (id == null) {
      throw StateError('素材 ID 无效');
    }
    final params = <String, dynamic>{
      'media_no': item.media_no,
      'title': title,
      'description': item.description ?? '',
      'customer_id': item.customer_id,
      'category_id': item.category_id,
      'media_type': item.media_type,
      'file_format': item.file_format,
      'file_path': item.file_path,
      'file_md5': item.file_md5,
      'file_size': item.file_size,
      'duration': item.duration ?? 0,
      'screen_width': item.screen_width ?? 0,
      'screen_height': item.screen_height ?? 0,
      'preview_path': item.preview_path ?? item.file_path,
      'loop_count': item.loop_count,
      'order_frequency': item.order_frequency,
      'now_frequency': item.now_frequency,
      'terminal_ids': item.terminal_ids,
      'status': item.status ?? 1,
      'push_status': item.push_status ?? 0,
      'start_time': item.start_time,
      'end_time': item.end_time,
      'send_time': item.send_time,
    }..removeWhere((_, value) => value == null);

    final resp = await AdMediaApi.update(id: id, params: params);
    final updated = resp.data;
    final items = activeState.items;
    final index = items.indexWhere((e) => e.id == id);
    if (index >= 0) {
      if (updated != null) {
        items[index] = updated;
      } else {
        items[index].title = title;
        items.refresh();
      }
    }
    return resp.msg?.isNotEmpty == true ? resp.msg! : '修改成功';
  }

  void _loadInitial() {
    Future<void>(() async {
      await Future.wait([loadFilterOptions(), loadCategories()]);
      await Future.wait([
        ensureLoaded(AdMediaLibraryScope.local),
        ensureLoaded(AdMediaLibraryScope.cloud),
      ]);
    });
  }

  /// 拉取筛选下拉选项（媒体类型 / 客户 / 分辨率 / 格式）。
  Future<void> loadFilterOptions() async {
    try {
      final resp = await AdMediaApi.filterOptions();
      if (!resp.isSuccess()) return;
      final data = resp.data;
      if (data == null) return;

      mediaTypeOptions.replaceAll([
        for (final e in data.media_type ?? const [])
          if (e.value != null)
            AppOption<int?>(
              value: e.value,
              label: e.label?.trim().isNotEmpty == true
                  ? e.label!.trim()
                  : '${e.value}',
            ),
      ]);

      final seenCustomerIds = <int>{};
      customerOptions.replaceAll([
        _allCustomerOption,
        for (final e in data.customer ?? const [])
          if (e.value != null && seenCustomerIds.add(e.value!))
            AppOption<int?>(
              value: e.value,
              label: e.label?.trim().isNotEmpty == true
                  ? e.label!.trim()
                  : '${e.value}',
            ),
      ]);

      resolutionOptions.replaceAll([
        for (final e in data.resolution ?? const [])
          if (e.value != null && e.value!.trim().isNotEmpty)
            AppOption<String?>(
              value: e.value!.trim(),
              label: (e.label?.trim().isNotEmpty == true)
                  ? e.label!.trim()
                  : e.value!.trim().replaceAll('*', '×'),
            ),
      ]);

      fileFormatOptions.replaceAll([
        for (final e in data.file_format ?? const [])
          if (e.value != null && e.value!.trim().isNotEmpty)
            AppOption<String?>(
              value: e.value!.trim(),
              label: e.label?.trim().isNotEmpty == true
                  ? e.label!.trim()
                  : e.value!.trim(),
            ),
      ]);
    } catch (_) {
      // 选项失败时保留空列表，不影响素材列表加载。
    }
  }

  Future<void> loadCategories() async {
    categoryLoading.value = true;
    try {
      final resp = await AdMediaApi.contentCategory(
        customerId: customerId.value,
      );
      categoryRoot.value = resp.data;
      _syncSelectedFolderId();
    } finally {
      categoryLoading.value = false;
    }
  }

  void _syncSelectedFolderId() {
    final int? cid = categoryId.value;
    if (cid != null) {
      selectedFolderId.value = categoryFolderId(cid);
      return;
    }
    selectedFolderId.value = allFolderId;
  }

  Map<String, dynamic> _params() {
    final Map<String, dynamic> params = <String, dynamic>{'is_delete': 0};
    final String kw = keyword.value.trim();
    if (kw.isNotEmpty) params['title'] = kw;
    final int? cid = customerId.value;
    if (cid != null) params['customer_id'] = cid;
    final int? catId = categoryId.value;
    if (catId != null) params['category_id'] = catId;
    final int? type = mediaType.value;
    if (type != null) params['media_type'] = type;
    final String? format = fileFormat.value?.trim();
    if (format != null && format.isNotEmpty) params['file_format'] = format;
    final String? res = resolution.value?.trim();
    if (res != null && res.isNotEmpty) {
      final parts = res.toLowerCase().split(RegExp(r'[x*]'));
      if (parts.length == 2) {
        final width = int.tryParse(parts[0].trim());
        final height = int.tryParse(parts[1].trim());
        if (width != null && width > 0) params['screen_width'] = width;
        if (height != null && height > 0) params['screen_height'] = height;
      }
    }
    final title = titleSort.value;
    if (title != null) params['title_sort'] = title;
    final createTime = createTimeSort.value;
    if (createTime != null) params['create_time_sort'] = createTime;
    return params;
  }

  Future<void> ensureLoaded(AdMediaLibraryScope scope) async {
    final AdMediaScopeState state = stateOf(scope);
    if (state.items.isEmpty && !state.loading.value) {
      await loadPage(scope, 1);
    }
  }

  Future<void> reload(AdMediaLibraryScope scope) => loadPage(scope, 1);

  Future<void> loadMore(AdMediaLibraryScope scope) async {
    final AdMediaScopeState state = stateOf(scope);
    final int next = state.page.value + 1;
    if (state.totalPages.value > 0 && next > state.totalPages.value) return;
    await loadPage(scope, next, append: true);
  }

  Future<void> loadPage(
    AdMediaLibraryScope scope,
    int pageNo, {
    bool append = false,
  }) async {
    final AdMediaScopeState state = stateOf(scope);
    if (state.loading.value) return;
    if (pageNo < 1) return;
    if (append && state.totalPages.value > 0 && pageNo > state.totalPages.value)
      return;

    state.loading.value = true;
    try {
      final resp = await AdMediaApi.list(
        page: pageNo,
        size: pageSize,
        param: _params(),
      );
      if (!append) state.items.clear();
      state.items.addAll(resp.data ?? []);
      state.page.value = resp.page?.page ?? pageNo;
      state.totalPages.value = resp.page?.totalPages ?? 0;
      state.totalSize.value = resp.page?.totalSize ?? 0;
    } finally {
      state.loading.value = false;
    }
  }

  Future<void> search(String value, AdMediaLibraryScope scope) async {
    keyword.value = value.trim();
    stateOf(scope).totalPages.value = 0;
    await loadPage(scope, 1);
  }

  Future<void> filterByCustomer(int? id, AdMediaLibraryScope scope) async {
    customerId.value = id;
    categoryId.value = null;
    _syncSelectedFolderId();
    stateOf(scope).totalPages.value = 0;
    await Future.wait([loadCategories(), loadPage(scope, 1)]);
  }

  /// 更新筛选条件并立即刷新分类树与列表。
  Future<void> setFilters({
    int? customerId,
    int? mediaType,
    String? resolution,
    String? fileFormat,
  }) async {
    final bool customerChanged = this.customerId.value != customerId;
    this.customerId.value = customerId;
    this.mediaType.value = mediaType;
    this.resolution.value = resolution;
    this.fileFormat.value = fileFormat;
    if (customerChanged) {
      categoryId.value = null;
      _syncSelectedFolderId();
    }
    activeState.totalPages.value = 0;
    await Future.wait([loadCategories(), loadPage(activeScope, 1)]);
  }

  Future<void> resetFilters() => setFilters();

  Future<void> toggleToolbarSort(AdMediaToolbarSort mode) async {
    if (mode == AdMediaToolbarSort.name) {
      createTimeSort.value = null;
      titleSort.value = _nextSortDir(titleSort.value);
    } else {
      titleSort.value = null;
      createTimeSort.value = _nextSortDir(createTimeSort.value);
    }
    await loadPage(activeScope, 1);
  }

  static String? _nextSortDir(String? current) => switch (current) {
    null => 'desc',
    'desc' => 'asc',
    _ => null,
  };

  Future<void> selectFolder(
    AdContentCategoryEntity node,
    AdMediaLibraryScope scope,
  ) async {
    final int? catId = node.category_id;
    if (catId != null && catId != 0) {
      categoryId.value = catId;
      selectedFolderId.value = categoryFolderId(catId);
    } else {
      categoryId.value = null;
      selectedFolderId.value = allFolderId;
    }
    stateOf(scope).totalPages.value = 0;
    await loadPage(scope, 1);
  }

  Future<void> selectAllFolder(AdMediaLibraryScope scope) async {
    categoryId.value = null;
    customerId.value = null;
    mediaType.value = null;
    resolution.value = null;
    fileFormat.value = null;
    selectedFolderId.value = allFolderId;
    stateOf(scope).totalPages.value = 0;
    await Future.wait([loadCategories(), loadPage(scope, 1)]);
  }

  /// 根据已上传文件创建素材记录。
  Future<String> createMedia({
    required AdMediaPickedFile file,
    required String title,
    required int customerId,
    required int categoryId,
    required int duration,
    required bool pushToCloud,
    String? description,
    required AdMediaLibraryScope scope,
  }) async {
    if (uploading.value) {
      throw StateError('正在上传中');
    }

    uploading.value = true;
    try {
      final String? fileUrl = file.publicUrl;
      if (fileUrl == null || fileUrl.isEmpty) {
        throw StateError('文件地址为空');
      }

      final Map<String, dynamic> params = <String, dynamic>{
        'media_no': _generateMediaNo(),
        'title': title,
        'description': description?.trim() ?? '',
        'customer_id': customerId,
        'category_id': categoryId,
        'media_type': file.mediaType,
        'file_format': file.fileFormat,
        'file_path': fileUrl,
        'file_size': file.fileSizeMb,
        'duration': duration,
        'preview_path': fileUrl,
        'status': 1,
        'push_status': pushToCloud ? 1 : 0,
      };
      final int? width = file.width;
      final int? height = file.height;
      if (width != null && width > 0) params['screen_width'] = width;
      if (height != null && height > 0) params['screen_height'] = height;

      final AppRespEntity<AdMediaEntity> createResp = await AdMediaApi.create(
        params: params,
      );
      if (!createResp.isSuccess()) throw createResp;
      await Future.wait([reload(scope), loadCategories()]);
      return createResp.msg?.isNotEmpty == true ? createResp.msg! : '添加成功';
    } finally {
      uploading.value = false;
    }
  }

  /// 创建网页类素材（media_type = 4）。
  Future<String> createWebMedia({
    required String title,
    required int customerId,
    required int categoryId,
    required String url,
    String? description,
    required AdMediaLibraryScope scope,
  }) async {
    return _createUrlMedia(
      title: title,
      customerId: customerId,
      categoryId: categoryId,
      url: url,
      description: description,
      scope: scope,
      mediaType: 4,
      fileFormat: 'URL',
    );
  }

  /// 创建直播类素材（media_type = 5）。
  Future<String> createLiveMedia({
    required String title,
    required int customerId,
    required int categoryId,
    required String url,
    String? description,
    required AdMediaLibraryScope scope,
  }) async {
    return _createUrlMedia(
      title: title,
      customerId: customerId,
      categoryId: categoryId,
      url: url,
      description: description,
      scope: scope,
      mediaType: 5,
      fileFormat: 'M3U8',
    );
  }

  /// 创建插件类素材（media_type = 6）。
  Future<String> createPluginMedia({
    required String title,
    required int customerId,
    required int categoryId,
    required String contentUrl,
    String? previewUrl,
    String? description,
    required AdMediaLibraryScope scope,
  }) async {
    return _createUrlMedia(
      title: title,
      customerId: customerId,
      categoryId: categoryId,
      url: contentUrl,
      previewUrl: previewUrl,
      description: description,
      scope: scope,
      mediaType: 6,
      fileFormat: 'PLUGIN',
    );
  }

  Future<String> _createUrlMedia({
    required String title,
    required int customerId,
    required int categoryId,
    required String url,
    String? previewUrl,
    String? description,
    required AdMediaLibraryScope scope,
    required int mediaType,
    required String fileFormat,
  }) async {
    if (uploading.value) {
      throw StateError('正在提交中');
    }

    final String trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      throw StateError('请输入 URL');
    }
    final String trimmedPreview = previewUrl?.trim() ?? '';

    uploading.value = true;
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'media_no': _generateMediaNo(),
        'title': title,
        'description': description?.trim() ?? '',
        'customer_id': customerId,
        'category_id': categoryId,
        'media_type': mediaType,
        'file_format': fileFormat,
        'file_path': trimmedUrl,
        'file_size': 0,
        'duration': 0,
        'screen_width': 0,
        'screen_height': 0,
        'preview_path': trimmedPreview.isNotEmpty ? trimmedPreview : trimmedUrl,
        'status': 1,
        'push_status': 1,
      };

      final AppRespEntity<AdMediaEntity> createResp = await AdMediaApi.create(
        params: params,
      );
      if (!createResp.isSuccess()) throw createResp;
      await Future.wait([reload(scope), loadCategories()]);
      return createResp.msg?.isNotEmpty == true ? createResp.msg! : '添加成功';
    } finally {
      uploading.value = false;
    }
  }
}
