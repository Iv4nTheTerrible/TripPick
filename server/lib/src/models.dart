const supportedInterests = {
  'nature',
  'food',
  'culture',
  'shopping',
  'relaxation',
  'adventure',
};

class ValidationFailure implements Exception {
  const ValidationFailure(this.details);

  final List<String> details;
}

class RecommendationRequest {
  const RecommendationRequest({
    required this.originCountry,
    required this.scope,
    required this.budgetLevel,
    required this.tripDays,
    required this.interests,
    required this.locale,
    this.travelMonth,
  });

  final String originCountry;
  final String scope;
  final String budgetLevel;
  final int tripDays;
  final List<String> interests;
  final int? travelMonth;
  final String locale;

  factory RecommendationRequest.fromJson(Map<String, Object?> json) {
    final issues = <String>[];
    final origin = (json['originCountry'] as String? ?? '').toUpperCase();
    final scope = json['scope'] as String? ?? '';
    final budget = json['budgetLevel'] as String? ?? '';
    final days = json['tripDays'];
    final month = json['travelMonth'];
    final locale = json['locale'] as String? ?? '';
    final rawInterests = json['interests'];
    final interests = rawInterests is List
        ? rawInterests.whereType<String>().toList(growable: false)
        : const <String>[];

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(origin)) {
      issues.add('originCountry must be a two-letter ISO code.');
    }
    if (!{'domestic', 'international'}.contains(scope)) {
      issues.add('scope must be domestic or international.');
    }
    if (!{'low', 'medium', 'high'}.contains(budget)) {
      issues.add('budgetLevel must be low, medium, or high.');
    }
    if (days is! int || days < 1 || days > 30) {
      issues.add('tripDays must be between 1 and 30.');
    }
    if (interests.isEmpty ||
        interests.length > 5 ||
        interests.any((interest) => !supportedInterests.contains(interest)) ||
        interests.toSet().length != interests.length) {
      issues.add('interests must contain 1 to 5 distinct supported values.');
    }
    if (month != null && (month is! int || month < 1 || month > 12)) {
      issues.add('travelMonth must be null or between 1 and 12.');
    }
    if (!{'ja', 'en'}.contains(locale)) {
      issues.add('locale must be ja or en.');
    }
    if (issues.isNotEmpty) throw ValidationFailure(issues);

    return RecommendationRequest(
      originCountry: origin,
      scope: scope,
      budgetLevel: budget,
      tripDays: days as int,
      interests: interests,
      travelMonth: month as int?,
      locale: locale,
    );
  }
}

class DestinationCandidate {
  const DestinationCandidate({
    required this.city,
    required this.countryCode,
    required this.reason,
    this.highlights = const [],
  });

  final String city;
  final String countryCode;
  final String reason;
  final List<String> highlights;

  factory DestinationCandidate.fromJson(Map<String, Object?> json) {
    final city = (json['city'] as String? ?? '').trim();
    final country = (json['countryCode'] as String? ?? '').trim().toUpperCase();
    var reason = (json['reason'] as String? ?? '').trim();
    final rawHighlights = json['highlights'];
    final highlights = rawHighlights is List
        ? rawHighlights
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .take(3)
              .toList(growable: false)
        : const <String>[];
    if (city.isEmpty ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(country) ||
        reason.isEmpty ||
        highlights.length != 3) {
      throw const FormatException('Invalid candidate.');
    }
    if (reason.length > 240) reason = reason.substring(0, 240);
    return DestinationCandidate(
      city: city,
      countryCode: country,
      reason: reason,
      highlights: highlights,
    );
  }
}

class RecommendationEngineException implements Exception {
  const RecommendationEngineException({
    required this.code,
    required this.status,
  });

  final String code;
  final int status;
}

abstract interface class RecommendationEngine {
  Future<List<Map<String, Object?>>> recommend(RecommendationRequest request);
}
