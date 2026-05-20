import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';

import '../app_constants.dart';
import '../errors.dart';

/// Logging interceptor — prints request/response in debug mode only.
class LoggingInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final request = chain.request;
    if (kDebugMode) {
      debugPrint('[Chopper] --> ${request.method} ${request.url}');
      if (request.body != null) debugPrint('[Chopper] body: ${request.body}');
    }

    final response = await chain.proceed(request);

    if (kDebugMode) {
      debugPrint(
        '[Chopper] <-- ${response.statusCode} ${response.base.request?.url}',
      );
    }

    return response;
  }
}

/// Adds 'Content-Type: application/json' to every outgoing request.
class JsonHeaderInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) {
    final modifiedRequest = applyHeader(chain.request, 'Content-Type', 'application/json');
    return chain.proceed(modifiedRequest);
  }
}

/// Centralised error handler — converts non-2xx responses into [NetworkException].
class ErrorInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final response = await chain.proceed(chain.request);

    if (!response.isSuccessful) {
      throw NetworkException(
        statusCode: response.statusCode,
        message: _messageFor(response.statusCode),
      );
    }
    return response;
  }

  String _messageFor(int code) => switch (code) {
    400 => 'Bad request',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'Not found',
    408 => 'Request timeout',
    429 => 'Too many requests',
    500 => 'Internal server error',
    503 => 'Service unavailable',
    _ => 'HTTP error $code',
  };
}

/// Builds and returns a configured [ChopperClient].
ChopperClient buildChopperClient({List<ChopperService> services = const []}) {
  return ChopperClient(
    baseUrl: Uri.parse(AppConstants.baseUrl),
    services: services,
    converter: const JsonConverter(),
    interceptors: [
      JsonHeaderInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ],
  );
}