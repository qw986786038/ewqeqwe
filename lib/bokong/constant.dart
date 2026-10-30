class Constant {
  Constant._();

  static String get SP_USER => "SP_USER";
  static String get SP_USERNAME => "SP_USERNAME";
  static String get SP_PASSWORD => "SP_PASSWORD";

  static String get SP_USER_SET => "SP_USER_SET";

  static String get SP_REMEMBER_PWD => "SP_REMEMBER_PWD";

  static String get SP_ACCESS_TOKEN => "SP_ACCESS_TOKEN";

  static String get SP_REFRESH_TOKEN => "SP_REFRESH_TOKEN";

  static String get baseUrl {
    return 'https://play.mediasys.cn';
    // return 'http://192.168.5.12:80';
  }
}
