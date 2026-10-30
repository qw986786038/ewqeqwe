import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_dept.dart';
import '../../../models/hrm_employee.dart';
import '../../../services/hrm_api.dart';

class DirectoryDeptNode {
  DirectoryDeptNode(this.dept);

  final HrmDept dept;
  final List<DirectoryDeptNode> children = [];

  String? get id => dept.deptId?.trim();

  int get onDuty => dept.onDuty ?? 0;

  String get name {
    final n = dept.deptName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return '未命名部门';
  }
}

/// HRM · 企业通讯录。
class EnterpriseDirectoryController extends LxController {
  final _api = HrmApi();
  final searchCtrl = TextEditingController();

  final loading = true.obs;
  final empLoading = false.obs;
  final errorMessage = Rxn<String>();

  final roots = <DirectoryDeptNode>[].obs;
  final expandedIds = <String>{}.obs;

  /// `null` 表示「全部同事」。
  final selectedDeptId = Rxn<String>();

  final employees = <HrmEmployee>[].obs;
  final searchQuery = ''.obs;

  /// 全部同事总数（全量通讯录）。
  final allCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onDispose() {
    searchCtrl.dispose();
    super.onDispose();
  }

  String get headerTitle {
    final id = selectedDeptId.value;
    if (id == null) return '全部同事';
    final node = _findNode(id);
    return node?.name ?? '全部同事';
  }

  int get headerCount => filteredEmployees.length;

  List<HrmEmployee> get filteredEmployees {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return employees.toList();
    return [
      for (final e in employees)
        if (_matchSearch(e, q)) e,
    ];
  }

  bool _matchSearch(HrmEmployee e, String q) {
    if (e.name?.toLowerCase().contains(q) == true) return true;
    if (e.englishName?.toLowerCase().contains(q) == true) return true;
    if (e.aliasName?.toLowerCase().contains(q) == true) return true;
    if (e.no?.toLowerCase().contains(q) == true) return true;
    for (final t in e.titleList) {
      if (t.postName?.toLowerCase().contains(q) == true) return true;
      if (t.deptName?.toLowerCase().contains(q) == true) return true;
      if (t.postSeqLeveName?.toLowerCase().contains(q) == true) return true;
    }
    return false;
  }

  DirectoryDeptNode? _findNode(String id) {
    DirectoryDeptNode? walk(DirectoryDeptNode n) {
      if (n.id == id) return n;
      for (final c in n.children) {
        final hit = walk(c);
        if (hit != null) return hit;
      }
      return null;
    }

    for (final r in roots) {
      final hit = walk(r);
      if (hit != null) return hit;
    }
    return null;
  }

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final depts = await _api.fetchDepts();
      final tree = _buildTree(depts);
      roots
        ..clear()
        ..addAll(tree);
      roots.refresh();
      final allIds = <String>[];
      void collect(DirectoryDeptNode n) {
        final id = n.id;
        if (id != null && id.isNotEmpty) allIds.add(id);
        for (final c in n.children) {
          collect(c);
        }
      }

      for (final r in tree) {
        collect(r);
      }
      expandedIds
        ..clear()
        ..addAll(allIds);
      expandedIds.refresh();
      selectedDeptId.value = null;
      await _loadEmployees(null);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> selectAll() async {
    if (selectedDeptId.value == null && employees.isNotEmpty) return;
    selectedDeptId.value = null;
    searchCtrl.clear();
    searchQuery.value = '';
    await _loadEmployees(null);
  }

  Future<void> selectDept(String deptId) async {
    final id = deptId.trim();
    if (id.isEmpty) return;
    if (selectedDeptId.value == id) return;
    selectedDeptId.value = id;
    searchCtrl.clear();
    searchQuery.value = '';
    await _loadEmployees(id);
  }

