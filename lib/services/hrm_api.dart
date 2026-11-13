import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_http.dart';
import 'auth_session.dart';
import '../models/hrm_dept.dart';
import '../models/hrm_dept_summary.dart';
import '../models/hrm_employee.dart';
import '../models/hrm_employee_assign.dart';
import '../models/hrm_employee_contact.dart';
import '../models/hrm_employee_contract.dart';
import '../models/hrm_employee_edu.dart';
import '../models/hrm_employee_file.dart';
import '../models/hrm_employee_profile.dart';
import '../models/hrm_employee_skill.dart';
import '../models/hrm_employee_work.dart';
import '../models/hrm_nation.dart';
import '../models/hrm_office_location.dart';
import '../models/hrm_position.dart';
import '../models/hrm_post.dart';
import '../models/hrm_post_seq.dart';
import '../models/hrm_post_seq_level.dart';
import '../models/hrm_skill_group.dart';

class HrmApiException implements Exception {
  HrmApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HrmApi {
  Future<List<HrmDept>> fetchDepts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmDept}');
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw HrmApiException(body['msg']?.toString() ?? '部门列表加载失败');
    }
    final raw = body['data'];
    final list = <HrmDept>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parseDept(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 公司整体配置：`GET /desktop/hrm/dept/summary`。
  Future<HrmDeptSummary> fetchDeptSummary() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmDeptSummary}');
    final body = await _getJson(uri);
    _ensureOk(body, '公司整体配置加载失败');
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return _parseDeptSummary(data);
    }
    if (data is Map) {
      return _parseDeptSummary(Map<String, dynamic>.from(data));
    }
    throw HrmApiException('公司整体配置数据为空');
  }

  /// 部门详情：`GET /desktop/hrm/dept/{deptId}`。
  Future<HrmDept> fetchDeptDetail(String deptId) async {
    final id = deptId.trim();
    if (id.isEmpty) {
      throw HrmApiException('部门 id 不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmDeptDetail(id)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw HrmApiException(body['msg']?.toString() ?? '部门详情加载失败');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return _parseDept(data);
    }
    if (data is Map) {
      return _parseDept(Map<String, dynamic>.from(data));
    }
    throw HrmApiException('部门详情数据为空');
  }

  /// 新增部门：`POST /desktop/hrm/dept`。
  Future<void> createDept({
    required String parentId,
    required String deptName,
    int? orderNum,
    String? status,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmDept}');
    final body = await _postJson(
      uri,
      _deptWriteBody(
        parentId: parentId,
        deptName: deptName,
        orderNum: orderNum,
        status: status,
      ),
    );
    _ensureOk(body, '新增部门失败');
  }

  /// 修改部门：`PUT /desktop/hrm/dept/{deptId}`。
  Future<void> updateDept({
    required String deptId,
    required String parentId,
    required String deptName,
    int? orderNum,
    String? status,
  }) async {
    final id = deptId.trim();
    if (id.isEmpty) throw HrmApiException('部门 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmDeptDetail(id)}',
    );
    final body = await _putJson(
      uri,
      _deptWriteBody(
        parentId: parentId,
        deptName: deptName,
        orderNum: orderNum,
        status: status,
      ),
    );
    _ensureOk(body, '修改部门失败');
  }

  /// 删除部门：`DELETE /desktop/hrm/dept/{deptId}`。
  Future<void> deleteDept(String deptId) async {
    final id = deptId.trim();
    if (id.isEmpty) throw HrmApiException('部门 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmDeptDetail(id)}',
    );
    final body = await _deleteJson(uri);
    _ensureOk(body, '删除部门失败');
  }

  Map<String, dynamic> _deptWriteBody({
    required String parentId,
    required String deptName,
    int? orderNum,
    String? status,
  }) {
    final parentRaw = parentId.trim();
    final parent = parentRaw.isEmpty ? 0 : int.tryParse(parentRaw);
    if (parent == null) throw HrmApiException('父部门无效');
    final name = deptName.trim();
    if (name.isEmpty) throw HrmApiException('部门名称不能为空');
    if (name.length > 30) throw HrmApiException('部门名称不能超过 30 字');
    final st = status?.trim() ?? '';
    if (st.isNotEmpty && st != '0' && st != '1') {
      throw HrmApiException('部门状态无效');
    }
    return {
      'parentId': parent,
      'deptName': name,
      'orderNum': ?orderNum,
      if (st.isNotEmpty) 'status': st,
    };
  }

  /// 员工通讯录：`GET /desktop/hrm/employee-directory`（过滤参数均可选）。
  Future<List<HrmEmployee>> fetchEmployees({
    String? sysDeptId,
    bool? includeChildren,
  }) async {
    final query = <String, String>{};
    final id = sysDeptId?.trim();
    if (id != null && id.isNotEmpty) query['sysDeptId'] = id;
    if (includeChildren != null) {
      query['includeChildren'] = includeChildren ? '1' : '0';
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeDirectory}',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw HrmApiException(body['msg']?.toString() ?? '员工通讯录加载失败');
    }
    final raw = body['data'];
    final list = <HrmEmployee>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parseEmployee(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  /// 任职：`POST /desktop/hrm/employee-assign/appoint`。
  Future<void> appointEmployee({
    required int employeeUserId,
    required int positionId,
    required int postSeqLevelId,
    required String startType,
    required String startDate,
    int isPrimary = 1,
  }) async {
    final type = startType.trim().toUpperCase();
    if (type != 'HIRE' &&
        type != 'REGULARIZATION' &&
        type != 'PROMOTION') {
      throw HrmApiException('开始类型无效');
    }
    final date = startDate.trim();
    if (date.isEmpty) throw HrmApiException('请选择开始时间');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeAssignAppoint}',
    );
    final body = await _postJson(uri, {
      'employeeUserId': employeeUserId,
      'positionId': positionId,
      'postSeqLevelId': postSeqLevelId,
      'isPrimary': isPrimary,
      'startType': type,
      'startDate': date,
    });
    _ensureOk(body, '任职失败');
  }

  /// 卸任：`POST /desktop/hrm/employee-assign/relieve`。
  Future<void> relieveEmployeeAssign({
    required int id,
    required String endDate,
    required String endType,
  }) async {
    final type = endType.trim().toUpperCase();
    const allowed = {
      'TRANSFER_OUT',
      'REGULARIZATION_OUT',
      'PROMOTION_OUT',
      'CONCURRENT_END',
      'RESIGN',
    };
    if (!allowed.contains(type)) {
      throw HrmApiException('结束类型无效');
    }
    final date = endDate.trim();
    if (date.isEmpty) throw HrmApiException('请选择卸任时间');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeAssignRelieve}',
    );
    final body = await _postJson(uri, {
      'id': id,
      'endDate': date,
      'endType': type,
    });
    _ensureOk(body, '卸任失败');
  }

  /// 修改职级：`POST /desktop/hrm/employee-assign/level`。
  Future<void> updateEmployeeAssignLevel({
    required int id,
    required int postSeqLevelId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeAssignLevel}',
    );
    final body = await _postJson(uri, {
      'id': id,
      'postSeqLevelId': postSeqLevelId,
    });
    _ensureOk(body, '修改职级失败');
  }

  /// 调岗：`POST /desktop/hrm/employee-assign/transfer`。
  Future<void> transferEmployeeAssign({
    required String oldPositionId,
    required String newPositionId,
    required String newPostSeqLevelId,
  }) async {
    final oldId = oldPositionId.trim();
    final newId = newPositionId.trim();
    final levelId = newPostSeqLevelId.trim();
    if (oldId.isEmpty) throw HrmApiException('原编制不能为空');
    if (newId.isEmpty) throw HrmApiException('目标编制不能为空');
    if (levelId.isEmpty) throw HrmApiException('目标职级不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeAssignTransfer}',
    );
    final body = await _postJson(uri, {
      'oldPositionId': oldId,
      'newPositionId': newId,
      'newPostSeqLevelId': levelId,
    });
    _ensureOk(body, '调岗失败');
  }

  /// 职务列表：`GET /desktop/hrm/post`。
  Future<List<HrmPost>> fetchPosts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPost}');
    final body = await _getJson(uri);
    _ensureOk(body, '职务列表加载失败');
    final list = <HrmPost>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parsePost(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 新增职务：`POST /desktop/hrm/post`，返回新建 id。
  Future<String> createPost({
    required String name,
    required String postSeqLevelIdMin,
    required String postSeqLevelIdMax,
    required int orderNum,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPost}');
    final body = await _postJson(uri, {
      'name': name,
      'postSeqLevelIdMin': postSeqLevelIdMin,
      'postSeqLevelIdMax': postSeqLevelIdMax,
      'orderNum': orderNum,
    });
    _ensureOk(body, '新增职务失败');
    final data = body['data'];
    final id = data?.toString().trim();
    if (id == null || id.isEmpty) {
      throw HrmApiException('新增职务成功但未返回 id');
    }
    return id;
  }

  /// 修改职务：`PUT /desktop/hrm/post/{id}`。
  Future<void> updatePost({
    required String id,
    required String name,
    int? orderNum,
  }) async {
    final postId = id.trim();
    if (postId.isEmpty) {
      throw HrmApiException('职务 id 不能为空');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw HrmApiException('请输入职务名称');
    }
    if (trimmed.length > 10) {
      throw HrmApiException('职务名称不能超过10个字');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPost}/$postId');
    final payload = <String, dynamic>{'name': trimmed, 'orderNum': ?orderNum};
    final body = await _putJson(uri, payload);
    _ensureOk(body, '修改职务失败');
  }

  /// 删除职务：`DELETE /desktop/hrm/post/{id}`。
  Future<void> deletePost(String id) async {
    final postId = id.trim();
    if (postId.isEmpty) {
      throw HrmApiException('职务 id 不能为空');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPost}/$postId');
    final body = await _deleteJson(uri);
    _ensureOk(body, '删除职务失败');
  }

  /// 职务序列列表：`GET /desktop/hrm/post-seq`。
  Future<List<HrmPostSeq>> fetchPostSeqs() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPostSeq}');
    final body = await _getJson(uri);
    _ensureOk(body, '职务序列加载失败');
    final list = <HrmPostSeq>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parsePostSeq(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 新增职务序列：`POST /desktop/hrm/post-seq`，返回新建 id。
  Future<String> createPostSeq({
    required String code,
    required String name,
    required String channel,
    int? orderNum,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPostSeq}');
    final payload = <String, dynamic>{
      'code': code,
      'name': name,
      'channel': channel,
    };
    if (orderNum != null) payload['orderNum'] = orderNum;
    final body = await _postJson(uri, payload);
    _ensureOk(body, '新增职务序列失败');
    final data = body['data'];
    final id = data?.toString().trim();
    if (id == null || id.isEmpty) {
      throw HrmApiException('新增职务序列成功但未返回 id');
    }
    return id;
  }

  /// 修改职务序列：`PUT /desktop/hrm/post-seq/{id}`。
  Future<void> updatePostSeq({
    required String id,
    required String code,
    required String name,
    required String channel,
    int? orderNum,
  }) async {
    final seqId = id.trim();
    if (seqId.isEmpty) {
      throw HrmApiException('职务序列 id 不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPostSeq}/$seqId',
    );
    final payload = <String, dynamic>{
      'code': code,
      'name': name,
      'channel': channel,
    };
    if (orderNum != null) payload['orderNum'] = orderNum;
    final body = await _putJson(uri, payload);
    _ensureOk(body, '修改职务序列失败');
  }

  /// 删除职务序列：`DELETE /desktop/hrm/post-seq/{id}`。
  Future<void> deletePostSeq(String id) async {
    final seqId = id.trim();
    if (seqId.isEmpty) {
      throw HrmApiException('职务序列 id 不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPostSeq}/$seqId',
    );
    final body = await _deleteJson(uri);
    _ensureOk(body, '删除职务序列失败');
  }

  /// 新增职务序列职级：`POST /desktop/hrm/post-seq-level`，返回新建 id。
  Future<String> createPostSeqLevel({
    required String postSeqId,
    required String code,
    required num salaryMin,
    required num salaryMax,
    int? orderNum,
  }) async {
    final seqId = postSeqId.trim();
    if (seqId.isEmpty) {
      throw HrmApiException('所属职务序列不能为空');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPostSeqLevel}');
    final payload = <String, dynamic>{
      'postSeqId': int.tryParse(seqId) ?? seqId,
      'code': code,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
    };
    if (orderNum != null) payload['orderNum'] = orderNum;
    final body = await _postJson(uri, payload);
    _ensureOk(body, '新增职级失败');
    final data = body['data'];
    final id = data?.toString().trim();
    if (id == null || id.isEmpty) {
      throw HrmApiException('新增职级成功但未返回 id');
    }
    return id;
  }

  /// 修改职务序列职级：`PUT /desktop/hrm/post-seq-level/{id}`。
  Future<void> updatePostSeqLevel({
    required String id,
    required String postSeqId,
    required String code,
    required num salaryMin,
    required num salaryMax,
    int? orderNum,
  }) async {
    final levelId = id.trim();
    final seqId = postSeqId.trim();
    if (levelId.isEmpty) {
      throw HrmApiException('职级 id 不能为空');
    }
    if (seqId.isEmpty) {
      throw HrmApiException('所属职务序列不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPostSeqLevel}/$levelId',
    );
    final payload = <String, dynamic>{
      'postSeqId': int.tryParse(seqId) ?? seqId,
      'code': code,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
    };
    if (orderNum != null) payload['orderNum'] = orderNum;
    final body = await _putJson(uri, payload);
    _ensureOk(body, '修改职级失败');
  }

  /// 删除职务序列职级：`DELETE /desktop/hrm/post-seq-level/{id}`。
  Future<void> deletePostSeqLevel(String id) async {
    final levelId = id.trim();
    if (levelId.isEmpty) {
      throw HrmApiException('职级 id 不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPostSeqLevel}/$levelId',
    );
    final body = await _deleteJson(uri);
    _ensureOk(body, '删除职级失败');
  }

  /// 职务序列职级列表：`GET /desktop/hrm/post-seq-level`。
  Future<List<HrmPostSeqLevel>> fetchPostSeqLevels({String? postSeqId}) async {
    final query = <String, String>{};
    final seqId = postSeqId?.trim();
    if (seqId != null && seqId.isNotEmpty) {
      query['postSeqId'] = seqId;
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPostSeqLevel}',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final body = await _getJson(uri);
    _ensureOk(body, '职务序列职级加载失败');
    final list = <HrmPostSeqLevel>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parsePostSeqLevel(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 按职务序列查职级：`GET /desktop/hrm/post-seq-level/post-seq/{postSeqId}`。
  Future<List<HrmPostSeqLevel>> fetchPostSeqLevelsBySeq(String postSeqId) async {
    final id = postSeqId.trim();
    if (id.isEmpty) return const [];
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPostSeqLevelsBySeq(id)}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '序列职级加载失败');
    final list = <HrmPostSeqLevel>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parsePostSeqLevel(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 编制分页：`GET /desktop/hrm/position`（过滤参数均可选）。
  Future<HrmPositionsPage> fetchPositionsPage({
    String? sysDeptId,
    String? postId,
    String? type,
    String? reportPositionId,
    String? dottedPositionId,
    int pageNum = 1,
    int pageSize = 10,
    String? orderByColumn,
    String? isAsc,
  }) async {
    final query = <String, String>{
      'pageNum': '$pageNum',
      'pageSize': '$pageSize',
    };
    final dept = sysDeptId?.trim();
    final post = postId?.trim();
    final t = type?.trim();
    final report = reportPositionId?.trim();
    final dotted = dottedPositionId?.trim();
    final orderCol = orderByColumn?.trim();
    final asc = isAsc?.trim();
    if (dept != null && dept.isNotEmpty) query['sysDeptId'] = dept;
    if (post != null && post.isNotEmpty) query['sysPostId'] = post;
    if (t != null && t.isNotEmpty) query['type'] = t;
    if (report != null && report.isNotEmpty) query['reportPositionId'] = report;
    if (dotted != null && dotted.isNotEmpty) {
      query['dottedPositionId'] = dotted;
    }
    if (orderCol != null && orderCol.isNotEmpty) {
      query['orderByColumn'] = orderCol;
    }
    if (asc != null && asc.isNotEmpty) query['isAsc'] = asc;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPosition}',
    ).replace(queryParameters: query);
    final body = await _getJson(uri);
    _ensureOk(body, '编制列表加载失败');
    final list = <HrmPosition>[];
    final raw = body['rows'] ?? body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parsePosition(Map<String, dynamic>.from(item)));
        }
      }
    }
    final total = _asInt(body['total']) ?? list.length;
    return HrmPositionsPage(total: total, rows: list);
  }

  /// 新增编制：`POST /desktop/hrm/position`，返回新建 id。
  Future<String> createPosition({
    required String sysDeptId,
    required String postId,
    required String type,
    String? reportPositionId,
    String? dottedPositionId,
  }) async {
    final dept = sysDeptId.trim();
    final post = postId.trim();
    final t = type.trim().toUpperCase();
    if (dept.isEmpty) throw HrmApiException('所属部门不能为空');
    if (post.isEmpty) throw HrmApiException('所属职务不能为空');
    if (t != 'REGULAR' && t != 'RESERVE' && t != 'OUTSOURCE') {
      throw HrmApiException('编制类型无效');
    }
    final postVal = int.tryParse(post) ?? post;
    final payload = <String, dynamic>{
      'sysDeptId': int.tryParse(dept) ?? dept,
      'sysPostId': postVal,
      'postId': postVal,
      'type': t,
    };
    final report = reportPositionId?.trim();
    final dotted = dottedPositionId?.trim();
    if (report != null && report.isNotEmpty) {
      payload['reportPositionId'] = int.tryParse(report) ?? report;
    }
    if (dotted != null && dotted.isNotEmpty) {
      payload['dottedPositionId'] = int.tryParse(dotted) ?? dotted;
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmPosition}');
    final body = await _postJson(uri, payload);
    _ensureOk(body, '新增编制失败');
    final data = body['data'];
    final id = data?.toString().trim();
    if (id == null || id.isEmpty) {
      throw HrmApiException('新增编制成功但未返回 id');
    }
    return id;
  }

  /// 修改编制：`PUT /desktop/hrm/position/{id}`。
  Future<void> updatePosition({
    required String id,
    required String sysDeptId,
    required String postId,
    required String type,
    String? reportPositionId,
    String? dottedPositionId,
  }) async {
    final positionId = id.trim();
    final dept = sysDeptId.trim();
    final post = postId.trim();
    final t = type.trim().toUpperCase();
    if (positionId.isEmpty) throw HrmApiException('编制 id 不能为空');
    if (dept.isEmpty) throw HrmApiException('所属部门不能为空');
    if (post.isEmpty) throw HrmApiException('所属职务不能为空');
    if (t != 'REGULAR' && t != 'RESERVE' && t != 'OUTSOURCE') {
      throw HrmApiException('编制类型无效');
    }
    final postVal = int.tryParse(post) ?? post;
    final payload = <String, dynamic>{
      'sysDeptId': int.tryParse(dept) ?? dept,
      'sysPostId': postVal,
      'postId': postVal,
      'type': t,
    };
    final report = reportPositionId?.trim();
    final dotted = dottedPositionId?.trim();
    if (report != null && report.isNotEmpty) {
      payload['reportPositionId'] = int.tryParse(report) ?? report;
    }
    if (dotted != null && dotted.isNotEmpty) {
      payload['dottedPositionId'] = int.tryParse(dotted) ?? dotted;
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPosition}/$positionId',
    );
    final body = await _putJson(uri, payload);
    _ensureOk(body, '修改编制失败');
  }

  /// 删除编制：`DELETE /desktop/hrm/position/{id}`。
  Future<void> deletePosition(String id) async {
    final positionId = id.trim();
    if (positionId.isEmpty) throw HrmApiException('编制 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPosition}/$positionId',
    );
    final body = await _deleteJson(uri);
    _ensureOk(body, '删除编制失败');
  }

  /// 编制 / 编制列表：`GET /desktop/hrm/position/list`（过滤参数均可选）。
  /// Query 字段与接口一致：`sysDeptId` / `sysPostId` / `type` / `used`。
  /// [used] 为 0 时只返回空编。
  Future<List<HrmPosition>> fetchPositions({
    String? sysDeptId,
    String? postId,
    String? type,
    int? used,
  }) async {
    final query = <String, String>{};
    final dept = sysDeptId?.trim();
    final post = postId?.trim();
    final t = type?.trim();
    if (dept != null && dept.isNotEmpty) query['sysDeptId'] = dept;
    if (post != null && post.isNotEmpty) query['sysPostId'] = post;
    if (t != null && t.isNotEmpty) query['type'] = t;
    if (used != null) query['used'] = '$used';

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmPositionList}',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final body = await _getJson(uri);
    _ensureOk(body, '编制列表加载失败');
    final list = <HrmPosition>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parsePosition(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  /// 按部门批量拉编制。
  /// 先试 dept+type；若全空且提供了 [postIds]，再试 dept+post+type（接口三者皆必填时）。
  Future<List<HrmPosition>> fetchPositionsForDepts(
    Iterable<String> deptIds, {
    Iterable<String> postIds = const [],
    List<String> types = const ['REGULAR', 'RESERVE', 'OUTSOURCE'],
  }) async {
    final ids = [
      for (final id in deptIds)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (ids.isEmpty) return const [];

    final out = <HrmPosition>[];
    final seen = <String>{};

    Future<List<HrmPosition>> safeFetch({
      required String deptId,
      required String type,
      String? postId,
    }) async {
      try {
        return await fetchPositions(
          sysDeptId: deptId,
          postId: postId,
          type: type,
        );
      } catch (_) {
        return const [];
      }
    }

    void collect(List<HrmPosition> list) {
      for (final p in list) {
        final id = p.id?.trim();
        if (id == null || id.isEmpty || !seen.add(id)) continue;
        out.add(p);
      }
    }

    // 分批：部门 × 编制类型
    const chunk = 10;
    for (var i = 0; i < ids.length; i += chunk) {
      final end = (i + chunk > ids.length) ? ids.length : i + chunk;
      final slice = ids.sublist(i, end);
      final batches = await Future.wait([
        for (final deptId in slice)
          for (final type in types) safeFetch(deptId: deptId, type: type),
      ]);
      for (final list in batches) {
        collect(list);
      }
    }

    if (out.isNotEmpty) return out;

    final posts = [
      for (final id in postIds)
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (posts.isEmpty) return out;

    // 兜底：部门 × 职务 × 编制类型
    for (final deptId in ids) {
      for (var i = 0; i < posts.length; i += 6) {
        final end = (i + 6 > posts.length) ? posts.length : i + 6;
        final slice = posts.sublist(i, end);
        final batches = await Future.wait([
          for (final postId in slice)
            for (final type in types)
              safeFetch(deptId: deptId, type: type, postId: postId),
        ]);
        for (final list in batches) {
          collect(list);
        }
      }
    }
    return out;
  }

  /// 全部在任：`GET /desktop/hrm/employee-assign/on-duty`。
  Future<List<HrmEmployeeAssign>> fetchOnDutyAssigns() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeAssignOnDuty}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '在任列表加载失败');
    final list = <HrmEmployeeAssign>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parseAssign(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  /// 员工分页：`GET /desktop/hrm/employee`（过滤参数均可选）。
  Future<HrmEmployeesPage> fetchEmployeesPage({
    String? keyword,
    String? name,
    String? no,
    String? mobile,
    String? empStatus,
    String? conversionStatus,
    String? empType,
    String? sysDeptId,
    String? sysPostId,
    int pageNum = 1,
    int pageSize = 10,
    String? orderByColumn,
    String? isAsc,
  }) async {
    final query = <String, String>{
      'pageNum': '$pageNum',
      'pageSize': '$pageSize',
    };
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) query[key] = v;
    }

    put('keyword', keyword);
    put('name', name);
    put('no', no);
    put('mobile', mobile);
    put('empStatus', empStatus);
    put('conversionStatus', conversionStatus);
    put('empType', empType);
    put('sysDeptId', sysDeptId);
    put('sysPostId', sysPostId);
    put('orderByColumn', orderByColumn);
    put('isAsc', isAsc);

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeList}',
    ).replace(queryParameters: query);
    final body = await _getJson(uri);
    _ensureOk(body, '员工列表加载失败');
    final list = <HrmEmployeeProfile>[];
    final raw = body['rows'] ?? body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parseEmployeeProfile(Map<String, dynamic>.from(item)));
        }
      }
    }
    final total = _asInt(body['total']) ?? list.length;
    return HrmEmployeesPage(total: total, rows: list);
  }

  /// 员工统计：`GET /desktop/hrm/employee/stats`。
  Future<HrmEmployeeStats> fetchEmployeeStats() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeStats}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '员工统计加载失败');
    final data = body['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return HrmEmployeeStats()
      ..totalCount = _asInt(map['totalCount']) ?? 0
      ..activeCount = _asInt(map['activeCount']) ?? 0
      ..probationCount = _asInt(map['probationCount']) ?? 0
      ..pendingActiveCount = _asInt(map['pendingActiveCount']) ?? 0
      ..nearestPendingHireDate = _asString(map['nearestPendingHireDate'])
      ..leaveCount = _asInt(map['leaveCount']) ?? 0
      ..monthHireCount = _asInt(map['monthHireCount']) ?? 0
      ..lastMonthHireCount = _asInt(map['lastMonthHireCount']) ?? 0
      ..monthLeaveCount = _asInt(map['monthLeaveCount']) ?? 0
      ..monthLeaveVoluntaryCount =
          _asInt(map['monthLeaveVoluntaryCount']) ?? 0
      ..monthLeaveInvoluntaryCount =
          _asInt(map['monthLeaveInvoluntaryCount']) ?? 0
      ..monthLeaveOtherCount = _asInt(map['monthLeaveOtherCount']) ?? 0
      ..contractExpiringCount = _asInt(map['contractExpiringCount']) ?? 0
      ..contractExpiringDays = _asInt(map['contractExpiringDays']) ?? 90;
  }

  /// 待入职统计：`GET /desktop/hrm/employee/stats/pending-active`。
  Future<HrmEmployeePendingActiveStats> fetchPendingActiveStats() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeePendingActiveStats}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '待入职统计加载失败');
    final data = body['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return HrmEmployeePendingActiveStats()
      ..totalCount = _asInt(map['totalCount']) ?? 0
      ..todayCount = _asInt(map['todayCount']) ?? 0
      ..monthCount = _asInt(map['monthCount']) ?? 0;
  }

  /// 待转正统计：`GET /desktop/hrm/employee/stats/pending-regularization`。
  Future<HrmEmployeePendingRegularizationStats>
      fetchPendingRegularizationStats() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeePendingRegularizationStats}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '待转正统计加载失败');
    final data = body['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return HrmEmployeePendingRegularizationStats()
      ..totalCount = _asInt(map['totalCount']) ?? 0
      ..overdueCount = _asInt(map['overdueCount']) ?? 0
      ..monthCount = _asInt(map['monthCount']) ?? 0
      ..nextMonthCount = _asInt(map['nextMonthCount']) ?? 0;
  }

  /// 确认转正：`POST /desktop/hrm/employee/{id}/regularize`。
  Future<void> regularizeEmployee({
    required String id,
    required String regularizationDate,
  }) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final date = regularizationDate.trim();
    if (date.isEmpty) throw HrmApiException('转正日期不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeRegularize(employeeId)}',
    );
    final body = await _postJson(uri, {'regularizationDate': date});
    _ensureOk(body, '确认转正失败');
  }

  /// 离职申请：`POST /desktop/hrm/employee/{id}/leave-apply`。
  Future<void> applyEmployeeLeave({
    required String id,
    required String leaveDate,
    required String leaveType,
    String? leaveRemark,
  }) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final date = leaveDate.trim();
    if (date.isEmpty) throw HrmApiException('离职日期不能为空');
    final type = leaveType.trim();
    if (type != 'VOLUNTARY' && type != 'INVOLUNTARY' && type != 'OTHER') {
      throw HrmApiException('离职类型无效');
    }
    final remark = leaveRemark?.trim() ?? '';
    if (remark.length > 100) throw HrmApiException('离职备注不能超过 100 个字符');
    final payload = <String, dynamic>{
      'leaveDate': date,
      'leaveType': type,
    };
    if (remark.isNotEmpty) payload['leaveRemark'] = remark;
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeLeaveApply(employeeId)}',
    );
    final body = await _postJson(uri, payload);
    _ensureOk(body, '办理离职失败');
  }

  /// 确认离职：`POST /desktop/hrm/employee/{id}/leave-confirm`。
  Future<void> confirmEmployeeLeave({
    required String id,
    required String leaveDate,
    required String leaveType,
    String? leaveRemark,
  }) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final date = leaveDate.trim();
    if (date.isEmpty) throw HrmApiException('离职日期不能为空');
    final type = leaveType.trim();
    if (type != 'VOLUNTARY' && type != 'INVOLUNTARY' && type != 'OTHER') {
      throw HrmApiException('离职类型无效');
    }
    final remark = leaveRemark?.trim() ?? '';
    if (remark.length > 100) throw HrmApiException('离职备注不能超过 100 个字符');
    final payload = <String, dynamic>{
      'leaveDate': date,
      'leaveType': type,
    };
    if (remark.isNotEmpty) payload['leaveRemark'] = remark;
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeLeaveConfirm(employeeId)}',
    );
    final body = await _postJson(uri, payload);
    _ensureOk(body, '确认离职失败');
  }

  /// 撤销离职申请：`POST /desktop/hrm/employee/{id}/leave-revoke`。
  Future<void> revokeEmployeeLeave(String id) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeLeaveRevoke(employeeId)}',
    );
    final body = await _postJson(uri, const <String, dynamic>{});
    _ensureOk(body, '撤销离职失败');
  }

  /// 确认入职：`POST /desktop/hrm/employee/{id}/hire`。
  Future<void> hireEmployee({
    required String id,
    required String name,
    required String mobile,
    required String expectedHireDate,
    required String empType,
    String? personalEmail,
    int? sysDeptId,
    int? sysPostId,
    int? positionId,
    int? postSeqLevelId,
  }) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final payload = <String, dynamic>{
      'name': name.trim(),
      'mobile': mobile.trim(),
      'expectedHireDate': expectedHireDate.trim(),
      'empType': empType.trim(),
    };
    final email = personalEmail?.trim();
    if (email != null && email.isNotEmpty) payload['personalEmail'] = email;
    if (sysDeptId != null) payload['sysDeptId'] = sysDeptId;
    if (sysPostId != null) payload['sysPostId'] = sysPostId;
    if (positionId != null) payload['positionId'] = positionId;
    if (postSeqLevelId != null) payload['postSeqLevelId'] = postSeqLevelId;
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeHire(employeeId)}',
    );
    final body = await _postJson(uri, payload);
    _ensureOk(body, '确认入职失败');
  }

  /// 取消入职：`POST /desktop/hrm/employee/{id}/hire-revoke`。
  Future<void> revokeHire(String id) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeHireRevoke(employeeId)}',
    );
    final body = await _postJson(uri, <String, dynamic>{});
    _ensureOk(body, '取消入职失败');
  }

  /// 恢复为待入职：`POST /desktop/hrm/employee/{id}/hire-restore`。
  Future<void> restoreHire(String id) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeHireRestore(employeeId)}',
    );
    final body = await _postJson(uri, <String, dynamic>{});
    _ensureOk(body, '恢复为待入职失败');
  }

  /// 员工列表（组织架构等全量拉取）：`GET /desktop/hrm/employee`。
  Future<List<HrmEmployeeProfile>> fetchEmployeeProfiles({
    int pageNum = 1,
    int pageSize = 10000,
  }) async {
    final page = await fetchEmployeesPage(
      pageNum: pageNum,
      pageSize: pageSize,
    );
    return page.rows;
  }

  /// 按员工 ID 查详情：`GET /desktop/hrm/employee/{id}`，返回 `HrmEmployeeVo`。
  Future<HrmEmployeeProfile> fetchEmployeeById(String id) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) {
      throw HrmApiException('员工 id 不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeDetail(employeeId)}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '员工详情加载失败');
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return _parseEmployeeProfile(data);
    }
    if (data is Map) {
      return _parseEmployeeProfile(Map<String, dynamic>.from(data));
    }
    throw HrmApiException('员工详情数据为空');
  }

  /// 按 userId 查员工详情：`GET /desktop/hrm/employee/user/{userId}`。
  Future<HrmEmployeeProfile> fetchEmployeeByUser(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeByUser(userId)}',
    );
    final body = await _getJson(uri);
    _ensureOk(body, '员工详情加载失败');
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return _parseEmployeeProfile(data);
    }
    if (data is Map) {
      return _parseEmployeeProfile(Map<String, dynamic>.from(data));
    }
    throw HrmApiException('员工详情数据为空');
  }

  Map<String, dynamic> _employeeWritePayload({
    required Map<String, dynamic> info,
    List<Map<String, dynamic>>? workList,
    List<Map<String, dynamic>>? contactList,
    List<Map<String, dynamic>>? eduList,
    List<Map<String, dynamic>>? contracts,
    List<int>? skillIds,
    List<Map<String, dynamic>>? assignAppoint,
  }) {
    final payload = <String, dynamic>{'info': info};
    if (workList != null) payload['workList'] = workList;
    if (contactList != null) payload['contactList'] = contactList;
    if (eduList != null) payload['eduList'] = eduList;
    if (contracts != null) payload['contracts'] = contracts;
    if (skillIds != null) payload['skillIds'] = skillIds;
    if (assignAppoint != null) payload['assignAppoint'] = assignAppoint;
    return payload;
  }

  /// 添加待入职：`POST /desktop/hrm/employee/pending-active`。
  Future<void> createPendingEmployee({
    required String name,
    required String mobile,
    required String expectedHireDate,
    required String empType,
    String? personalEmail,
    int? sysDeptId,
    int? sysPostId,
    int? positionId,
    int? postSeqLevelId,
  }) async {
    final personName = name.trim();
    final phone = mobile.trim();
    final hireDate = expectedHireDate.trim();
    final type = empType.trim();
    if (personName.isEmpty) throw HrmApiException('姓名不能为空');
    if (personName.length > 30) throw HrmApiException('姓名不能超过30个字');
    if (phone.isEmpty) throw HrmApiException('手机号不能为空');
    if (phone.length > 20) throw HrmApiException('手机号不能超过20个字');
    if (hireDate.isEmpty) throw HrmApiException('预计入职日期不能为空');
    const types = {'FORMAL', 'INTERN', 'OUTSOURCE', 'LABOR', 'CONSULTANT'};
    if (!types.contains(type)) throw HrmApiException('员工类型无效');
    final payload = <String, dynamic>{
      'name': personName,
      'mobile': phone,
      'expectedHireDate': hireDate,
      'empType': type,
    };
    final email = personalEmail?.trim();
    if (email != null && email.isNotEmpty) {
      if (email.length > 100) throw HrmApiException('个人邮箱不能超过100个字');
      payload['personalEmail'] = email;
    }
    if (sysDeptId != null) payload['sysDeptId'] = sysDeptId;
    if (sysPostId != null) payload['sysPostId'] = sysPostId;
    if (positionId != null) payload['positionId'] = positionId;
    if (postSeqLevelId != null) payload['postSeqLevelId'] = postSeqLevelId;
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeePendingActive}',
    );
    final body = await _postJson(uri, payload);
    _ensureOk(body, '添加待入职失败');
  }

  /// 新增员工：`POST /desktop/hrm/employee`，返回新建 id。
  /// Body：`{ info, workList?, contactList?, eduList?, contracts?, skillIds?, assignAppoint? }`。
  Future<String> createEmployee({
    required Map<String, dynamic> info,
    List<Map<String, dynamic>>? workList,
    List<Map<String, dynamic>>? contactList,
    List<Map<String, dynamic>>? eduList,
    List<Map<String, dynamic>>? contracts,
    List<int>? skillIds,
    List<Map<String, dynamic>>? assignAppoint,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeList}');
    final body = await _postJson(
      uri,
      _employeeWritePayload(
        info: info,
        workList: workList,
        contactList: contactList,
        eduList: eduList,
        contracts: contracts,
        skillIds: skillIds,
        assignAppoint: assignAppoint,
      ),
    );
    _ensureOk(body, '新增员工失败');
    final data = body['data'];
    if (data is Map) {
      final id = _asString(data['id'])?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    final id = data?.toString().trim();
    if (id == null || id.isEmpty || id == 'null') {
      throw HrmApiException('新增员工成功但未返回 id');
    }
    return id;
  }

  /// 修改员工：`PUT /desktop/hrm/employee/{id}`。
  /// Body 为员工字段本身（`name`、`employeeNo` 等），不再包在 `info` 里。
  Future<void> updateEmployee({
    required String id,
    required Map<String, dynamic> info,
    List<Map<String, dynamic>>? workList,
    List<Map<String, dynamic>>? contactList,
    List<Map<String, dynamic>>? eduList,
    List<Map<String, dynamic>>? contracts,
    List<int>? skillIds,
    List<Map<String, dynamic>>? assignAppoint,
  }) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) {
      throw HrmApiException('员工 id 不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeUpdate(employeeId)}',
    );
    final payload = _employeeUpdateBody(info);
    if (workList != null) payload['workList'] = workList;
    if (contactList != null) payload['contactList'] = contactList;
    if (eduList != null) payload['eduList'] = eduList;
    if (contracts != null) payload['contracts'] = contracts;
    if (skillIds != null) payload['skillIds'] = skillIds;
    if (assignAppoint != null) payload['assignAppoint'] = assignAppoint;
    final body = await _putJson(uri, payload);
    _ensureOk(body, '修改员工失败');
  }

  /// 把档案表单整理成修改员工接口的扁平 Body。
  Map<String, dynamic> _employeeUpdateBody(Map<String, dynamic> info) {
    String? text(Object? raw) {
      final s = raw?.toString().trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    void checkLen(String label, String value, int max) {
      if (value.length > max) {
        throw HrmApiException('$label不能超过$max个字');
      }
    }

    final name = text(info['name']);
    if (name == null) throw HrmApiException('姓名不能为空');
    checkLen('姓名', name, 30);
    final employeeNo = text(info['employeeNo']) ?? text(info['no']);
    if (employeeNo == null) throw HrmApiException('工号不能为空');
    checkLen('工号', employeeNo, 32);

    final body = <String, dynamic>{
      'name': name,
      'employeeNo': employeeNo,
    };

    void putStr(String key, {int? max, String? label}) {
      final s = text(info[key]);
      if (s == null) return;
      if (max != null) checkLen(label ?? key, s, max);
      body[key] = s;
    }

    void putInt(String key) {
      final raw = info[key];
      if (raw is int) {
        body[key] = raw;
        return;
      }
      final s = text(raw);
      if (s == null) return;
      final n = int.tryParse(s);
      if (n != null) body[key] = n;
    }

    String? allowed(Object? raw, Set<String> values) {
      final s = text(raw);
      if (s == null || !values.contains(s)) return null;
      return s;
    }

    putStr('corpEmail', max: 100, label: '企业邮箱');
    putStr('officePhone', max: 30, label: '办公电话');
    putInt('officeLocation');
    putStr('workstation', max: 50, label: '工位');
    final empStatus = allowed(info['empStatus'], {
          'PENDING_ACTIVE',
          'ACTIVE',
          'PENDING_LEAVE',
          'LEAVE',
          'CANCEL_ACTIVE',
        }) ??
        switch (text(info['empStatus'])) {
          'PENDING' => 'PENDING_ACTIVE',
          'LEFT' => 'LEAVE',
          _ => null,
        };
    if (empStatus != null) body['empStatus'] = empStatus;
    final conversionStatus = allowed(info['conversionStatus'], {
      'NOT_REQUIRED',
      'PENDING',
      'CONVERTED',
    });
    if (conversionStatus != null) {
      body['conversionStatus'] = conversionStatus;
    }
    putStr('regularizationDate');
    final trip = info['businessTrip'];
    final tripCode = trip is int ? trip : int.tryParse(text(trip) ?? '');
    if (tripCode == 0 || tripCode == 1 || tripCode == 3) {
      body['businessTrip'] = tripCode;
    }
    putStr('businessTripCity', max: 100, label: '出差城市');
    final empType = allowed(info['empType'], {
          'FORMAL',
          'INTERN',
          'OUTSOURCE',
          'LABOR',
          'CONSULTANT',
        }) ??
        switch (text(info['empType'])) {
          'FULL_TIME' || 'EMPLOYEE' => 'FORMAL',
          _ => null,
        };
    if (empType != null) body['empType'] = empType;
    putStr('hireDate');
    putStr('leaveDate');
    final leaveType = allowed(info['leaveType'], {
      'VOLUNTARY',
      'INVOLUNTARY',
      'OTHER',
    });
    if (leaveType != null) body['leaveType'] = leaveType;
    putStr('leaveRemark', max: 100, label: '离职备注');
    putStr('mobile', max: 20, label: '手机号');
    putStr('personalEmail', max: 100, label: '个人邮箱');
    putStr('pinYin', max: 30, label: '姓名拼音');
    putStr('englishName', max: 50, label: '英文名');
    final gender = allowed(info['gender'], {'0', '1', '2'});
    if (gender != null) body['gender'] = gender;
    putStr('birthDate');
    putStr('nation', max: 30, label: '民族');
    putInt('province');
    putInt('city');
    putInt('district');
    putStr('householdAddress', max: 200, label: '户籍所在地');
    putStr('residence', max: 200, label: '现居住地');
    putStr('politicalStatus', max: 30, label: '政治面貌');
    final maritalStatus = allowed(info['maritalStatus'], {'0', '1', '3', '9'});
    if (maritalStatus != null) body['maritalStatus'] = maritalStatus;
    putStr('firstWorkDate');
    putStr('socialSecurityAccount', max: 64, label: '社保账号');
    putStr('housingFundAccount', max: 64, label: '公积金账号');
    putStr('idCardType', max: 30, label: '证件类型');
    putStr('idCardNo', max: 32, label: '证件号码');
    putStr('imAccount', max: 100, label: 'IM账号');
    for (final key in const [
      'showMobile',
      'showEmail',
      'showIm',
      'showOffice',
      'keepInDirectory',
    ]) {
      final raw = info[key];
      final n = switch (raw) {
        int value => value,
        bool value => value ? 1 : 0,
        _ => int.tryParse(text(raw) ?? ''),
      };
      if (n == 0 || n == 1) body[key] = n;
    }
    return body;
  }

  /// 民族列表：`GET /desktop/hrm/nation`。
  Future<List<HrmNation>> fetchNations() async {
    final list = await _fetchList(
      ApiConfig.hrmNation,
      '民族列表加载失败',
      _parseNation,
    );
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 办公地点列表：`GET /desktop/hrm/office-location`。
  Future<List<HrmOfficeLocation>> fetchOfficeLocations() async {
    final list = await _fetchList(
      ApiConfig.hrmOfficeLocation,
      '办公地点加载失败',
      _parseOfficeLocation,
    );
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 新增办公地：`POST /desktop/hrm/office-location`，返回新建 id。
  Future<String> createOfficeLocation({
    required String name,
    required String address,
    required int orderNum,
  }) async {
    final n = name.trim();
    final a = address.trim();
    if (n.isEmpty) throw HrmApiException('办公地址名称不能为空');
    if (n.length > 30) throw HrmApiException('办公地址名称不能超过 30 字');
    if (a.isEmpty) throw HrmApiException('详细地址不能为空');
    if (a.length > 100) throw HrmApiException('详细地址不能超过 100 字');
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmOfficeLocation}');
    final body = await _postJson(uri, {
      'name': n,
      'address': a,
      'orderNum': orderNum,
    });
    _ensureOk(body, '新增办公地失败');
    final data = body['data'];
    final id = data?.toString().trim();
    if (id == null || id.isEmpty) {
      throw HrmApiException('新增办公地成功但未返回 id');
    }
    return id;
  }

  /// 修改办公地：`PUT /desktop/hrm/office-location/{id}`。
  Future<void> updateOfficeLocation({
    required String id,
    required String name,
    required String address,
    required int orderNum,
  }) async {
    final locationId = id.trim();
    if (locationId.isEmpty) throw HrmApiException('办公地 id 不能为空');
    final n = name.trim();
    final a = address.trim();
    if (n.isEmpty) throw HrmApiException('办公地址名称不能为空');
    if (n.length > 30) throw HrmApiException('办公地址名称不能超过 30 字');
    if (a.isEmpty) throw HrmApiException('详细地址不能为空');
    if (a.length > 100) throw HrmApiException('详细地址不能超过 100 字');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmOfficeLocationById(locationId)}',
    );
    final body = await _putJson(uri, {
      'name': n,
      'address': a,
      'orderNum': orderNum,
    });
    _ensureOk(body, '修改办公地失败');
  }

  /// 删除办公地：`DELETE /desktop/hrm/office-location/{id}`。
  Future<void> deleteOfficeLocation(String id) async {
    final locationId = id.trim();
    if (locationId.isEmpty) throw HrmApiException('办公地 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmOfficeLocationById(locationId)}',
    );
    final body = await _deleteJson(uri);
    _ensureOk(body, '删除办公地失败');
  }

  /// 能力标签分组：`GET /desktop/hrm/skill-group`。
  Future<List<HrmSkillGroup>> fetchSkillGroups() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.hrmSkillGroup}');
    final body = await _getJson(uri);
    _ensureOk(body, '能力标签加载失败');
    final list = <HrmSkillGroup>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parseSkillGroup(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  /// 紧急联系人：`GET /desktop/hrm/employees/{id}/contacts`。
  Future<List<HrmEmployeeContact>> fetchEmployeeContacts(String id) async {
    return _fetchEmployeeSubList(
      ApiConfig.hrmEmployeeContacts(id),
      '紧急联系人加载失败',
      _parseEmployeeContact,
    );
  }

  /// 教育背景：`GET /desktop/hrm/employees/{id}/educations`。
  Future<List<HrmEmployeeEdu>> fetchEmployeeEducations(String id) async {
    return _fetchEmployeeSubList(
      ApiConfig.hrmEmployeeEducations(id),
      '教育背景加载失败',
      _parseEmployeeEdu,
    );
  }

  /// 工作经历：`GET /desktop/hrm/employees/{id}/work-experiences`。
  Future<List<HrmEmployeeWork>> fetchEmployeeWorkExperiences(String id) async {
    return _fetchEmployeeSubList(
      ApiConfig.hrmEmployeeWorkExperiences(id),
      '工作经历加载失败',
      _parseEmployeeWork,
    );
  }

  /// 合同与协议：`GET /desktop/hrm/employees/{id}/contracts`。
  Future<List<HrmEmployeeContract>> fetchEmployeeContracts(String id) async {
    return _fetchEmployeeSubList(
      ApiConfig.hrmEmployeeContracts(id),
      '合同加载失败',
      _parseEmployeeContract,
    );
  }

  /// 能力标签：`GET /desktop/hrm/employees/{id}/skills`。
  Future<List<HrmEmployeeSkill>> fetchEmployeeSkills(String id) async {
    return _fetchEmployeeSubList(
      ApiConfig.hrmEmployeeSkills(id),
      '员工能力标签加载失败',
      _parseEmployeeSkill,
    );
  }

  /// 覆盖员工能力标签：`PUT /desktop/hrm/employees/{employeeId}/skills`。
  /// Body：`[skillTagId, ...]`（`List<Long>`；空数组表示清空）。
  Future<void> replaceEmployeeSkills({
    required String employeeId,
    required List<int> skillTagIds,
  }) async {
    final id = employeeId.trim();
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.hrmEmployeeSkills(id)}',
    );
    final payload = <int>[
      for (final tagId in skillTagIds)
        if (tagId > 0) tagId,
    ];
    final body = await _putJsonBody(uri, payload);
    _ensureOk(body, '能力标签保存失败');
  }

  /// 附件列表：`GET /desktop/hrm/employees/{employeeId}/files`。
  Future<List<HrmEmployeeFile>> fetchEmployeeFiles(String id) async {
    final employeeId = id.trim();
    if (employeeId.isEmpty) throw HrmApiException('员工 id 不能为空');
    return _fetchEmployeeSubList(
      ApiConfig.hrmEmployeeFiles(employeeId),
      '员工附件加载失败',
      _parseEmployeeFile,
    );
  }

  Future<List<T>> _fetchList<T>(
    String path,
    String fallback,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final body = await _getJson(uri);
    _ensureOk(body, fallback);
    final list = <T>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(parse(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  Future<List<T>> _fetchEmployeeSubList<T>(
    String path,
    String fallback,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final body = await _getJson(uri);
    _ensureOk(body, fallback);
    final list = <T>[];
    final raw = body['data'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(parse(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  void _ensureOk(Map<String, dynamic> body, String fallback) {
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw HrmApiException(body['msg']?.toString() ?? fallback);
    }
  }

  HrmPost _parsePost(Map<String, dynamic> json) {
    return HrmPost()
      ..id = _asString(json['id'])
      ..name = _asString(json['name'])
      ..postSeqLevelIdMax = _asString(json['postSeqLevelIdMax'])
      ..postSeqLevelIdMin = _asString(json['postSeqLevelIdMin'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmPostSeq _parsePostSeq(Map<String, dynamic> json) {
    return HrmPostSeq()
      ..id = _asString(json['id'])
      ..code = _asString(json['code'])
      ..name = _asString(json['name'])
      ..channel = _asString(json['channel'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmPostSeqLevel _parsePostSeqLevel(Map<String, dynamic> json) {
    return HrmPostSeqLevel()
      ..id = _asString(json['id'])
      ..postSeqId = _asString(json['postSeqId'])
      ..code = _asString(json['code'])
      ..salaryMin = _asNum(json['salaryMin'])
      ..salaryMax = _asNum(json['salaryMax'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmPosition _parsePosition(Map<String, dynamic> json) {
    return HrmPosition()
      ..id = _asString(json['id'])
      ..sysDeptId = _asString(json['sysDeptId'])
      ..postId = _asString(json['sysPostId']) ?? _asString(json['postId'])
      ..type = _asString(json['type'])
      ..reportPositionId = _asString(json['reportPositionId'])
      ..dottedPositionId = _asString(json['dottedPositionId'])
      ..deptName = _asString(json['deptName']) ??
          _asString(json['sysDeptName'])
      ..postName = _asString(json['postName']);
  }

  HrmEmployeeAssign _parseAssign(Map<String, dynamic> json) {
    return HrmEmployeeAssign()
      ..id = _asString(json['id'])
      ..employeeUserId = _asInt(json['employeeUserId'])
      ..positionId = _asString(json['positionId'])
      ..postSeqLevelId = _asString(json['postSeqLevelId'])
      ..isPrimary = _asInt(json['isPrimary'])
      ..startType = _asString(json['startType'])
      ..startDate = _asString(json['startDate'])
      ..endDate = _asString(json['endDate'])
      ..endType = _asString(json['endType']);
  }

  HrmEmployeeProfile _parseEmployeeProfile(Map<String, dynamic> json) {
    final titles = <HrmEmployeeTitle>[];
    final rawTitles = json['titleList'];
    if (rawTitles is List) {
      for (final item in rawTitles) {
        if (item is Map) {
          titles.add(_parseTitle(Map<String, dynamic>.from(item)));
        }
      }
    }
    return HrmEmployeeProfile()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['userId'])
      ..no = _asString(json['employeeNo']) ?? _asString(json['no'])
      ..name = _asString(json['name'])
      ..pinYin = _asString(json['pinYin'])
      ..englishName = _asString(json['englishName'])
      ..aliasName = _asString(json['aliasName'])
      ..gender = _asString(json['gender'])
      ..mobile = _asString(json['mobile'])
      ..corpEmail = _asString(json['corpEmail'])
      ..empStatus = _asString(json['empStatus'])
      ..empType = _asString(json['empType'])
      ..conversionStatus = _asString(json['conversionStatus'])
      ..timeType = _asString(json['timeType'])
      ..hireDate = _asString(json['hireDate'])
      ..regularizationDate = _asString(json['regularizationDate'])
      ..leaveDate = _asString(json['leaveDate'])
      ..leaveType = _asString(json['leaveType'])
      ..leaveRemark = _asString(json['leaveRemark'])
      ..birthDate = _asString(json['birthDate'])
      ..nation = _asString(json['nation'])
      ..province = _asString(json['province'])
      ..city = _asString(json['city'])
      ..district = _asString(json['district'])
      ..householdAddress = _asString(json['householdAddress'])
      ..residence = _asString(json['residence'])
      ..politicalStatus = _asString(json['politicalStatus'])
      ..maritalStatus = _asString(json['maritalStatus'])
      ..firstWorkDate = _asString(json['firstWorkDate'])
      ..socialSecurityAccount = _asString(json['socialSecurityAccount'])
      ..housingFundAccount = _asString(json['housingFundAccount'])
      ..idCardType = _asString(json['idCardType'])
      ..idCardNo = _asString(json['idCardNo'])
      ..highestEducation = _asString(json['highestEducation'])
      ..graduateSchool = _asString(json['graduateSchool'])
      ..major = _asString(json['major'])
      ..personalEmail = _asString(json['personalEmail'])
      ..imAccount = _asString(json['imAccount'])
      ..officePhone = _asString(json['officePhone'])
      ..officeExt = _asString(json['officeExt'])
      ..officeLocation = _asString(json['officeLocation'])
      ..officeLocationName = _asString(json['officeLocationName'])
      ..workstation = _asString(json['workstation'])
      ..showMobile = _asInt(json['showMobile'])
      ..showEmail = _asInt(json['showEmail'])
      ..showIm = _asInt(json['showIm'])
      ..showOffice = _asInt(json['showOffice'])
      ..keepInDirectory = _asInt(json['keepInDirectory'])
      ..overtime = _asInt(json['overtime'])
      ..commonLanguage = _asString(json['commonLanguage'])
      ..dispatchCity = _asString(json['dispatchCity'])
      ..businessTrip = _asString(json['businessTrip'])
      ..businessTripCity = _asString(json['businessTripCity'])
      ..contracts = _parseEmployeeContractList(json['contracts'])
      ..titleList = titles;
  }

  List<HrmEmployeeContract> _parseEmployeeContractList(Object? raw) {
    final list = <HrmEmployeeContract>[];
    if (raw is! List) return list;
    for (final item in raw) {
      if (item is Map) {
        list.add(_parseEmployeeContract(Map<String, dynamic>.from(item)));
      }
    }
    list.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return list;
  }

  HrmNation _parseNation(Map<String, dynamic> json) {
    return HrmNation()
      ..id = _asString(json['id'])
      ..name = _asString(json['name'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmOfficeLocation _parseOfficeLocation(Map<String, dynamic> json) {
    return HrmOfficeLocation()
      ..id = _asString(json['id'])
      ..name = _asString(json['name'])
      ..address = _asString(json['address'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmSkillGroup _parseSkillGroup(Map<String, dynamic> json) {
    final tags = <HrmSkillTag>[];
    final rawTags = json['tags'];
    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is Map) {
          tags.add(_parseSkillTag(Map<String, dynamic>.from(item)));
        }
      }
    }
    tags.sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
    return HrmSkillGroup()
      ..id = _asString(json['id'])
      ..name = _asString(json['name'])
      ..orderNum = _asInt(json['orderNum'])
      ..tags = tags;
  }

  HrmSkillTag _parseSkillTag(Map<String, dynamic> json) {
    return HrmSkillTag()
      ..id = _asString(json['id'])
      ..name = _asString(json['name'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmEmployeeContact _parseEmployeeContact(Map<String, dynamic> json) {
    return HrmEmployeeContact()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['employeeUserId']) ?? _asInt(json['userId'])
      ..name = _asString(json['name'])
      ..relation = _asString(json['relation'])
      // Vo：mobile；兼容旧 phone。
      ..phone = _asString(json['mobile']) ?? _asString(json['phone'])
      ..isPrimary = _asString(json['isPrimary'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmEmployeeEdu _parseEmployeeEdu(Map<String, dynamic> json) {
    return HrmEmployeeEdu()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['employeeUserId']) ?? _asInt(json['userId'])
      ..startDate = _asString(json['startDate'])
      ..endDate = _asString(json['endDate'])
      ..school = _asString(json['school'])
      ..major = _asString(json['major'])
      // Vo：education；兼容旧 degree。
      ..degree = _asString(json['education']) ?? _asString(json['degree'])
      ..isHighest = _asInt(json['isHighest']) ??
          (_asString(json['isHighest']) == '1' ? 1 : null);
  }

  HrmEmployeeWork _parseEmployeeWork(Map<String, dynamic> json) {
    return HrmEmployeeWork()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['employeeUserId']) ?? _asInt(json['userId'])
      ..company =
          _asString(json['companyName']) ?? _asString(json['company'])
      ..industry = _asString(json['industry'])
      ..companySize = _asString(json['companySize'])
      ..deptName = _asString(json['deptName'])
      ..position =
          _asString(json['positionName']) ?? _asString(json['position'])
      ..reportTo = _asString(json['reportTo'])
      ..startDate = _asString(json['startDate'])
      ..endDate = _asString(json['endDate'])
      ..duties = _asString(json['duty']) ?? _asString(json['duties'])
      ..leaveReason = _asString(json['leaveReason'])
      ..backgroundCheck = _asString(json['backgroundCheck'])
      ..refereeName = _asString(json['refereeName'])
      ..refereeMobile = _asString(json['refereeMobile'])
      ..nonCompete = _asString(json['nonCompete']);
  }

  HrmEmployeeContract _parseEmployeeContract(Map<String, dynamic> json) {
    return HrmEmployeeContract()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['employeeUserId']) ?? _asInt(json['userId'])
      ..type = _asString(json['type'])
      // Vo：no / partyA / startDate / endDate / signingDate / file
      ..contractNo = _asString(json['no']) ?? _asString(json['contractNo'])
      ..signParty = _asString(json['partyA']) ?? _asString(json['signParty'])
      ..effectiveDate =
          _asString(json['startDate']) ?? _asString(json['effectiveDate'])
      ..expireDate = _asString(json['endDate']) ?? _asString(json['expireDate'])
      ..signDate =
          _asString(json['signingDate']) ?? _asString(json['signDate'])
      ..attachmentUrl = _asString(json['file']) ?? _asString(json['attachmentUrl'])
      ..orderNum = _asInt(json['orderNum']);
  }

  HrmEmployeeSkill _parseEmployeeSkill(Map<String, dynamic> json) {
    return HrmEmployeeSkill()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['userId'])
      ..skillTagId = _asInt(json['skillTagId'])
      ..skillTagName = _asString(json['skillTagName']);
  }

  HrmEmployeeFile _parseEmployeeFile(Map<String, dynamic> json) {
    return HrmEmployeeFile()
      ..id = _asString(json['id'])
      ..userId = _asInt(json['userId'])
      ..url = _fileText(json['url'])
      ..type = _fileText(json['type'])
      ..createTime = _fileText(json['createTime'])
      ..createBy = _asString(json['createBy']);
  }

  static String? _fileText(Object? value) {
    final s = _asString(value);
    if (s == null || s == '##default') return null;
    return s;
  }

  HrmDept _parseDept(Map<String, dynamic> json) {
    return HrmDept()
      ..deptId = _asString(json['deptId'])
      ..parentId = _asString(json['parentId'])
      ..ancestors = _asString(json['ancestors'])
      ..deptName = _asString(json['deptName'])
      ..orderNum = _asInt(json['orderNum'])
      ..status = _asString(json['status'])
      ..headcount = _asInt(json['headcount'])
      ..onDuty = _asInt(json['onDuty']);
  }

  HrmDeptSummary _parseDeptSummary(Map<String, dynamic> json) {
    return HrmDeptSummary()
      ..headcount = _asInt(json['headcount'])
      ..onDuty = _asInt(json['onDuty'])
      ..vacancy = _asInt(json['vacancy'])
      ..manageOnDuty = _asInt(json['manageOnDuty'])
      ..professionalOnDuty = _asInt(json['professionalOnDuty'])
      ..fillRate = _asInt(json['fillRate']);
  }

  HrmEmployee _parseEmployee(Map<String, dynamic> json) {
    final titles = <HrmEmployeeTitle>[];
    final rawTitles = json['titleList'];
    if (rawTitles is List) {
      for (final item in rawTitles) {
        if (item is Map) {
          titles.add(_parseTitle(Map<String, dynamic>.from(item)));
        }
      }
    }
    return HrmEmployee()
      ..userId = _asInt(json['userId'])
      ..no = _asString(json['no'])
      ..name = _asString(json['name'])
      ..englishName = _asString(json['englishName'])
      ..aliasName = _asString(json['aliasName'])
      ..gender = _asString(json['gender'])
      ..empStatus = _asString(json['empStatus'])
      ..mobile = _asString(json['mobile'])
      ..corpEmail = _asString(json['corpEmail'])
      ..imAccount = _asString(json['imAccount'])
      ..titleList = titles;
  }

  HrmEmployeeTitle _parseTitle(Map<String, dynamic> json) {
    return HrmEmployeeTitle()
      ..id = _asString(json['id'])
      ..positionId = _asString(json['positionId'])
      ..reportPositionId = _asString(json['reportPositionId'])
      ..reportEmployeeId = _asInt(json['reportEmployeeId'])
      ..reportEmployeeName = _asString(json['reportEmployeeName'])
      ..sysDeptId = _asString(json['sysDeptId'])
      ..deptName = _asString(json['deptName'])
      ..postId = _asString(json['sysPostId']) ?? _asString(json['postId'])
      ..postName = _asString(json['postName'])
      ..postOrderNum = _asInt(json['postOrderNum'])
      ..postSeqLevelId = _asString(json['postSeqLevelId'])
      ..postSeqLeveName = _asString(json['postSeqLeveName'])
      ..postSeqId = _asString(json['postSeqId'])
      ..postSeqName = _asString(json['postSeqName']) ?? _asString(json['seqName'])
      ..postSeqLeveOrderNum = _asInt(json['postSeqLeveOrderNum'])
      ..isPrimary = _asInt(json['isPrimary'])
      ..startDate = _asString(json['startDate']);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );
      return _decodeResponse(response);
    } on HrmApiException {
      rethrow;
    } on FormatException {
      throw HrmApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is HrmApiException) rethrow;
      throw HrmApiException('网络请求失败：$e');
    }
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    return _sendJson('POST', uri, payload);
  }

  Future<Map<String, dynamic>> _putJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    return _sendJson('PUT', uri, payload);
  }

  /// PUT 任意 JSON（对象或数组）；子资源全量覆盖接口用。
  Future<Map<String, dynamic>> _putJsonBody(Uri uri, Object payload) async {
    return _sendJson('PUT', uri, payload);
  }

  Future<Map<String, dynamic>> _deleteJson(Uri uri) async {
    try {
      final response = await ApiHttp.delete(
        uri,
        headers: AuthSession.headers(),
      );
      return _decodeResponse(response);
    } on HrmApiException {
      rethrow;
    } on FormatException {
      throw HrmApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is HrmApiException) rethrow;
      throw HrmApiException('网络请求失败：$e');
    }
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    Uri uri,
    Object payload,
  ) async {
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(AuthSession.headers(json: true))
        ..body = jsonEncode(payload);
      final response = await ApiHttp.send(request);
      return _decodeResponse(response);
    } on HrmApiException {
      rethrow;
    } on FormatException {
      throw HrmApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is HrmApiException) rethrow;
      throw HrmApiException('网络请求失败：$e');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw HrmApiException('服务器返回为空');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw HrmApiException('服务器返回数据格式错误');
    }
    if (response.statusCode == 401) {
      throw HrmApiException(
        decoded['msg']?.toString() ?? '未登录或登录已过期',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HrmApiException(
        decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
      );
    }
    return decoded;
  }
}

String? _asString(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? _asNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
