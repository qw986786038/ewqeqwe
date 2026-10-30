import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/ad_file_list_entity.dart';
import 'package:yidivination/bokong/entity/lcd/ad_office_building_file_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_filter_options_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_scene_pic_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_maintain_log_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_operation_log_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_play_log_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_play_preview_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_stats_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_create_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_order_file_entity.dart';
import 'package:yidivination/bokong/api/ad_media_api.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_publish_device_entity.dart';
import 'package:yidivination/bokong/entity/order/order_create_entity.dart';
import 'package:yidivination/bokong/entity/order/order_customer_entity.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_create_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_feedback_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_group_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_vas_entity.dart';
import 'package:yidivination/bokong/utils/ext.dart';

import 'common_api.dart';

class LcdApi {
  LcdApi._();

  /// LCD 终端设备状态统计
  static Future<AppRespEntity<LcdTerminalStatsEntity>> terminalListStats() {
    return CommonApi.get<LcdTerminalStatsEntity>(
      '/api/system/ad/terminal/list_stats/',
      params: {'device_tab': 'lcd'},
    );
  }

  /// 设备管理侧边栏文件信息（type: 1 物业 / 2 客户）
  static Future<AppRespEntity<AdFileListEntity>> fileList({
    required int type,
    int? propertyId,
    int? customerId,
    String deviceTab = 'LCD',
  }) {
    final params = <String, dynamic>{'type': type, 'device_tab': deviceTab};
    if (propertyId != null) params['property_id'] = propertyId;
    if (customerId != null) params['customer_id'] = customerId;
    return CommonApi.get<AdFileListEntity>(
      '/api/system/ad/file_list/',
      params: params,
    );
  }

  /// 根据写字楼查询文件详情
  static Future<AppRespEntity<AdOfficeBuildingFileEntity>> officeBuildingFile({
    required int officeId,
  }) {
    return CommonApi.get<AdOfficeBuildingFileEntity>(
      '/api/system/ad/file/office_building/',
      params: {'office_id': officeId},
    );
  }

  /// 获取客户订单文件详情（ShowDoc 1585；订单二级侧边栏）
  static Future<AppRespEntity<AdCustomerOrderFileEntity>> customerOrderFile({
    required String orderNo,
  }) {
    return CommonApi.get<AdCustomerOrderFileEntity>(
      '/api/system/ad/file/customer_order/',
      params: {'order_no': orderNo},
    );
  }

  /// 添加标签（type: 1 物业 / 2 客户 / 3 写字楼 / 4 主订单）
  static Future<AppRespEntity<AdFileAddTagsEntity>> addTags({
    required int type,
    required String tags,
    int? propertyId,
    int? customerId,
    int? officeId,
    String? orderNo,
  }) {
    final params = <String, dynamic>{'type': type, 'tags': tags};
    if (propertyId != null) params['property_id'] = propertyId;
    if (customerId != null) params['customer_id'] = customerId;
    if (officeId != null) params['office_id'] = officeId;
    final no = orderNo?.trim();
    if (no != null && no.isNotEmpty) params['order_no'] = no;
    return CommonApi.post<AdFileAddTagsEntity>(
      '/api/system/ad/file/add_tags/',
      params: params,
    );
  }

  /// 删除标签（type: 1 物业 / 2 客户 / 3 写字楼 / 4 主订单）
  static Future<AppRespEntity<AdFileAddTagsEntity>> delTags({
    required int type,
    required String tags,
    int? propertyId,
    int? customerId,
    int? officeId,
    String? orderNo,
  }) {
    final params = <String, dynamic>{'type': type, 'tags': tags};
    if (propertyId != null) params['property_id'] = propertyId;
    if (customerId != null) params['customer_id'] = customerId;
    if (officeId != null) params['office_id'] = officeId;
    final no = orderNo?.trim();
    if (no != null && no.isNotEmpty) params['order_no'] = no;
    return CommonApi.post<AdFileAddTagsEntity>(
      '/api/system/ad/file/del_tags/',
      params: params,
    );
  }

