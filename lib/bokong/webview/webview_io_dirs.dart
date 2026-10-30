import 'dart:io';

/// 确保 WebView2 用户数据目录存在（仅 VM/桌面等带 `dart:io` 的目标）。
Future<void> ensureWebViewUserDataDirectory(String absolutePath) async {
  await Directory(absolutePath).create(recursive: true);
}
