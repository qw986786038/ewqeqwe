import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

/// 详情弹窗水平边距（由 [AppFormDialog.padding] 统一提供）。
const kDeviceDetailEdge = 20.0;

/// 顶栏标题/副标题紧凑行高，避免与徽章、按钮垂直不对齐。
const kDeviceDetailHeaderTextStyle = TextStyle(
  height: 1,
  leadingDistribution: TextLeadingDistribution.even,
);

/// 详情顶栏设备名称：20 号。
const kDeviceDetailHeaderTitleStyle = TextStyle(
  fontSize: 20,
  height: 1,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Title / Tab 栏：外边距已由弹窗 padding 提供。
const kDeviceDetailTitlePadding = EdgeInsets.zero;

/// 各 Tab 页内容区：水平/底边距已由弹窗 padding 提供。
const kDeviceDetailPagePadding = EdgeInsets.zero;

/// 各 Tab 顶栏卡片内边距（与操作按钮行高解耦，避免切 Tab 跳动）。
const kDeviceDetailHeaderPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
);

/// 详情弹窗外边距（与上游 [AppFormDialog] 默认一致）。
const kDeviceDetailDialogPadding = EdgeInsets.all(kDeviceDetailEdge);
