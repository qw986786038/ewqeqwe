import 'package:flutter/material.dart';
import 'package:yidivination/bokong/api/ad_media_api.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 行业分类标签颜色；无有效值时返回 `null` 以回退默认样式。
Color? industryTagColor(LcdProgramMaterialEntity material) =>
    parseHexColor(material.color);

/// 解析节目素材对应的素材库 ID。
int? resolveProgramMaterialMediaId(LcdProgramMaterialEntity material) =>
    material.media_id;

/// 更新节目素材（素材库 + 排期规则）。
Future<void> updateProgramMaterial({
  required LcdProgramMaterialEntity material,
  required Map<String, dynamic> mediaParams,
  required Set<int> industryIds,
  required int exclusiveRule,
  required int loopRule,
}) async {
  final int? mediaId = resolveProgramMaterialMediaId(material);
  final int? programId = material.id;
  if (mediaId == null) {
    showWarn('无法获取素材库 ID');
    throw StateError('无法获取素材库 ID');
  }
  if (programId == null) {
    showWarn('节目素材 ID 无效');
    throw StateError('节目素材 ID 无效');
  }

  await AdMediaApi.update(id: mediaId, params: mediaParams);
  await LcdApi.programMaterialUpdateRule(
    id: programId,
    exclusiveIndustry: industryIds.toList(),
    exclusiveRule: exclusiveRule,
    loopRule: loopRule,
  );
  showComplete('保存成功');
}
