# lemon_net

> 更完整的接入示例请参阅[使用指南](doc/使用指南.md)，其中包含常用请求、文件上传下载、Cookie/JWT 本地持久化、退出登录清理和业务 JSON 反序列化方案。

`lemon_net` 是一个基于 Dio 的通用网络请求库。

它只负责 HTTP 请求相关的基础能力，不关心业务响应协议、数据序列化或界面交互。

## 快速开始

`lemon_net` 同时支持全局单例和独立客户端。简单项目可以初始化一次后在全局使用：

```dart
LemonNet.init('https://api.example.com');

final response = await LemonNet.instance.get('/users');
```

需要多域名或不同网络配置时，可以创建独立实例：

```dart
final uploadNet = LemonNet(
  'https://upload.example.com',
  receiveTimeout: const Duration(minutes: 5),
);

final response = await uploadNet.post('/upload', data: formData);
```

单例只是便捷入口，不会限制独立实例的使用。

### 单例生命周期

初始化全局实例：

```dart
LemonNet.init(
  'https://api.example.com',
  auth: [
    LemonAuth.session(),
    LemonAuth.bearer(() => accessToken),
  ],
);
```

访问全局实例：

```dart
final net = LemonNet.instance;
```

判断是否已经初始化：

```dart
if (LemonNet.isInitialized) {
  // 可以使用 LemonNet.instance
}
```

清理全局实例：

```dart
LemonNet.reset();
```

在调用 `init` 前访问 `instance` 会抛出清晰的 `StateError`。重复调用 `init` 时，库会关闭并替换旧的全局实例，避免连接资源泄漏。`reset` 用于退出、测试隔离或重新初始化，并会关闭当前全局实例。

## 设计边界

`lemon_net` 负责：

- 管理 Dio 实例和基础配置
- 发起 GET、POST、PUT、PATCH、DELETE 等 HTTP 请求
- 透传请求参数、请求体、请求头和 Dio `Options`
- 支持 `CancelToken`
- 支持上传、下载以及进度回调
- 支持注入自定义 Dio 实例和拦截器
- 支持同时启用多种认证方式
- 返回完整的 Dio `Response<T>`

`lemon_net` 不负责：

- 判断业务 `code`
- 提取 `data`、`message` 或分页信息
- JSON 与业务实体之间的序列化和反序列化
- 具体项目的登录接口和认证响应协议
- Cookie 的具体持久化方式
- Toast、页面跳转或登录失效处理

这些能力应由使用方的业务网络层或拦截器实现。

## 认证

第一版支持多个认证提供器同时存在，例如 Session Cookie、Bearer/JWT 和自定义 Header Token。认证能力通过有序的提供器链执行，不把具体项目的登录接口、Token 响应结构或存储实现写死在库中。

```dart
final net = LemonNet(
  'https://api.example.com',
  auth: [
    LemonAuth.session(),
    LemonAuth.bearer(() => jwt),
    LemonAuth.token(
      () => token,
      header: 'X-Token',
    ),
  ],
);
```

认证提供器按照注册顺序处理请求和响应。每个提供器具有唯一名称，单次请求可以使用全部认证、只选择指定认证，或完全跳过认证：

```dart
// 使用客户端配置的全部认证提供器。
await net.get('/profile');

// 只使用指定认证提供器。
await net.get(
  '/jwt/profile',
  authNames: {'jwt'},
);

// 登录、刷新凭证等请求可以跳过认证。
await net.post(
  '/login',
  skipAuth: true,
);
```

第一版认证范围包括：

- Session/Cookie 的自动接收和发送
- `Authorization: Bearer <token>` 形式的 JWT 或 Access Token
- 可配置 Header 名称和前缀的普通 Token
- 从响应 Header 更新 Token
- 凭证读取、写入和清除接口
- 按 host 或自定义 scope 隔离凭证
- 多个认证提供器的组合、筛选和跳过

凭证存储通过抽象接口由使用方注入。基础库不强制使用 Hive、SharedPreferences 或 SecureStorage。

当多个提供器写入同一个 Header 时，后注册的提供器不能静默覆盖已有值。默认应抛出配置冲突异常；需要覆盖时必须由使用方显式配置。

JWT Payload 解析、角色权限判断、登录页面跳转以及具体项目的刷新 Token 协议不属于基础认证传输能力。

由于所有 HTTP 状态码默认正常返回，内置刷新策略会在响应处理阶段识别 401，使用 single-flight 刷新凭证，并安全地重放一次可重放请求。

### Session 与 Token 同时认证

真实项目可能同时依赖持久化 Session Cookie 和响应 Header 中持续更新的 Token：

```dart
LemonNet.init(
  'https://api.example.com',
  auth: [
    LemonAuth.session(cookieJar: persistentCookieJar),
    LemonAuth.token(
      loadToken,
      header: 'Authorization',
      responseHeader: 'Authorization',
      save: saveToken,
    ),
  ],
);
```

Token 认证需要满足：

- Token 为空时不添加认证 Header
- 每次请求前读取最新 Token
- 从所有有效 HTTP 响应的指定 Header 更新 Token
- 支持按照请求 host 或自定义 scope 隔离 Token
- 请求可以使用全部认证、选择部分认证或跳过认证

Session 默认可以使用内存 Cookie。持久化实现及存储位置应允许调用方配置，不与 Hive、SharedPreferences 或 SecureStorage 强绑定。

