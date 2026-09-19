import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<void> Function()? refreshTokens,
  Future<void> Function()? logout,
}) {
  late final Dio dio;

  dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  final refreshLock = _AsyncLock();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;

        if (kDebugMode) {
          debugPrint('[API] ← ${response.requestOptions.method} ${response.requestOptions.uri} ($status)');
        }

        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
          return;
        }

        handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final isAuthCall = path.contains('/auth/');
        final alreadyRetried = error.requestOptions.extra['__retried'] == true;

        if (kDebugMode) {
          debugPrint('[API] ✕ ${error.requestOptions.method} ${error.requestOptions.uri}: ${error.type} status=$status');
        }

        // Автообновление токена при 401: только для НЕ /auth/*
        if (status == 401 && !isAuthCall && !alreadyRetried && refreshTokens != null) {
          try {
            await refreshLock.run(() async {
              await refreshTokens();
            });

            final newToken = tokenProvider?.call();
            final opts = error.requestOptions;

            opts.extra['__retried'] = true;

            if (newToken != null && newToken.isNotEmpty) {
              opts.headers['Authorization'] = 'Bearer $newToken';
            } else {
              opts.headers.remove('Authorization');
            }

            final response = await dio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (e) {
            // Если refresh не удался по причине 401/403 — корректно выходим.
            if (logout != null) {
              await logout();
            }
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}

class _AsyncLock {
  Future<void>? _running;

  Future<void> run(Future<void> Function() action) async {
    while (_running != null) {
      await _running;
    }
    final f = action();
    _running = f;
    try {
      await f;
    } finally {
      _running = null;
    }
  }
}