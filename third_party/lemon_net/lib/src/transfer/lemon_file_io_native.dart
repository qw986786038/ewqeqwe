import 'dart:io';

Future<int> lemonFileLength(String path) async {
  final file = File(path);
  return await file.exists() ? file.length() : 0;
}

Stream<List<int>> lemonReadFile(String path, {int? start, int? end}) =>
    File(path).openRead(start, end);

Future<void> lemonWriteFile(
  String path,
  Stream<List<int>> stream, {
  required bool append,
}) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  final sink = file.openWrite(mode: append ? FileMode.append : FileMode.write);
  try {
    await sink.addStream(stream);
  } finally {
    await sink.close();
  }
}
