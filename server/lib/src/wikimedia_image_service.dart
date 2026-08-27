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
    this.emptyCacheDuration = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  static const _userAgent = 'TripPick/1.0 (https://github.com/ramen123861/c)';

  final http.Client _client;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _delay;
  final Duration cacheDuration;
  final Duration emptyCacheDuration;
  final Duration requestTimeout;
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, String> _countryEntityIds = {};

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
      photo = await _resolve(imageSearchTerm.trim(), countryCode.toUpperCase());
    } catch (_) {
      photo = const WikimediaPhoto.empty();
    }
    final duration = photo.isEmpty ? emptyCacheDuration : cacheDuration;
    _cache[key] = _CacheEntry(photo, now.add(duration));
    return photo;
  }

  Future<WikimediaPhoto> _resolve(
    String imageSearchTerm,
    String countryCode,
  ) async {
    if (imageSearchTerm.isEmpty) return const WikimediaPhoto.empty();
    final countryName = _countryNames[countryCode] ?? countryCode;
    var fileName = await _findLeadImage(
      imageSearchTerm,
      countryCode,
      countryName,
    );
    if (fileName.isEmpty) {
      fileName = await _searchLeadImage(
        imageSearchTerm,
        countryCode,
        countryName,
      );
    }
    if (fileName.isEmpty) return const WikimediaPhoto.empty();

    return _resolveFile(fileName);
  }

  Future<String> _findLeadImage(
    String articleTitle,
    String countryCode,
    String countryName,
  ) async {
    final articleUri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'prop': 'pageimages|coordinates|pageterms|pageprops',
      'piprop': 'name',
      'ppprop': 'wikibase_item',
      'wbptterms': 'description',
      'titles': articleTitle,
    });
    final articleJson = await _getJson(articleUri);
    final pages = _listAt(articleJson, ['query', 'pages']);
    if (pages.isEmpty) return '';
    final page = _map(pages.first);
    if (!await _isExpectedCity(page, countryCode, countryName)) return '';
    final fileName = page['pageimage'];
    return fileName is String ? fileName.trim() : '';
  }

  Future<String> _searchLeadImage(
    String searchTerm,
    String countryCode,
    String countryName,
  ) async {
    final searchUri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'generator': 'search',
      'gsrsearch': '$searchTerm $countryName city',
      'gsrnamespace': '0',
      'gsrlimit': '5',
      'prop': 'pageimages|coordinates|pageterms|pageprops',
      'piprop': 'name',
      'ppprop': 'wikibase_item',
      'wbptterms': 'description',
    });
    final searchJson = await _getJson(searchUri);
    final pages = _listAt(searchJson, ['query', 'pages']);
    for (final rawPage in pages) {
      final page = _map(rawPage);
      if (!await _isExpectedCity(page, countryCode, countryName)) continue;
      final fileName = page['pageimage'];
      if (fileName is String && fileName.trim().isNotEmpty) {
        return fileName.trim();
      }
    }
    return '';
  }

  Future<bool> _isExpectedCity(
    Map<String, Object?> page,
    String countryCode,
    String countryName,
  ) async {
    final coordinates = page['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return false;

    final cityEntityId = _map(page['pageprops'])['wikibase_item'];
    if (cityEntityId is String && cityEntityId.isNotEmpty) {
      final countryEntityId = await _countryEntityId(countryCode, countryName);
      if (countryEntityId.isNotEmpty) {
        final entityCountryIds = await _entityCountryIds(cityEntityId);
        if (entityCountryIds != null && entityCountryIds.isNotEmpty) {
          return entityCountryIds.contains(countryEntityId);
        }
      }
    }

    final terms = _map(page['terms']);
    final descriptions = terms['description'];
    if (descriptions is! List) return false;
    final expectedCountry = _normalizeSearchText(countryName);
    return descriptions.whereType<String>().any(
      (description) =>
          _normalizeSearchText(description).contains(expectedCountry),
    );
  }

  Future<String> _countryEntityId(
    String countryCode,
    String countryName,
  ) async {
    final cached = _countryEntityIds[countryCode];
    if (cached != null) return cached;

    final countryUri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'prop': 'pageprops',
      'ppprop': 'wikibase_item',
      'titles': countryName,
    });
    final countryJson = await _getJson(countryUri);
    final pages = _listAt(countryJson, ['query', 'pages']);
    if (pages.isEmpty) return '';
    final entityId = _map(_map(pages.first)['pageprops'])['wikibase_item'];
    if (entityId is! String || entityId.isEmpty) return '';
    _countryEntityIds[countryCode] = entityId;
    return entityId;
  }

  Future<Set<String>?> _entityCountryIds(String entityId) async {
    final entityUri = Uri.https('www.wikidata.org', '/w/api.php', {
      'action': 'wbgetentities',
      'format': 'json',
      'formatversion': '2',
      'ids': entityId,
      'props': 'claims',
    });
    final entityJson = await _getJson(entityUri);
    if (entityJson.isEmpty) return null;
    final entities = _map(entityJson['entities']);
    final claims = _map(_map(entities[entityId])['claims']);
    final countryClaims = claims['P17'];
    if (countryClaims is! List) return const <String>{};

    return countryClaims
        .map(_map)
        .map((claim) => _map(claim['mainsnak']))
        .map((snak) => _map(snak['datavalue']))
        .map((dataValue) => _map(dataValue['value'])['id'])
        .whereType<String>()
        .toSet();
  }

  String _normalizeSearchText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  Future<WikimediaPhoto> _resolveFile(String fileName) async {
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
    final rawLicenseUrl = _metadataText(metadata, 'LicenseUrl');
    final licenseUrl = _normalizeLicenseUrl(rawLicenseUrl, sourceUrl);
    if (license.isEmpty || licenseUrl.isEmpty) {
      return const WikimediaPhoto.empty();
    }
    final creator = artist.isEmpty ? 'Wikimedia Commons contributor' : artist;
    return WikimediaPhoto(
      url: thumbnail,
      attribution: '$creator · $license',
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

  String _normalizeLicenseUrl(String value, String sourceUrl) {
    if (value.isEmpty) return sourceUrl;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return '';
    if (uri.scheme == 'https') return uri.toString();
    if (uri.scheme == 'http' &&
        const {
          'creativecommons.org',
          'www.creativecommons.org',
        }.contains(uri.host.toLowerCase())) {
      return uri.replace(scheme: 'https').toString();
    }
    return '';
  }
}

class _CacheEntry {
  const _CacheEntry(this.photo, this.expiresAt);

  final WikimediaPhoto photo;
  final DateTime expiresAt;
}

const _countryNames = <String, String>{
  'JP': 'Japan',
  'KR': 'South Korea',
  'CN': 'China',
  'TW': 'Taiwan',
  'SG': 'Singapore',
  'TH': 'Thailand',
  'VN': 'Vietnam',
  'MY': 'Malaysia',
  'ID': 'Indonesia',
  'IN': 'India',
  'AU': 'Australia',
  'NZ': 'New Zealand',
  'US': 'United States',
  'CA': 'Canada',
  'MX': 'Mexico',
  'BR': 'Brazil',
  'AR': 'Argentina',
  'GB': 'United Kingdom',
  'FR': 'France',
  'DE': 'Germany',
  'IT': 'Italy',
  'ES': 'Spain',
  'PT': 'Portugal',
  'NL': 'Netherlands',
  'BE': 'Belgium',
  'CH': 'Switzerland',
  'AT': 'Austria',
  'SE': 'Sweden',
  'NO': 'Norway',
  'DK': 'Denmark',
  'FI': 'Finland',
  'IS': 'Iceland',
  'GR': 'Greece',
  'TR': 'Turkey',
  'AE': 'United Arab Emirates',
  'EG': 'Egypt',
  'ZA': 'South Africa',
};
