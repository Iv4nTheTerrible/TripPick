enum TravelScope {
  domestic,
  international;

  String get wireValue => name;
}

enum BudgetLevel {
  low,
  medium,
  high;

  String get wireValue => name;
}

enum TravelInterest {
  nature,
  food,
  culture,
  shopping,
  relaxation,
  adventure;

  String get wireValue => name;
}

class TravelPreferences {
  const TravelPreferences({
    required this.originCountry,
    required this.scope,
    required this.budgetLevel,
    required this.tripDays,
    required this.interests,
    required this.locale,
    this.travelMonth,
  });

  final String originCountry;
  final TravelScope scope;
  final BudgetLevel budgetLevel;
  final int tripDays;
  final List<TravelInterest> interests;
  final int? travelMonth;
  final String locale;

  Map<String, Object?> toJson() => {
    'originCountry': originCountry,
    'scope': scope.wireValue,
    'budgetLevel': budgetLevel.wireValue,
    'tripDays': tripDays,
    'interests': interests.map((interest) => interest.wireValue).toList(),
    'travelMonth': travelMonth,
    'locale': locale,
  };
}
