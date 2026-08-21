import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/recommendation_controller.dart';
import '../data/recommendation_repository.dart';
import '../domain/recommendation.dart';
import '../domain/travel_preferences.dart';
import '../l10n/generated/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.repository,
    required this.locale,
    required this.onLocaleChanged,
    super.key,
  });

  final RecommendationRepository repository;
  final Locale locale;
  final Future<void> Function(Locale locale) onLocaleChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _formSectionKey = GlobalKey();
  final _resultsSectionKey = GlobalKey();
  final _daysController = TextEditingController(text: '4');

  late final RecommendationController _controller;
  String? _originCountry = 'JP';
  TravelScope _scope = TravelScope.domestic;
  BudgetLevel _budget = BudgetLevel.medium;
  final Set<TravelInterest> _interests = {
    TravelInterest.food,
    TravelInterest.culture,
  };
  int? _travelMonth;

  @override
  void initState() {
    super.initState();
    _controller = RecommendationController(widget.repository)
      ..addListener(_onControllerChanged);
    _daysController.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _daysController
      ..removeListener(_refreshForm)
      ..dispose();
    super.dispose();
  }

  void _refreshForm() => setState(() {});

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_controller.status == RecommendationStatus.success ||
        _controller.status == RecommendationStatus.failure) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _resultsSectionKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            alignment: 0.05,
          );
        }
      });
    }
  }

  bool get _canSubmit {
    final days = int.tryParse(_daysController.text);
    return _originCountry != null &&
        days != null &&
        days >= 1 &&
        days <= 30 &&
        _interests.isNotEmpty &&
        _interests.length <= 5 &&
        _controller.status != RecommendationStatus.loading;
  }

  Future<void> _submit() async {
    if (!_canSubmit || !(_formKey.currentState?.validate() ?? false)) return;
    await _controller.fetch(
      TravelPreferences(
        originCountry: _originCountry!,
        scope: _scope,
        budgetLevel: _budget,
        tripDays: int.parse(_daysController.text),
        interests: _interests.toList(growable: false),
        travelMonth: _travelMonth,
        locale: widget.locale.languageCode,
      ),
    );
  }

  void _scrollToForm() {
    final context = _formSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopBar(
                locale: widget.locale,
                onLocaleChanged: widget.onLocaleChanged,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 56),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 960;
                        return Column(
                          children: [
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 390,
                                    child: _Hero(strings: strings),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildFormCard(strings)),
                                ],
                              )
                            else ...[
                              _Hero(strings: strings),
                              const SizedBox(height: 18),
                              _buildFormCard(strings),
                            ],
                            const SizedBox(height: 40),
                            _buildStatusSection(strings),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(AppLocalizations strings) {
    return Card(
      key: _formSectionKey,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionEyebrow(label: strings.stepPreferences),
              const SizedBox(height: 10),
              Text(
                strings.preferencesTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(strings.preferencesSubtitle),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final fieldWidth = isWide
                      ? (constraints.maxWidth - 20) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 22,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          key: const Key('originCountry'),
                          initialValue: _originCountry,
                          decoration: InputDecoration(
                            labelText: strings.originCountry,
                            prefixIcon: const Icon(Icons.public),
                          ),
                          items: _countries
                              .map(
                                (country) => DropdownMenuItem(
                                  value: country.code,
                                  child: Text(
                                    country.label(widget.locale.languageCode),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _originCountry = value),
                          validator: (value) =>
                              value == null ? strings.requiredField : null,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          key: const Key('tripDays'),
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.tripDays,
                            hintText: strings.tripDaysHint,
                            prefixIcon: const Icon(Icons.calendar_view_week),
                          ),
                          validator: (value) {
                            final days = int.tryParse(value ?? '');
                            return days == null || days < 1 || days > 30
                                ? strings.invalidDays
                                : null;
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 640;
                  final scope = _ChoiceField(
                    label: strings.travelScope,
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TravelScope>(
                        key: const Key('travelScope'),
                        segments: [
                          ButtonSegment(
                            value: TravelScope.domestic,
                            icon: const Icon(Icons.home_outlined),
                            label: Text(strings.domestic),
                          ),
                          ButtonSegment(
                            value: TravelScope.international,
                            icon: const Icon(Icons.flight_takeoff),
                            label: Text(strings.international),
                          ),
                        ],
                        selected: {_scope},
                        onSelectionChanged: (value) =>
                            setState(() => _scope = value.first),
                      ),
                    ),
                  );
                  final budget = _ChoiceField(
                    label: strings.budget,
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<BudgetLevel>(
                        key: const Key('budgetLevel'),
                        segments: [
                          ButtonSegment(
                            value: BudgetLevel.low,
                            label: Text(strings.low),
                          ),
                          ButtonSegment(
                            value: BudgetLevel.medium,
                            label: Text(strings.medium),
                          ),
                          ButtonSegment(
                            value: BudgetLevel.high,
                            label: Text(strings.high),
                          ),
                        ],
                        selected: {_budget},
                        onSelectionChanged: (value) =>
                            setState(() => _budget = value.first),
                      ),
                    ),
                  );
                  if (!isWide) {
                    return Column(
                      children: [scope, const SizedBox(height: 20), budget],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: scope),
                      const SizedBox(width: 18),
                      Expanded(child: budget),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              _FieldLabel(strings.interests),
              const SizedBox(height: 6),
              Text(
                strings.chooseInterests,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TravelInterest.values.map((interest) {
                  final selected = _interests.contains(interest);
                  return FilterChip(
                    key: Key('interest-${interest.name}'),
                    selected: selected,
                    showCheckmark: true,
                    avatar: Icon(_interestIcon(interest), size: 18),
                    label: Text(_interestLabel(strings, interest)),
                    onSelected: (value) {
                      setState(() {
                        if (value && _interests.length < 5) {
                          _interests.add(interest);
                        } else if (!value) {
                          _interests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<int?>(
                key: const Key('travelMonth'),
                initialValue: _travelMonth,
                decoration: InputDecoration(
                  labelText: strings.travelMonth,
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(strings.anyMonth),
                  ),
                  ...List.generate(
                    12,
                    (index) => DropdownMenuItem<int?>(
                      value: index + 1,
                      child: Text(_monthLabel(strings, index + 1)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _travelMonth = value),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(strings.budgetNote)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('submitPreferences'),
                  onPressed: _canSubmit ? _submit : null,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.findDestinations),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(AppLocalizations strings) {
    return switch (_controller.status) {
      RecommendationStatus.initial => const SizedBox.shrink(),
      RecommendationStatus.loading => _LoadingPanel(
        key: _resultsSectionKey,
        strings: strings,
      ),
      RecommendationStatus.failure => _ErrorPanel(
        key: _resultsSectionKey,
        title: strings.errorTitle,
        message: _errorMessage(strings),
        canRetry: _controller.failure?.retryable ?? true,
        onRetry: _controller.retry,
        onEdit: _scrollToForm,
        strings: strings,
      ),
      RecommendationStatus.success => _ResultsSection(
        key: _resultsSectionKey,
        recommendations: _controller.recommendations,
        strings: strings,
        onEdit: _scrollToForm,
        onRefresh: _controller.retry,
      ),
    };
  }

  String _errorMessage(AppLocalizations strings) {
    final failure = _controller.failure;
    if (failure == null) return strings.genericError;
    return switch (failure.kind) {
      RecommendationFailureKind.connection => strings.connectionError,
      RecommendationFailureKind.invalidResponse => strings.invalidResponse,
      RecommendationFailureKind.server =>
        failure.message.isEmpty ? strings.genericError : failure.message,
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.locale, required this.onLocaleChanged});

  final Locale locale;
  final Future<void> Function(Locale locale) onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      color: const Color(0xFFF8F5EE),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.appName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      strings.appTagline,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Semantics(
                label: strings.language,
                child: SegmentedButton<String>(
                  key: const Key('languageSwitch'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'ja', label: Text('日本語')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: {locale.languageCode},
                  onSelectionChanged: (value) =>
                      onLocaleChanged(Locale(value.first)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 440),
      padding: const EdgeInsets.fromLTRB(30, 32, 30, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A514E), Color(0xFF12786E), Color(0xFF309583)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24104F49),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -30,
            child: Icon(
              Icons.public,
              size: 180,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  strings.heroBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                strings.heroTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.heroBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              _HeroBenefit(icon: Icons.bolt_rounded, label: strings.quickSetup),
              const SizedBox(height: 12),
              _HeroBenefit(
                icon: Icons.auto_awesome_rounded,
                label: strings.threeMatches,
              ),
              const SizedBox(height: 12),
              _HeroBenefit(
                icon: Icons.photo_camera_outlined,
                label: strings.realPlaces,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBenefit extends StatelessWidget {
  const _HeroBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDDA5).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFFFD89A)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.recommendations,
    required this.strings,
    required this.onEdit,
    required this.onRefresh,
    super.key,
  });

  final List<DestinationRecommendation> recommendations;
  final AppLocalizations strings;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('recommendationResults'),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.luggage_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionEyebrow(label: strings.stepResults),
                    const SizedBox(height: 6),
                    Text(
                      strings.resultsTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(strings.resultsSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 18)) / columns;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: recommendations.indexed
                    .map(
                      (entry) => SizedBox(
                        width: width,
                        child: _DestinationCard(
                          rank: entry.$1 + 1,
                          recommendation: entry.$2,
                          strings: strings,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.tune_rounded),
                label: Text(strings.editPreferences),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.newRecommendations),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.rank,
    required this.recommendation,
    required this.strings,
  });

  final int rank;
  final DestinationRecommendation recommendation;
  final AppLocalizations strings;

  Future<void> _open(BuildContext context, String value) async {
    final opened = await launchUrl(
      Uri.parse(value),
      webOnlyWindowName: '_blank',
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.mapsError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DestinationImage(
            photo: recommendation.photo,
            label: recommendation.city,
            badge: strings.matchNumber(rank),
            strings: strings,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recommendation.city,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        recommendation.countryCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  recommendation.reason,
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.highlights,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...recommendation.highlights.map(
                  (highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => _open(context, highlight.mapsUri),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(highlight.name)),
                            const Icon(Icons.open_in_new, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _open(context, recommendation.mapsUri),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(strings.openMaps),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.poweredByGoogle,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationImage extends StatelessWidget {
  const _DestinationImage({
    required this.photo,
    required this.label,
    required this.badge,
    required this.strings,
  });

  final PlacePhoto photo;
  final String label;
  final String badge;
  final AppLocalizations strings;

  Future<void> _openSource(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(photo.sourceUrl),
      webOnlyWindowName: '_blank',
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.photoSourceError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBCDCD5), Color(0xFFF2C98D)],
        ),
      ),
      child: Semantics(
        image: true,
        label: strings.photoUnavailable,
        child: const Icon(
          Icons.landscape_outlined,
          size: 58,
          color: Color(0xFF315B55),
        ),
      ),
    );
    return Stack(
      children: [
        if (photo.url.isEmpty)
          fallback
        else
          Semantics(
            image: true,
            label: label,
            child: Image.network(
              photo.url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (photo.attribution.isNotEmpty)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Semantics(
                button: photo.sourceUrl.isNotEmpty,
                label: '${strings.photoSource}: ${photo.attribution}',
                child: Tooltip(
                  message: strings.photoSource,
                  child: InkWell(
                    key: Key('photoAttribution-$label'),
                    onTap: photo.sourceUrl.isEmpty
                        ? null
                        : () => _openSource(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              photo.attribution,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (photo.sourceUrl.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.strings, super.key});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('loadingPanel'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.loadingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(strings.loadingBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.title,
    required this.message,
    required this.canRetry,
    required this.onRetry,
    required this.onEdit,
    required this.strings,
    super.key,
  });

  final String title;
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onEdit;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('errorPanel'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.travel_explore,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  child: Text(strings.editPreferences),
                ),
                if (canRetry)
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(strings.tryAgain),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_FieldLabel(label), const SizedBox(height: 10), child],
    );
  }
}

IconData _interestIcon(TravelInterest interest) => switch (interest) {
  TravelInterest.nature => Icons.park_outlined,
  TravelInterest.food => Icons.restaurant_outlined,
  TravelInterest.culture => Icons.museum_outlined,
  TravelInterest.shopping => Icons.shopping_bag_outlined,
  TravelInterest.relaxation => Icons.spa_outlined,
  TravelInterest.adventure => Icons.hiking_outlined,
};

String _interestLabel(AppLocalizations strings, TravelInterest interest) =>
    switch (interest) {
      TravelInterest.nature => strings.nature,
      TravelInterest.food => strings.food,
      TravelInterest.culture => strings.culture,
      TravelInterest.shopping => strings.shopping,
      TravelInterest.relaxation => strings.relaxation,
      TravelInterest.adventure => strings.adventure,
    };

String _monthLabel(AppLocalizations strings, int month) => switch (month) {
  1 => strings.month1,
  2 => strings.month2,
  3 => strings.month3,
  4 => strings.month4,
  5 => strings.month5,
  6 => strings.month6,
  7 => strings.month7,
  8 => strings.month8,
  9 => strings.month9,
  10 => strings.month10,
  11 => strings.month11,
  _ => strings.month12,
};

class _CountryOption {
  const _CountryOption(this.code, this.en, this.ja);

  final String code;
  final String en;
  final String ja;

  String label(String locale) => '$code — ${locale == 'ja' ? ja : en}';
}

const _countries = [
  _CountryOption('JP', 'Japan', '日本'),
  _CountryOption('KR', 'South Korea', '韓国'),
  _CountryOption('CN', 'China', '中国'),
  _CountryOption('TW', 'Taiwan', '台湾'),
  _CountryOption('SG', 'Singapore', 'シンガポール'),
  _CountryOption('TH', 'Thailand', 'タイ'),
  _CountryOption('VN', 'Vietnam', 'ベトナム'),
  _CountryOption('MY', 'Malaysia', 'マレーシア'),
  _CountryOption('ID', 'Indonesia', 'インドネシア'),
  _CountryOption('IN', 'India', 'インド'),
  _CountryOption('AU', 'Australia', 'オーストラリア'),
  _CountryOption('NZ', 'New Zealand', 'ニュージーランド'),
  _CountryOption('US', 'United States', 'アメリカ'),
  _CountryOption('CA', 'Canada', 'カナダ'),
  _CountryOption('MX', 'Mexico', 'メキシコ'),
  _CountryOption('BR', 'Brazil', 'ブラジル'),
  _CountryOption('AR', 'Argentina', 'アルゼンチン'),
  _CountryOption('GB', 'United Kingdom', 'イギリス'),
  _CountryOption('FR', 'France', 'フランス'),
  _CountryOption('DE', 'Germany', 'ドイツ'),
  _CountryOption('IT', 'Italy', 'イタリア'),
  _CountryOption('ES', 'Spain', 'スペイン'),
  _CountryOption('PT', 'Portugal', 'ポルトガル'),
  _CountryOption('NL', 'Netherlands', 'オランダ'),
  _CountryOption('BE', 'Belgium', 'ベルギー'),
  _CountryOption('CH', 'Switzerland', 'スイス'),
  _CountryOption('AT', 'Austria', 'オーストリア'),
  _CountryOption('SE', 'Sweden', 'スウェーデン'),
  _CountryOption('NO', 'Norway', 'ノルウェー'),
  _CountryOption('DK', 'Denmark', 'デンマーク'),
  _CountryOption('FI', 'Finland', 'フィンランド'),
  _CountryOption('IS', 'Iceland', 'アイスランド'),
  _CountryOption('GR', 'Greece', 'ギリシャ'),
  _CountryOption('TR', 'Turkey', 'トルコ'),
  _CountryOption('AE', 'United Arab Emirates', 'アラブ首長国連邦'),
  _CountryOption('EG', 'Egypt', 'エジプト'),
  _CountryOption('ZA', 'South Africa', '南アフリカ'),
];
