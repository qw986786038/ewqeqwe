# dart_json_mapper

[English](README.md) | 简体中文

`dart_json_mapper` 是一个基于注解和代码生成的 Dart JSON
序列化、反序列化工具。它可以通过统一的泛型 API 在 Dart 对象、JSON 字符串和
`Map<String, dynamic>` 之间进行转换，并且不要求模型类实现 `fromJson`、
`toJson`、Mixin 或基类。

该库不依赖 `dart:mirrors`，可以在 Dart VM、Web 和 Flutter 等平台使用。
底层通过 `reflectable` 在编译阶段生成运行时所需的类型元数据。

## 主要特点

- 使用 `JsonMapper.deserialize<T>()` 根据泛型类型反序列化。
- 模型类不需要编写 `fromJson` 和 `toJson`。
- 支持构造函数、不可变对象、继承、Mixin 和泛型。
- 支持 List、Set、Map、枚举和常用 Dart 类型。
- 支持自定义 Converter、字段别名、命名风格和默认值。
- 支持多态类型、嵌套路径、对象扁平化和循环引用检测。
- 可以通过 Adapter 扩展 Flutter、MobX、Built Collection 和 Fixnum 类型。

## 安装

在项目的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  dart_json_mapper:

dev_dependencies:
  build_runner:
```

`reflectable_builder` 已经由 `dart_json_mapper` 提供，应用项目不需要再单独声明。

## 基本使用

假设项目中有以下模型：

```dart
import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, JsonProperty, jsonSerializable;

import 'main.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class User {
  final int id;

  @JsonProperty(name: 'user_name')
  final String name;

  @JsonProperty(ignore: true)
  final String? localToken;

  const User({
    required this.id,
    required this.name,
    this.localToken,
  });
}

void main() {
  initializeJsonMapper();

  const user = User(id: 1, name: 'Alice');
  final json = JsonMapper.serialize(user);
  final decoded = JsonMapper.deserialize<User>(json);

  print(json);
  print(decoded?.name);
}
```

输出：

```text
{"id":1,"user_name":"Alice"}
Alice
```

## 配置代码生成

在应用根目录创建或修改 `build.yaml`：

```yaml
targets:
  $default:
    builders:
      dart_json_mapper:
        generate_for:
          # 填写包含 main() 的入口文件
          - lib/main.dart

      # dart_json_mapper 已经包装了 reflectable 的生成过程，
      # 因此需要禁止原始 reflectable builder 重复执行。
      reflectable_builder:
        generate_for:
          - no/files
```

执行一次生成：

```shell
dart run build_runner build --delete-conflicting-outputs
```

开发时可以持续监听文件变化：

```shell
dart run build_runner watch --delete-conflicting-outputs
```

修改模型或入口文件后，需要重新生成 `*.mapper.g.dart`。应用启动时必须调用生成文件中的
`initializeJsonMapper()`。

## 核心 API

### 对象转 JSON

```dart
final json = JsonMapper.serialize(user);
// 等价写法
final json2 = JsonMapper.toJson(user);
```

格式化输出：

```dart
final json = JsonMapper.serialize(
  user,
  const SerializationOptions(indent: '  '),
);
```

### JSON 转对象

```dart
final user = JsonMapper.deserialize<User>(json);
// 仅接受字符串的等价写法
final user2 = JsonMapper.fromJson<User>(json);
```

集合与泛型也可以直接作为目标类型：

```dart
final users = JsonMapper.deserialize<List<User>>(json);
final result = JsonMapper.deserialize<ApiResult<User>>(json);
```

### 对象与 Map 互转

```dart
final map = JsonMapper.toMap(user);
final user2 = JsonMapper.fromMap<User>(map);
```

### 克隆和复制

```dart
final cloned = JsonMapper.clone(user);
final copied = JsonMapper.copyWith(user, {
  'user_name': 'Bob',
});
```

`copyWith` 基于 JSON Map 合并实现，只适合能够完整序列化和反序列化的对象。

### 构造查询 URI

```dart
final uri = JsonMapper.toUri(
  baseUrl: 'https://example.com/users?lang=zh#list',
  getParams: {
    'page': 1,
    'tag': ['dart', 'flutter'],
    'optional': null,
  },
);
```

结果：

```text
https://example.com/users?lang=zh&page=1&tag=dart&tag=flutter#list
```

新参数会覆盖同名的已有参数；null 和空集合参数会被省略。

## 常用注解

### `@jsonSerializable`

声明一个类、Mixin 或枚举需要参与 JSON 映射：

```dart
@jsonSerializable
class Product {}
```

### `@JsonProperty`

配置字段映射：

```dart
@JsonProperty(name: 'product_id')
final int id;
```

常用参数：

| 参数 | 作用 |
| --- | --- |
| `name` | 修改 JSON 字段名，也可以配置字段别名或嵌套路径 |
| `ignore` | 序列化和反序列化都忽略该字段 |
| `ignoreForSerialization` | 仅在序列化时忽略 |
| `ignoreForDeserialization` | 仅在反序列化时忽略 |
| `ignoreIfNull` | 值为 null 时不输出 |
| `ignoreIfDefault` | 值等于默认值时不输出 |
| `required` | JSON 中必须存在该字段 |
| `notNull` | JSON 中必须存在且不能为 null |
| `defaultValue` | 字段缺失时使用默认值 |
| `converter` | 为字段指定自定义 Converter |
| `converterParams` | 向 Converter 传递配置参数 |
| `flatten` | 将嵌套对象字段合并到当前 JSON 对象 |
| `rawJson` | 将字段作为原始 JSON 字符串处理 |
| `inject` | 从 `injectableValues` 注入字段值 |

### 字段别名

第一个名称是主名称，后续名称用于兼容旧数据：

```dart
@JsonProperty(name: ['id', 'user_id', 'userId'])
final int id;
```

### 默认值与必填字段

```dart
@JsonProperty(defaultValue: 0)
final int count;

