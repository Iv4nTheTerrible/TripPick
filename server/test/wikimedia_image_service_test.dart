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

  test('caches successful results for the configured duration', () async {
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
  });

  test('expires empty results after the shorter cache duration', () async {
    var calls = 0;
    var now = DateTime(2026, 8, 21);
    final resolver = WikimediaImageResolver(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'query': {
              'pages': [
                {'pageid': 1, 'title': 'Unknown'},
              ],
            },
          }),
          200,
        );
      }),
      clock: () => now,
      emptyCacheDuration: const Duration(minutes: 5),
    );

    await resolver.resolve(imageSearchTerm: 'Unknown', countryCode: 'ZZ');
    now = now.add(const Duration(minutes: 4));
    await resolver.resolve(imageSearchTerm: 'unknown', countryCode: 'zz');
    expect(calls, 2);

    now = now.add(const Duration(minutes: 2));
    await resolver.resolve(imageSearchTerm: 'Unknown', countryCode: 'ZZ');
    expect(calls, 4);
  });

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

  test(
    'rejects a non-geographic exact match and finds an alternate city spelling',
    () async {
      var searchQuery = '';
      final requestedUrls = <Uri>[];
      final resolver = WikimediaImageResolver(
        client: MockClient((request) async {
          requestedUrls.add(request.url);
          if (request.url.host == 'commons.wikimedia.org') {
            return http.Response(_commonsResponse(), 200);
          }
          if (request.url.queryParameters['generator'] == 'search') {
            searchQuery = request.url.queryParameters['gsrsearch'] ?? '';
            return http.Response.bytes(
              utf8.encode(_hueArticleResponse),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            );
          }
          return http.Response(
            jsonEncode({
              'query': {
                'pages': [
                  {
                    'pageid': 1,
                    'title': 'Hue',
                    'pageimage': 'Hue_color_solid_box.svg',
                    'terms': {
                      'description': ['property of light'],
                    },
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final photo = await resolver.resolve(
        imageSearchTerm: 'Hue',
        countryCode: 'VN',
      );

      expect(requestedUrls.map((uri) => uri.host), [
        'en.wikipedia.org',
        'en.wikipedia.org',
        'commons.wikimedia.org',
      ]);
      expect(photo.url, 'https://upload.wikimedia.org/kyoto.jpg');
      expect(searchQuery, 'Hue Vietnam city');
    },
  );

  test(
    'uses Wikidata country claims and caches the expected country entity',
    () async {
      var countryLookups = 0;
      final resolver = WikimediaImageResolver(
        client: MockClient((request) async {
          if (request.url.host == 'commons.wikimedia.org') {
            return http.Response(_commonsResponse(), 200);
          }
          if (request.url.host == 'www.wikidata.org') {
            final entityId = request.url.queryParameters['ids']!;
            return http.Response(
              _wikidataCountryResponse(entityId, 'Q884'),
              200,
            );
          }

          final title = request.url.queryParameters['titles'];
          if (title == 'South Korea') {
            countryLookups++;
            return http.Response(_countryResponse('South Korea', 'Q884'), 200);
          }
          final entityId = title == 'Seoul' ? 'Q8684' : 'Q16520';
          return http.Response(
            _cityResponse(
              title: title ?? '',
              entityId: entityId,
              description: 'metropolitan city in the Republic of Korea',
            ),
            200,
          );
        }),
      );

      final seoul = await resolver.resolve(
        imageSearchTerm: 'Seoul',
        countryCode: 'KR',
      );
      final busan = await resolver.resolve(
        imageSearchTerm: 'Busan',
        countryCode: 'KR',
      );

      expect(seoul.isEmpty, isFalse);
      expect(busan.isEmpty, isFalse);
      expect(countryLookups, 1);
    },
  );

  test(
    'falls back to the country description when Wikidata is unavailable',
    () async {
      var wikidataCalls = 0;
      final resolver = WikimediaImageResolver(
        client: MockClient((request) async {
          if (request.url.host == 'commons.wikimedia.org') {
            return http.Response(_commonsResponse(), 200);
          }
          if (request.url.host == 'www.wikidata.org') {
            wikidataCalls++;
            return http.Response('', 503);
          }
          if (request.url.queryParameters['titles'] == 'Japan') {
            return http.Response(_countryResponse('Japan', 'Q17'), 200);
          }
          return http.Response(
            _cityResponse(
              title: 'Kyoto',
              entityId: 'Q34600',
              description: 'city in Kyoto Prefecture, Japan',
            ),
            200,
          );
        }),
        delay: (_) async {},
      );

      final photo = await resolver.resolve(
        imageSearchTerm: 'Kyoto',
        countryCode: 'JP',
      );

      expect(photo.isEmpty, isFalse);
      expect(wikidataCalls, 2);
    },
  );

  test('uses a safe creator fallback when Commons omits the artist', () async {
    final resolver = WikimediaImageResolver(
      client: MockClient(
        (request) async => request.url.host == 'en.wikipedia.org'
            ? http.Response(_articleResponse, 200)
            : http.Response(_commonsResponse(includeArtist: false), 200),
      ),
    );

    final photo = await resolver.resolve(
      imageSearchTerm: 'Kyoto',
      countryCode: 'JP',
    );

    expect(photo.isEmpty, isFalse);
    expect(photo.attribution, 'Wikimedia Commons contributor · CC BY-SA 4.0');
  });

  test('upgrades a Creative Commons HTTP license URL to HTTPS', () async {
    final resolver = WikimediaImageResolver(
      client: MockClient(
        (request) async => request.url.host == 'en.wikipedia.org'
            ? http.Response(_articleResponse, 200)
            : http.Response(
                _commonsResponse(
                  licenseUrl: 'http://creativecommons.org/licenses/by-sa/3.0/',
                ),
                200,
              ),
      ),
    );

    final photo = await resolver.resolve(
      imageSearchTerm: 'Tokyo',
      countryCode: 'JP',
    );

    expect(photo.isEmpty, isFalse);
    expect(photo.licenseUrl, 'https://creativecommons.org/licenses/by-sa/3.0/');
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
    expect(calls, 4);
    expect(photo.isEmpty, isTrue);
  });
}

final _articleResponse = jsonEncode({
  'query': {
    'pages': [
      {
        'pageid': 1,
        'title': 'Kyoto',
        'pageimage': 'Kyoto.jpg',
        'coordinates': [
          {'lat': 35.0116, 'lon': 135.7681},
        ],
        'terms': {
          'description': ['city in Kyoto Prefecture, Japan'],
        },
      },
    ],
  },
});

final _hueArticleResponse = jsonEncode({
  'query': {
    'pages': [
      {
        'pageid': 2,
        'title': 'Huế',
        'pageimage': 'Kyoto.jpg',
        'coordinates': [
          {'lat': 16.4637, 'lon': 107.5909},
        ],
        'terms': {
          'description': ['provincial city in Vietnam'],
        },
      },
    ],
  },
});

String _commonsResponse({
  String mime = 'image/jpeg',
  bool includeArtist = true,
  String licenseUrl = 'https://creativecommons.org/licenses/by-sa/4.0/',
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
              'LicenseUrl': {'value': licenseUrl},
            },
          },
        ],
      },
    ],
  },
});

String _cityResponse({
  required String title,
  required String entityId,
  required String description,
}) => jsonEncode({
  'query': {
    'pages': [
      {
        'pageid': 10,
        'title': title,
        'pageimage': 'Kyoto.jpg',
        'coordinates': [
          {'lat': 35.0, 'lon': 135.0},
        ],
        'pageprops': {'wikibase_item': entityId},
        'terms': {
          'description': [description],
        },
      },
    ],
  },
});

String _countryResponse(String title, String entityId) => jsonEncode({
  'query': {
    'pages': [
      {
        'pageid': 20,
        'title': title,
        'pageprops': {'wikibase_item': entityId},
      },
    ],
  },
});

String _wikidataCountryResponse(String entityId, String countryEntityId) =>
    jsonEncode({
      'entities': {
        entityId: {
          'claims': {
            'P17': [
              {
                'mainsnak': {
                  'datavalue': {
                    'value': {'id': countryEntityId},
                  },
                },
              },
            ],
          },
        },
      },
    });
