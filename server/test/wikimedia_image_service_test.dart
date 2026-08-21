import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:trip_pick_server/trip_pick_server.dart';

void main() {
  test('maps a Wikipedia lead image and Commons attribution', () async {
    final requestedHosts = <String>[];
    final resolver = WikimediaImageResolver(
      client: MockClient((request) async {
        requestedHosts.add(request.url.host);
        expect(request.headers['user-agent'], contains('TripPick/1.0'));
        return request.url.host == 'en.wikipedia.org'
            ? http.Response(_articleResponse, 200)
            : http.Response(_commonsResponse(), 200);
      }),
    );

    final photo = await resolver.resolve(
      imageSearchTerm: 'Kyoto',
      countryCode: 'JP',
    );

    expect(requestedHosts, ['en.wikipedia.org', 'commons.wikimedia.org']);
    expect(photo.url, 'https://upload.wikimedia.org/kyoto.jpg');
    expect(photo.attribution, 'Jane Doe · CC BY-SA 4.0');
    expect(
      photo.sourceUrl,
      'https://commons.wikimedia.org/wiki/File:Kyoto.jpg',
    );
    expect(photo.licenseUrl, 'https://creativecommons.org/licenses/by-sa/4.0/');
  });

  test(
    'caches successful and empty results for the configured duration',
    () async {
      var calls = 0;
      var now = DateTime(2026, 8, 21);
      final resolver = WikimediaImageResolver(
        client: MockClient((request) async {
          calls++;
          return request.url.host == 'en.wikipedia.org'
              ? http.Response(_articleResponse, 200)
              : http.Response(_commonsResponse(), 200);
        }),
        clock: () => now,
      );

      await resolver.resolve(imageSearchTerm: 'Kyoto', countryCode: 'JP');
      await resolver.resolve(imageSearchTerm: 'kyoto', countryCode: 'jp');
      expect(calls, 2);

      now = now.add(const Duration(hours: 25));
      await resolver.resolve(imageSearchTerm: 'Kyoto', countryCode: 'JP');
      expect(calls, 4);
    },
  );

  test('returns empty when an article has no lead image', () async {
    final resolver = WikimediaImageResolver(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'query': {
              'pages': [
                {'pageid': 1, 'title': 'Unknown'},
              ],
            },
          }),
          200,
        ),
      ),
    );
    final photo = await resolver.resolve(
      imageSearchTerm: 'Unknown',
      countryCode: 'ZZ',
    );
    expect(photo.isEmpty, isTrue);
  });

  for (final status in [429, 500]) {
    test('retries once after HTTP $status', () async {
      var calls = 0;
      final delays = <Duration>[];
      final resolver = WikimediaImageResolver(
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response('', status, headers: {'retry-after': '0'});
          }
          return request.url.host == 'en.wikipedia.org'
              ? http.Response(_articleResponse, 200)
              : http.Response(_commonsResponse(), 200);
        }),
        delay: (duration) async => delays.add(duration),
      );
      final photo = await resolver.resolve(
        imageSearchTerm: 'Kyoto',
        countryCode: 'JP',
      );
      expect(photo.isEmpty, isFalse);
      expect(calls, 3);
      expect(delays, hasLength(1));
    });
  }

  test('returns empty for malformed metadata and non-image media', () async {
    var commonsCalls = 0;
    final resolver = WikimediaImageResolver(
      client: MockClient((request) async {
        if (request.url.host == 'en.wikipedia.org') {
          return http.Response(_articleResponse, 200);
        }
        commonsCalls++;
        return http.Response(
          _commonsResponse(mime: 'application/pdf', includeArtist: false),
          200,
        );
      }),
    );
    final photo = await resolver.resolve(
      imageSearchTerm: 'Kyoto',
      countryCode: 'JP',
    );
    expect(commonsCalls, 1);
    expect(photo.isEmpty, isTrue);
  });

  test('times out, retries once, and returns empty without throwing', () async {
    var calls = 0;
    final resolver = WikimediaImageResolver(
      client: MockClient((_) {
        calls++;
        return Completer<http.Response>().future;
      }),
      requestTimeout: const Duration(milliseconds: 1),
      delay: (_) async {},
    );
    final photo = await resolver.resolve(
      imageSearchTerm: 'Kyoto',
      countryCode: 'JP',
    );
    expect(calls, 2);
    expect(photo.isEmpty, isTrue);
  });
}

final _articleResponse = jsonEncode({
  'query': {
    'pages': [
      {'pageid': 1, 'title': 'Kyoto', 'pageimage': 'Kyoto.jpg'},
    ],
  },
});

String _commonsResponse({
  String mime = 'image/jpeg',
  bool includeArtist = true,
}) => jsonEncode({
  'query': {
    'pages': [
      {
        'pageid': 2,
        'title': 'File:Kyoto.jpg',
        'imageinfo': [
          {
            'mime': mime,
            'thumburl': 'https://upload.wikimedia.org/kyoto.jpg',
            'descriptionurl':
                'https://commons.wikimedia.org/wiki/File:Kyoto.jpg',
            'extmetadata': {
              if (includeArtist) 'Artist': {'value': '<a>Jane Doe</a>'},
              'LicenseShortName': {'value': 'CC BY-SA 4.0'},
              'LicenseUrl': {
                'value': 'https://creativecommons.org/licenses/by-sa/4.0/',
              },
            },
          },
        ],
      },
    ],
  },
});
