import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/entity/order/order_customer_entity.dart';

String customerTypeLabel(int? type) {
  return switch (type) {
    0 => '渠道',
    1 => '直客',
    2 => '代理公司',
    _ => '未知',
  };
}

/// 解析接口返回的十六进制颜色（如 `#4da620`）。
Color? parseHexColor(String? value) {
  final String? trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final String hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  if (hex.length == 6) {
    final int? color = int.tryParse(hex, radix: 16);
    if (color != null) return Color(0xFF000000 | color);
  }
  if (hex.length == 8) {
    final int? color = int.tryParse(hex, radix: 16);
    if (color != null) return Color(color);
  }
  return null;
}

String orderCustomerTypeLabel(OrderCustomerEntity customer) {
  final String? text = customer.type_text?.trim();
  if (text != null && text.isNotEmpty) return text;
  return customerTypeLabel(customer.type);
}

Widget customerIndustryTag({
  required String label,
  String? colorHex,
  bool filled = false,
  AppBadgeSize size = AppBadgeSize.normal,
}) {
  final Color? color = parseHexColor(colorHex);
  final AppBadgeStyle appearance = filled
      ? AppBadgeStyle.soft
      : AppBadgeStyle.outline;
  if (color != null) {
    return AppBadge.custom(
      color: color,
      appearance: appearance,
      shape: AppBadgeShape.square,
      size: size,
      child: Text(label),
    );
  }
  return AppBadge.info(
    appearance: appearance,
    shape: AppBadgeShape.square,
    size: size,
    child: Text(label),
  );
}

String customerStatusLabel(int? status) {
  return switch (status) {
    1 => '生效中',
    2 => '已到期',
    0 => '已禁用',
    _ => '未知',
  };
}

Widget customerStatusBadge(int? status) {
  final String label = customerStatusLabel(status);
  return switch (status) {
    1 => AppBadge.success(
      appearance: AppBadgeStyle.outline,
      shape: AppBadgeShape.square,
      child: Text(label),
    ),
    0 => AppBadge.secondary(
      appearance: AppBadgeStyle.outline,
      shape: AppBadgeShape.square,
      child: Text(label),
    ),
    _ => AppBadge.warning(
      appearance: AppBadgeStyle.outline,
      shape: AppBadgeShape.square,
      child: Text(label),
    ),
  };
}
