import 'package:flutter/material.dart';

/// 应用通用展开行：默认无悬停/水波纹、无展开边框与背景色。
///
/// ```dart
/// AppExpansionTile(
///   title: Text('标题'),
///   children: [Text('内容')],
/// )
/// ```
class AppExpansionTile extends StatelessWidget {
  const AppExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.children = const <Widget>[],
    this.onExpansionChanged,
    this.tilePadding = EdgeInsets.zero,
    this.childrenPadding = EdgeInsets.zero,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.leading,
    this.trailing,
    this.showTrailingIcon = true,
    this.expandedAlignment,
    this.expandedCrossAxisAlignment,
    this.controller,
  });

  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry tilePadding;
  final EdgeInsetsGeometry childrenPadding;
  final bool initiallyExpanded;
  final bool maintainState;
  final Widget? leading;
  final Widget? trailing;

  /// 是否显示右侧展开箭头；自定义右上角按钮时可设为 `false`。
  final bool showTrailingIcon;
  final Alignment? expandedAlignment;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final ExpansibleController? controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        listTileTheme: theme.listTileTheme.copyWith(
          selectedTileColor: Colors.transparent,
          tileColor: Colors.transparent,
        ),
      ),
      child: ExpansionTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        showTrailingIcon: showTrailingIcon,
        tilePadding: tilePadding,
        childrenPadding: childrenPadding,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: initiallyExpanded,
        maintainState: maintainState,
        expandedAlignment: expandedAlignment,
        expandedCrossAxisAlignment: expandedCrossAxisAlignment,
        controller: controller,
        onExpansionChanged: onExpansionChanged,
        children: children,
      ),
    );
  }
}
