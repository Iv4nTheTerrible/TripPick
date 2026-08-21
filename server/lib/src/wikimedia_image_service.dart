import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

abstract interface class DestinationImageResolver {
  Future<WikimediaPhoto> resolve({
    required String imageSearchTerm,
    required String countryCode,
  });
}

class WikimediaPhoto {
  const WikimediaPhoto({
    required this.url,
    required this.attribution,
    required this.sourceUrl,
    required this.licenseUrl,
  });

  const WikimediaPhoto.empty()
    : url = '',
      attribution = '',
      sourceUrl = '',
      licenseUrl = '';

  final String url;
  final String attribution;
  final String sourceUrl;
  final String licenseUrl;

  bool get isEmpty => url.isEmpty;

  Map<String, Object?> toJson() => {
    'url': url,
    'attribution': attribution,
    'sourceUrl': sourceUrl,
    'licenseUrl': licenseUrl,
  };
}

class EmptyDestinationImageResolver implements DestinationImageResolver {
  const EmptyDestinationImageResolver();

  @override
  Future<WikimediaPhoto> resolve({
    required String imageSearchTerm,
    required String countryCode,
  }) async => const WikimediaPhoto.empty();
}

class WikimediaImageResolver implements DestinationImageResolver {
  WikimediaImageResolver({
    http.Client? client,
    DateTime Function()? clock,
    Future<void> Function(Duration)? delay,
    this.cacheDuration = const Duration(hours: 24),
    this.requestTimeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  static const _userAgent = 'TripPick/1.0 (https://github.com/ramen123861/c)';

  final http.Client _client;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _delay;
  final Duration cacheDuration;
  final Duration requestTimeout;
  final Map<String, _CacheEntry> _cache = {};

  @override
  Future<WikimediaPhoto> resolve({
    required String imageSearchTerm,
    required String countryCode,
  }) async {
    final key =
        '${imageSearchTerm.trim().toLowerCase()}|${countryCode.toUpperCase()}';
    final cached = _cache[key];
    final now = _clock();
    if (cached != null && cached.expiresAt.isAfter(now)) return cached.photo;

    WikimediaPhoto photo;
    try {
      photo = await _resolve(imageSearchTerm.trim());
    } catch (_) {
      photo = const WikimediaPhoto.empty();
    }
    _cache[key] = _CacheEntry(photo, now.add(cacheDuration));
    return photo;
  }

  Future<WikimediaPhoto> _resolve(String imageSearchTerm) async {
    if (imageSearchTerm.isEmpty) return const WikimediaPhoto.empty();
    final articleUri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'prop': 'pageimages',
      'piprop': 'name',
      'titles': imageSearchTerm,
    });
    final articleJson = await _getJson(articleUri);
    final pages = _listAt(articleJson, ['query', 'pages']);
    if (pages.isEmpty) return const WikimediaPhoto.empty();
    final page = _map(pages.first);
    final fileName = page['pageimage'];
    if (fileName is! String || fileName.trim().isEmpty) {
      return const WikimediaPhoto.empty();
    }

    final fileUri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'prop': 'imageinfo',
      'titles': 'File:$fileName',
      'iiprop': 'url|extmetadata|mime',
      'iiurlwidth': '1200',
      'iiextmetadatafilter': 'Artist|LicenseShortName|LicenseUrl',
    });
    final fileJson = await _getJson(fileUri);
    final filePages = _listAt(fileJson, ['query', 'pages']);
    if (filePages.isEmpty) return const WikimediaPhoto.empty();
    final imageInfoList = _map(filePages.first)['imageinfo'];
    if (imageInfoList is! List || imageInfoList.isEmpty) {
      return const WikimediaPhoto.empty();
    }
    final imageInfo = _map(imageInfoList.first);
    final mime = imageInfo['mime'];
    final thumbnail = imageInfo['thumburl'];
    final sourceUrl = imageInfo['descriptionurl'];
    if (mime is! String ||
        !mime.startsWith('image/') ||
        thumbnail is! String ||
        sourceUrl is! String ||
        !_trustedUrl(thumbnail, 'upload.wikimedia.org') ||
        !_trustedUrl(sourceUrl, 'commons.wikimedia.org')) {
      return const WikimediaPhoto.empty();
    }

    final metadata = _map(imageInfo['extmetadata']);
    final artist = _metadataText(metadata, 'Artist');
    final license = _metadataText(metadata, 'LicenseShortName');
    final licenseUrl = _metadataText(metadata, 'LicenseUrl');
    if (artist.isEmpty || license.isEmpty || !_trustedHttpsUrl(licenseUrl)) {
      return const WikimediaPhoto.empty();
    }
    return WikimediaPhoto(
      url: thumbnail,
      attribution: '$artist · $license',
      sourceUrl: sourceUrl,
      licenseUrl: licenseUrl,
    );
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      http.Response response;
      try {
        response = await _client
            .get(uri, headers: const {'user-agent': _userAgent})
            .timeout(requestTimeout);
      } catch (_) {
        if (attempt == 0) {
          await _delay(const Duration(milliseconds: 250));
          continue;
        }
        return const {};
      }
      if (response.statusCode == 200) {
        try {
          return Map<String, Object?>.from(jsonDecode(response.body) as Map);
        } catch (_) {
          return const {};
        }
      }
      if (attempt == 0 &&
          (response.statusCode == 429 || response.statusCode >= 500)) {
        await _delay(_retryDelay(response));
        continue;
      }
      return const {};
    }
    return const {};
  }

  Duration _retryDelay(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    if (seconds == null) return const Duration(milliseconds: 250);
    return Duration(seconds: seconds.clamp(0, 5));
  }

  List<Object?> _listAt(Map<String, Object?> json, List<String> path) {
    Object? value = json;
    for (final key in path) {
      if (value is! Map) return const [];
      value = value[key];
    }
    return value is List ? value : const [];
  }

  Map<String, Object?> _map(Object? value) => value is Map
      ? Map<String, Object?>.from(value)
      : const <String, Object?>{};

  String _metadataText(Map<String, Object?> metadata, String key) {
    final entry = _map(metadata[key]);
    final raw = entry['value'];
    if (raw is! String) return '';
    return (html_parser.parseFragment(raw).text ?? '').trim();
  }

  bool _trustedUrl(String value, String host) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host == host;
  }

  bool _trustedHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}

class _CacheEntry {
  const _CacheEntry(this.photo, this.expiresAt);

  final WikimediaPhoto photo;
  final DateTime expiresAt;
}
