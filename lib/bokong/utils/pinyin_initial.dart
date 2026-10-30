import 'package:pinyin/pinyin.dart';

/// 取名称拼音首字母（大写）；非中文则尽量取首字母，否则 `?`。
String pinyinInitialOf(String? name) {
  final text = name?.trim() ?? '';
  if (text.isEmpty) return '?';

  final short = PinyinHelper.getShortPinyin(text).trim();
  if (short.isNotEmpty) {
    final letter = short.substring(0, 1).toUpperCase();
    if (_isAsciiLetter(letter)) return letter;
  }

  final first = String.fromCharCode(text.runes.first).toUpperCase();
  if (_isAsciiLetter(first) || RegExp(r'[0-9]').hasMatch(first)) {
    return first;
  }
  return '?';
}

bool _isAsciiLetter(String value) => RegExp(r'^[A-Z]$').hasMatch(value);
