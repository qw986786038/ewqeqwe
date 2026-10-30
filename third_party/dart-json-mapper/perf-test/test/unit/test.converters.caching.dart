import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

const myCustomConverter = _MyCustomConverter();

class _MyCustomConverter implements ICustomConverter<String?> {
  static int callsCount = 0;
  const _MyCustomConverter();

  @override
  String? fromJSON(dynamic jsonValue, [DeserializationContext? context]) {
    callsCount++;
    if (jsonValue is int) return jsonValue.toString();
    if (jsonValue is String) return jsonValue;
    return null;
  }

  @override
  dynamic toJSON(String? object, [SerializationContext? context]) {
    throw UnimplementedError();
  }
}

@jsonSerializable
class UserX {
  final int id;

  @JsonProperty(converter: myCustomConverter)
  final String type;

  const UserX(this.id, this.type);
}

void testConvertersCaching() {
  group('[Verify Custom converters results caching]', () {
    test('built-in mutable converters are created per resolution', () {
      final converterHandler = JsonMapper().converterHandler;
      final listTypeInfo =
          JsonMapper().typeInfoHandler.getTypeInfo(List<String>);
      final mapTypeInfo =
          JsonMapper().typeInfoHandler.getTypeInfo(Map<String, String>);

      expect(
        converterHandler.getConverter(null, listTypeInfo),
        isNot(same(converterHandler.getConverter(null, listTypeInfo))),
      );
      expect(
        converterHandler.getConverter(null, mapTypeInfo),
        isNot(same(converterHandler.getConverter(null, mapTypeInfo))),
      );
    });

    test('context equality returns false for unrelated objects', () {
      const context = DeserializationContext(DeserializationOptions());

      expect(context == Object(), isFalse);
    });

    test('converter should be called once', () {
      // given

      // when
      JsonMapper.deserialize<UserX>('''{"id": 42,  "type": "sudoer"}''');
      JsonMapper.deserialize<UserX>('''{"id": 42,  "type": "sudoer"}''');
      JsonMapper.deserialize<UserX>('''{"id": 42,  "type": "sudoer"}''');

      // then
      expect(_MyCustomConverter.callsCount, 1);
    });
  });
}
