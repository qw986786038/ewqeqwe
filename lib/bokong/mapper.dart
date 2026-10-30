// 供 build_runner 收集 @jsonSerializable 实体
// ignore_for_file: unused_import

import 'entity/analytics/ad_data_analysis_comprehensive_entity.dart';
import 'entity/analytics/ad_data_analysis_comprehensive_order_entity.dart';
import 'entity/analytics/ad_data_analysis_district_rank_entity.dart';
import 'entity/analytics/ad_data_analysis_entity.dart';
import 'entity/analytics/ad_data_analysis_play_trends_entity.dart';
import 'entity/analytics/ad_data_analysis_property_rank_entity.dart';
import 'entity/analytics/ad_data_analysis_rank_entity.dart';
import 'entity/analytics/ad_data_analysis_trends_order_entity.dart';
import 'entity/analytics/ad_data_analysis_up_rate_rank_entity.dart';
import 'entity/lcd/ad_file_list_entity.dart';
import 'entity/lcd/ad_office_building_file_entity.dart';
import 'entity/lcd/ad_office_list_entity.dart';
import 'entity/lcd/ad_property_list_entity.dart';
import 'entity/lcd/lcd_device_entity.dart';
import 'entity/lcd/lcd_device_scene_pic_entity.dart';
import 'entity/lcd/lcd_filter_options_entity.dart';
import 'entity/lcd/lcd_program_create_entity.dart';
import 'entity/lcd/lcd_program_device_entity.dart';
import 'entity/lcd/lcd_program_material_entity.dart';
import 'entity/lcd/lcd_terminal_create_entity.dart';
import 'entity/lcd/lcd_terminal_maintain_log_entity.dart';
import 'entity/lcd/lcd_terminal_operation_log_entity.dart';
import 'entity/lcd/lcd_terminal_play_log_entity.dart';
import 'entity/lcd/lcd_terminal_play_preview_entity.dart';
import 'entity/lcd/lcd_terminal_stats_entity.dart';
import 'entity/lcd/lcd_terminal_up_rate_daily_entity.dart';
import 'entity/lcd/lcd_terminal_up_rate_list_entity.dart';
import 'entity/order/ad_content_category_entity.dart';
import 'entity/order/ad_content_group_entity.dart';
import 'entity/order/ad_customer_create_entity.dart';
import 'entity/order/ad_customer_entity.dart';
import 'entity/order/ad_customer_order_file_entity.dart';
import 'entity/order/ad_media_entity.dart';
import 'entity/order/ad_media_filter_options_entity.dart';
import 'entity/order/ad_plugin_entity.dart';
import 'entity/order/ad_publish_device_entity.dart';
import 'entity/order/order_create_entity.dart';
import 'entity/order/order_customer_entity.dart';
import 'entity/order/order_entity.dart';
import 'entity/order/order_monitor_create_entity.dart';
import 'entity/order/order_monitor_feedback_entity.dart';
import 'entity/order/order_monitor_entity.dart';
import 'entity/order/order_monitor_group_media_entity.dart';
import 'entity/order/order_monitor_vas_entity.dart';
import 'entity/system/area_entity.dart';
import 'entity/system/file_presign_entity.dart';
import 'entity/user/captcha_entity.dart';
import 'entity/user/user_entity.dart';

/// reflectable / dart_json_mapper 要求入口库存在 `main`，实际启动仍走 `lib/main.dart`。
void main() {}