  /// 客户 / 写字楼 / 设备 / 主订单侧栏图标（ShowDoc 1514）。
  ///
  /// [type]：1 客户 / 2 写字楼 / 3 设备 / 4 主订单。
  /// [avatarIcon]：上传图为 http(s) URL；模版为 JSON
  /// `{"name":"...","color":"#RRGGBB","bg":"#RRGGBB"}`。
  static Future<AppRespEntity<dynamic>> updateFileIcon({
    required int type,
    required int updateId,
    required String avatarIcon,
    String? title,
  }) {
    return CommonApi.post<dynamic>(
      '/api/system/ad/file/update_icon/',
      params: {
        'type': type,
        'update_id': updateId,
        'avatar_icon': avatarIcon,
        'title': ?title,
      },
    );
  }

  /// LCD 终端设备列表
  static Future<AppRespEntity<List<LcdDeviceEntity>>> terminalList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    params['device_tab'] = 'lcd';
    return CommonApi.get<List<LcdDeviceEntity>>(
      '/api/system/ad/terminal/',
      params: params,
    );
  }

  /// LCD 设备管理筛选选项
  static Future<AppRespEntity<LcdFilterOptionsEntity>>
  terminalLcdFilterOptions() {
    return CommonApi.get<LcdFilterOptionsEntity>(
      '/api/system/ad/terminal/lcd_filter_options/',
      params: {'device_tab': 'lcd'},
    );
  }

  /// 预览设备正在播放内容（ShowDoc 1515）
  static Future<AppRespEntity<LcdTerminalPlayPreviewEntity>>
  terminalPlayPreview({required String deviceNo}) {
    return CommonApi.get<LcdTerminalPlayPreviewEntity>(
      '/api/system/ad/terminal/play_preview/',
      params: {'device_no': deviceNo},
    );
  }

  /// 添加 LCD 终端设备
  static Future<AppRespEntity<LcdDeviceEntity>> terminalCreate({
    required LcdTerminalCreateEntity param,
  }) {
    return CommonApi.post<LcdDeviceEntity>(
      '/api/system/ad/terminal/?device_tab=lcd',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 修改 LCD 终端设备
  static Future<AppRespEntity<LcdDeviceEntity>> terminalUpdate({
    required int id,
    required LcdTerminalCreateEntity param,
  }) {
    return CommonApi.put<LcdDeviceEntity>(
      '/api/system/ad/terminal/$id/?device_tab=lcd',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// LCD 终端设备详情
  static Future<AppRespEntity<LcdDeviceEntity>> terminalDetail({
    required int id,
  }) {
    return CommonApi.get<LcdDeviceEntity>(
      '/api/system/ad/terminal/$id/',
      params: {'device_tab': 'lcd'},
    );
  }

  /// LCD 终端现场照片列表
  static Future<AppRespEntity<List<LcdDeviceScenePicEntity>>>
  terminalScenePicList({required int id}) {
    return CommonApi.get<List<LcdDeviceScenePicEntity>>(
      '/api/system/ad/terminal/$id/scene_pic_list/',
      params: {'device_tab': 'lcd'},
    );
  }

  /// 删除 LCD 终端现场照片
  static Future<AppRespEntity<String>> terminalDeleteScenePic({
    required int id,
    required String path,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/terminal/$id/delete_scene_pic/?device_tab=lcd',
      params: <String, dynamic>{'path': path},
    );
  }

  /// LCD 节目排期设备列表
  static Future<AppRespEntity<List<LcdProgramDeviceEntity>>> programDeviceList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<LcdProgramDeviceEntity>>(
      '/api/system/ad/new_schedule/',
      params: params,
    );
  }

  /// 重新生成节目单（async 为 true 时异步执行）
  static Future<AppRespEntity<String>> programScheduleNewGenerate({
    bool async = true,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/new_schedule/new_generate/',
      params: {'async': async},
    );
  }

  /// LCD 节目排期素材列表（设备详情「播放排期」Tab，需传 schedule_id）。
  ///
  /// [date] 非必传，格式 `yyyy-MM-dd`，不传时后端默认当天。
  /// [terminalId] 非必传，设备 ID。
  static Future<AppRespEntity<List<LcdProgramMaterialEntity>>>
  programMaterialList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
    String? date,
    int? terminalId,
  }) {
    final params = param.page(page: page, size: 200);
    _putProgramDateAndTerminal(params, date: date, terminalId: terminalId);
    return CommonApi.get<List<LcdProgramMaterialEntity>>(
      '/api/system/ad/new_program/',
      params: params,
    );
  }

  /// LCD 节目单预览（设备详情「节目单预览」Tab）。
  ///
  /// [scheduleId] 有排期时传入。[date] 非必传，格式 `yyyy-MM-dd`，不传时后端默认当天。
  /// [terminalId] 非必传，设备 ID。
  static Future<AppRespEntity<List<LcdProgramMaterialEntity>>>
  programPreviewSheet({int? scheduleId, String? date, int? terminalId}) {
    final params = <String, dynamic>{};
    if (scheduleId != null) params['schedule_id'] = scheduleId;
    _putProgramDateAndTerminal(params, date: date, terminalId: terminalId);
    return CommonApi.get<List<LcdProgramMaterialEntity>>(
      '/api/system/ad/new_program/preview_sheet/',
      params: params,
    );
  }

  static void _putProgramDateAndTerminal(
    Map<String, dynamic> params, {
    String? date,
    int? terminalId,
  }) {
    final trimmedDate = date?.trim();
    if (trimmedDate != null && trimmedDate.isNotEmpty) {
      params['date'] = trimmedDate;
    }
    if (terminalId != null) {
      params['terminal_id'] = terminalId;
    }
  }

  /// 节目单导出（需传 schedule_id；data 为 xlsx 下载地址）
  static Future<AppRespEntity<String>> programExportSheet({
    required int scheduleId,
    int limit = 999,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/new_program/export_sheet/',
      params: {'schedule_id': scheduleId, 'limit': limit},
    );
  }

  /// 节目素材排序（schedule_id 为排期 id，ids 为排序后的素材 id 列表）
  static Future<AppRespEntity<String>> programMaterialReorder({
    required int scheduleId,
    required List<int> ids,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/new_program/reorder/',
      params: {'schedule_id': scheduleId, 'ids': ids},
    );
  }

  /// 节目排期执行（action 如 start 启动执行）
  static Future<AppRespEntity<String>> programScheduleExecute({
    required int scheduleId,
    required String action,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/new_program/schedule_execute/',
      params: {'schedule_id': scheduleId, 'action': action},
    );
  }

  /// 节目素材上下刊（id 为素材 id；onShelf true 上刊，false 下刊）
  static Future<AppRespEntity<String>> programMaterialShelf({
    required int id,
    required bool onShelf,
  }) {
    final action = onShelf ? 'on_shelf' : 'off_shelf';
    return CommonApi.post<String>(
      '/api/system/ad/new_program/$id/$action/',
      params: const <String, dynamic>{},
    );
  }

  /// 节目素材暂停 / 启动（id 为素材 id；start true 启动，false 暂停）
  static Future<AppRespEntity<String>> programMaterialPlay({
    required int id,
    required bool start,
  }) {
    final action = start ? 'start' : 'pause';
    return CommonApi.post<String>(
      '/api/system/ad/new_program/$id/$action/',
      params: const <String, dynamic>{},
    );
  }

  /// 更新节目素材排他规则（id 为素材 id）
  static Future<AppRespEntity<String>> programMaterialUpdateRule({
    required int id,
    List<int>? exclusiveIndustry,
    int? exclusiveRule,
    int? loopRule,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (exclusiveIndustry != null)
      params['exclusive_industry'] = exclusiveIndustry;
    if (exclusiveRule != null) params['exclusive_rule'] = exclusiveRule;
    if (loopRule != null) params['loop_rule'] = loopRule;
    return CommonApi.post<String>(
      '/api/system/ad/new_program/$id/update_rule/',
      params: params,
    );
  }

  /// 创建节目（需传 schedule_id、customer_id 与 items 等）
  static Future<AppRespEntity<String>> programCreateForSchedule({
    required LcdProgramCreateEntity param,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/new_program/create_for_schedule/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 订单客户列表
  ///
  /// [param] 可选筛选，如 `kw`；`status`：`-1` 全部（默认），`1` 执行中，`2` 已完播，`3` 已暂停。
  static Future<AppRespEntity<List<OrderCustomerEntity>>> customerList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<OrderCustomerEntity>>(
      '/api/system/ad/customer_list/',
      params: params,
    );
  }

  /// 客户订单列表
  /// 客户订单列表
  ///
  /// [param] 含 `customer_id`；可选 `status`：`-1` 全部（默认），`1` 执行中，`2` 已完播，`3` 已暂停。
  static Future<AppRespEntity<List<OrderEntity>>> customerOrderList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<OrderEntity>>(
      '/api/system/ad/customer_order_list/',
      params: params,
    );
  }

  /// 添加客户订单
  static Future<AppRespEntity<OrderEntity>> customerOrderCreate({
    required OrderCreateEntity param,
  }) {
    return CommonApi.post<OrderEntity>(
      '/api/customer_order/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 编辑客户订单
  static Future<AppRespEntity<OrderEntity>> customerOrderUpdate({
    required int id,
    required OrderCreateEntity param,
  }) {
    return CommonApi.put<OrderEntity>(
      '/api/customer_order/$id/update_order/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 修改订单素材（路径参数为订单明细 id；body 仅传需修改字段）
  static Future<AppRespEntity<OrderEntity>> customerOrderEditDetail({
    required int orderDetailId,
    required Map<String, dynamic> params,
  }) {
    print(json.encode(params));

    return CommonApi.post<OrderEntity>(
      '/api/customer_order/$orderDetailId/edit_order_detail/',
      params: params,
    );
  }

  /// 新增发布单（路径参数为订单 id；body 仅传 items，不含 customer_id）
  static Future<AppRespEntity<OrderEntity>> customerOrderAddDetail({
    required int orderId,
    required Map<String, dynamic> params,
  }) {
    return CommonApi.post<OrderEntity>(
      '/api/customer_order/$orderId/create_order/',
      params: params,
    );
  }

  /// 软删除订单素材（路径参数 id 为订单明细 id）
  static Future<AppRespEntity<String>> customerOrderSoftDelete({
    required int id,
  }) {
    return CommonApi.post<String>('/api/customer_order/$id/soft_delete/');
  }

  /// 订单素材下刊（路径参数 id 为素材 id）
  static Future<AppRespEntity<String>> customerOrderOffShelf({
    required int id,
  }) {
    return CommonApi.postForm<String>(
      '/api/customer_order/$id/off_shelf/',
      params: <String, dynamic>{'status': '3'},
    );
  }

  /// 订单素材上刊（路径参数 id 为素材 id）
  static Future<AppRespEntity<String>> customerOrderOnShelf({required int id}) {
    return CommonApi.post<String>(
      '/api/customer_order/$id/off_shelf/',
      params: <String, dynamic>{'status': '1'},
    );
  }

  /// 订单素材换刊（路径参数 id 为素材明细 id）
  static Future<AppRespEntity<String>> customerOrderChangeMedia({
    required int id,
    required int mediaId,
  }) {
    return CommonApi.put<String>(
      '/api/customer_order/$id/change_media/',
      params: <String, dynamic>{'media_id': mediaId},
    );
  }

  /// 客户列表（订单添加选择客户）
  static Future<AppRespEntity<List<AdCustomerEntity>>> adCustomerList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<AdCustomerEntity>>(
      '/api/system/ad/customer/',
      params: params,
    );
  }

  /// 添加客户
  static Future<AppRespEntity<AdCustomerEntity>> adCustomerCreate({
    required AdCustomerCreateEntity param,
  }) {
    return CommonApi.post<AdCustomerEntity>(
      '/api/system/ad/customer/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 排他行业列表（内容分组）
  static Future<AppRespEntity<List<AdContentGroupEntity>>> contentGroupList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<AdContentGroupEntity>>(
      '/api/system/ad/content_group/',
      params: params,
    );
  }

  /// 绑定终端列表（订单发布设备）
  static Future<AppRespEntity<List<AdPublishDeviceEntity>>> publishDeviceList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<AdPublishDeviceEntity>>(
      '/api/system/ad/program/publish_devices/',
      params: params,
    );
  }

  /// 素材列表（订单添加选择素材，需传 customer_id）
  static Future<AppRespEntity<List<AdMediaEntity>>> mediaList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    return AdMediaApi.list(page: page, size: size, param: param);
  }

  /// 订单详情（需传 order_no）
  static Future<AppRespEntity<OrderEntity>> orderDetail({
    required String orderNo,
  }) {
    return CommonApi.get<OrderEntity>(
      '/api/system/ad/order_detail/',
      params: {'order_no': orderNo},
    );
  }

  /// 获取监测要求（需传 order_no、order_detail_id）
  static Future<AppRespEntity<OrderMonitorFeedbackEntity>> orderMonitor({
    required String orderNo,
    required int orderDetailId,
  }) {
    return CommonApi.get<OrderMonitorFeedbackEntity>(
      '/api/system/ad/order_monitor/',
      params: {'order_no': orderNo, 'order_detail_id': orderDetailId},
    );
  }

  /// 订单监测要求导出（需传 order_no；data 为 xlsx 下载地址）
  static Future<AppRespEntity<String>> orderMonitorExportSheet({
    required String orderNo,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/order_monitor/export_sheet/',
      params: {'order_no': orderNo},
    );
  }

  /// 删除订单监测要求（需传 id、order_no）
  static Future<AppRespEntity<String>> orderMonitorDelete({
    required int id,
    required String orderNo,
  }) {
    return CommonApi.delete<String>(
      '/api/system/ad/order_monitor/$id/',
      params: {'order_no': orderNo},
    );
  }

  /// 新增订单监测要求
  static Future<AppRespEntity<OrderMonitorFeedbackEntity>> orderMonitorCreate({
    required OrderMonitorCreateEntity param,
  }) {
    return CommonApi.post<OrderMonitorFeedbackEntity>(
      '/api/system/ad/order_monitor/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 编辑订单监测要求（需传 id）
  static Future<AppRespEntity<String>> orderMonitorUpdate({
    required int id,
    required Map<String, dynamic> param,
  }) {
    return CommonApi.put<String>(
      '/api/system/ad/order_monitor/$id/',
      params: param,
    );
  }

  /// 获取监测拍摄分组媒体（需传 order_no、order_detail_id、group_id）
  static Future<AppRespEntity<OrderMonitorGroupMediaEntity>>
  orderMonitorGroupMedia({
    required String orderNo,
    required int orderDetailId,
    required int groupId,
  }) {
    return CommonApi.get<OrderMonitorGroupMediaEntity>(
      '/api/system/ad/order_monitor/group_media/',
      params: {
        'order_no': orderNo,
        'order_detail_id': orderDetailId,
        'group_id': groupId,
      },
    );
  }

  /// 登记监测拍摄媒体（需传 order_no、order_detail_id、group_id、file_url、file_name、file_type）
  static Future<AppRespEntity<OrderMonitorGroupMediaItemEntity>>
  orderMonitorUploadMedia({required OrderMonitorUploadMediaEntity param}) {
    return CommonApi.post<OrderMonitorGroupMediaItemEntity>(
      '/api/system/ad/order_monitor/upload_media/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 删除监测拍摄媒体（需传 order_no、order_detail_id、id）
  static Future<AppRespEntity<String>> orderMonitorDeleteMedia({
    required String orderNo,
    required int orderDetailId,
    required int id,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/order_monitor/delete_media/',
      params: {'order_no': orderNo, 'order_detail_id': orderDetailId, 'id': id},
    );
  }

  /// 修改监测期次日期
  static Future<AppRespEntity<String>> orderMonitorUpdatePeriod({
    required OrderMonitorUpdatePeriodEntity param,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/order_monitor/update_period/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 获取订单监测增值服务
  static Future<AppRespEntity<OrderMonitorVasEntity>> getMonitorVas({
    required int orderDetailId,
  }) {
    return CommonApi.get<OrderMonitorVasEntity>(
      '/api/system/ad/v2/get_monitor_vas/',
      params: {'order_detail_id': orderDetailId},
    );
  }

  /// 保存订单监测增值服务
  static Future<AppRespEntity<OrderMonitorVasSaveResultEntity>> saveMonitorVas({
    required OrderMonitorVasSaveEntity param,
  }) {
    return CommonApi.post<OrderMonitorVasSaveResultEntity>(
      '/api/system/ad/v2/save_monitor_vas/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 终端设备音量控制（form：device_no 为设备编号列表，volume 为 1–100）
  static Future<AppRespEntity<String>> terminalVolume({
    required List<String> deviceNo,
    required int volume,
  }) {
    return CommonApi.postForm<String>(
      '/api/app/terminal/volume',
      params: {'device_no': deviceNo, 'volume': volume},
    );
  }

  /// 终端屏幕亮度调节（form：device_no 为设备编号列表，screen_brightness 为 1–100）
  static Future<AppRespEntity<String>> terminalScreenBrightness({
    required List<String> deviceNo,
    required int screenBrightness,
  }) {
    print(json.encode(deviceNo));
    
    return CommonApi.postForm<String>(
      '/api/app/terminal/screen_brightness',
      params: {'device_no': deviceNo, 'screen_brightness': screenBrightness},
    );
  }

  /// 终端屏幕开关（form：device_no 为设备编号列表，screen_power 为 1 开 / 2 关）
  static Future<AppRespEntity<String>> terminalScreenPower({
    required List<String> deviceNo,
    required int screenPower,
  }) {
    return CommonApi.postForm<String>(
      '/api/app/terminal/screen_power',
      params: {'device_no': deviceNo, 'screen_power': screenPower},
    );
  }

  /// 批量设置开关机时段（ShowDoc 1586；强制覆盖所选设备原时段）。
  static Future<AppRespEntity<String>> terminalEditTimeSlots({
    required List<String> deviceNo,
    required List<LcdDeviceTimeSlotEntity> timeSlots,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/terminal/edit_time_slots/',
      params: {
        'device_no': deviceNo,
        'time_slots': [
          for (var i = 0; i < timeSlots.length; i++)
            {
              'slot_index': timeSlots[i].slot_index ?? (i + 1),
              'start_time': timeSlots[i].start_time,
              'end_time': timeSlots[i].end_time,
            },
        ],
      },
    );
  }

  /// 终端设备重启（form：device_no 为设备编号列表）
  static Future<AppRespEntity<String>> terminalReboot({
    required List<String> deviceNo,
  }) {
    return CommonApi.postForm<String>(
      '/api/app/terminal/reboot',
      params: {'device_no': deviceNo},
    );
  }

  /// 终端设备播放日志（需传 device_no；可选 media_id / start_time / end_time）
  static Future<AppRespEntity<List<LcdTerminalPlayLogEntity>>>
  terminalPlayLogList({int? page, int? size, Map<String, dynamic>? param}) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<LcdTerminalPlayLogEntity>>(
      '/api/app/terminal/logs/play',
      params: params,
    );
  }

  /// 终端设备播放日志导出（查询参数与列表一致，额外传 export=1；data 为 xlsx 下载地址）
  static Future<AppRespEntity<String>> terminalPlayLogExport({
    Map<String, dynamic>? param,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{
      ...?param,
      'export': 1,
    };
    return CommonApi.get<String>('/api/app/terminal/logs/play', params: params);
  }

  /// 终端设备操作日志（需传 device_no）
  static Future<AppRespEntity<List<LcdTerminalOperationLogEntity>>>
  terminalOperationLogList({
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = param.page(page: page, size: size);
    return CommonApi.get<List<LcdTerminalOperationLogEntity>>(
      '/api/app/terminal/logs/operation',
      params: params,
    );
  }

  /// 终端维保 / 巡检 / 异常告警记录（需传 terminal_id；type：1 维保，2 巡检，3 异常告警）
  ///
  /// 可选筛选：`start_time` / `end_time` / `keyword`。
  static Future<AppRespEntity<List<LcdTerminalMaintainLogEntity>>>
  terminalMaintainLogs({
    required int terminalId,
    int type = 1,
    int? page,
    int? size,
    Map<String, dynamic>? param,
  }) {
    final params = <String, dynamic>{
      'terminal_id': terminalId,
      'type': type,
      ...?param,
    }.page(page: page, size: size);
    return CommonApi.get<List<LcdTerminalMaintainLogEntity>>(
      '/api/system/ad/terminal/maintain_logs/',
      params: params,
    );
  }

  /// 维保 / 巡检 / 异常告警记录导出（data 为 xlsx 下载地址）
  ///
  /// 可选筛选与列表一致：`start_time` / `end_time` / `keyword`。
  static Future<AppRespEntity<String>> terminalMaintainLogExport({
    required int terminalId,
    int type = 1,
    Map<String, dynamic>? param,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/terminal/maintain_export/',
      params: <String, dynamic>{
        'terminal_id': terminalId,
        'type': type,
        ...?param,
      },
    );
  }

  /// 新建维保 / 巡检 / 异常告警记录（支持多附件）
  static Future<AppRespEntity<LcdTerminalMaintainLogEntity>>
  terminalMaintainLogCreate({
    required LcdTerminalMaintainLogCreateEntity param,
  }) {
    return CommonApi.post<LcdTerminalMaintainLogEntity>(
      '/api/system/ad/terminal/maintain_logs/',
      params: json.decode(JsonMapper.serialize(param)) as Map<String, dynamic>,
    );
  }

  /// 软删除维保 / 巡检 / 异常告警记录
  static Future<AppRespEntity<String>> terminalMaintainLogSoftDelete({
    required int id,
  }) {
    return CommonApi.post<String>(
      '/api/system/ad/terminal/maintain_log_soft_delete/',
      params: <String, dynamic>{'id': id},
    );
  }
}
