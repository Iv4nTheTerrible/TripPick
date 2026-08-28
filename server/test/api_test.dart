import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:trip_pick_server/trip_pick_server.dart';

const _validRequest = {
  'originCountry': 'JP',
  'scope': 'domestic',
  'budgetLevel': 'medium',
  'tripDays': 4,
  'interests': ['food', 'culture'],
  'travelMonth': 10,
  'locale': 'en',
};

void main() {
  late TripPickApi api;

  setUp(() {
    api = TripPickApi(
      engine: const FakeRecommendationEngine(),
      allowedOrigin: 'http://localhost:3000',
      logger: (_) {},
    );
  });

  test('health endpoint responds without credentials', () async {
    final response = await api.handler(
      Request('GET', Uri.parse('http://localhost/health')),
    );
    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), {'status': 'ok'});
  });

  test('fake endpoint returns three complete results', () async {
    final response = await api.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/recommendations'),
        headers: {
          'origin': 'http://localhost:3000',
          'content-type': 'application/json',
        },
        body: jsonEncode(_validRequest),
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map;
    final recommendations = body['recommendations'] as List;
    expect(response.statusCode, 200);
    expect(
      response.headers['access-control-allow-origin'],
      'http://localhost:3000',
    );
    expect(recommendations, hasLength(3));
    for (final item in recommendations.cast<Map>()) {
      expect(item['highlights'], hasLength(3));
    }
  });

  test('rejects malformed preferences with a safe 400 response', () async {
    final invalid = {..._validRequest, 'tripDays': 0};
    final response = await api.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/recommendations'),
        body: jsonEncode(invalid),
      ),
    );
    final body = jsonDecode(await response.readAsString()) as Map;
    expect(response.statusCode, 400);
    expect((body['error'] as Map)['code'], 'INVALID_REQUEST');
    expect((body['error'] as Map)['retryable'], isFalse);
  });

  test('rejects unapproved browser origins', () async {
    final response = await api.handler(
      Request(
        'OPTIONS',
        Uri.parse('http://localhost/v1/recommendations'),
        headers: {'origin': 'https://example.com'},
      ),
    );
    expect(response.statusCode, 403);
    expect(response.headers['access-control-allow-origin'], isNull);
  });
}
