import 'package:lemon_x/lemon_x.dart';

import '../../../../models/srm_purchase_order.dart';
import '../../../../models/srm_supplier.dart';
import '../../../../services/srm_purchase_order_api.dart';
import '../../../../services/srm_supplier_api.dart';

class SupplierDetailController extends LxController {
  SupplierDetailController({required this.supplierId});

  final String supplierId;
  final _api = SrmSupplierApi();
  final _poApi = SrmPurchaseOrderApi();

  final detail = Rxn<SrmSupplier>();
  final loading = false.obs;
  final errorMessage = Rxn<String>();

  final purchaseOrders = <SrmPurchaseOrder>[].obs;
  final purchaseOrdersLoading = false.obs;
  final selectedOrderIds = <String>{}.obs;

  int? get _supplierIdInt => int.tryParse(supplierId.trim());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      detail.value = await _api.fetchDetail(supplierId);
    } catch (e) {
      errorMessage.value = e.toString();
      detail.value = null;
      return;
    } finally {
      loading.value = false;
    }
    await loadPurchaseOrders();
  }

  Future<void> loadPurchaseOrders() async {
    final sid = _supplierIdInt;
    if (sid == null) {
      purchaseOrders.clear();
      selectedOrderIds.clear();
      return;
    }
    purchaseOrdersLoading.value = true;
    try {
      final page = await _poApi.fetchList(
        SrmPurchaseOrderQuery(
          supplierId: sid,
          pageNum: 1,
          pageSize: 200,
        ),
      );
      purchaseOrders
        ..clear()
        ..addAll(page.rows);
      selectedOrderIds.removeWhere(
        (id) => !purchaseOrders.any((e) => e.id == id),
      );
    } catch (_) {
      purchaseOrders.clear();
    } finally {
      purchaseOrdersLoading.value = false;
    }
  }

  void toggleOrderSelected(String? id, bool selected) {
    final sid = id?.trim();
    if (sid == null || sid.isEmpty) return;
    if (selected) {
      selectedOrderIds.add(sid);
    } else {
      selectedOrderIds.remove(sid);
    }
  }

  void toggleSelectAll(bool selected) {
    if (!selected) {
      selectedOrderIds.clear();
      return;
    }
    selectedOrderIds
      ..clear()
      ..addAll({
        for (final e in purchaseOrders)
          if ((e.id ?? '').trim().isNotEmpty) e.id!.trim(),
      });
  }

  Future<void> bindOrders(List<int> ids) async {
    final sid = _supplierIdInt;
    if (sid == null) {
      throw SrmPurchaseOrderApiException('供应商 ID 无效');
    }
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请选择要关联的采购订单');
    }
    await _poApi.bindSupplier(
      supplierId: sid,
      ids: ids,
      supplierFullName: detail.value?.fullName,
    );
    await loadPurchaseOrders();
  }

  Future<void> unbindSelected() async {
    final sid = _supplierIdInt;
    if (sid == null) {
      throw SrmPurchaseOrderApiException('供应商 ID 无效');
    }
    final ids = <int>[
      for (final id in selectedOrderIds)
        if (int.tryParse(id) != null) int.parse(id),
    ];
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请先勾选要移除的采购订单');
    }
    await _poApi.unbindSupplier(supplierId: sid, ids: ids);
    selectedOrderIds.clear();
    await loadPurchaseOrders();
  }
}