@JsonProperty(required: true)
final String name;

@JsonProperty(notNull: true)
final String token;
```

### 指定构造函数

```dart
@jsonSerializable
class User {
  final int id;
  final String name;

  @jsonConstructor
  const User.fromJson(this.id, this.name);
}
```

## 命名风格

可以在类或单次调用中指定字段命名风格：

```dart
@jsonSerializable
@Json(caseStyle: CaseStyle.snake)
class UserProfile {
  final String firstName;

  const UserProfile(this.firstName);
}
```

也可以通过 Options 配置：

```dart
final user = JsonMapper.deserialize<UserProfile>(
  json,
  const DeserializationOptions(caseStyle: CaseStyle.snake),
);
```

支持 camel、pascal、kebab、snake 和全大写 snake 等风格。

## DateTime 和数字格式

通过 `converterParams` 提供 `intl` 格式：

```dart
@JsonProperty(converterParams: {'format': 'yyyy-MM-dd'})
final DateTime birthday;

@JsonProperty(converterParams: {'format': '##.##'})
final num salary;
```

## Iterable

List 和 Set 默认支持。使用分隔符将集合编码为字符串：

```dart
@JsonProperty(converterParams: {'delimiter': ','})
final List<String> tags;
```

如需支持 `HashSet` 或 `UnmodifiableListView`，可以配置 Builder：

```yaml
targets:
  $default:
    builders:
      dart_json_mapper:
        options:
          iterables: List, Set, HashSet, UnmodifiableListView
```

## 自定义 Converter

```dart
class MoneyConverter implements ICustomConverter<Money> {
  const MoneyConverter();

  @override
  Money fromJSON(dynamic jsonValue, DeserializationContext context) {
    return Money.parse(jsonValue as String);
  }

  @override
  dynamic toJSON(Money object, SerializationContext context) {
    return object.toString();
  }
}

@JsonProperty(converter: MoneyConverter())
final Money price;
```

也可以通过 `JsonMapperAdapter` 为某个类型全局注册 Converter。

## 多态和继承

基类配置 discriminator 字段，子类配置对应值：

```dart
@jsonSerializable
@Json(discriminatorProperty: 'type')
abstract class Payment {}

@jsonSerializable
@Json(discriminatorValue: 'card')
class CardPayment extends Payment {
  final String cardNumber;

  CardPayment(this.cardNumber);
}

@jsonSerializable
@Json(discriminatorValue: 'cash')
class CashPayment extends Payment {}
```

反序列化 `Payment` 或 `List<Payment>` 时，会根据 `type` 选择实际子类。

## 嵌套路径

字段名支持类似 JSON Pointer 的路径：

```dart
@JsonProperty(name: 'data/user/id')
final int userId;
```

也可以从嵌套对象引用父级字段：

```dart
@JsonProperty(name: '../id')
final int parentId;
```

## 对象扁平化

```dart
@jsonSerializable
class Page {
  @JsonProperty(flatten: true)
  final Pagination pagination;

  final List<Item> items;

  Page(this.pagination, this.items);
}
```

`Pagination` 中的字段会直接写入 `Page` 对应的 JSON 对象。

## 值注入

```dart
@JsonProperty(inject: true)
final String requestId;
```

反序列化时提供：

```dart
final result = JsonMapper.deserialize<Model>(
  json,
  const DeserializationOptions(
    injectableValues: {'requestId': 'request-001'},
  ),
);
```

## Adapter

官方仓库提供以下补充包：

- `dart_json_mapper_flutter`
- `dart_json_mapper_mobx`
- `dart_json_mapper_built`
- `dart_json_mapper_fixnum`

以 Flutter Adapter 为例：

```yaml
dependencies:
  dart_json_mapper:
  dart_json_mapper_flutter:

dev_dependencies:
  build_runner:
```

初始化时注册 Adapter：

```dart
initializeJsonMapper(
  adapters: [flutterAdapter],
);
```

## 错误处理

常见异常包括：

- 目标类型没有添加 `@jsonSerializable`。
- 没有提供泛型目标类型。
- required 或 notNull 字段不符合要求。
- 多态 discriminator 值不存在。
- 构造函数参数无法满足。
- 序列化对象存在不允许的循环引用。

建议在网络层捕获 `JsonMapperError` 及其具体子类型，并记录目标类型和原始响应。

## 已知限制

- 修改模型后必须重新运行代码生成。
- 入口文件必须正确配置到 `build.yaml` 的 `generate_for`。
- 当前实现依赖生成的 reflectable 元数据。
- Dart 代码混淆可能破坏依赖类型名称的映射，不建议在开启相关混淆选项时使用。
- 全局 Mapper 配置和 Adapter 注册属于共享状态，应用初始化完成后不建议动态修改。

## 更多资料

英文 README 包含完整的注解参数、Scheme、枚举映射、Mixin、不可变对象、模板、
自定义 Iterable 和 Adapter 开发示例：

- [完整英文文档](README.md)
- [API 文档](https://pub.dev/documentation/dart_json_mapper/latest/)
- [GitHub 仓库](https://github.com/k-paxian/dart-json-mapper)
