import 'dart:convert' show JsonDecoder;

import 'package:collection/collection.dart' show IterableExtension;

import 'model/index.dart';

/// Provides logic for traversing Json object tree
class JsonMap {
  final pathDelimiter = '/';

  final Map map;
  final List<JsonMap>? parentMaps;
  final Json? jsonMeta;

  const JsonMap(this.map, [this.jsonMeta, this.parentMaps = const []]);

  static final JsonDecoder _jsonDecoder = const JsonDecoder();

  static bool isValidJSON(dynamic jsonValue) {
    try {
      if (jsonValue is String) {
        _jsonDecoder.convert(jsonValue);
        return true;
      }
      return false;
    } on FormatException {
      return false;
    }
  }

  bool hasProperty(String name) {
    return _isPathExists(_getPath(name));
  }

  dynamic getPropertyValue(String name) {
    dynamic result;
    final path = _getPath(name);
    _isPathExists(path, (m, k) {
      result = (m is Map && m.containsKey(k) && k != path) ? m[k] : m;
    });
    return result;
  }

  void setPropertyValue(String name, dynamic value) {
    _setPathValue(_getPath(name), value);
  }

  bool _setPathValue(String path, dynamic value) {
    final segments = _pathSegments(path);
    dynamic current = map;

    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      final isLastSegment = index == segments.length - 1;

      if (segment == JsonProperty.parentReference) {
        final nearestParent =
            parentMaps!.lastWhereOrNull((element) => element.map != current);
        if (nearestParent == null) {
          return false;
        }
        current = nearestParent.map;
        continue;
      }

      if (current is Map) {
        if (isLastSegment) {
          current[segment] = value;
          return true;
        }
        final nextContainer = _ensurePathContainer(
          current[segment],
          segments[index + 1],
        );
        current[segment] = nextContainer;
        current = nextContainer;
        continue;
      }

      if (current is List) {
        final listIndex = int.tryParse(segment);
        if (listIndex == null || listIndex < 0) {
          return false;
        }
        while (current.length <= listIndex) {
          current.add(null);
        }
        if (isLastSegment) {
          return _setListValue(current, listIndex, value);
        }
        final nextContainer = _ensurePathContainer(
          current[listIndex],
          segments[index + 1],
        );
        if (!_setListValue(current, listIndex, nextContainer)) {
          return false;
        }
        current = nextContainer;
        continue;
      }

      return false;
    }
    return false;
  }

  dynamic _ensurePathContainer(dynamic current, String nextSegment) {
    if (current is Map || current is List) {
      return current;
    }
    return int.tryParse(nextSegment) != null ? [] : <String, dynamic>{};
  }

  bool _setListValue(List list, int index, dynamic value) {
    try {
      list[index] = value;
      return true;
    } on TypeError {
      return false;
    } on UnsupportedError {
      return false;
    }
  }

  String _decodePath(String path) {
    if (path.startsWith('#')) {
      path = Uri.decodeComponent(path).substring(1);
    }
    return path;
  }

  String _getPath(String propertyName) {
    final rootObjectSegments = jsonMeta != null && jsonMeta!.name != null
        ? _decodePath(jsonMeta!.name!).split(pathDelimiter)
        : [];
    final propertySegments = _decodePath(propertyName).split(pathDelimiter);
    rootObjectSegments.addAll(propertySegments);
    rootObjectSegments.removeWhere((value) => value == '');
    return rootObjectSegments.join(pathDelimiter);
  }

  bool _isPathExists(String path, [Function? propertyVisitor]) {
    final segments = _pathSegments(path);
    dynamic current = map;
    var existingSegmentsCount = 0;
    for (var segment in segments) {
      final idx = int.tryParse(segment);
      if (segment == JsonProperty.parentReference) {
        final nearestParent =
            parentMaps!.lastWhereOrNull((element) => element.map != current);
        if (nearestParent != null) {
          current = nearestParent.map;
          existingSegmentsCount++;
        }
        continue;
      }
      if (current is List &&
          idx != null &&
          (current.length > idx) &&
          (idx >= 0) &&
          current.elementAt(idx) != null) {
        current = current.elementAt(idx);
        existingSegmentsCount++;
        continue;
      }
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
        existingSegmentsCount++;
      }
    }
    if (propertyVisitor != null && current != null) {
      propertyVisitor(current, segments.last);
    }
    return segments.length == existingSegmentsCount &&
        existingSegmentsCount > 0;
  }

  List<String> _pathSegments(String path) => path
      .split(pathDelimiter)
      .map((p) => p.replaceAll('~1', pathDelimiter).replaceAll('~0', '~'))
      .toList();
}
