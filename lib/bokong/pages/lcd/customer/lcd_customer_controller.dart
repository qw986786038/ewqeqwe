import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_entity.dart';

class LcdCustomerController extends LxController {
  Rxn<AdCustomerEntity> current = Rxn();
  RxList<AdCustomerEntity> customers = RxList();

  void selectCustomer(AdCustomerEntity customer) {
    if (current.value?.id == customer.id) return;
    current.value = customer;
  }
}
