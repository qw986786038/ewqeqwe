import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_dept.dart';
import '../../../models/hrm_position.dart';
import '../../../models/hrm_post.dart';
import '../../../services/hrm_api.dart';

class SeatController extends LxController {
  final _api = HrmApi();

  final loading = false.obs;
  final metaLoading = false.obs;
  /// 元数据（部门 / 岗位 / 全量席位）刷新后递增，驱动筛选下拉重建。
  final metaVersion = 0.obs;
  final errorMessage = Rxn<String>();

  final rows = <HrmPosition>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;

  final filterDeptId = Rxn<String>();
  final filterPostId = Rxn<String>();
  final filterType = Rxn<String>();

  final depts = <HrmDept>[];
  final posts = <HrmPost>[];
  final allPositions = <HrmPosition>[];

  final Map<String, String> _deptNameById = {};
  final Map<String, String> _postNameById = {};
  final Map<String, HrmPosition> _positionById = {};

  static const typeOptions = <(String, String)>[
    ('REGULAR', '正式'),
    ('RESERVE', '储备'),
    ('OUTSOURCE', '外包'),
  ];

  int get totalPages {
    final size = pageSize.value;
    if (size <= 0) return 1;
    return ((total.value + size - 1) / size).ceil().clamp(1, 999999);
  }

  @override
  void onInit() {
    super.onInit();
    refreshMeta().then((_) => loadPage());
  }

  Future<void> refreshMeta() async {
    metaLoading.value = true;
    try {
      final results = await Future.wait([
        _api.fetchDepts(),
        _api.fetchPosts(),
        _api.fetchPositions(),
      ]);
      depts
        ..clear()
        ..addAll(results[0] as List<HrmDept>);
      posts
        ..clear()
        ..addAll(results[1] as List<HrmPost>);
      allPositions
        ..clear()
        ..addAll(results[2] as List<HrmPosition>);
      _rebuildMaps();
      metaVersion.value++;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      metaLoading.value = false;
    }
  }

  void _rebuildMaps() {
    _deptNameById
      ..clear()
      ..addEntries([
        for (final d in depts)
          if (d.deptId != null && d.deptId!.trim().isNotEmpty)
            MapEntry(d.deptId!.trim(), (d.deptName ?? '').trim()),
      ]);
    _postNameById
      ..clear()
      ..addEntries([
        for (final p in posts)
          if (p.id != null && p.id!.trim().isNotEmpty)
            MapEntry(p.id!.trim(), (p.name ?? '').trim()),
      ]);
    _positionById
      ..clear()
      ..addEntries([
        for (final p in allPositions)
          if (p.id != null && p.id!.trim().isNotEmpty)
            MapEntry(p.id!.trim(), p),
      ]);
  }

  Future<void> loadPage({int? page}) async {
    if (page != null) pageNum.value = page;
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _api.fetchPositionsPage(
        sysDeptId: filterDeptId.value,
        postId: filterPostId.value,
        type: filterType.value,
        pageNum: pageNum.value,
        pageSize: pageSize.value,
      );
      for (final p in result.rows) {
        final id = p.id?.trim();
        if (id != null && id.isNotEmpty) {
          _positionById[id] = p;
        }
      }
      total.value = result.total;
      final maxPage = totalPages;
      if (pageNum.value > maxPage) {
        pageNum.value = maxPage;
        if (result.total > 0 && page != null) {
          await loadPage(page: maxPage);
          return;
        }
      }
      rows
        ..clear()
        ..addAll(result.rows);
      rows.refresh();
    } catch (e) {
      errorMessage.value = e.toString();
      if (rows.isEmpty) {
        total.value = 0;
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await refreshMeta();
    await loadPage(page: pageNum.value);
  }

  void search() {
    loadPage(page: 1);
  }

  void resetSearch() {
    filterDeptId.value = null;
    filterPostId.value = null;
    filterType.value = null;
    loadPage(page: 1);
  }

  void goPage(int page) {
    final target = page.clamp(1, totalPages);
    if (target == pageNum.value && rows.isNotEmpty) return;
    loadPage(page: target);
  }

  void changePageSize(int size) {
    if (size == pageSize.value) return;
    pageSize.value = size;
    loadPage(page: 1);
  }

  static String typeLabel(String? type) {
    switch (type?.trim().toUpperCase()) {
      case 'REGULAR':
        return '正式';
      case 'RESERVE':
        return '储备';
      case 'OUTSOURCE':
        return '外包';
      default:
        return type?.trim().isNotEmpty == true ? type!.trim() : '-';
    }
  }

  String deptDisplay(HrmPosition p) {
    final name = p.deptName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = p.sysDeptId?.trim();
    if (id == null || id.isEmpty) return '-';
    final mapped = _deptNameById[id];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    return id;
  }

  String postDisplay(HrmPosition p) {
    final name = p.postName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = p.postId?.trim();
    if (id == null || id.isEmpty) return '-';
    final mapped = _postNameById[id];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    return id;
  }

  /// 汇报席位展示：`部门 / 岗位 / 编制类型`。
  String positionRefDisplay(String? positionId) {
    final id = positionId?.trim();
    if (id == null || id.isEmpty) return '';
    final pos = _positionById[id];
    if (pos == null) return id;
    return '${deptDisplay(pos)} / ${postDisplay(pos)} / ${typeLabel(pos.type)}';
  }

  String positionOptionLabel(HrmPosition p) =>
      '${deptDisplay(p)} / ${postDisplay(p)} / ${typeLabel(p.type)}';

  Future<void> createSeat({
    required String sysDeptId,
    required String postId,
    required String type,
    String? reportPositionId,
    String? dottedPositionId,
  }) async {
    await _api.createPosition(
      sysDeptId: sysDeptId,
      postId: postId,
      type: type,
      reportPositionId: reportPositionId,
      dottedPositionId: dottedPositionId,
    );
    await refreshAll();
  }

  Future<void> updateSeat({
    required String id,
    required String sysDeptId,
    required String postId,
    required String type,
    String? reportPositionId,
    String? dottedPositionId,
  }) async {
    await _api.updatePosition(
      id: id,
      sysDeptId: sysDeptId,
      postId: postId,
      type: type,
      reportPositionId: reportPositionId,
      dottedPositionId: dottedPositionId,
    );
    await refreshAll();
  }

  Future<void> deleteSeat(String id) async {
    await _api.deletePosition(id);
    await loadPage(page: pageNum.value);
    await refreshMeta();
  }
}
