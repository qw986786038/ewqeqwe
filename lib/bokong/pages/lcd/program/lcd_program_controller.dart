import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_create_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/http/app_exceptions.dart';
import 'package:yidivination/bokong/widget/message.dart';

class LcdProgramController extends LxController {
  Rxn<LcdProgramDeviceEntity> current = Rxn();
  Rxn<LcdProgramMaterialEntity> currentMaterial = Rxn();
  RxList<LcdProgramDeviceEntity> devices = RxList();
  RxList<LcdProgramMaterialEntity> materials = RxList();
  RxBool loadingMaterials = false.obs;

  int get total => devices.length;

  int get onlineCount =>
      devices.where((e) => e.terminal_device_status == '在线').length;

  int get offlineCount =>
      devices.where((e) => e.terminal_device_status != '在线').length;

  void selectMaterial(LcdProgramMaterialEntity material) {
    currentMaterial.value = material;
  }

  Future<void> selectDevice(LcdProgramDeviceEntity device) async {
    if (current.value?.id == device.id && materials.isNotEmpty) {
      return;
    }
    current.value = device;
    currentMaterial.value = null;
    await loadMaterials(device.id);
  }

  Future<void> loadMaterials(int? scheduleId) async {
    if (scheduleId == null) {
      materials.clear();
      currentMaterial.value = null;
      return;
    }
    loadingMaterials.value = true;
    try {
      final resp = await LcdApi.programMaterialList(
        page: 1,
        size: 20,
        param: {'schedule_id': scheduleId},
      );
      final list = resp.data ?? [];
      materials.replaceAll(list);
      currentMaterial.value = list.isEmpty ? null : list.first;
    } finally {
      loadingMaterials.value = false;
    }
  }

  Future<void> reorderMaterials(
    List<Object> orderedKeys,
    List<LcdProgramMaterialEntity> orderedRows,
  ) async {
    if (_sameMaterialOrder(materials, orderedRows)) return;
    final int? scheduleId = current.value?.id;
    if (scheduleId == null) return;

    final List<LcdProgramMaterialEntity> backup =
        List<LcdProgramMaterialEntity>.from(materials);
    materials.replaceAll(orderedRows);
    for (int i = 0; i < materials.length; i++) {
      materials[i].play_sort = i + 1;
    }

    final List<int> ids = materials.map((e) => e.id).whereType<int>().toList();
    if (ids.length != materials.length) {
      materials.replaceAll(backup);
      showWarn('存在无效素材 ID，无法排序');
      return;
    }

    try {
      await LcdApi.programMaterialReorder(scheduleId: scheduleId, ids: ids);
    } catch (e) {
      materials.replaceAll(backup);
      for (int i = 0; i < materials.length; i++) {
        materials[i].play_sort = i + 1;
      }
      _onApiError(e);
    }
  }

  Future<void> startScheduleExecution() async {
    final int? scheduleId = current.value?.id;
    if (scheduleId == null) {
      showWarn('请先选择左侧节目设备');
      return;
    }
    try {
      final AppRespEntity<String> resp = await LcdApi.programScheduleExecute(
        scheduleId: scheduleId,
        action: 'start',
      );
      showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '启动执行成功');
    } catch (e) {
      _onApiError(e);
    }
  }

  Future<void> createProgram(LcdProgramCreateEntity param) async {
    final AppRespEntity<String> resp = await LcdApi.programCreateForSchedule(
      param: param,
    );
    if (!resp.isSuccess()) throw resp;
    showComplete(resp.msg?.isNotEmpty == true ? resp.msg! : '创建节目成功');
    await loadMaterials(current.value?.id);
  }

  Future<void> toggleMaterialShelf(LcdProgramMaterialEntity material) async {
    final int? id = material.id;
    if (id == null) {
      showWarn('素材 ID 无效');
      return;
    }
    final bool onShelf = material.is_delete == 1;
    try {
      await LcdApi.programMaterialShelf(id: id, onShelf: onShelf);
      await loadMaterials(current.value?.id);
    } catch (e) {
      _onApiError(e);
    }
  }

  Future<void> updateMaterialRule({
    required int materialId,
    Set<int>? industryIds,
    int? exclusiveRule,
    int? loopRule,
  }) async {
    try {
      await LcdApi.programMaterialUpdateRule(
        id: materialId,
        exclusiveIndustry: industryIds?.toList(),
        exclusiveRule: exclusiveRule,
        loopRule: loopRule,
      );
      final int? selectedId = currentMaterial.value?.id;
      await loadMaterials(current.value?.id);
      if (selectedId != null) {
        for (final LcdProgramMaterialEntity item in materials) {
          if (item.id == selectedId) {
            currentMaterial.value = item;
            break;
          }
        }
      }
    } catch (e) {
      _onApiError(e);
    }
  }

  void _onApiError(Object e) {
    if (e is AppRespEntity) {
      showError(e.msg);
    } else if (e is AppException) {
      showError(e.msg);
    } else {
      showError(e.toString());
    }
  }

  bool _sameMaterialOrder(
    List<LcdProgramMaterialEntity> currentRows,
    List<LcdProgramMaterialEntity> orderedRows,
  ) {
    if (currentRows.length != orderedRows.length) return false;
    for (int i = 0; i < currentRows.length; i++) {
      if (currentRows[i].id != orderedRows[i].id) return false;
    }
    return true;
  }
}
