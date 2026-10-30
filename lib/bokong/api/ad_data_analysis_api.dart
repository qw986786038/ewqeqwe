import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_comprehensive_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_comprehensive_order_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_district_rank_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_play_trends_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_property_rank_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_rank_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_trends_order_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_up_rate_rank_entity.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_up_rate_daily_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_up_rate_list_entity.dart';

import 'common_api.dart';

class AdDataAnalysisApi {
  AdDataAnalysisApi._();

  static Map<String, dynamic> _rankParams({
    required int type,
    String? cityIds,
    String? districtIds,
    String? mediaAddress,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    final params = <String, dynamic>{'type': type};
    if (cityIds != null && cityIds.isNotEmpty) {
      params['city_ids'] = cityIds;
    }
    if (districtIds != null && districtIds.isNotEmpty) {
      params['district_ids'] = districtIds;
    }
    if (mediaAddress != null && mediaAddress.isNotEmpty) {
      params['media_address'] = mediaAddress;
    }
    if (status != null) {
      params['status'] = status;
    }
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (moudle != null && moudle.isNotEmpty) {
      params['moudle'] = moudle;
    }
    return params;
  }

  /// 数据分析（设备管理 / 客户订单）KPI 指标卡
  ///
  /// [type] 1：设备管理，2：客户订单（默认 1）
  /// [cityIds] 城市 code 集合，如 `1,2,3`
  /// [districtIds] 区域 code 集合，如 `1,2,3`
  /// [mediaAddress] 媒体位置
  /// [status] type=1：默认 0 全部，1 在线，2 离线；type=2：1 执行中，2 已暂停，3 已完播
  /// [startDate] / [endDate] 起止日期
  static Future<AppRespEntity<AdDataAnalysisEntity>> dataAnalysis({
    int type = 1,
    String? cityIds,
    String? districtIds,
    String? mediaAddress,
    int? status,
    String? startDate,
    String? endDate,
  }) {
    final params = <String, dynamic>{'type': type};
    if (cityIds != null && cityIds.isNotEmpty) {
      params['city_ids'] = cityIds;
    }
    if (districtIds != null && districtIds.isNotEmpty) {
      params['district_ids'] = districtIds;
    }
    if (mediaAddress != null && mediaAddress.isNotEmpty) {
      params['media_address'] = mediaAddress;
    }
    if (status != null) {
      params['status'] = status;
    }
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }
    return CommonApi.get<AdDataAnalysisEntity>(
      '/api/system/ad/v2/data_analysis/',
      params: params,
    );
  }

