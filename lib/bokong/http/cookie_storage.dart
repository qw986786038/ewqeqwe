import 'dart:io';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:lemon_net/lemon_net.dart';
import 'package:path_provider/path_provider.dart';

///Save cookies in  files

class CookieStorage implements Storage {
  CookieStorage([this._storageName]);

  String? _storageName;

  Box? _storage;

  String Function(Uint8List list)? readPreHandler;

  List<int> Function(String value)? writePreHandler;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    _storageName = _storageName ?? 'GetCookie';
    _storageName =
        '${_storageName!}ie${ignoreExpires ? 1 : 0}_ps${persistSession ? 1 : 0}';
    _storage = await initHive(_storageName!);
  }

  static Future<Box> initHive(String name) async {
    ///为了一套软件能在一台电脑上运行不串数据
    if (Platform.isWindows) {
      var appDir = Directory.current.path;
      print(appDir);
      Hive.init(appDir);
    } else if (Platform.isAndroid) {
      var appDir = await getApplicationSupportDirectory();
      Hive.init(appDir.path);
    } else {
      await Hive.initFlutter();
    }

    return await Hive.openBox(
      name,
      compactionStrategy: (entries, deletedEntries) {
        return deletedEntries > 10;
      },
    );
  }

  @override
  Future<void> delete(String key) async {
    return _storage?.delete(key);
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    _storage?.deleteAll(keys);
    return Future.value();
  }

  @override
  Future<String?> read(String key) async {
    if (readPreHandler != null) {
      return Future.value(readPreHandler!(_storage?.get(key)));
    } else {
      return Future.value(_storage?.get(key));
    }
  }

  @override
  Future<void> write(String key, String value) async {
    if (writePreHandler != null) {
      return _storage?.put(key, writePreHandler!(value));
    } else {
      return _storage?.put(key, value);
    }
  }
}
