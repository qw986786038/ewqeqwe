import 'package:lemon_x/lemon_x.dart';

import '../../../../models/srm_supplier.dart';
import '../../../../services/srm_supplier_api.dart';

class SupplierDetailController extends LxController {
  SupplierDetailController({required this.supplierId});

  final String supplierId;
  final _api = SrmSupplierApi();

  final detail = Rxn<SrmSupplier>();
  final loading = false.obs;
  final errorMessage = Rxn<String>();

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
    } finally {
      loading.value = false;
    }
  }
}
