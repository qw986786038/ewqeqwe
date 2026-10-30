import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/user_api.dart';
import 'package:yidivination/bokong/widget/message.dart';

class MainController extends LxController {
  @override
  void onInit() {
    super.onInit();
    getUser();
  }

  void getUser() {
    UserApi.userInfo()
        .then((v) {
          showInfo(v.data?.username ?? "");
        })
        .catchError((e) {
          showError(e.msg);
        });
  }
}
