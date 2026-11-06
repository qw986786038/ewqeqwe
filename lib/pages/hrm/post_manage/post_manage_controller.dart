import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_post.dart';
import '../../../models/hrm_post_seq.dart';
import '../../../models/hrm_post_seq_level.dart';
import '../../../services/hrm_api.dart';

class PostManageController extends LxController {
  final _api = HrmApi();

  final nameSearchCtrl = TextEditingController();

  final loading = false.obs;
  final errorMessage = Rxn<String>();

  final posts = <HrmPost>[].obs;
  final filteredPosts = <HrmPost>[].obs;

  final seqs = <HrmPostSeq>[];
  final levels = <HrmPostSeqLevel>[];

  final Map<String, HrmPostSeq> _seqById = {};
  final Map<String, HrmPostSeqLevel> _levelById = {};

  String _nameQuery = '';

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onDispose() {
    nameSearchCtrl.dispose();
    super.onDispose();
  }

  Future<void> refreshAll() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _api.fetchPosts(),
        _api.fetchPostSeqs(),
        _api.fetchPostSeqLevels(),
      ]);
      final postList = results[0] as List<HrmPost>;
      seqs
        ..clear()
        ..addAll(results[1] as List<HrmPostSeq>);
      levels
        ..clear()
        ..addAll(results[2] as List<HrmPostSeqLevel>);

      _seqById
        ..clear()
        ..addEntries([
          for (final s in seqs)
            if (s.id != null && s.id!.isNotEmpty) MapEntry(s.id!, s),
        ]);
      _levelById
        ..clear()
        ..addEntries([
          for (final l in levels)
            if (l.id != null && l.id!.isNotEmpty) MapEntry(l.id!, l),
        ]);

      posts
        ..clear()
        ..addAll(postList);
      posts.refresh();
      _applyFilter();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void search() {
    _nameQuery = nameSearchCtrl.text.trim();
    _applyFilter();
  }

  void resetSearch() {
    nameSearchCtrl.clear();
    _nameQuery = '';
    _applyFilter();
  }

  void _applyFilter() {
    final q = _nameQuery;
    if (q.isEmpty) {
      filteredPosts
        ..clear()
        ..addAll(posts);
    } else {
      filteredPosts
        ..clear()
        ..addAll([
          for (final p in posts)
            if ((p.name ?? '').contains(q)) p,
        ]);
    }
    filteredPosts.refresh();
  }

  static String channelLabel(String? channel) {
    switch (channel?.trim().toUpperCase()) {
      case 'M':
        return '管理岗';
      case 'T':
        return '技术岗';
      default:
        return channel?.trim() ?? '';
    }
  }

  /// 职务序列列：`序列名 (通道类型)`。
  String seqDisplay(HrmPost post) {
    final levelId = post.postSeqLevelIdMin ?? post.postSeqLevelIdMax;
    if (levelId == null || levelId.isEmpty) return '-';
    final level = _levelById[levelId];
    final seqId = level?.postSeqId;
    if (seqId == null || seqId.isEmpty) return '-';
    final seq = _seqById[seqId];
    if (seq == null) return '-';
    final name = seq.name?.trim();
    if (name == null || name.isEmpty) return '-';
    final ch = channelLabel(seq.channel);
    if (ch.isEmpty) return name;
    return '$name ($ch)';
  }

  String levelCodeMin(HrmPost post) =>
      _levelById[post.postSeqLevelIdMin]?.code?.trim().isNotEmpty == true
          ? _levelById[post.postSeqLevelIdMin]!.code!.trim()
          : '-';

  String levelCodeMax(HrmPost post) =>
      _levelById[post.postSeqLevelIdMax]?.code?.trim().isNotEmpty == true
          ? _levelById[post.postSeqLevelIdMax]!.code!.trim()
          : '-';

  /// 新增默认排序：当前最大 orderNum + 1。
  int get nextOrderNum {
    var max = 0;
    for (final p in posts) {
      final n = p.orderNum ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  String seqOptionLabel(HrmPostSeq seq) {
    final name = seq.name?.trim() ?? '';
    final ch = channelLabel(seq.channel);
    if (name.isEmpty) return ch.isEmpty ? '-' : ch;
    if (ch.isEmpty) return name;
    return '$name ($ch)';
  }

  List<HrmPostSeqLevel> levelsOfSeq(String? seqId) {
    final id = seqId?.trim();
    if (id == null || id.isEmpty) return const [];
    return [
      for (final l in levels)
        if (l.postSeqId == id) l,
    ];
  }

  /// 由职级 id 反查所属职务序列 id。
  String? seqIdOfLevel(String? levelId) {
    final id = levelId?.trim();
    if (id == null || id.isEmpty) return null;
    return _levelById[id]?.postSeqId?.trim();
  }

  Future<void> createPost({
    required String name,
    required String postSeqLevelIdMin,
    required String postSeqLevelIdMax,
    required int orderNum,
  }) async {
    await _api.createPost(
      name: name,
      postSeqLevelIdMin: postSeqLevelIdMin,
      postSeqLevelIdMax: postSeqLevelIdMax,
      orderNum: orderNum,
    );
    await refreshAll();
  }

  Future<void> updatePost({
    required String id,
    required String name,
    int? orderNum,
  }) async {
    await _api.updatePost(
      id: id,
      name: name,
      orderNum: orderNum,
    );
    await refreshAll();
  }

  Future<void> deletePost(String id) async {
    await _api.deletePost(id);
    await refreshAll();
  }
}
