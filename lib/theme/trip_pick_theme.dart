import 'package:flutter/material.dart';

@immutable
class TripPickPalette extends ThemeExtension<TripPickPalette> {
  const TripPickPalette({
    required this.canvas,
    required this.surface,
    required this.raisedSurface,
    required this.mutedSurface,
    required this.text,
    required this.mutedText,
    required this.border,
    required this.primary,
    required this.primaryStrong,
    required this.accent,
    required this.sun,
    required this.selection,
    required this.onSelection,
    required this.heroSurface,
    required this.heroText,
    required this.imageOverlay,
  });

  static const light = TripPickPalette(
    canvas: Color(0xFFFFF8EC),
    surface: Color(0xFFFFFFFF),
    raisedSurface: Color(0xFFFFFFFF),
    mutedSurface: Color(0xFFFFF3DC),
    text: Color(0xFF17312B),
    mutedText: Color(0xFF566761),
    border: Color(0xFFD8D9CC),
    primary: Color(0xFF087F6A),
    primaryStrong: Color(0xFF075E54),
    accent: Color(0xFFE76F51),
    sun: Color(0xFFF2B84B),
    selection: Color(0xFF087162),
    onSelection: Color(0xFFFFFFFF),
    heroSurface: Color(0xFF075E54),
    heroText: Color(0xFFFFFFFF),
    imageOverlay: Color(0xBD071D19),
  );

  static const dark = TripPickPalette(
    canvas: Color(0xFF071712),
    surface: Color(0xFF0E211B),
    raisedSurface: Color(0xFF173129),
    mutedSurface: Color(0xFF1E3A31),
    text: Color(0xFFFFF8EB),
    mutedText: Color(0xFFB5C7BE),
    border: Color(0xFF315046),
    primary: Color(0xFF4FD1B5),
    primaryStrong: Color(0xFF087F6A),
    accent: Color(0xFFFF8B68),
    sun: Color(0xFFF2C45E),
    selection: Color(0xFF087162),
    onSelection: Color(0xFFFFFFFF),
    heroSurface: Color(0xFF063C35),
    heroText: Color(0xFFFFF8EB),
    imageOverlay: Color(0xC4071712),
  );

  final Color canvas;
  final Color surface;
  final Color raisedSurface;
  final Color mutedSurface;
  final Color text;
  final Color mutedText;
  final Color border;
  final Color primary;
  final Color primaryStrong;
  final Color accent;
  final Color sun;
  final Color selection;
  final Color onSelection;
  final Color heroSurface;
  final Color heroText;
  final Color imageOverlay;

  @override
  TripPickPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? raisedSurface,
    Color? mutedSurface,
    Color? text,
    Color? mutedText,
    Color? border,
    Color? primary,
    Color? primaryStrong,
    Color? accent,
    Color? sun,
    Color? selection,
    Color? onSelection,
    Color? heroSurface,
    Color? heroText,
    Color? imageOverlay,
  }) => TripPickPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    raisedSurface: raisedSurface ?? this.raisedSurface,
    mutedSurface: mutedSurface ?? this.mutedSurface,
    text: text ?? this.text,
    mutedText: mutedText ?? this.mutedText,
    border: border ?? this.border,
    primary: primary ?? this.primary,
    primaryStrong: primaryStrong ?? this.primaryStrong,
    accent: accent ?? this.accent,
    sun: sun ?? this.sun,
    selection: selection ?? this.selection,
    onSelection: onSelection ?? this.onSelection,
    heroSurface: heroSurface ?? this.heroSurface,
    heroText: heroText ?? this.heroText,
    imageOverlay: imageOverlay ?? this.imageOverlay,
  );

  @override
  TripPickPalette lerp(covariant TripPickPalette? other, double t) {
    if (other == null) return this;
    return TripPickPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raisedSurface: Color.lerp(raisedSurface, other.raisedSurface, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      onSelection: Color.lerp(onSelection, other.onSelection, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      heroText: Color.lerp(heroText, other.heroText, t)!,
      imageOverlay: Color.lerp(imageOverlay, other.imageOverlay, t)!,
    );
  }
}

abstract final class TripPickTheme {
  static ThemeData get light => _build(TripPickPalette.light, Brightness.light);

  static ThemeData get dark => _build(TripPickPalette.dark, Brightness.dark);

  static ThemeData _build(TripPickPalette palette, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
          surface: palette.surface,
        ).copyWith(
          primary: palette.primary,
          onPrimary: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF06231C),
          primaryContainer: brightness == Brightness.light
              ? const Color(0xFFD5F4EA)
              : const Color(0xFF184D42),
          onPrimaryContainer: brightness == Brightness.light
              ? palette.primaryStrong
              : palette.text,
          secondary: palette.accent,
          onSecondary: brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF2C130B),
          surface: palette.surface,
          onSurface: palette.text,
          outline: palette.border,
          outlineVariant: palette.border,
        );
    final baseTextTheme = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      fontFamilyFallback: const ['NotoSansJP'],
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      extensions: [palette],
      fontFamilyFallback: const ['NotoSansJP'],
      useMaterial3: true,
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.08,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: -0.4,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.55),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.raisedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.raisedSurface,
        elevation: brightness == Brightness.light ? 5 : 1,
        shadowColor: palette.primaryStrong.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.raisedSurface,
        selectedColor: palette.selection,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        labelStyle: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
        secondaryLabelStyle: TextStyle(
          color: palette.onSelection,
          fontWeight: FontWeight.w800,
        ),
        checkmarkColor: palette.onSelection,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.raisedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.text,
        contentTextStyle: TextStyle(color: palette.canvas),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension TripPickThemeContext on BuildContext {
  TripPickPalette get tripPickPalette =>
      Theme.of(this).extension<TripPickPalette>()!;
}
