import 'package:flutter/widgets.dart';

/// 详情弹窗水平边距（由 [AppFormDialog.padding] 统一提供）。
const kOrderDetailEdge = 20.0;

/// Title / Tab 栏：外边距已由弹窗 padding 提供。
const kOrderDetailTitlePadding = EdgeInsets.zero;

/// 各 Tab 页内容区：水平/底边距已由弹窗 padding 提供。
const kOrderDetailPagePadding = EdgeInsets.zero;

/// 各 Tab 顶栏卡片内边距。
const kOrderDetailHeaderPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
);

/// 详情弹窗外边距（与上游 [AppFormDialog] 默认一致）。
const kOrderDetailDialogPadding = EdgeInsets.all(kOrderDetailEdge);
