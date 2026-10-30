import 'package:flutter/material.dart';

Widget tableText(
  BuildContext context,
  String text, {
  Color? color,
  int? maxLines,
}) => Text(
  text,
  maxLines: maxLines,
  style: Theme.of(
    context,
  ).textTheme.titleSmall?.copyWith(color: color, fontSize: 18),
  overflow: TextOverflow.ellipsis,
);

Widget listTitle(
  BuildContext context,
  String text, {
  Color? color,
  int? maxLines,
}) => Text(
  text,
  style: TextStyle(
    fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
    color: color,
  ),
  overflow: TextOverflow.ellipsis,
  maxLines: maxLines,
);

Widget subtitle(
  BuildContext context,
  String text, {
  Color? color,
  int? maxLines,
}) => Text(
  text,
  maxLines: maxLines,
  style: Theme.of(
    context,
  ).textTheme.titleSmall?.copyWith(color: color, fontSize: 16),
);

Widget title(
  BuildContext context,
  String text, {
  Color? color,
  int? maxLines,
  TextAlign? textAlign,
}) => Text(
  text,
  maxLines: maxLines,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
  textAlign: textAlign,
);

Widget titleLarge(
  BuildContext context,
  String text, {
  Color? color,
  int? maxLines,
  TextAlign? textAlign,
}) => Text(
  text,
  maxLines: maxLines,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
  textAlign: textAlign,
);

Widget smallTitle(
  BuildContext context,
  String text, {
  Color? color,
  int? maxLines,
}) => Text(
  text,
  style: Theme.of(
    context,
  ).textTheme.titleLarge?.copyWith(color: color, fontSize: 12),
  maxLines: maxLines,
  overflow: TextOverflow.ellipsis,
);

Widget body(
  BuildContext context,
  String text, {
  int? maxLines,
  Color? color,
  double? fontSize,
}) => Text(
  text,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
  style: Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: color, fontSize: fontSize),
);

Widget bigTextTip(BuildContext context, String text) => Text(
  text,
  style: Theme.of(
    context,
  ).textTheme.headlineLarge?.copyWith(color: Colors.black26),
);

Widget bigText(BuildContext context, String text) => Text(
  text,
  style: Theme.of(
    context,
  ).textTheme.headlineLarge?.copyWith(color: Colors.black87),
);

Widget text(BuildContext context, String text, {Color? color, double? size}) =>
    Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color ?? Colors.black87,
        fontSize: size,
      ),
    );

Widget line({double? width, double indent = 12, double endIndent = 12}) {
  return Container(
    margin: EdgeInsets.only(left: indent, right: endIndent),
    height: 1,
    width: width,
    color: Colors.black12,
  );
}

typedef MenuItemSelected = void Function(int index, String label);

Widget popMenu({
  required List<String> labels,
  Widget? child,
  offset = Offset.zero,
  List<IconData>? icons,
  MenuItemSelected? onSelected,
}) {
  assert(
    icons == null ? true : labels.length == icons.length,
    "icon数量必须等于label数量",
  );
  return PopupMenuButton(
    tooltip: "更多选项",
    padding: const EdgeInsets.all(0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
    itemBuilder: (BuildContext context) {
      return labels
          .map(
            (e) => PopupMenuItem(
              value: labels.indexOf(e),
              child: icons == null
                  ? subtitle(context, e)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        subtitle(context, e),
                        Icon(icons[labels.indexOf(e)], color: Colors.black54),
                      ],
                    ),
            ),
          )
          .toList();
    },
    onSelected: (index) {
      onSelected?.call(index, labels[index]);
    },
    offset: offset,
    child: child,
  );
}

Widget button({
  String? text,
  EdgeInsetsGeometry margin = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  ),
  required VoidCallback onPressed,
  Color? color,
}) {
  return Padding(
    padding: margin,
    child: MaterialButton(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
      height: 43,
      minWidth: 80,
      color: color ?? Colors.blue,
      onPressed: onPressed,
      child: text == null
          ? null
          : Text(text, style: const TextStyle(color: Colors.white)),
    ),
  );
}
