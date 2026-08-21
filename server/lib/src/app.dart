import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';

import 'models.dart';

typedef LogSink = void Function(Map<String, Object?> entry);

class TripPickApi {
  TripPickApi({
    required RecommendationEngine engine,
    required this.allowedOrigin,
    LogSink? logger,
  }) : _engine = engine,
       _logger = logger ?? _writeLog;

  final RecommendationEngine _engine;
  final String allowedOrigin;
  final LogSink _logger;

  Handler get handler => _handle;

  Future<Response> _handle(Request request) async {
    final requestId = _requestId();
    final started = DateTime.now();
    final origin = request.headers['origin'];
    Response response;

    try {
      if (origin != null && origin != allowedOrigin) {
        response = _error(
          status: 403,
          code: 'ORIGIN_NOT_ALLOWED',
          message: 'Origin is not allowed.',
          retryable: false,
          requestId: requestId,
        );
      } else if (request.method == 'OPTIONS') {
        response = Response(204);
      } else if (request.method == 'GET' && request.url.path == 'health') {
        response = _json(200, {'status': 'ok'});
      } else if (request.method == 'POST' &&
          request.url.path == 'v1/recommendations') {
        response = await _recommend(request, requestId);
      } else {
        response = _error(
          status: 404,
          code: 'NOT_FOUND',
          message: 'Route not found.',
          retryable: false,
          requestId: requestId,
        );
      }
    } catch (_) {
      response = _error(
        status: 503,
        code: 'UPSTREAM_UNAVAILABLE',
        message: 'The recommendation service is temporarily unavailable.',
        retryable: true,
        requestId: requestId,
      );
    }

    final headers = <String, String>{
      'cache-control': 'no-store',
      'x-request-id': requestId,
      if (origin == allowedOrigin) ...{
        'access-control-allow-origin': allowedOrigin,
        'access-control-allow-methods': 'GET, POST, OPTIONS',
        'access-control-allow-headers': 'content-type',
        'vary': 'Origin',
      },
    };
    final completed = response.change(
      headers: {...response.headers, ...headers},
    );
    _logger({
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'event': 'request_completed',
      'requestId': requestId,
      'method': request.method,
      'path': request.url.path,
      'status': completed.statusCode,
      'durationMs': DateTime.now().difference(started).inMilliseconds,
    });
    return completed;
  }

  Future<Response> _recommend(Request request, String requestId) async {
    String body;
    try {
      body = await _readBody(request, maximumBytes: 32768);
    } on _PayloadTooLarge {
      return _error(
        status: 400,
        code: 'INVALID_REQUEST',
        message: 'The request body is too large.',
        retryable: false,
        requestId: requestId,
      );
    }

    Map<String, Object?> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) throw const FormatException();
      json = Map<String, Object?>.from(decoded);
    } catch (_) {
      return _error(
        status: 400,
        code: 'INVALID_JSON',
        message: 'The request body must be valid JSON.',
        retryable: false,
        requestId: requestId,
      );
    }

    final locale = json['locale'] == 'ja' ? 'ja' : 'en';
    RecommendationRequest recommendationRequest;
    try {
      recommendationRequest = RecommendationRequest.fromJson(json);
    } on ValidationFailure catch (failure) {
      return _error(
        status: 400,
        code: 'INVALID_REQUEST',
        message: locale == 'ja'
            ? '入力内容を確認してください。'
            : 'Please check the submitted preferences.',
        retryable: false,
        requestId: requestId,
        details: failure.details,
      );
    }

    try {
      final recommendations = await _engine.recommend(recommendationRequest);
      if (recommendations.length != 3) {
        throw const RecommendationEngineException(
          code: 'UPSTREAM_INVALID_RESPONSE',
          status: 502,
        );
      }
      return _json(200, {'recommendations': recommendations});
    } on RecommendationEngineException catch (failure) {
      return _error(
        status: failure.status,
        code: failure.code,
        message: _localizedFailure(failure.code, locale),
        retryable: failure.status >= 500,
        requestId: requestId,
      );
    }
  }

  String _localizedFailure(String code, String locale) {
    if (locale == 'ja') {
      return code == 'INSUFFICIENT_RESULTS'
          ? '条件に合う3つの旅先を確認できませんでした。もう一度お試しください。'
          : code == 'UPSTREAM_INVALID_RESPONSE'
          ? 'おすすめサービスから不完全な結果が返されました。'
          : 'おすすめサービスを一時的に利用できません。もう一度お試しください。';
    }
    return code == 'INSUFFICIENT_RESULTS'
        ? 'We could not verify three matching destinations. Please try again.'
        : code == 'UPSTREAM_INVALID_RESPONSE'
        ? 'The recommendation service returned incomplete results.'
        : 'The recommendation service is temporarily unavailable. Please try again.';
  }

  Response _json(int status, Map<String, Object?> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Response _error({
    required int status,
    required String code,
    required String message,
    required bool retryable,
    required String requestId,
    List<String>? details,
  }) {
    return _json(status, {
      'error': {
        'code': code,
        'message': message,
        'retryable': retryable,
        'requestId': requestId,
        'details': ?details,
      },
    });
  }

  Future<String> _readBody(Request request, {required int maximumBytes}) async {
    final declaredLength = request.contentLength;
    if (declaredLength != null && declaredLength > maximumBytes) {
      throw const _PayloadTooLarge();
    }
    final bytes = <int>[];
    await for (final chunk in request.read()) {
      if (bytes.length + chunk.length > maximumBytes) {
        throw const _PayloadTooLarge();
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  String _requestId() {
    final random = Random.secure();
    return List.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static void _writeLog(Map<String, Object?> entry) {
    stdout.writeln(jsonEncode(entry));
  }
}

class _PayloadTooLarge implements Exception {
  const _PayloadTooLarge();
}
