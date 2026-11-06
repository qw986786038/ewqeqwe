import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_post_seq.dart';
import '../../../models/hrm_post_seq_level.dart';
import '../../../services/hrm_api.dart' show HrmApi, HrmApiException;

class PostSeqController extends LxController {
  final _api = HrmApi();

  final seqLoading = false.obs;
  final levelLoading = false.obs;
  final seqError = Rxn<String>();
  final levelError = Rxn<String>();

  final seqs = <HrmPostSeq>[].obs;
  final levels = <HrmPostSeqLevel>[].obs;
  final selectedSeqId = Rxn<String>();

  HrmPostSeq? get selectedSeq {
    final id = selectedSeqId.value;
    if (id == null || id.isEmpty) return null;
    for (final s in seqs) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    refreshSeqs();
  }

  Future<void> refreshSeqs() async {
    seqLoading.value = true;
    seqError.value = null;
    try {
      final list = await _api.fetchPostSeqs();
      seqs
        ..clear()
        ..addAll(list);
      seqs.refresh();

      final keep = selectedSeqId.value;
      final keepOk =
          keep != null && keep.isNotEmpty && list.any((s) => s.id == keep);
      if (keepOk) {
        await loadLevels(keep);
      } else if (list.isNotEmpty && list.first.id?.isNotEmpty == true) {
        await selectSeq(list.first.id!);
      } else {
        selectedSeqId.value = null;
        levels.clear();
        levels.refresh();
      }
    } catch (e) {
      seqError.value = e.toString();
    } finally {
      seqLoading.value = false;
    }
  }

  Future<void> selectSeq(String id) async {
    final next = id.trim();
    if (next.isEmpty) return;
    selectedSeqId.value = next;
    // 始终按选中序列拉职级：`GET …/post-seq-level/post-seq/{postSeqId}`。
    await loadLevels(next);
  }

  Future<void> loadLevels(String postSeqId) async {
    levelLoading.value = true;
    levelError.value = null;
    try {
      final list = await _api.fetchPostSeqLevelsBySeq(postSeqId);
      // 右侧列表按排序降序展示（与截图一致：高 order 在上）。
      list.sort((a, b) => (b.orderNum ?? 0).compareTo(a.orderNum ?? 0));
      levels
        ..clear()
        ..addAll(list);
      levels.refresh();
    } catch (e) {
      levels.clear();
      levels.refresh();
      levelError.value = e.toString();
    } finally {
      levelLoading.value = false;
    }
  }

  /// 新增序列默认排序：当前最大 orderNum + 1。
  int get nextOrderNum {
    var max = 0;
    for (final s in seqs) {
      final n = s.orderNum ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  /// 新增职级默认排序：当前列表最大 orderNum + 1。
  int get nextLevelOrderNum {
    var max = 0;
    for (final l in levels) {
      final n = l.orderNum ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  Future<void> createLevel({
    required String code,
    required num salaryMin,
    required num salaryMax,
    required int orderNum,
  }) async {
    final seqId = selectedSeqId.value?.trim();
    if (seqId == null || seqId.isEmpty) {
      throw HrmApiException('请先选择序列');
    }
    await _api.createPostSeqLevel(
      postSeqId: seqId,
      code: code,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      orderNum: orderNum,
    );
    await loadLevels(seqId);
  }

  Future<void> updateLevel({
    required String id,
    required String code,
    required num salaryMin,
    required num salaryMax,
    required int orderNum,
  }) async {
    final seqId = selectedSeqId.value?.trim();
    if (seqId == null || seqId.isEmpty) {
      throw HrmApiException('请先选择序列');
    }
    await _api.updatePostSeqLevel(
      id: id,
      postSeqId: seqId,
      code: code,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      orderNum: orderNum,
    );
    await loadLevels(seqId);
  }

  Future<void> deleteLevel(String id) async {
    final seqId = selectedSeqId.value?.trim();
    await _api.deletePostSeqLevel(id);
    if (seqId != null && seqId.isNotEmpty) {
      await loadLevels(seqId);
    }
  }

  Future<void> createSeq({
    required String code,
    required String name,
    required String channel,
    required int orderNum,
  }) async {
    final id = await _api.createPostSeq(
      code: code,
      name: name,
      channel: channel,
      orderNum: orderNum,
    );
    selectedSeqId.value = id;
    await refreshSeqs();
  }

  Future<void> updateSeq({
    required String id,
    required String code,
    required String name,
    required String channel,
    required int orderNum,
  }) async {
    await _api.updatePostSeq(
      id: id,
      code: code,
      name: name,
      channel: channel,
      orderNum: orderNum,
    );
    await refreshSeqs();
  }

  Future<void> deleteSeq(String id) async {
    await _api.deletePostSeq(id);
    if (selectedSeqId.value == id.trim()) {
      selectedSeqId.value = null;
      levels.clear();
      levels.refresh();
    }
    await refreshSeqs();
  }

  static String channelLabel(String? channel) {
    switch (channel?.trim().toUpperCase()) {
      case 'M':
        return '管理岗';
      case 'S':
        return '销售岗';
      case 'T':
      case 'P':
        return '技术岗';
      default:
        return channel?.trim() ?? '';
    }
  }

  /// 薪资展示：`3` → `3.00`（与截图一致）。
  static String moneyText(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2);
  }
}