  void toggleExpand(String deptId) {
    final id = deptId.trim();
    if (id.isEmpty) return;
    if (expandedIds.contains(id)) {
      expandedIds.remove(id);
    } else {
      expandedIds.add(id);
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> _loadEmployees(String? deptId) async {
    empLoading.value = true;
    try {
      final list = deptId == null
          ? await _api.fetchEmployees(includeChildren: true)
          : await _api.fetchEmployees(
              sysDeptId: deptId,
              includeChildren: true,
            );
      employees
        ..clear()
        ..addAll(list);
      employees.refresh();
      if (deptId == null) {
        allCount.value = list.length;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      employees.clear();
      employees.refresh();
    } finally {
      empLoading.value = false;
    }
  }

  List<DirectoryDeptNode> _buildTree(List<HrmDept> depts) {
    final nodes = <String, DirectoryDeptNode>{};
    for (final d in depts) {
      final id = d.deptId?.trim();
      if (id == null || id.isEmpty) continue;
      nodes[id] = DirectoryDeptNode(d);
    }
    final rootsOut = <DirectoryDeptNode>[];
    for (final node in nodes.values) {
      final parentId = node.dept.parentId?.trim();
      if (parentId == null ||
          parentId.isEmpty ||
          parentId == '0' ||
          !nodes.containsKey(parentId)) {
        rootsOut.add(node);
      } else {
        nodes[parentId]!.children.add(node);
      }
    }
    void sortRec(DirectoryDeptNode n) {
      n.children.sort(
        (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
      );
      for (final c in n.children) {
        sortRec(c);
      }
    }

    rootsOut.sort(
      (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
    );
    for (final r in rootsOut) {
      sortRec(r);
    }
    return rootsOut;
  }

  static HrmEmployeeTitle? primaryTitle(HrmEmployee e) {
    for (final t in e.titleList) {
      if (t.isPrimary == 1) return t;
    }
    return e.titleList.isEmpty ? null : e.titleList.first;
  }

  static String titleLine(HrmEmployee e) {
    final t = primaryTitle(e);
    if (t == null) return '—';
    final parts = [
      if (t.deptName?.trim().isNotEmpty == true) t.deptName!.trim(),
      if (t.postName?.trim().isNotEmpty == true) t.postName!.trim(),
      if (t.postSeqLeveName?.trim().isNotEmpty == true)
        t.postSeqLeveName!.trim(),
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  static String statusLabel(String? status) {
    switch (status?.trim().toUpperCase()) {
      case 'ACTIVE':
        return '在职';
      case 'PENDING':
        return '待入职';
      case 'LEFT':
        return '离职';
      case 'PROBATION':
        return '试用';
      default:
        return status?.trim().isNotEmpty == true ? status!.trim() : '在职';
    }
  }

  static bool statusActive(String? status) {
    final s = status?.trim().toUpperCase();
    return s == null || s.isEmpty || s == 'ACTIVE' || s == 'PROBATION';
  }

  static String formatMobile(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return '未公开';
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    return s;
  }

  static String formatIm(HrmEmployee e) {
    final im = e.imAccount?.trim() ?? '';
    if (im.isNotEmpty) {
      return im.startsWith('@') ? im : '@$im';
    }
    final alias = e.aliasName?.trim() ?? '';
    if (alias.isNotEmpty) return '@$alias';
    final name = e.name?.trim() ?? '';
    if (name.isNotEmpty) return '@$name';
    return '未公开';
  }

  static Color avatarColor(HrmEmployee e) {
    const palette = <Color>[
      Color(0xFFFA8C16),
      Color(0xFF52C41A),
      Color(0xFF1677FF),
      Color(0xFF722ED1),
      Color(0xFF13C2C2),
      Color(0xFFEB2F96),
      Color(0xFF2F54EB),
      Color(0xFFA0D911),
    ];
    final seed = e.userId ?? e.name?.hashCode ?? 0;
    return palette[seed.abs() % palette.length];
  }

  /// 拨打：唤起系统电话；不可用时复制号码。
  static Future<void> callMobile(
    BuildContext context,
    String? mobile,
  ) async {
    final digits = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      AppToast.show(context: context, title: '手机号未公开');
      return;
    }
    final opened = await _openExternal('tel:$digits');
    if (opened) return;
    await Clipboard.setData(ClipboardData(text: digits));
    if (context.mounted) {
      AppToast.show(context: context, title: '已复制手机号 $digits');
    }
  }

  /// 邮件：唤起系统邮件客户端；不可用时复制邮箱。
  static Future<void> sendEmail(
    BuildContext context,
    String? email,
  ) async {
    final address = email?.trim() ?? '';
    if (address.isEmpty) {
      AppToast.show(context: context, title: '企业邮箱未公开');
      return;
    }
    final opened = await _openExternal('mailto:$address');
    if (opened) return;
    await Clipboard.setData(ClipboardData(text: address));
    if (context.mounted) {
      AppToast.show(context: context, title: '已复制邮箱 $address');
    }
  }

  static Future<bool> _openExternal(String uri) async {
    if (kIsWeb) return false;
    try {
      if (Platform.isWindows) {
        final r = await Process.run('cmd', ['/c', 'start', '', uri]);
        return r.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final r = await Process.run('open', [uri]);
        return r.exitCode == 0;
      }
      if (Platform.isLinux) {
        final r = await Process.run('xdg-open', [uri]);
        return r.exitCode == 0;
      }
    } catch (_) {}
    return false;
  }
}
