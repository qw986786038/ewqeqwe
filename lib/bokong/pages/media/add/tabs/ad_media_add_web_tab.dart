import 'package:flutter/material.dart';

/// 添加素材 ·「网页」Tab。
///
/// URL / 备注已上提到 [ad_media_add_dialog] 公共区，避免 Tab 切换时
/// 同名字段重复注册（旧字段 dispose 滞后于新字段 mount）。
class AdMediaAddWebTab extends StatelessWidget {
  const AdMediaAddWebTab({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
