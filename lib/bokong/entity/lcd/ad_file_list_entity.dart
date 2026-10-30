import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 设备管理侧边栏文件信息
@jsonSerializable
class AdFileListEntity {
  /// 文件信息标题
  String? file_info;

  /// 侧栏头像图标（http URL 或模版 JSON）
  String? avatar_icon;

  /// 设备 / 订单基础统计（物业与客户共用，字段按 type 不同）
  AdFileListDeviceBasicEntity? device_basic_data;

  /// 上刊率 TOP3（物业 type=1）
  List<AdFileListRateTopEntity>? advertising_rate_top3;

  /// 客户订单排名 TOP3（客户 type=2）
  List<AdFileListCustomerOrderRankEntity>? customer_order_ranking_top3;

  /// 行业排名 TOP3（客户 type=2）
  List<AdFileListIndustryRankEntity>? industry_ranking_top3;

  /// 标签（物业；接口可能为字符串列表或对象列表）
  List? tags;

  /// 标签（客户 type=2）
  List? add_tag;

  /// 设备占比图（物业 type=1）
  AdFileListChartEntity? chart;

  /// 下方统计卡片（物业 type=1）
  List<AdFileListCardEntity>? cards;

  /// 订单分布（客户 type=2）
  AdFileListOrderDistributionEntity? order_distribution;
}

/// 设备基础统计（物业 / 客户共用字段；按 type 只填一部分）
@jsonSerializable
class AdFileListDeviceBasicEntity {
  /// 设备总量（物业 type=1）
  int? total_devices;

  /// 98 寸数量（物业 type=1）
  int? count_98inch;

  /// 86 寸数量（物业 type=1）
  int? count_86inch;

  /// 在线设备（物业 type=1）
  int? online_devices;

  /// 离线设备（物业 type=1）
  int? offline_devices;

  /// 异常设备（物业 type=1）
  int? abnormal_devices;

  /// 运营天数（物业 type=1）
  int? operation_days;

  /// 订单总量（客户 type=2）
  int? total_orders;

  /// 播放中订单数（客户 type=2）
  int? play_orders;

  /// 已完结订单数（客户 type=2）
  int? end_orders;
}

/// 上刊率排行项
@jsonSerializable
class AdFileListRateTopEntity {
  /// 排名
  int? rank;

  /// 媒体位置
  String? media_location;

  /// 百分率
  String? rate;
}

/// 客户订单排名项
@jsonSerializable
class AdFileListCustomerOrderRankEntity {
  /// 排名
  int? rank;

  /// 客户名称
  String? customer_name;

  /// 订单数
  int? order_count;
}

/// 行业排名项
@jsonSerializable
class AdFileListIndustryRankEntity {
  /// 排名
  int? rank;

  /// 行业名称
  String? industry_name;

  /// 订单数
  int? order_count;
}

/// 客户订单分布
@jsonSerializable
class AdFileListOrderDistributionEntity {
  /// 占比图
  AdFileListChartEntity? chart;

  /// 统计卡片
  List<AdFileListCardEntity>? cards;
}

/// 侧边栏标签
@jsonSerializable
class AdFileListTagEntity {
  /// 标签名
  String? name;

  /// 展示文案
  String? label;

  /// 颜色（如 #F97316）
  String? color;
}

/// 添加标签接口返回
@jsonSerializable
class AdFileAddTagsEntity {
  /// 标签列表
  List? tags;

  /// 备注 / 本次标签文案
  String? remark;
}

/// 将 file_list.tags / add_tag 规范为可展示标签（兼容字符串 / Map / 实体）。
List<AdFileListTagEntity> parseAdFileListTags(List? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final out = <AdFileListTagEntity>[];
  for (final item in raw) {
    if (item == null) continue;
    if (item is AdFileListTagEntity) {
      out.add(item);
      continue;
    }
    if (item is String) {
      final text = item.trim();
      if (text.isNotEmpty) {
        out.add(AdFileListTagEntity()..name = text);
      }
      continue;
    }
    if (item is Map) {
      final map = <String, dynamic>{
        for (final e in item.entries) '${e.key}': e.value,
      };
      out.add(
        AdFileListTagEntity()
          ..name = map['name']?.toString()
          ..label = map['label']?.toString()
          ..color = map['color']?.toString(),
      );
    }
  }
  return out;
}

/// 设备占比图
@jsonSerializable
class AdFileListChartEntity {
  /// 图类型
  String? type;

  /// 中心文案与数值
  AdFileListChartCenterEntity? center;

  /// 扇区
  List<AdFileListChartSegmentEntity>? segments;

  /// 总量
  int? total;
}

/// 占比图中心
@jsonSerializable
class AdFileListChartCenterEntity {
  /// 中心标签
  String? label;

  /// 中心数值
  int? value;
}

/// 占比图扇区
@jsonSerializable
class AdFileListChartSegmentEntity {
  int? id;

  /// 扇区名称
  String? name;

  /// 数量
  int? value;

  /// 占比（0–100）
  double? percentage;

  /// 占比文案
  String? percentage_label;
}

/// 侧边栏统计卡
@jsonSerializable
class AdFileListCardEntity {
  int? id;

  /// 标题
  String? title;

  /// 数值
  int? value;

  /// 格式化数值
  String? formatted_value;

  /// 底部附加信息
  AdFileListCardExtraEntity? extra;
}

/// 统计卡底部附加（value 可能为百分比字符串或数字）
@jsonSerializable
class AdFileListCardExtraEntity {
  /// 标签（如「占比」「较昨日」）
  String? label;

  dynamic value;

  /// 涨跌方向（up / down）
  String? direction;

  /// 涨跌展示文案
  String? display;
}
