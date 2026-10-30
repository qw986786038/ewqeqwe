Future<int> lemonFileLength(String path) =>
    Future<int>.error(UnsupportedError('File transfer is not supported.'));

Stream<List<int>> lemonReadFile(String path, {int? start, int? end}) =>
    Stream<List<int>>.error(
      UnsupportedError('File transfer is not supported.'),
    );

Future<void> lemonWriteFile(
  String path,
  Stream<List<int>> stream, {
  required bool append,
}) => Future<void>.error(UnsupportedError('File transfer is not supported.'));
