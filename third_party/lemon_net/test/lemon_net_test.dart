import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lemon_net/lemon_net.dart';
import 'package:test/test.dart';

void main() {
  tearDown(LemonNet.reset);

  group('LemonNet', () {
    test('refreshes a token once and replays a 401 request', () async {
      var token = 'expired';
      var refreshes = 0;
      var requests = 0;
      final net = _client(
        auth: [LemonAuth.bearer(() => token)],
        refreshPolicy: LemonRefreshPolicy(
          refresh: () async {
            refreshes++;
            token = 'fresh';
            return true;
          },
        ),
        maxConcurrentRequests: 1,
        adapter: _FakeAdapter((options) {
          requests++;
          final authorized = options.headers['Authorization'] == 'Bearer fresh';
          return ResponseBody.fromString(
            '{}',
            authorized ? 200 : 401,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }),
      );

      final response = await net.get<Map<String, dynamic>>('/protected');

      expect(response.statusCode, 200);
      expect(refreshes, 1);
      expect(requests, 2);
    });

    test('shares one refresh across concurrent 401 responses', () async {
      var token = 'expired';
      var refreshes = 0;
      final net = _client(
        auth: [LemonAuth.bearer(() => token)],
        refreshPolicy: LemonRefreshPolicy(
          refresh: () async {
            refreshes++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            token = 'fresh';
            return true;
          },
        ),
        maxConcurrentRequests: 2,
        adapter: _FakeAdapter(
          (options) => ResponseBody.fromString(
            '{}',
            options.headers['Authorization'] == 'Bearer fresh' ? 200 : 401,
          ),
        ),
      );

      final responses = await Future.wait([
        net.get<dynamic>('/first'),
        net.get<dynamic>('/second'),
      ]);

      expect(responses.map((response) => response.statusCode), [200, 200]);
      expect(refreshes, 1);
    });

    test('retries idempotent requests but not POST by default', () async {
      var getCount = 0;
      var postCount = 0;
      final net = _client(
        retryPolicy: const LemonRetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration.zero,
        ),
        maxConcurrentRequests: 1,
        adapter: _FakeAdapter((options) {
          final isGet = options.method == 'GET';
          final count = isGet ? ++getCount : ++postCount;
          return ResponseBody.fromString('{}', count < 2 ? 503 : 200);
        }),
      );

      expect((await net.get<dynamic>('/retry')).statusCode, 200);
      expect((await net.post<dynamic>('/no-retry')).statusCode, 503);
      expect(getCount, 2);
      expect(postCount, 1);
    });

    test('parses a configured business response envelope', () async {
      final net = _client(
        responseParser: const LemonJsonResponseParser(),
        adapter: _FakeAdapter(
          (_) => ResponseBody.fromString(
            jsonEncode({
              'code': 0,
              'message': 'ok',
              'data': {'id': 7},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        ),
      );

      final response = await net.get<Map<String, dynamic>>('/user');
      final id = net.parse<int>(
        response,
        (data) => (data as Map<String, dynamic>)['id'] as int,
      );

      expect(id, 7);
    });

    test('caches and deduplicates GET requests', () async {
      var requests = 0;
      final net = _client(
        cachePolicy: const LemonCachePolicy(ttl: Duration(minutes: 1)),
        deduplicateRequests: true,
        adapter: _FakeAdapter((_) async {
          requests++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return ResponseBody.fromString(
            '{"value":1}',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }),
      );

      final concurrent = await Future.wait([
        net.get<Map<String, dynamic>>('/cached'),
        net.get<Map<String, dynamic>>('/cached'),
      ]);
      final cached = await net.get<Map<String, dynamic>>('/cached');

      expect(requests, 1);
      expect(concurrent, hasLength(2));
      expect(cached.extra['lemonNetFromCache'], isTrue);
    });

    test('limits concurrent network requests', () async {
      var active = 0;
      var peak = 0;
      final net = _client(
        maxConcurrentRequests: 2,
        adapter: _FakeAdapter((_) async {
          active++;
          if (active > peak) peak = active;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          active--;
          return ResponseBody.fromString('{}', 200);
        }),
      );

      await Future.wait(
        List.generate(5, (index) => net.get<dynamic>('/$index')),
      );
      expect(peak, 2);
    });

    test('resumes downloads and calculates file hashes', () async {
      final directory = await Directory.systemTemp.createTemp('lemon_net_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/file.txt');
      await file.writeAsString('hello ');
      String? range;
      final net = _client(
        adapter: _FakeAdapter((options) {
          range = options.headers['range'] as String?;
          return ResponseBody.fromString(
            'world',
            206,
            headers: {
              Headers.contentLengthHeader: ['5'],
            },
          );
        }),
      );

      final result = await net.downloadResumable('/file', file.path);

      expect(range, 'bytes=6-');
      expect(result.resumedFrom, 6);
      expect(await file.readAsString(), 'hello world');
      expect(
        await lemonFileSha256(file.path),
        'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9',
      );
    });

    test('splits uploads into resumable chunks', () async {
      final directory = await Directory.systemTemp.createTemp('lemon_net_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/upload.bin');
      await file.writeAsBytes([0, 1, 2, 3, 4]);
      final chunks = <LemonUploadChunk>[];

      await lemonUploadFileInChunks(
        file.path,
        uploadId: 'upload-1',
        chunkSize: 2,
        uploadChunk: (chunk) async => chunks.add(chunk),
      );

      expect(chunks.map((chunk) => chunk.bytes), [
        [0, 1],
        [2, 3],
        [4],
      ]);
      expect(chunks.last.isLast, isTrue);
      expect(chunks.last.contentRange, 'bytes 4-4/5');
    });

    test('resolves download names with safe fallbacks', () {
      final encodedHeaders = Headers.fromMap({
        'content-disposition': [
          "attachment; filename*=UTF-8''%E6%8A%A5%E5%91%8A.pdf",
        ],
      });
      expect(
        LemonDownloadFileName.resolve(
          headers: encodedHeaders,
          requestPath: '/files/export',
        ),
        '报告.pdf',
      );

      final pathHeaders = Headers.fromMap({
        Headers.contentTypeHeader: ['image/png'],
      });
      expect(
        LemonDownloadFileName.resolve(
          headers: pathHeaders,
          requestPath: '/files/avatar?size=large',
        ),
        'avatar.png',
      );

      final invalidHeader = Headers.fromMap({
        'content-disposition': ['attachment; filename="../bad:name.pdf"'],
      });
      expect(
        LemonDownloadFileName.resolve(
          headers: invalidHeader,
          requestPath: '/ignored',
        ),
        'bad_name.pdf',
      );

      expect(
        LemonDownloadFileName.resolve(
          headers: Headers(),
          requestPath: '/',
          fallbackFileName: 'fallback.txt',
        ),
        'fallback.txt',
      );
    });

    test('returns 400 and 500 responses normally', () async {
      final adapter = _FakeAdapter((options) {
        final status = int.parse(options.path.substring(1));
        return ResponseBody.fromString(
          jsonEncode({'status': status}),
          status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      final net = _client(adapter: adapter);

      expect((await net.get<Map<String, dynamic>>('/400')).statusCode, 400);
      expect((await net.get<Map<String, dynamic>>('/500')).statusCode, 500);
    });

    test('allows one request to override the status policy', () async {
      final net = _client(
        adapter: _FakeAdapter((_) => ResponseBody.fromString('failed', 500)),
      );

      await expectLater(
        net.get<dynamic>(
          '/500',
          options: Options(validateStatus: (status) => status == 200),
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );
    });

    test('supports singleton initialization, replacement and reset', () {
      final first = LemonNet.init('https://first.example');
      final second = LemonNet.init('https://second.example');

      expect(first.isClosed, isTrue);
      expect(LemonNet.instance, same(second));
      expect(LemonNet.isInitialized, isTrue);

      LemonNet.reset();
      expect(LemonNet.isInitialized, isFalse);
      expect(() => LemonNet.instance, throwsStateError);
    });

    test(
      'applies multiple auth providers and updates response token',
      () async {
        var token = 'old-token';
        late RequestOptions captured;
        final net = _client(
          auth: [
            LemonAuth.bearer(() => 'jwt-value'),
            LemonAuth.token(
              () => token,
              name: 'device',
              header: 'X-Token',
              responseHeader: 'X-Token',
              save: (value) => token = value,
            ),
          ],
          adapter: _FakeAdapter((options) {
            captured = options;
            return ResponseBody.fromString(
              '{}',
              401,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
                'X-Token': ['new-token'],
              },
            );
          }),
        );

        final response = await net.get<Map<String, dynamic>>('/protected');

        expect(response.statusCode, 401);
        expect(captured.headers['Authorization'], 'Bearer jwt-value');
        expect(captured.headers['X-Token'], 'old-token');
        expect(token, 'new-token');
      },
    );

    test('can select or skip authentication per request', () async {
      final captured = <RequestOptions>[];
      final net = _client(
        auth: [
          LemonAuth.token(() => 'a', name: 'a', header: 'X-A'),
          LemonAuth.token(() => 'b', name: 'b', header: 'X-B'),
        ],
        adapter: _FakeAdapter((options) {
          captured.add(options);
          return ResponseBody.fromString('{}', 200);
        }),
      );

      await net.get<dynamic>('/selected', authNames: {'a'});
      await net.get<dynamic>('/none', skipAuth: true);

      expect(captured[0].headers['X-A'], 'a');
      expect(captured[0].headers.containsKey('X-B'), isFalse);
      expect(captured[1].headers.containsKey('X-A'), isFalse);
      expect(captured[1].headers.containsKey('X-B'), isFalse);
    });

    test('rejects conflicting authentication headers', () async {
      final net = _client(
        auth: [
          LemonAuth.token(() => 'a', name: 'a'),
          LemonAuth.token(() => 'b', name: 'b'),
        ],
      );

      await expectLater(
        net.get<dynamic>('/conflict'),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'error',
            isA<LemonAuthConflictException>(),
          ),
        ),
      );
    });

    test('passes the real host to scoped credentials', () async {
      String? host;
      final net = _client(
        auth: [
          LemonAuth.scopedToken((context) {
            host = context.host;
            return 'token';
          }),
        ],
      );

      await net.get<dynamic>('/scope');
      expect(host, 'api.example.com');
    });

    test('throws after an owned client is closed', () {
      final net = LemonNet('https://api.example.com');
      net.close();
      expect(() => net.get<dynamic>('/closed'), throwsStateError);
    });

    test('stores and sends session cookies', () async {
      var requestCount = 0;
      String? sentCookie;
      final net = _client(
        auth: [LemonAuth.session()],
        adapter: _FakeAdapter((options) {
          requestCount++;
          if (requestCount == 2) {
            sentCookie = options.headers['cookie'] as String?;
          }
          return ResponseBody.fromString(
            '{}',
            200,
            headers: requestCount == 1
                ? {
                    Headers.contentTypeHeader: ['application/json'],
                    'set-cookie': ['SESSION=abc; Path=/'],
                  }
                : {
                    Headers.contentTypeHeader: ['application/json'],
                  },
          );
        }),
      );

      await net.get<dynamic>('/login');
      await net.get<dynamic>('/profile');

      expect(sentCookie, contains('SESSION=abc'));
    });

    test('optional logger redacts authentication headers', () async {
      final messages = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = _FakeAdapter.success();
      final net = LemonNet.fromDio(
        dio,
        auth: [LemonAuth.token(() => 'top-secret', header: 'X-Token')],
        logger: messages.add,
      );

      await net.get<dynamic>('/logged');

      expect(messages.join('\n'), contains('X-Token: <redacted>'));
      expect(messages.join('\n'), isNot(contains('top-secret')));
    });
  });
}

LemonNet _client({
  List<LemonAuth> auth = const [],
  HttpClientAdapter? adapter,
  LemonRefreshPolicy? refreshPolicy,
  LemonRetryPolicy? retryPolicy,
  LemonCachePolicy? cachePolicy,
  bool deduplicateRequests = false,
  int? maxConcurrentRequests,
  LemonResponseParser? responseParser,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = adapter ?? _FakeAdapter.success();
  return LemonNet.fromDio(
    dio,
    auth: auth,
    refreshPolicy: refreshPolicy,
    retryPolicy: retryPolicy,
    cachePolicy: cachePolicy,
    deduplicateRequests: deduplicateRequests,
    maxConcurrentRequests: maxConcurrentRequests,
    responseParser: responseParser,
  );
}

final class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  factory _FakeAdapter.success() => _FakeAdapter(
    (_) => ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    ),
  );

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}
