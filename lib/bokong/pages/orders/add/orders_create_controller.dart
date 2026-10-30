import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_create_entity.dart';
import 'package:yidivination/bokong/utils/ext.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 创建订单：一组播放内容（对应接口 items[]）。
class OrdersCreateGroup {
  int? mediaId;
  String? mediaTitle;
  AdMediaEntity? media;

  /// 付费类型：1 付费，0 免费
  int orderPay = 1;

  /// 播放规则：1 循环播放，2 定屏播放
  int playRule = 1;

  /// 播放模式：1 正常播放，2 弹性播放
  int playModel = 1;

  /// 定屏开始 / 结束（play_rule=2 时提交 cover_start_time / cover_end_time）
  DateTime? coverStartTime;
  DateTime? coverEndTime;

  /// 合同时间 → start_time / end_time
  shad.DateTimeRange? contractRange = shad.DateTimeRange(
    DateTime.now(),
    DateTime.now(),
  );

  /// 开始时间 → send_time / send_end_time
  shad.DateTimeRange? sendRange = shad.DateTimeRange(
    DateTime.now(),
    DateTime.now(),
  );

  int duration = 15;
  int orderFrequency = 120;
  int giveFrequency = 0;

  final Set<int> industryIds = {};
  int exclusiveRule = 0;
  int loopRule = 0;

  /// 绑定终端 ID（接口 terminal_ids 逗号分隔）
  final List<int> terminalIds = [];
  final Map<int, String> terminalLabels = {};
}

/// 创建订单弹窗状态与提交。
class OrdersCreateController extends LxController {
  final customerId = Rxn<int>();
  final groups = <OrdersCreateGroup>[OrdersCreateGroup()].obs;
  final industryItems = <AdContentGroupEntity>[].obs;
  final customerSelectKey = 0.obs;

  void notifyGroups() => groups.refresh();

  void addGroup() {
    groups.add(OrdersCreateGroup());
  }

  void removeGroup(int index) {
    if (groups.length <= 1) return;
    groups.removeAt(index);
  }

  Future<void> loadIndustryItems() async {
    final resp = await LcdApi.contentGroupList(page: 1, size: 500);
    industryItems
      ..clear()
      ..addAll(resp.data ?? []);
  }

  void bumpCustomerSelect() => customerSelectKey.value++;

  void setCustomerId(int? id) {
    customerId.value = id;
  }

  void setMaterial(int index, AdMediaEntity media) {
    final group = groups[index];
    group.mediaId = media.id;
    group.mediaTitle = media.title ?? media.media_no;
    group.media = media;
    final duration = media.duration;
    if (duration != null && duration > 0) {
      group.duration = duration;
    }
    notifyGroups();
  }

  void clearMaterial(int index) {
    final group = groups[index];
    group.mediaId = null;
    group.mediaTitle = null;
    group.media = null;
    notifyGroups();
  }

  void setTerminals(int index, Map<int, String> selected) {
    final group = groups[index];
    group.terminalIds
      ..clear()
      ..addAll(selected.keys);
    group.terminalLabels
      ..clear()
      ..addAll(selected);
    notifyGroups();
  }

  String _dateText(DateTime? value) {
    if (value == null) return '';
    return value.millisecondsSinceEpoch.date2('yyyy-MM-dd');
  }

  String _dateTimeText(DateTime? value) {
    if (value == null) return '';
    return value.millisecondsSinceEpoch.date2('yyyy-MM-dd HH:mm:ss');
  }

  void _ensureFixedScreenTimes(OrdersCreateGroup group) {
    if (group.playRule != 2) return;
    final now = DateTime.now();
    group.coverStartTime ??= DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    group.coverEndTime ??= group.coverStartTime!.add(const Duration(hours: 1));
  }

  OrderCreateEntity? buildParam() {
    final id = customerId.value;
    if (id == null) {
      showWarn('请选择客户');
      return null;
    }

    final items = <OrderCreateItemEntity>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.mediaId == null) {
        showWarn('第${i + 1}组请选择素材');
        return null;
      }
      if (group.contractRange == null) {
        showWarn('第${i + 1}组请选择合同时间');
        return null;
      }
      if (group.sendRange == null) {
        showWarn('第${i + 1}组请选择开始时间');
        return null;
      }
      if (group.terminalIds.isEmpty) {
        showWarn('第${i + 1}组请选择绑定终端');
        return null;
      }
      if (group.playRule == 2) {
        if (group.coverStartTime == null) {
          showWarn('第${i + 1}组请选择定屏开始时间');
          return null;
        }
        if (group.coverEndTime == null) {
          showWarn('第${i + 1}组请选择定屏结束时间');
          return null;
        }
        if (!group.coverEndTime!.isAfter(group.coverStartTime!)) {
          showWarn('第${i + 1}组定屏结束时间须晚于开始时间');
          return null;
        }
      }

      final isFixedScreen = group.playRule == 2;
      items.add(
        OrderCreateItemEntity()
          ..media_id = group.mediaId
          ..media_title = group.mediaTitle
          ..start_time = _dateText(group.contractRange!.start)
          ..end_time = _dateText(group.contractRange!.end)
          ..send_time = _dateText(group.sendRange!.start)
          ..send_end_time = _dateText(group.sendRange!.end)
          ..duration = group.duration
          ..order_frequency = group.orderFrequency
          ..give_frequency = group.giveFrequency
          ..exclusive_industry = group.industryIds.toList()
          ..exclusive_rule = group.exclusiveRule
          ..loop_rule = group.loopRule
          ..order_pay = group.orderPay
          ..play_rule = group.playRule
          ..play_model = group.playModel
          ..cover_start_time = isFixedScreen
              ? _dateTimeText(group.coverStartTime)
              : ''
          ..cover_end_time = isFixedScreen
              ? _dateTimeText(group.coverEndTime)
              : ''
          ..terminal_ids = group.terminalIds.join(','),
      );
    }

    return OrderCreateEntity()
      ..customer_id = id
      ..items = items;
  }

  void setPlayRule(int index, int value) {
    final group = groups[index];
    group.playRule = value;
    _ensureFixedScreenTimes(group);
    notifyGroups();
  }

  /// 校验并提交；失败返回 `false`（弹窗应保持打开）。
  Future<bool> submit() async {
    final param = buildParam();
    if (param == null) return false;
    final resp = await LcdApi.customerOrderCreate(param: param);
    if (!resp.isSuccess()) throw resp;
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '创建订单成功');
    return true;
  }

  void onApiError(Object e) {
    if (e is AppRespEntity) {
      showError(e.msg);
    } else {
      showError('$e');
    }
  }
}
