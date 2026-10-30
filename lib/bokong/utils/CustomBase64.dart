import 'dart:convert';

class CustomBase64 {
  static const String _standard =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  // 必须正好 64 个字符，并且不能重复
  static const String _custom =
      '_-9876543210zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA';

  static String encode(List<int> bytes) {
    // 使用无填充 Base64URL
    final standardText = base64UrlEncode(bytes).replaceAll('=', '');

    final output = StringBuffer();

    for (final codeUnit in standardText.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final index = _standard.indexOf(char);

      if (index < 0) {
        throw const FormatException('Base64 编码结果异常');
      }

      output.write(_custom[index]);
    }

    return output.toString();
  }

  static List<int> decode(String customText) {
    if (customText.isEmpty) {
      return <int>[];
    }

    final output = StringBuffer();

    for (final codeUnit in customText.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final index = _custom.indexOf(char);

      if (index < 0) {
        throw const FormatException('密文包含非法字符');
      }

      output.write(_standard[index]);
    }

    var standardText = output.toString();

    // 补回 Base64 的 =
    final remainder = standardText.length % 4;

    if (remainder == 1) {
      throw const FormatException('密文长度不正确');
    }

    if (remainder > 0) {
      standardText += '=' * (4 - remainder);
    }

    return base64Url.decode(standardText);
  }
}
