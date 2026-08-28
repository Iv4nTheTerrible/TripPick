import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/recommendation_controller.dart';
import '../data/recommendation_repository.dart';
import '../domain/recommendation.dart';
import '../domain/travel_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/trip_pick_theme.dart';

const _heroPhotoSource =
    'https://commons.wikimedia.org/wiki/File:Mountains_%26_clouds_from_plane_window.jpg';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.repository,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    super.key,
  });

  final RecommendationRepository repository;
  final Locale locale;
  final ThemeMode themeMode;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

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
                themeMode: widget.themeMode,
                onLocaleChanged: widget.onLocaleChanged,
                onThemeModeChanged: widget.onThemeModeChanged,
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
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: _Hero(
                                      strings: strings,
                                      showTicket: true,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 46,
                                    ),
                                    child: Container(
                                      key: const Key('planningFormSurface'),
                                      child: _buildFormCard(strings),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _Hero(strings: strings, showTicket: false),
                              const SizedBox(height: 18),
                              Container(
                                key: const Key('planningFormSurface'),
                                child: _buildFormCard(strings),
                              ),
                            ],
                            SizedBox(height: isWide ? 52 : 40),
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
    final palette = context.tripPickPalette;
    return Card(
      key: _formSectionKey,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(height: 7, color: palette.primary),
              ),
              Expanded(
                flex: 2,
                child: Container(height: 7, color: palette.sun),
              ),
              Expanded(
                flex: 2,
                child: Container(height: 7, color: palette.accent),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 25, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionEyebrow(label: strings.stepPreferences),
                  const SizedBox(height: 8),
                  Text(
                    strings.preferencesTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(strings.preferencesSubtitle),
                  const SizedBox(height: 22),
                  _FormBand(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 680;
                        final fieldWidth = isWide
                            ? (constraints.maxWidth - 18) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                key: const Key('originCountry'),
                                isExpanded: true,
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
                                          country.label(
                                            widget.locale.languageCode,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _originCountry = value),
                                validator: (value) => value == null
                                    ? strings.requiredField
                                    : null,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                key: const Key('tripDays'),
                                controller: _daysController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: strings.tripDays,
                                  hintText: strings.tripDaysHint,
                                  prefixIcon: const Icon(
                                    Icons.calendar_view_week,
                                  ),
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
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 640;
                      final scope = _ChoiceField(
                        label: strings.travelScope,
                        child: SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<TravelScope>(
                            key: const Key('travelScope'),
                            style: _segmentedButtonStyle(context),
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
                            style: _segmentedButtonStyle(context),
                            segments: [
                              ButtonSegment(
                                value: BudgetLevel.low,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(strings.low, maxLines: 1),
                                ),
                              ),
                              ButtonSegment(
                                value: BudgetLevel.medium,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(strings.medium, maxLines: 1),
                                ),
                              ),
                              ButtonSegment(
                                value: BudgetLevel.high,
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(strings.high, maxLines: 1),
                                ),
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
                  const SizedBox(height: 5),
                  Text(
                    strings.chooseInterests,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedText),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720 ? 3 : 2;
                      final tileWidth =
                          (constraints.maxWidth - ((columns - 1) * 10)) /
                          columns;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: TravelInterest.values.map((interest) {
                          final selected = _interests.contains(interest);
                          return _InterestTile(
                            key: Key('interest-${interest.name}'),
                            width: tileWidth,
                            icon: _interestIcon(interest),
                            label: _interestLabel(strings, interest),
                            selected: selected,
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
                      );
                    },
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
                  const SizedBox(height: 17),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: palette.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.budgetNote,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.mutedText),
                        ),
                      ),
                    ],
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
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
                  ),
                ],
              ),
            ),
          ),
        ],
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
  const _TopBar({
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.tripPickPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
        boxShadow: [
          BoxShadow(
            color: palette.primaryStrong.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: palette.primaryStrong,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: palette.sun,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.appName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (constraints.maxWidth >= 700)
                        Text(
                          strings.appTagline,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.mutedText),
                        ),
                    ],
                  ),
                ),
                Tooltip(
                  message: strings.language,
                  child: PopupMenuButton<String>(
                    key: const Key('languageMenu'),
                    tooltip: strings.language,
                    initialValue: locale.languageCode,
                    onSelected: (value) => onLocaleChanged(Locale(value)),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'ja', child: Text(strings.japanese)),
                      PopupMenuItem(value: 'en', child: Text(strings.english)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            locale.languageCode == 'ja' ? 'JA' : 'EN',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.expand_more, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<ThemeMode>(
                  key: const Key('themeModeMenu'),
                  tooltip: strings.appearance,
                  initialValue: themeMode,
                  icon: Icon(_themeModeIcon(themeMode)),
                  onSelected: onThemeModeChanged,
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      key: const Key('themeMode-system'),
                      value: ThemeMode.system,
                      checked: themeMode == ThemeMode.system,
                      child: Text(strings.themeSystem),
                    ),
                    CheckedPopupMenuItem(
                      key: const Key('themeMode-light'),
                      value: ThemeMode.light,
                      checked: themeMode == ThemeMode.light,
                      child: Text(strings.themeLight),
                    ),
                    CheckedPopupMenuItem(
                      key: const Key('themeMode-dark'),
                      value: ThemeMode.dark,
                      checked: themeMode == ThemeMode.dark,
                      child: Text(strings.themeDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.strings, required this.showTicket});

  final AppLocalizations strings;
  final bool showTicket;

  Future<void> _openSource(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(_heroPhotoSource),
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
    final palette = context.tripPickPalette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final isJapanese = Localizations.localeOf(context).languageCode == 'ja';
        return Container(
          key: const Key('travelHero'),
          constraints: BoxConstraints(minHeight: compact ? 380 : 430),
          decoration: BoxDecoration(
            color: palette.heroSurface,
            borderRadius: BorderRadius.circular(compact ? 20 : 28),
            border: Border.all(color: palette.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: palette.primaryStrong.withValues(alpha: 0.22),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/trip_pick_hero.jpg',
                  key: const Key('heroPhoto'),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.18),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.heroSurface.withValues(alpha: 0.97),
                        palette.heroSurface.withValues(alpha: 0.76),
                        palette.heroSurface.withValues(alpha: 0.18),
                      ],
                      stops: const [0, 0.48, 1],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: compact ? 28 : 72,
                child: Container(
                  width: compact ? 94 : 150,
                  height: 9,
                  color: palette.accent,
                ),
              ),
              Positioned(
                right: compact ? -28 : 26,
                bottom: compact ? 28 : 22,
                child: CustomPaint(
                  size: Size(compact ? 210 : 330, compact ? 125 : 190),
                  painter: _RouteLinePainter(
                    lineColor: Colors.white.withValues(alpha: 0.38),
                    pointColor: palette.sun,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 26 : 46,
                  compact ? 34 : 48,
                  compact ? 24 : 34,
                  compact ? 58 : 44,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: showTicket ? 610 : 650),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: palette.sun,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          strings.heroKicker.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF25312C),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.05,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 24 : 30),
                      Text(
                        strings.heroTitle,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: palette.heroText,
                              fontSize: compact
                                  ? (isJapanese ? 33 : 39)
                                  : (isJapanese ? 47 : 52),
                              height: 1.02,
                              letterSpacing: -1.1,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.heroBody,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: palette.heroText.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 2,
                            color: palette.accent,
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              strings.heroSummary,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: palette.heroText.withValues(
                                      alpha: 0.84,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (showTicket)
                Positioned(
                  right: 52,
                  top: 70,
                  child: _TravelTicket(strings: strings),
                ),
              Positioned(
                right: 16,
                bottom: 11,
                child: Tooltip(
                  message: strings.photoSource,
                  child: InkWell(
                    key: const Key('heroPhotoAttribution'),
                    onTap: () => _openSource(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.imageOverlay,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Mashkawat Ahsan · CC BY-SA 4.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TravelTicket extends StatelessWidget {
  const _TravelTicket({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.tripPickPalette;
    return Transform.rotate(
      angle: 0.035,
      child: Container(
        width: 255,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EC).withValues(alpha: 0.94),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(7),
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000F0C),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: palette.primaryStrong, size: 22),
                const Spacer(),
                Text(
                  'TRIPPICK / 03',
                  style: TextStyle(
                    color: palette.primaryStrong,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _TicketStop(color: palette.accent),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: 1,
                    color: palette.primaryStrong.withValues(alpha: 0.35),
                  ),
                ),
                Icon(
                  Icons.flight_rounded,
                  color: palette.primaryStrong,
                  size: 20,
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    height: 1,
                    color: palette.primaryStrong.withValues(alpha: 0.35),
                  ),
                ),
                _TicketStop(color: palette.sun),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              strings.heroSummary,
              style: const TextStyle(
                color: Color(0xFF17312B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketStop extends StatelessWidget {
  const _TicketStop({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}

class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter({required this.lineColor, required this.pointColor});

  final Color lineColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(8, size.height * 0.74)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.58,
        size.height * 0.92,
        size.width - 10,
        size.height * 0.18,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final pointPaint = Paint()..color = pointColor;
    canvas
      ..drawCircle(Offset(8, size.height * 0.74), 5, pointPaint)
      ..drawCircle(Offset(size.width - 10, size.height * 0.18), 5, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.pointColor != pointColor;
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
    final palette = context.tripPickPalette;
    return Container(
      key: const Key('recommendationResults'),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(26, 24, 22, 24),
            decoration: BoxDecoration(
              color: palette.mutedSurface.withValues(alpha: 0.58),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionEyebrow(label: strings.stepResults),
                      const SizedBox(height: 6),
                      Text(
                        strings.resultsTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.resultsSubtitle,
                        style: TextStyle(color: palette.mutedText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: palette.primaryStrong,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ],
            ),
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
    final palette = context.tripPickPalette;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DestinationImage(
            photo: recommendation.photo,
            label: recommendation.city,
            rank: rank,
            strings: strings,
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(height: 5, color: palette.primary),
              ),
              Expanded(child: Container(height: 5, color: palette.sun)),
              Expanded(child: Container(height: 5, color: palette.accent)),
            ],
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
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.mutedSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        recommendation.countryCode,
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  recommendation.reason,
                  style: TextStyle(color: palette.mutedText, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.highlights,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: palette.mutedSurface.withValues(alpha: 0.44),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: recommendation.highlights.indexed
                        .map(
                          (entry) => Column(
                            children: [
                              if (entry.$1 > 0) const Divider(height: 1),
                              InkWell(
                                key: Key(
                                  'highlight-${recommendation.city}-${entry.$1}',
                                ),
                                onTap: () => _open(context, entry.$2.mapsUri),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.place_outlined,
                                        color: palette.accent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(child: Text(entry.$2.name)),
                                      Icon(
                                        Icons.north_east,
                                        size: 14,
                                        color: palette.mutedText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _open(context, recommendation.mapsUri),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(strings.openMaps),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.poweredByGoogle,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: palette.mutedText),
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
    required this.rank,
    required this.strings,
  });

  final PlacePhoto photo;
  final String label;
  final int rank;
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
    final palette = context.tripPickPalette;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primaryStrong,
            palette.primary.withValues(alpha: 0.76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Semantics(
          image: true,
          label: strings.photoUnavailable,
          child: Icon(Icons.landscape_outlined, size: 54, color: Colors.white),
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo.url.isEmpty)
            fallback
          else
            Semantics(
              image: true,
              label: label,
              child: Image.network(
                photo.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: palette.primaryStrong.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
              ),
              child: Text(
                rank.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
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
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: palette.imageOverlay,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
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
                                Icons.north_east,
                                color: Colors.white,
                                size: 11,
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
      ),
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

class _FormBand extends StatelessWidget {
  const _FormBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.tripPickPalette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.mutedSurface.withValues(alpha: 0.62),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.tripPickPalette;
    final foreground = selected ? palette.onSelection : palette.text;
    return SizedBox(
      width: width,
      child: FilterChip(
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        backgroundColor: palette.raisedSurface,
        selectedColor: palette.selection,
        side: BorderSide(
          color: selected ? palette.selection : palette.border,
          width: selected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
        labelPadding: const EdgeInsets.symmetric(horizontal: 7),
        label: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Icon(icon, size: 19, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 5),
                Icon(Icons.check_rounded, size: 17, color: foreground),
              ],
            ],
          ),
        ),
      ),
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

ButtonStyle _segmentedButtonStyle(BuildContext context) {
  final palette = context.tripPickPalette;
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return palette.selection;
      return palette.raisedSurface;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return palette.onSelection;
      return palette.text;
    }),
    iconColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return palette.onSelection;
      return palette.primary;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      return BorderSide(
        color: states.contains(WidgetState.selected)
            ? palette.selection
            : palette.border,
        width: states.contains(WidgetState.focused) ? 2 : 1,
      );
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
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
