import 'package:flutter/material.dart';

/// 展开菜单实体，支持多层级 children。
class MenuItem {
  const MenuItem({
    required this.id,
    required this.title,
    this.icon,
    this.children = const [],
  });

  final String id;
  final String title;
  final IconData? icon;
  final List<MenuItem> children;

  bool get hasChildren => children.isNotEmpty;
}
