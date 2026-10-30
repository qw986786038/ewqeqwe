import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 点位名称最多字数。
const kLcdPointNameMaxLength = 10;

/// 媒体位置最多字数。
const kLcdMediaAddressMaxLength = 6;

/// 组字结束后再截断，避免 [TextField.maxLength] 默认 enforcement 打断中文 IME。
///
/// 待上游：`AppTextFormField` / `AppInlineEdit.text` 补 `maxLengthEnforcement`，
/// 默认 `MaxLengthEnforcement.truncateAfterCompositionEnds`。
List<TextInputFormatter> lcdMaxLengthFormatters(int maxLength) {
  return [
    LengthLimitingTextInputFormatter(
      maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
    ),
  ];
}

String? lcdMaxLengthError(String? value, int maxLength) {
  if ((value ?? '').trim().length > maxLength) {
    return '最多$maxLength个字';
  }
  return null;
}

/// LCD 设备表单共用选项。
const List<AppOption<String>> kLcdMediaSizeOptions = <AppOption<String>>[
  AppOption<String>(value: '98', label: '98 寸'),
  AppOption<String>(value: '86', label: '86 寸'),
  AppOption<String>(value: '75', label: '75 寸'),
  AppOption<String>(value: '65', label: '65 寸'),
  AppOption<String>(value: '55', label: '55 寸'),
  AppOption<String>(value: '43', label: '43 寸'),
  AppOption<String>(value: '32', label: '32 寸'),
];

const List<AppOption<String>> kLcdNetworkTypeOptions = <AppOption<String>>[
  AppOption<String>(value: 'wifi', label: 'wifi'),
  AppOption<String>(value: '流量卡', label: '流量卡'),
  AppOption<String>(value: '有线网', label: '有线网'),
  AppOption<String>(value: '无', label: '无'),
];