## HTTP 状态码策略

只要服务器返回了有效的 HTTP 响应，`lemon_net` 默认将所有 HTTP 状态码作为正常响应返回，包括 2xx、3xx、4xx 和 5xx。

默认配置等价于：

```dart
BaseOptions(
  validateStatus: (status) => status != null,
  receiveDataWhenStatusError: true,
)
```

因此，400、401、403、404、500 等响应不会因为状态码而进入 `catch`。调用方需要根据 `Response.statusCode` 自行处理：

```dart
final response = await net.get<Map<String, dynamic>>('/user');

switch (response.statusCode) {
  case 200:
    // 处理成功响应
    break;
  case 401:
    // 处理未认证响应
    break;
  case 500:
    // 处理服务端异常响应
    break;
}
```

调用方仍可通过 Dio 的 `BaseOptions` 或单次请求的 `Options` 覆盖 `validateStatus`。

Dio 默认可能自动跟随 3xx 重定向，因此调用方通常收到最终响应。需要取得原始 3xx 时，可以为请求设置 `followRedirects: false`。

## 异常策略

没有获得有效 HTTP 响应时，请求仍会抛出 Dio `DioException`，例如：

- 连接、发送或接收超时
- DNS 解析或网络连接失败
- 请求被取消
- TLS 或证书错误
- Dio 转换阶段发生异常

这类异常通常没有 `statusCode`，调用方应通过 `DioException.type` 判断。`lemon_net` 不会吞掉或替换原始 Dio 异常。

## API 方向

核心请求方法直接返回 `Future<Response<T>>`：

```dart
Future<Response<T>> get<T>(...);
Future<Response<T>> post<T>(...);
Future<Response<T>> put<T>(...);
Future<Response<T>> patch<T>(...);
Future<Response<T>> delete<T>(...);
Future<Response<T>> request<T>(...);
```

业务层可以在收到原始响应后自行解析：

```dart
final Response<Map<String, dynamic>> response =
    await net.post<Map<String, dynamic>>(
  '/user/login',
  data: {
    'username': username,
    'password': password,
  },
);

final body = response.data;
// 从这里开始由业务层判断业务状态并完成序列化。
```

### 表单上传

上传直接使用 Dio `FormData`，不在基础库中定义业务文件字段：

```dart
final form = FormData.fromMap({
  ...params,
  'file0': await MultipartFile.fromFile(file0),
  'file1': await MultipartFile.fromFile(file1),
});

await LemonNet.instance.post(
  '/upload',
  data: form,
  onSendProgress: onProgress,
);
```

### 文件下载

下载支持固定保存路径、Dio 动态保存路径、取消、进度和单次超时配置：

```dart
await LemonNet.instance.download(
  url,
  savePath,
  cancelToken: cancelToken,
  onReceiveProgress: onProgress,
  options: Options(
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ),
);
```

### 可选日志

日志默认关闭。传入日志函数即可启用，认证 Header、Cookie 和自定义 Token Header 会被脱敏：

```dart
final net = LemonNet(
  'https://api.example.com',
  logger: print,
);
```

### 业务层适配

业务项目可以在 `lemon_net` 之上继续封装自己的响应协议。由于所有 HTTP 状态码都会正常返回，业务适配层应先判断 HTTP 状态码，再处理业务 `code` 和序列化：

```dart
final response = await LemonNet.instance.post<Map<String, dynamic>>(
  path,
  data: params,
);

final statusCode = response.statusCode;
if (statusCode == null || statusCode < 200 || statusCode >= 300) {
  throw AppHttpException.fromResponse(response);
}

final body = response.data;
// 判断业务 code、提取 data 和实体转换均由业务层完成。
```

## 功能范围

当前包含：

- 单例和独立客户端
- GET、POST、PUT、PATCH、DELETE 和通用 `request`
- 所有 HTTP 状态码正常返回
- Session Cookie 及可选持久化
- 普通 Header Token 和 Bearer/JWT
- 多重认证、认证筛选及跳过认证
- 从响应 Header 更新 Token
- 按 host 或自定义 scope 隔离凭证
- `FormData` 多文件上传
- 固定或动态路径文件下载
- 上传和下载进度
- 客户端默认超时及单次请求覆盖
- `CancelToken`
- 自定义 Dio 和拦截器
- 原始 `Response<T>` 和 `DioException`
- 客户端关闭、单例替换和重置
- 日志及认证信息脱敏
- Token 自动刷新、并发刷新锁和一次请求重放
- 幂等请求安全重试与指数退避
- 可插拔业务响应解析
- 断点下载、分片上传辅助和 SHA-256 校验
- 可选内存缓存、GET 请求去重和并发控制

当前不包含：

- 业务响应实体和业务状态码判断
- JSON 与实体之间的序列化
- 分页模型
- Toast、页面跳转和登录页面处理
- JWT Payload 和角色权限解析
- 全局共享 `CancelToken`
- 关闭 TLS 证书校验的快捷开关

## 实现原则

- 支持可选全局单例，同时保留独立客户端实例
- 不使用所有请求共享的 `CancelToken`
- 尽量透传 Dio 原生类型，避免重复设计配置对象
- 不隐藏底层 Dio，保留高级配置和扩展能力
- 基础库保持与具体项目和业务协议无关
