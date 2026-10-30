import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_office_location.dart';
import '../../../services/hrm_api.dart';

class WorkplaceController extends LxController {
  final _api = HrmApi();

  final nameSearchCtrl = TextEditingController();

  final loading = false.obs;
  final errorMessage = Rxn<String>();

  final locations = <HrmOfficeLocation>[].obs;
  final filtered = <HrmOfficeLocation>[].obs;

  String _nameQuery = '';

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onDispose() {
    nameSearchCtrl.dispose();
    super.onDispose();
  }

  int get nextOrderNum {
    var max = -1;
    for (final loc in locations) {
      final n = loc.orderNum ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  Future<void> refreshAll() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final list = await _api.fetchOfficeLocations();
      locations
        ..clear()
        ..addAll(list);
      locations.refresh();
      _applyFilter();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void search() {
    _nameQuery = nameSearchCtrl.text.trim();
    _applyFilter();
  }

  void resetSearch() {
    nameSearchCtrl.clear();
    _nameQuery = '';
    _applyFilter();
  }

  void _applyFilter() {
    final q = _nameQuery;
    if (q.isEmpty) {
      filtered
        ..clear()
        ..addAll(locations);
    } else {
      filtered
        ..clear()
        ..addAll([
          for (final loc in locations)
            if (loc.name?.contains(q) == true ||
                loc.address?.contains(q) == true)
              loc,
        ]);
    }
    filtered.refresh();
  }

  Future<void> createLocation({
    required String name,
    required String address,
    required int orderNum,
  }) async {
    await _api.createOfficeLocation(
      name: name,
      address: address,
      orderNum: orderNum,
    );
    await refreshAll();
  }

  Future<void> updateLocation({
    required String id,
    required String name,
    required String address,
    required int orderNum,
  }) async {
    await _api.updateOfficeLocation(
      id: id,
      name: name,
      address: address,
      orderNum: orderNum,
    );
    await refreshAll();
  }

  Future<void> deleteLocation(String id) async {
    await _api.deleteOfficeLocation(id);
    await refreshAll();
  }
}
