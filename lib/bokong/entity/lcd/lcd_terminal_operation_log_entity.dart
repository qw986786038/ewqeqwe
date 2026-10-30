import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 终端设备操作日志
@jsonSerializable
class LcdTerminalOperationLogEntity {
  /// 日志编号
  String? log_no;

  /// 操作模块
  String? module;

  /// 操作动作
  String? action;

  /// 操作内容
  String? operation_content;

  /// 下发时间
  String? issue_time;

  /// 完成时间
  String? result_time;

  /// 操作状态
  int? operation_status;

  /// 错误信息
  String? error_message;
}