  /// 数据分析行政区域排行（设备）
  static Future<AppRespEntity<AdDataAnalysisDistrictRankEntity>>
  dataAnalysisDistrictRank({
    int type = 1,
    String? cityIds,
    String? districtIds,
    String? mediaAddress,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisDistrictRankEntity>(
      '/api/system/ad/v2/data_analysis_district_rank/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        mediaAddress: mediaAddress,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析行政区设备订单排行（客户订单）
  static Future<AppRespEntity<AdDataAnalysisDistrictRankEntity>>
  dataAnalysisDistrictOrder({
    int type = 2,
    String? cityIds,
    String? districtIds,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisDistrictRankEntity>(
      '/api/system/ad/v2/data_analysis_district_order/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析物业公司关联设备数量排行
  static Future<AppRespEntity<AdDataAnalysisPropertyRankEntity>>
  dataAnalysisPropertyRank({
    int type = 1,
    String? cityIds,
    String? districtIds,
    String? mediaAddress,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisPropertyRankEntity>(
      '/api/system/ad/v2/data_analysis_property_rank/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        mediaAddress: mediaAddress,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析客户订单排行
  static Future<AppRespEntity<AdDataAnalysisDistrictRankEntity>>
  dataAnalysisCustomerOrder({
    int type = 2,
    String? cityIds,
    String? districtIds,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisDistrictRankEntity>(
      '/api/system/ad/v2/data_analysis_customer_order/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析所属行业订单排行
  static Future<AppRespEntity<AdDataAnalysisDistrictRankEntity>>
  dataAnalysisCategoryOrder({
    int type = 2,
    String? cityIds,
    String? districtIds,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisDistrictRankEntity>(
      '/api/system/ad/v2/data_analysis_category_order/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析写字楼订单排行
  static Future<AppRespEntity<AdDataAnalysisDistrictRankEntity>>
  dataAnalysisOfficeOrder({
    int type = 2,
    String? cityIds,
    String? districtIds,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisDistrictRankEntity>(
      '/api/system/ad/v2/data_analysis_office_order/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析上刊率排行
  static Future<AppRespEntity<AdDataAnalysisUpRateRankEntity>>
  dataAnalysisUpRateDailyRank({
    int type = 1,
    String? cityIds,
    String? districtIds,
    String? mediaAddress,
    int? status,
    String? startDate,
    String? endDate,
    int? limit,
    String? moudle,
  }) {
    return CommonApi.get<AdDataAnalysisUpRateRankEntity>(
      '/api/system/ad/v2/data_analysis_up_rate_daily_rank/',
      params: _rankParams(
        type: type,
        cityIds: cityIds,
        districtIds: districtIds,
        mediaAddress: mediaAddress,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        moudle: moudle,
      ),
    );
  }

  /// 数据分析播放趋势面积图
  static Future<AppRespEntity<AdDataAnalysisPlayTrendsEntity>>
  dataAnalysisPlayTrends({String? startDate, String? endDate}) {
    final params = <String, dynamic>{};
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }
    return CommonApi.get<AdDataAnalysisPlayTrendsEntity>(
      '/api/system/ad/v2/data_analysis_play_trends/',
      params: params.isEmpty ? null : params,
    );
  }

  /// 数据分析设备维度综合数据（情况 / 效率 / 分布环图）
  static Future<AppRespEntity<AdDataAnalysisComprehensiveEntity>>
  dataAnalysisComprehensive() {
    return CommonApi.get<AdDataAnalysisComprehensiveEntity>(
      '/api/system/ad/v2/data_analysis_comprehensive/',
    );
  }

  /// 数据分析客户订单维度订单状态
  static Future<AppRespEntity<AdDataAnalysisComprehensiveOrderEntity>>
  dataAnalysisComprehensiveOrder() {
    return CommonApi.get<AdDataAnalysisComprehensiveOrderEntity>(
      '/api/system/ad/v2/data_analysis_comprehensive_order/',
    );
  }

  /// 数据分析客户订单经营趋势
  ///
  /// [type] 1：订单数，2：客户数，3：播放次数
  /// [startDate] / [endDate] 起止日期
  static Future<AppRespEntity<AdDataAnalysisTrendsOrderEntity>>
  dataAnalysisTrendsOrder({
    required int type,
    String? startDate,
    String? endDate,
  }) {
    final params = <String, dynamic>{'type': type};
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }
    return CommonApi.get<AdDataAnalysisTrendsOrderEntity>(
      '/api/system/ad/v2/data_analysis_trends_order/',
      params: params,
    );
  }

  /// 数据分析下半部分（排行 / 趋势）
  static Future<AppRespEntity<AdDataAnalysisRankEntity>> dataAnalysisRank({
    int type = 1,
    String? startDate,
    String? endDate,
    int? limit,
    int? page,
    int? publicationRatePage,
    int? publicationRateTop,
    int? propertyCompanyDevicePage,
    int? propertyCompanyDeviceTop,
    int? customerOrderPage,
    int? customerOrderTop,
    int? industryOrderPage,
    int? industryOrderTop,
    int? propertyOrderPage,
    int? propertyOrderTop,
    int? cityIds,
    int? districtIds,
    int? isVolume,
  }) {
    final params = <String, dynamic>{'type': type};
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }
    if (limit != null) {
      params['limit'] = limit;
    }
    if (page != null) {
      params['page'] = page;
    }
    if (publicationRatePage != null) {
      params['publication_rate_page'] = publicationRatePage;
    }
    if (publicationRateTop != null) {
      params['publication_rate_top'] = publicationRateTop;
    }
    if (propertyCompanyDevicePage != null) {
      params['property_company_device_page'] = propertyCompanyDevicePage;
    }
    if (propertyCompanyDeviceTop != null) {
      params['property_company_device_top'] = propertyCompanyDeviceTop;
    }
    if (customerOrderPage != null) {
      params['customer_order_page'] = customerOrderPage;
    }
    if (customerOrderTop != null) {
      params['customer_order_top'] = customerOrderTop;
    }
    if (industryOrderPage != null) {
      params['industry_order_page'] = industryOrderPage;
    }
    if (industryOrderTop != null) {
      params['industry_order_top'] = industryOrderTop;
    }
    if (propertyOrderPage != null) {
      params['property_order_page'] = propertyOrderPage;
    }
    if (propertyOrderTop != null) {
      params['property_order_top'] = propertyOrderTop;
    }
    if (cityIds != null) {
      params['city_ids'] = cityIds;
    }
    if (districtIds != null) {
      params['district_ids'] = districtIds;
    }
    if (isVolume != null) {
      params['is_volume'] = isVolume;
    }
    return CommonApi.get<AdDataAnalysisRankEntity>(
      '/api/system/ad/v2/data_analysis_rank/',
      params: params,
    );
  }

  /// 终端单日上刊率
  static Future<AppRespEntity<LcdTerminalUpRateDailyEntity>>
  terminalUpRateDaily({required int terminalId, String? date}) {
    final params = <String, dynamic>{'terminal_id': terminalId};
    if (date != null && date.isNotEmpty) {
      params['date'] = date;
    }
    return CommonApi.get<LcdTerminalUpRateDailyEntity>(
      '/api/system/ad/v2/terminal_up_rate_daily/',
      params: params,
    );
  }

  /// 终端上刊率区间对比 / 趋势
  static Future<AppRespEntity<LcdTerminalUpRateListEntity>> terminalUpRateList({
    required int terminalId,
    String? startDate,
    String? endDate,
  }) {
    final params = <String, dynamic>{'terminal_id': terminalId};
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }
    return CommonApi.get<LcdTerminalUpRateListEntity>(
      '/api/system/ad/v2/terminal_up_rate_list/',
      params: params,
    );
  }
}
